import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { webview } from '@kit.ArkWeb';
import {
    CACHE_DIRECTORY_NAME, CACHE_MAX_STALE_MS, CACHE_MAX_BYTES,
    CACHE_MAINTENANCE_INTERVAL_MS, CACHE_MAINTENANCE_DELAY_MS,
} from './constants';
import { cacheFilesToRemove, validCacheTimestamp } from './CachePolicy';
import type { CacheFileInfo } from './CachePolicy';
import type { CachedValue } from './CachedRequest';

interface CacheEnvelope<T> { key?: string; savedAt: number; payload: T; }
export type CacheReadResult<T> = CachedValue<T>;
let appContext: common.Context | undefined = undefined;
let generation: number = 0;
let fileSequence: number = 0;
let work: Promise<void> = Promise.resolve();
let maintenanceTimer: number = -1;
let lastMaintenanceAt: number = 0;
let bytesSinceMaintenance: number = 0;
interface MemoryEntry { data: Object; savedAt: number; bytes: number; }
interface CacheReadOrder { version: number; readers: number; }
const memory: Map<string, MemoryEntry> = new Map();
// These values already belong to queued writes; keep them readable without retaining additional payload copies.
const pendingWrites: Map<string, MemoryEntry> = new Map();
const readOrders: Map<string, CacheReadOrder> = new Map();
let memoryBytes: number = 0;
let sizeSnapshot: number = -1;
let sizeSnapshotAt: number = 0;
let sizeRequest: Promise<number> | undefined = undefined;
let sizeRequestGeneration: number = -1;

function remember<T>(key: string, data: T, savedAt: number, bytes: number): void {
    const previous = memory.get(key);
    if (previous) { memoryBytes -= previous.bytes; memory.delete(key); }
    if (bytes > 4 * 1024 * 1024) return;
    memory.set(key, { data: data as Object, savedAt, bytes });
    memoryBytes += bytes;
    while (memory.size > 32 || memoryBytes > 4 * 1024 * 1024) {
        const first = memory.keys().next().value as string;
        memoryBytes -= memory.get(first)!.bytes;
        memory.delete(first);
    }
}

function residentValue<T>(key: string, ttlMs: number): CacheReadResult<T> | undefined {
    const pending = pendingWrites.get(key);
    const hit = pending ?? memory.get(key);
    if (hit && validCacheTimestamp(hit.savedAt, Date.now(), CACHE_MAX_STALE_MS)) {
        if (!pending) { memory.delete(key); memory.set(key, hit); }
        return { data: hit.data as T, savedAt: hit.savedAt, fresh: Date.now() - hit.savedAt <= ttlMs };
    }
    if (!pending && hit) { memory.delete(key); memoryBytes -= hit.bytes; }
    return undefined;
}

function invalidateOlderReads(key: string): void {
    const order = readOrders.get(key);
    if (order) order.version++;
}

/** 初始化只保留上下文；磁盘操作延后到首个实际请求。 */
export function initializeCache(context: common.Context): void { appContext = context; }
export function getCacheGeneration(): number { return generation; }

function contextOrThrow(): common.Context {
    if (!appContext) throw new Error('缓存服务尚未初始化');
    return appContext;
}
function apiCacheDirectory(): string { return `${contextOrThrow().cacheDir}/${CACHE_DIRECTORY_NAME}`; }

// 写入、维护和清空按序执行；读取依靠原子替换与代次检查独立进行。
function serialize<T>(action: () => Promise<T>): Promise<T> {
    const pending = work.then(action);
    work = pending.then((): void => {}, (): void => {});
    return pending;
}
async function ensureApiCacheDirectory(): Promise<void> {
    try {
        const directory = apiCacheDirectory();
        if (!await fileIo.access(directory)) await fileIo.mkdir(directory);
    } catch (error) { throw error as Error; }
}
function keyHash(key: string): string {
    let hash = 2166136261;
    for (let i = 0; i < key.length; i++) {
        hash ^= key.charCodeAt(i);
        hash = Math.imul(hash, 16777619);
    }
    return (hash >>> 0).toString(16);
}
function cacheFile(key: string): string { return `${apiCacheDirectory()}/${keyHash(key)}.json`; }

function discardInvalidFile(path: string, text: string, expectedGeneration: number): void {
    serialize(async (): Promise<void> => {
        if (generation !== expectedGeneration) return;
        try {
            // A newer atomic replacement must never be removed because an older read found corruption.
            if (await fileIo.readText(path) === text) { await fileIo.unlink(path); sizeSnapshotAt = 0; }
        } catch (_) { /* A concurrent clear or eviction already removed the file. */ }
    }).catch((): void => {});
}

