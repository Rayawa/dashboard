import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { webview } from '@kit.ArkWeb';
import { CACHE_DIRECTORY_NAME, CACHE_MAX_STALE_MS } from './constants';

interface CacheEnvelope<T> {
    savedAt: number;
    payload: T;
}

export interface CacheReadResult<T> {
    data: T;
    savedAt: number;
    fresh: boolean;
}

let appContext: common.Context | undefined = undefined;

export function initializeCache(context: common.Context): void {
    appContext = context;
    ensureApiCacheDirectory();
}

function contextOrThrow(): common.Context {
    if (!appContext) {
        throw new Error('缓存服务尚未初始化');
    }
    return appContext;
}

function apiCacheDirectory(): string {
    return `${contextOrThrow().cacheDir}/${CACHE_DIRECTORY_NAME}`;
}

function ensureApiCacheDirectory(): boolean {
    try {
        const directory = apiCacheDirectory();
        if (!fileIo.accessSync(directory)) {
            fileIo.mkdirSync(directory);
        }
        return true;
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 创建缓存目录失败: ${JSON.stringify(error)}`);
        return false;
    }
}

function keyHash(key: string): string {
    let hash = 2166136261;
    for (let i = 0; i < key.length; i++) {
        hash ^= key.charCodeAt(i);
        hash = Math.imul(hash, 16777619);
    }
    return (hash >>> 0).toString(16);
}

function cacheFile(key: string): string {
    return `${apiCacheDirectory()}/${keyHash(key)}.json`;
}

export function readCache<T>(key: string, ttlMs: number): CacheReadResult<T> | undefined {
    try {
        const path = cacheFile(key);
        if (!fileIo.accessSync(path)) {
            return undefined;
        }
        const raw = fileIo.readTextSync(path);
        const envelope = JSON.parse(raw) as CacheEnvelope<T>;
        const age = Date.now() - envelope.savedAt;
        if (age > CACHE_MAX_STALE_MS) {
            fileIo.unlinkSync(path);
            return undefined;
        }
        return { data: envelope.payload, savedAt: envelope.savedAt, fresh: age <= ttlMs };
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 读取失败 ${key}: ${JSON.stringify(error)}`);
        return undefined;
    }
}

export function writeCache<T>(key: string, payload: T): void {
    let file: fileIo.File | undefined = undefined;
    try {
        ensureApiCacheDirectory();
        const envelope: CacheEnvelope<T> = { savedAt: Date.now(), payload };
        file = fileIo.openSync(
            cacheFile(key),
            fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC,
        );
        fileIo.writeSync(file.fd, JSON.stringify(envelope), { encoding: 'utf-8' });
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 写入失败 ${key}: ${JSON.stringify(error)}`);
    } finally {
        if (file) {
            try {
                fileIo.closeSync(file);
            } catch (error) {
                console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 关闭缓存文件失败 ${key}: ${JSON.stringify(error)}`);
            }
        }
    }
}

function directorySize(path: string): number {
    let total = 0;
    try {
        const names = fileIo.listFileSync(path);
        names.forEach((name: string) => {
            const child = `${path}/${name}`;
            const stat = fileIo.statSync(child);
            total += stat.isDirectory() ? directorySize(child) : stat.size;
        });
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 统计缓存失败: ${JSON.stringify(error)}`);
    }
    return total;
}

export function getCacheSizeBytes(context?: common.Context): number {
    if (context) {
        appContext = context;
    }
    try {
        return directorySize(contextOrThrow().cacheDir);
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 缓存容量读取失败: ${JSON.stringify(error)}`);
        return 0;
    }
}

function clearDirectory(path: string, keepRoot: boolean): boolean {
    try {
        if (!fileIo.accessSync(path)) {
            return true;
        }
        let completelyCleared = true;
        const names = fileIo.listFileSync(path);
        names.forEach((name: string) => {
            const child = `${path}/${name}`;
            try {
                const stat = fileIo.statSync(child);
                if (stat.isDirectory()) {
                    completelyCleared = clearDirectory(child, false) && completelyCleared;
                } else {
                    fileIo.unlinkSync(child);
                }
            } catch (error) {
                completelyCleared = false;
                console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 清理缓存项失败 ${child}: ${JSON.stringify(error)}`);
            }
        });
        if (!keepRoot && completelyCleared) {
            fileIo.rmdirSync(path);
        }
        return completelyCleared;
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 无法遍历缓存目录 ${path}: ${JSON.stringify(error)}`);
        return false;
    }
}

export async function clearCompleteCache(context?: common.Context): Promise<void> {
    if (context) {
        appContext = context;
    }
    let fileCacheCleared = false;
    let webCacheCleared = false;
    try {
        fileCacheCleared = clearDirectory(contextOrThrow().cacheDir, true);
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `[cache] 文件缓存清理不完整: ${JSON.stringify(error)}`);
    }
    try {
        webview.WebStorage.deleteAllData();
        webview.WebCookieManager.clearAllCookiesSync();
        webCacheCleared = true;
    } catch (error) {
        console.warn('[Dashboard][common/CacheService][WARN]', `[cache] ArkWeb 缓存清理失败: ${JSON.stringify(error)}`);
    }
    const cacheDirectoryReady = ensureApiCacheDirectory();
    if (!fileCacheCleared || !webCacheCleared || !cacheDirectoryReady) {
        throw new Error('缓存未能完全清除');
    }
}
