import type { ApiDataResult, BaseAPIResponse } from './types';

export interface CachedValue<T> { data: T; savedAt: number; fresh: boolean; }
export interface RequestCache<T> {
    read(key: string, ttlMs: number): Promise<CachedValue<T> | undefined>;
    write(key: string, value: T, generation: number): Promise<void>;
    generation(): number;
}

export function validApiResponse(value: BaseAPIResponse | null | undefined): boolean {
    return value !== null && typeof value === 'object' && value.success === true &&
        value.data !== null && typeof value.data === 'object';
}

/** 网络、文件系统和 UI 解耦，统一处理请求合并、失败回退与清理期间的失效。 */
export class CachedRequest<T> {
    private cache: RequestCache<T>;
    private validate: (value: T) => boolean;
    private pending: Map<string, Promise<ApiDataResult<T>>> = new Map();
    private latest: Map<string, number> = new Map();
    private sequence: number = 0;

    constructor(cache: RequestCache<T>, validate: (value: T) => boolean) {
        this.cache = cache;
        this.validate = validate;
    }

    request(key: string, ttlMs: number, force: boolean, fetch: () => Promise<T>): Promise<ApiDataResult<T>> {
        const generation = this.cache.generation();
        // 强制刷新独立于普通读取，清理后的请求也不复用清理前的 Promise。
        const pendingKey = `${generation}:${force}:${key}`;
        const existing = this.pending.get(pendingKey);
        if (existing) return existing;
        const result = this.load(key, ttlMs, force, generation, fetch);
        this.pending.set(pendingKey, result);
        const release = (): void => { this.pending.delete(pendingKey); };
        result.then(release, release);
        return result;
    }

    private async load(key: string, ttlMs: number, force: boolean, generation: number,
        fetch: () => Promise<T>): Promise<ApiDataResult<T>> {
        let cached: CachedValue<T> | undefined = undefined;
        try { cached = await this.cache.read(key, ttlMs); }
        catch (_) { /* 缓存不可读时继续使用网络。 */ }
        if (cached && (!this.validate(cached.data) || generation !== this.cache.generation())) cached = undefined;
        if (!force && cached?.fresh) {
            return { data: cached.data, fromCache: true, cachedAt: cached.savedAt, stale: false };
        }
        const ticket = ++this.sequence;
        const latestKey = `${generation}:${key}`;
        this.latest.set(latestKey, ticket);
        try {
            const data = await fetch();
            if (!this.validate(data)) throw new Error('服务器业务响应无效');
            if (generation === this.cache.generation() && this.latest.get(latestKey) === ticket) {
                try { await this.cache.write(key, data, generation); }
                catch (_) { /* 写缓存失败不影响已经成功的网络响应。 */ }
            }
            return { data, fromCache: false, cachedAt: Date.now(), stale: false };
        } catch (error) {
            if (cached && generation === this.cache.generation()) {
                return { data: cached.data, fromCache: true, cachedAt: cached.savedAt, stale: true };
            }
            throw error as Error;
        } finally {
            if (this.latest.get(latestKey) === ticket) this.latest.delete(latestKey);
        }
    }
}