export async function readCache<T>(key: string, ttlMs: number): Promise<CacheReadResult<T> | undefined> {
    scheduleMaintenance();
    const expectedGeneration = generation;
    const hit = residentValue<T>(key, ttlMs);
    if (hit) return hit;
    const path = cacheFile(key);
    const order: CacheReadOrder = readOrders.get(key) ?? { version: 0, readers: 0 };
    readOrders.set(key, order); order.readers++;
    const version = order.version;
    // Atomic rename makes independent reads safe. A clear invalidates every in-flight read by generation.
    let text: string | undefined = undefined;
    try {
        if (!await fileIo.access(path)) return undefined;
        text = await fileIo.readText(path);
        if (expectedGeneration !== generation) return undefined;
        const newer = residentValue<T>(key, ttlMs);
        if (newer) return newer;
        if (version !== order.version) return readCache<T>(key, ttlMs);
        const envelope = JSON.parse(text) as CacheEnvelope<T>;
        if (!envelope || !validCacheTimestamp(envelope.savedAt, Date.now(), CACHE_MAX_STALE_MS)) {
            discardInvalidFile(path, text, expectedGeneration); return undefined;
        }
        if (envelope.key !== undefined && envelope.key !== key) return undefined;
        remember(key, envelope.payload, envelope.savedAt, text.length * 2);
        return { data: envelope.payload, savedAt: envelope.savedAt, fresh: Date.now() - envelope.savedAt <= ttlMs };
    } catch (_) {
        if (text !== undefined) discardInvalidFile(path, text, expectedGeneration);
        return undefined;
    } finally {
        order.readers--;
        if (order.readers === 0 && readOrders.get(key) === order) readOrders.delete(key);
    }
}

