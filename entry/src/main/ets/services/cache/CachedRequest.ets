import type { ApiDataResult, BaseAPIResponse } from '../../models/types';

export interface CachedValue<T> { data: T; savedAt: number; fresh: boolean; }
export interface RequestCache<T> {
    read(key: string, ttlMs: number): Promise<CachedValue<T> | undefined>;
    write(key: string, value: T, generation: number): Promise<void>;
    generation(): number;
}

/** A page owns a scope, while a merged transport is cancelled only after its last scoped subscriber leaves. */
export class RequestScope {
    cancelled: boolean = false;
    private listeners: Set<() => void> = new Set();
    onCancel(listener: () => void): () => void {
        if (this.cancelled) { listener(); return (): void => {}; }
        this.listeners.add(listener);
        return (): void => { this.listeners.delete(listener); };
    }
    waitFor<T>(operation: Promise<T>): Promise<T> {
        return new Promise<T>((resolve, reject): void => {
            let settled = false;
            let unsubscribe: () => void = (): void => {};
            const fail = (error: Error): void => {
                if (settled) return;
                settled = true; unsubscribe(); reject(error);
            };
            unsubscribe = this.onCancel((): void => fail(new Error('请求已取消')));
            // Always observe the operation, including late rejection after cancellation.
            operation.then((value: T): void => {
                if (settled) return;
                settled = true; unsubscribe(); resolve(value);
            }, fail);
        });
    }
    cancel(): void {
        if (this.cancelled) return;
        this.cancelled = true;
        for (const listener of this.listeners) { try { listener(); } catch (_) { /* Continue cancelling other subscribers. */ } }
        this.listeners.clear();
    }
}

interface PendingRequest<T> {
    result: Promise<ApiDataResult<T>>;
    transport: RequestScope;
    subscribers: number;
    unscoped: boolean;
}

interface RequestOrder {
    active: number;
    latestNetwork: number;
}

export function validApiResponse(value: BaseAPIResponse | null | undefined): boolean {
    return value !== null && typeof value === 'object' && value.success === true &&
        value.data !== null && typeof value.data === 'object';
}

/** 网络、文件系统和 UI 解耦，统一处理请求合并、失败回退与清理期间的失效。 */
export class CachedRequest<T> {
    private cache: RequestCache<T>;
    private validate: (value: T) => boolean;
    private pending: Map<string, PendingRequest<T>> = new Map();
    private ordering: Map<string, RequestOrder> = new Map();
    private sequence: number = 0;

    constructor(cache: RequestCache<T>, validate: (value: T) => boolean) {
        this.cache = cache;
        this.validate = validate;
    }

    request(key: string, ttlMs: number, force: boolean, fetch: (scope: RequestScope, refresh: boolean) => Promise<T>,
        staleWhileRevalidate: boolean = false, scope?: RequestScope): Promise<ApiDataResult<T>> {
        if (scope?.cancelled) return Promise.reject(new Error('请求已取消'));
        const generation = this.cache.generation();
        // 强制刷新独立于普通读取，清理后的请求也不复用清理前的 Promise。
        const pendingKey = `${generation}:${force}:${staleWhileRevalidate}:${key}`;
        const existing = this.pending.get(pendingKey);
        if (existing && !existing.transport.cancelled) return this.subscribe(existing, scope);
        // Reserve ordering before asynchronous cache I/O. Keep the barrier until all older reads finish.
        const orderKey = `${generation}:${key}`;
        const order: RequestOrder = this.ordering.get(orderKey) ?? { active: 0, latestNetwork: 0 };
        this.ordering.set(orderKey, order);
        order.active++;
        const ticket = ++this.sequence;
        const transport = new RequestScope();
        const result = this.load(key, ttlMs, force, generation, fetch, staleWhileRevalidate, transport, order, ticket)
            .finally((): void => {
                order.active--;
                if (order.active === 0 && this.ordering.get(orderKey) === order) this.ordering.delete(orderKey);
            });
        const pending: PendingRequest<T> = { result, transport, subscribers: 0, unscoped: false };
        this.pending.set(pendingKey, pending);
        const release = (): void => {
            if (this.pending.get(pendingKey) === pending) this.pending.delete(pendingKey);
        };
        result.then(release, release);
        return this.subscribe(pending, scope);
    }

    private subscribe(pending: PendingRequest<T>, scope?: RequestScope): Promise<ApiDataResult<T>> {
        if (!scope) { pending.unscoped = true; return pending.result; }
        pending.subscribers++;
        return new Promise<ApiDataResult<T>>((resolve, reject): void => {
            let finished = false;
            let unsubscribe: () => void = (): void => {};
            const release = (): void => {
                if (finished) return;
                finished = true; pending.subscribers--; unsubscribe();
            };
            unsubscribe = scope.onCancel((): void => {
                if (finished) return;
                release();
                if (pending.subscribers === 0 && !pending.unscoped) pending.transport.cancel();
                reject(new Error('请求已取消'));
            });
            pending.result.then((value: ApiDataResult<T>): void => {
                if (!finished) { release(); resolve(value); }
            }, (error: Error): void => {
                if (!finished) { release(); reject(error); }
            });
        });
    }

    private async load(key: string, ttlMs: number, force: boolean, generation: number,
        fetch: (scope: RequestScope, refresh: boolean) => Promise<T>, staleWhileRevalidate: boolean,
        transport: RequestScope, order: RequestOrder, ticket: number): Promise<ApiDataResult<T>> {
        let cached: CachedValue<T> | undefined = undefined;
        try { cached = await transport.waitFor(this.cache.read(key, ttlMs)); }
        catch (_) { /* 缓存不可读时继续使用网络。 */ }
        if (transport.cancelled) throw new Error('请求已取消');
        if (cached && (!this.validate(cached.data) || generation !== this.cache.generation())) cached = undefined;
        if (!force && cached?.fresh) {
            return { data: cached.data, fromCache: true, cachedAt: cached.savedAt, stale: false };
        }
        if (!force && cached && staleWhileRevalidate) {
            // Revalidation belongs to the cache service and can outlive the page that first read the stale value.
            const revalidated = this.request(key, ttlMs, true, fetch, true);
            revalidated.catch((): void => {});
            return { data: cached.data, fromCache: true, cachedAt: cached.savedAt, stale: true, revalidated };
        }
        order.latestNetwork = Math.max(order.latestNetwork, ticket);
        try {
            const data = await transport.waitFor(fetch(transport, force));
            if (transport.cancelled) throw new Error('请求已取消');
            if (!this.validate(data)) throw new Error('服务器业务响应无效');
            if (generation === this.cache.generation() && order.latestNetwork === ticket) {
                // File persistence is best effort; a successful response is immediately usable by the UI.
                try { this.cache.write(key, data, generation).catch((): void => {}); }
                catch (_) { /* A cache adapter may also throw before returning its Promise. */ }
            }
            return { data, fromCache: false, cachedAt: Date.now(), stale: false };
        } catch (error) {
            if (transport.cancelled) throw error as Error;
            if (cached && generation === this.cache.generation()) {
                return { data: cached.data, fromCache: true, cachedAt: cached.savedAt, stale: true };
            }
            throw error as Error;
        }
    }
}
