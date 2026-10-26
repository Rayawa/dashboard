import { describe, it, expect } from '@ohos/hypium';
import { CachedRequest, validApiResponse } from '../main/ets/services/cache/CachedRequest';
import type { CachedValue, RequestCache } from '../main/ets/services/cache/CachedRequest';
import { cacheFilesToRemove } from '../main/ets/services/cache/CachePolicy';
import type { CacheFileInfo } from '../main/ets/services/cache/CachePolicy';
import type { BaseAPIResponse } from '../main/ets/models/types';

interface Payload { value: number; }
function response(value: number): BaseAPIResponse { return { success: true, data: { value } as Payload, timestamp: 'test' }; }
function valueOf(value: BaseAPIResponse): number { return (value.data as Payload).value; }

class MemoryCache implements RequestCache<BaseAPIResponse> {
    entry: CachedValue<BaseAPIResponse> | undefined = undefined;
    version: number = 0;
    writes: number = 0;
    failWrite: boolean = false;
    failRead: boolean = false;
    generation(): number { return this.version; }
    async read(_key: string, _ttl: number): Promise<CachedValue<BaseAPIResponse> | undefined> {
        if (this.failRead) throw new Error('read failed');
        return this.entry;
    }
    async write(_key: string, data: BaseAPIResponse, generation: number): Promise<void> {
        if (this.failWrite) throw new Error('write failed');
        if (generation !== this.version) return;
        this.writes++;
        this.entry = { data, savedAt: Date.now(), fresh: true };
    }
}

class DeferredResponse {
    private resolveResult?: (value: BaseAPIResponse) => void;
    private rejectResult?: (error: Error) => void;
    private markStarted?: () => void;
    started: Promise<void> = new Promise<void>((resolve): void => { this.markStarted = resolve; });
    result: Promise<BaseAPIResponse> = new Promise<BaseAPIResponse>((resolve, reject): void => {
        this.resolveResult = resolve; this.rejectResult = reject;
    });
    fetch(): Promise<BaseAPIResponse> { if (this.markStarted) this.markStarted(); return this.result; }
    resolve(value: BaseAPIResponse): void { if (this.resolveResult) this.resolveResult(value); }
    reject(): void { if (this.rejectResult) this.rejectResult(new Error('offline')); }
}