export function writeCache<T>(key: string, payload: T, expectedGeneration: number = generation): Promise<void> {
    if (expectedGeneration !== generation) return Promise.resolve();
    const pending: MemoryEntry = { data: payload as Object, savedAt: Date.now(), bytes: 0 };
    pendingWrites.set(key, pending); invalidateOlderReads(key);
    return serialize(async (): Promise<void> => {
        if (expectedGeneration !== generation) return;
        let file: fileIo.File | undefined = undefined;
        let temporary = '';
        try {
            // Give the response's UI update a turn before serializing a large history payload.
            await new Promise<void>((resolve): void => { setTimeout(resolve, 0); });
            if (expectedGeneration !== generation) return;
            const envelope: CacheEnvelope<T> = { key, savedAt: pending.savedAt, payload };
            const encoded = new util.TextEncoder().encodeInto(JSON.stringify(envelope));
            remember(key, payload, envelope.savedAt, encoded.byteLength);
            if (encoded.byteLength > CACHE_MAX_BYTES) return;
            await ensureApiCacheDirectory();
            const path = cacheFile(key);
            temporary = `${path}.${++fileSequence}.tmp`;
            file = await fileIo.open(temporary, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
            const written = await fileIo.write(file.fd, encoded.buffer as ArrayBuffer);
            if (written !== encoded.byteLength) throw new Error('缓存文件写入不完整');
            await fileIo.close(file);
            file = undefined;
            // 清理可在 await 期间使请求失效，提交前再检查一次。
            if (expectedGeneration !== generation) return;
            await fileIo.rename(temporary, path);
            temporary = '';
            sizeSnapshotAt = 0;
            bytesSinceMaintenance += encoded.byteLength;
            scheduleMaintenance();
        } catch (error) {
            console.warn('[Dashboard][common/CacheService][WARN]', `写入缓存失败: ${JSON.stringify(error)}`);
        } finally {
            if (file) {
                try { await fileIo.close(file); } catch (_) { /* 继续清理临时文件。 */ }
            }
            if (temporary) {
                try { await fileIo.unlink(temporary); } catch (_) { /* 下次维护重试。 */ }
            }
        }
    }).finally((): void => {
        if (pendingWrites.get(key) === pending) pendingWrites.delete(key);
        if (expectedGeneration === generation) invalidateOlderReads(key);
    });
}

function scheduleMaintenance(): void {
    if (maintenanceTimer >= 0 || !appContext) return;
    if (lastMaintenanceAt > 0 && Date.now() - lastMaintenanceAt < CACHE_MAINTENANCE_INTERVAL_MS &&
        bytesSinceMaintenance < CACHE_MAX_BYTES / 8) return;
    maintenanceTimer = setTimeout((): void => {
        maintenanceTimer = -1;
        pruneApiCache().catch((error: Error): void => {
            console.warn('[Dashboard][common/CacheService][WARN]', `维护缓存失败: ${error.message}`);
        });
    }, CACHE_MAINTENANCE_DELAY_MS);
}

/** 按文件元数据淘汰过期和临时文件；损坏内容在实际读取时安全删除。 */
export function pruneApiCache(): Promise<void> {
    return serialize(async (): Promise<void> => {
        try {
            const directory = apiCacheDirectory();
            if (!await fileIo.access(directory)) return;
            const files: CacheFileInfo[] = [];
            let visited = 0;
            for (const name of await fileIo.listFile(directory)) {
                if (++visited % 32 === 0) await new Promise<void>((resolve): void => { setTimeout(resolve, 0); });
                const path = `${directory}/${name}`;
                const stat = await fileIo.stat(path);
                if (!stat.isFile()) continue;
                if (!name.endsWith('.json') && !name.endsWith('.tmp')) continue;
                // File timestamps are sufficient for eviction; payload validation stays on the read path.
                const savedAt = name.endsWith('.json') ? stat.mtime * 1000 : 0;
                files.push({ path, size: stat.size, savedAt });
            }
            for (const path of cacheFilesToRemove(files, Date.now(), CACHE_MAX_STALE_MS, CACHE_MAX_BYTES)) {
                await fileIo.unlink(path);
            }
            sizeSnapshotAt = 0;
            lastMaintenanceAt = Date.now();
            bytesSinceMaintenance = 0;
        } catch (error) { throw error as Error; }
    });
}

async function directorySize(path: string): Promise<number> {
    try {
        let total = 0;
        for (const name of await fileIo.listFile(path)) {
            const child = `${path}/${name}`;
            const stat = await fileIo.stat(child);
            total += stat.isDirectory() ? await directorySize(child) : stat.size;
        }
        return total;
    } catch (error) { throw error as Error; }
}
export function getCacheSizeBytes(context?: common.Context): Promise<number> {
    if (context) appContext = context;
    if (sizeSnapshot >= 0 && Date.now() - sizeSnapshotAt < 15000) return Promise.resolve(sizeSnapshot);
    if (sizeRequest && sizeRequestGeneration === generation) return sizeRequest;
    const expectedGeneration = generation;
    const request: Promise<number> = directorySize(contextOrThrow().cacheDir).then((size: number): number => {
        if (generation === expectedGeneration) { sizeSnapshot = size; sizeSnapshotAt = Date.now(); }
        return size;
    }).catch((): number => 0).finally((): void => { if (sizeRequest === request) sizeRequest = undefined; });
    sizeRequest = request; sizeRequestGeneration = expectedGeneration;
    return request;
}

async function clearDirectory(path: string, keepRoot: boolean): Promise<boolean> {
    try {
        if (!await fileIo.access(path)) return true;
        let complete = true;
        for (const name of await fileIo.listFile(path)) {
            const child = `${path}/${name}`;
            try {
                const stat = await fileIo.stat(child);
                if (stat.isDirectory()) complete = await clearDirectory(child, false) && complete;
                else await fileIo.unlink(child);
            } catch (error) {
                complete = false;
                console.warn('[Dashboard][common/CacheService][WARN]', `清理缓存项失败: ${JSON.stringify(error)}`);
            }
        }
        if (!keepRoot && complete) await fileIo.rmdir(path);
        return complete;
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `遍历缓存失败: ${JSON.stringify(error)}`);
        return false;
    }
}
export function clearCompleteCache(context?: common.Context): Promise<void> {
    if (context) appContext = context;
    generation++;
    pendingWrites.clear(); readOrders.clear();
    memory.clear(); memoryBytes = 0; sizeSnapshot = -1; sizeSnapshotAt = 0;
    if (maintenanceTimer >= 0) { clearTimeout(maintenanceTimer); maintenanceTimer = -1; }
    return serialize(async (): Promise<void> => {
        let complete = false;
        try { complete = await clearDirectory(contextOrThrow().cacheDir, true); }
        catch (error) { console.warn('[Dashboard][common/CacheService][WARN]', `文件缓存清理失败: ${JSON.stringify(error)}`); }
        try {
            webview.WebStorage.deleteAllData();
            webview.WebCookieManager.clearAllCookiesSync();
        } catch (error) {
            complete = false;
            console.warn('[Dashboard][common/CacheService][WARN]', `ArkWeb 缓存清理失败: ${JSON.stringify(error)}`);
        }
        lastMaintenanceAt = 0;
        bytesSinceMaintenance = 0;
        if (!complete) throw new Error('缓存未能完全清除');
    });
}
