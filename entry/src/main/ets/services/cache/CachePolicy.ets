export interface CacheFileInfo {
    path: string;
    size: number;
    savedAt: number;
}

export function validCacheTimestamp(savedAt: number, now: number, maxAge: number): boolean {
    return Number.isFinite(savedAt) && savedAt > 0 && savedAt <= now && now - savedAt <= maxAge;
}

/** 先删除失效文件，再按保存时间淘汰最旧数据；不修改调用方的文件列表。 */
export function cacheFilesToRemove(files: CacheFileInfo[], now: number, maxAge: number, maxBytes: number): string[] {
    const removed: string[] = [];
    const retained: CacheFileInfo[] = [];
    let total = 0;
    for (const file of files) {
        if (!validCacheTimestamp(file.savedAt, now, maxAge)) removed.push(file.path);
        else { retained.push(file); total += file.size; }
    }
    retained.sort((a: CacheFileInfo, b: CacheFileInfo): number => a.savedAt - b.savedAt);
    for (const file of retained) {
        if (total <= maxBytes) break;
        removed.push(file.path);
        total -= file.size;
    }
    return removed;
}