export default function cacheTests() {
    describe('cached requests and eviction', () => {
        it('onlySuccessfulResponsesWithDataAreValid', 0, () => {
            expect(validApiResponse(response(1))).assertTrue();
            expect(validApiResponse({ success: true, data: [], timestamp: 'test' })).assertTrue();
            expect(validApiResponse({ success: false, data: [], timestamp: 'test' })).assertFalse();
            expect(validApiResponse(JSON.parse('{"success":true}') as BaseAPIResponse)).assertFalse();
            expect(validApiResponse(null)).assertFalse();
            expect(validApiResponse(JSON.parse('{"success":true,"data":"invalid"}') as BaseAPIResponse)).assertFalse();
        });
        it('businessFailurePreservesSuccessfulCache', 0, async () => {
            const cache = new MemoryCache();
            cache.entry = { data: response(1), savedAt: 123, fresh: false };
            const client = new CachedRequest<BaseAPIResponse>(cache, validApiResponse);
            const result = await client.request('a', 100, true,
                async (): Promise<BaseAPIResponse> => ({ success: false, data: [], timestamp: 'test' }));
            expect(valueOf(result.data)).assertEqual(1);
            expect(result.stale).assertTrue();
            expect(result.cachedAt).assertEqual(123);
            expect(cache.writes).assertEqual(0);
            expect(valueOf(cache.entry!.data)).assertEqual(1);
        });
        it('invalidResponseWithoutCacheRejectsAndNextRequestCanRecover', 0, async () => {
            const cache = new MemoryCache();
            const client = new CachedRequest<BaseAPIResponse>(cache, validApiResponse);
            let rejected = false;
            try {
                await client.request('a', 100, false, async (): Promise<BaseAPIResponse> => ({ success: false, data: [], timestamp: 'test' }));
            } catch (_) { rejected = true; }
            expect(rejected).assertTrue();
            const next = await client.request('a', 100, false, async (): Promise<BaseAPIResponse> => response(2));
            expect(valueOf(next.data)).assertEqual(2);
            expect(cache.writes).assertEqual(1);
        });
        it('legacyPoisonedCacheCannotBeReturnedAsFreshOrOffline', 0, async () => {
            const cache = new MemoryCache();
            cache.entry = { data: { success: false, data: [], timestamp: 'test' }, savedAt: 123, fresh: true };
            const client = new CachedRequest<BaseAPIResponse>(cache, validApiResponse);
            let rejected = false;
            try { await client.request('a', 100, false, async (): Promise<BaseAPIResponse> => { throw new Error('offline'); }); }
            catch (_) { rejected = true; }
            expect(rejected).assertTrue();
        });
        it('freshCacheAvoidsNetworkButForceRefreshBypassesIt', 0, async () => {
            const cache = new MemoryCache();
            cache.entry = { data: response(1), savedAt: 123, fresh: true };
            const client = new CachedRequest<BaseAPIResponse>(cache, validApiResponse);
            let calls = 0;
            const fetch = async (): Promise<BaseAPIResponse> => { calls++; return response(2); };
            const cached = await client.request('a', 100, false, fetch);
            expect(calls).assertEqual(0);
            expect(cached.fromCache).assertTrue();
            const fresh = await client.request('a', 100, true, fetch);
            expect(calls).assertEqual(1);
            expect(fresh.fromCache).assertFalse();
            expect(valueOf(fresh.data)).assertEqual(2);
        });
        it('failedForceRefreshFallsBackToFreshCacheAsStale', 0, async () => {
            const cache = new MemoryCache();
            cache.entry = { data: response(1), savedAt: 123, fresh: true };
            const client = new CachedRequest<BaseAPIResponse>(cache, validApiResponse);
            const result = await client.request('a', 100, true, async (): Promise<BaseAPIResponse> => { throw new Error('offline'); });
            expect(result.stale).assertTrue();
            expect(valueOf(result.data)).assertEqual(1);
        });
        it('cacheIoFailureDoesNotDiscardNetworkSuccess', 0, async () => {
            const cache = new MemoryCache(); cache.failRead = true; cache.failWrite = true;
            const client = new CachedRequest<BaseAPIResponse>(cache, validApiResponse);
            const result = await client.request('a', 100, false, async (): Promise<BaseAPIResponse> => response(2));
            expect(valueOf(result.data)).assertEqual(2);
            expect(result.fromCache).assertFalse();
        });
        it('concurrentIdenticalRequestsShareNetworkWork', 0, async () => {
            const cache = new MemoryCache();
            const client = new CachedRequest<BaseAPIResponse>(cache, validApiResponse);
            let calls = 0;
            const fetch = async (): Promise<BaseAPIResponse> => { calls++; return response(1); };
            const results = await Promise.all([client.request('a', 100, false, fetch), client.request('a', 100, false, fetch)]);
            expect(calls).assertEqual(1);
            expect(cache.writes).assertEqual(1);
            expect(valueOf(results[1].data)).assertEqual(1);
        });
        it('olderOrdinaryRequestCannotOverwriteNewerForcedResult', 0, async () => {
            const cache = new MemoryCache();
            const client = new CachedRequest<BaseAPIResponse>(cache, validApiResponse);
            const old = new DeferredResponse(); const fresh = new DeferredResponse();
            const oldRequest = client.request('a', 100, false, (): Promise<BaseAPIResponse> => old.fetch());
            await old.started;
            const newRequest = client.request('a', 100, true, (): Promise<BaseAPIResponse> => fresh.fetch());
            await fresh.started;
            fresh.resolve(response(2)); await newRequest;
            old.resolve(response(1)); await oldRequest;
            expect(valueOf(cache.entry!.data)).assertEqual(2);
            expect(cache.writes).assertEqual(1);
        });
        it('clearingSeparatesNewRequestsAndPreventsOldWrites', 0, async () => {
            const cache = new MemoryCache();
            const client = new CachedRequest<BaseAPIResponse>(cache, validApiResponse);
            const old = new DeferredResponse();
            const pending = client.request('a', 100, false, (): Promise<BaseAPIResponse> => old.fetch());
            await old.started;
            cache.version++;
            const next = await client.request('a', 100, false, async (): Promise<BaseAPIResponse> => response(2));
            old.resolve(response(1)); await pending;
            expect(valueOf(next.data)).assertEqual(2);
            expect(valueOf(cache.entry!.data)).assertEqual(2);
            expect(cache.writes).assertEqual(1);
        });
        it('clearedCacheCannotReappearThroughFailureFallback', 0, async () => {
            const cache = new MemoryCache();
            cache.entry = { data: response(1), savedAt: 123, fresh: false };
            const client = new CachedRequest<BaseAPIResponse>(cache, validApiResponse);
            const network = new DeferredResponse();
            const pending = client.request('a', 100, true, (): Promise<BaseAPIResponse> => network.fetch());
            await network.started;
            cache.version++; cache.entry = undefined;
            network.reject();
            let rejected = false;
            try { await pending; } catch (_) { rejected = true; }
            expect(rejected).assertTrue();
            expect(cache.entry === undefined).assertTrue();
        });
        it('evictionDropsExpiredInvalidAndFutureFiles', 0, () => {
            const files: CacheFileInfo[] = [
                { path: 'expired', size: 1, savedAt: 1 }, { path: 'invalid', size: 1, savedAt: NaN },
                { path: 'future', size: 1, savedAt: 1001 }, { path: 'valid', size: 1, savedAt: 900 },
            ];
            expect(cacheFilesToRemove(files, 1000, 200, 100).join(',')).assertEqual('expired,invalid,future');
        });
        it('capacityEvictionIsOldestFirstAndPreservesInputOrder', 0, () => {
            const files: CacheFileInfo[] = [
                { path: 'new', size: 6, savedAt: 990 }, { path: 'old', size: 6, savedAt: 900 },
                { path: 'middle', size: 6, savedAt: 950 },
            ];
            expect(cacheFilesToRemove(files, 1000, 200, 10).join(',')).assertEqual('old,middle');
            expect(files[0].path).assertEqual('new');
        });
        it('capacityBoundaryRetainsFilesWithinBudget', 0, () => {
            expect(cacheFilesToRemove([{ path: 'a', size: 10, savedAt: 900 }], 1000, 100, 10).length).assertEqual(0);
        });
    });
}
