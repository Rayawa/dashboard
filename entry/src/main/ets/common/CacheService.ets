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

/** 初始化只保留上下文；磁盘操作延后到首个实际请求。 */
export function initializeCache(context: common.Context): void { appContext = context; }
export function getCacheGeneration(): number { return generation; }

function contextOrThrow(): common.Context {
    if (!appContext) throw new Error('缓存服务尚未初始化');
    return appContext;
}
function apiCacheDirectory(): string { return `${contextOrThrow().cacheDir}/${CACHE_DIRECTORY_NAME}`; }

// 缓存读写、维护和清空按序执行，避免维护误删正在写入的临时文件。
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

export function readCache<T>(key: string, ttlMs: number): Promise<CacheReadResult<T> | undefined> {
    scheduleMaintenance();
    return serialize(async (): Promise<CacheReadResult<T> | undefined> => {
        try {
            const path = cacheFile(key);
            if (!await fileIo.access(path)) return undefined;
            const envelope = JSON.parse(await fileIo.readText(path)) as CacheEnvelope<T>;
            if (!envelope || !validCacheTimestamp(envelope.savedAt, Date.now(), CACHE_MAX_STALE_MS)) {
                await fileIo.unlink(path);
                return undefined;
            }
            // 旧缓存没有 key 时仍兼容；新缓存可检测哈希碰撞。
            if (envelope.key !== undefined && envelope.key !== key) return undefined;
            return { data: envelope.payload, savedAt: envelope.savedAt, fresh: Date.now() - envelope.savedAt <= ttlMs };
        } catch (error) {
            console.warn('[Dashboard][common/CacheService][WARN]', `读取缓存失败: ${JSON.stringify(error)}`);
            return undefined;
        }
    });
}

export function writeCache<T>(key: string, payload: T, expectedGeneration: number = generation): Promise<void> {
    return serialize(async (): Promise<void> => {
        if (expectedGeneration !== generation) return;
        let file: fileIo.File | undefined = undefined;
        let temporary = '';
        try {
            const envelope: CacheEnvelope<T> = { key, savedAt: Date.now(), payload };
            const encoded = new util.TextEncoder().encodeInto(JSON.stringify(envelope));
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

/** 删除过期、损坏与遗留临时文件，并按时间将 API 缓存限制在容量预算内。 */
export function pruneApiCache(): Promise<void> {
    return serialize(async (): Promise<void> => {
        try {
            const directory = apiCacheDirectory();
            if (!await fileIo.access(directory)) return;
            const files: CacheFileInfo[] = [];
            for (const name of await fileIo.listFile(directory)) {
                const path = `${directory}/${name}`;
                const stat = await fileIo.stat(path);
                if (!stat.isFile()) continue;
                if (!name.endsWith('.json') && !name.endsWith('.tmp')) continue;
                let savedAt = 0;
                if (name.endsWith('.json')) {
                    try { savedAt = (JSON.parse(await fileIo.readText(path)) as CacheEnvelope<Object>).savedAt; }
                    catch (_) { /* 损坏缓存与临时文件统一淘汰。 */ }
                }
                files.push({ path, size: stat.size, savedAt });
            }
            for (const path of cacheFilesToRemove(files, Date.now(), CACHE_MAX_STALE_MS, CACHE_MAX_BYTES)) {
                await fileIo.unlink(path);
            }
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
    return serialize(async (): Promise<number> => {
        try { return await directorySize(contextOrThrow().cacheDir); }
        catch (error) {
            console.warn('[Dashboard][common/CacheService][WARN]', `缓存容量读取失败: ${JSON.stringify(error)}`);
            return 0;
        }
    });
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
