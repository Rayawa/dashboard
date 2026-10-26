import type { AdvancedAppsQuery, DownloadGrowthQuery, CategoryGrowthQuery, ReputationQuery } from '../../models/types';

function appendNumber(query: string, key: string, value: number | undefined): string {
    if (value === undefined || !Number.isFinite(value)) return query;
    return `${query}&${key}=${Math.max(0, Math.floor(value))}`;
}

export function buildAdvancedAppsQueryPath(options: AdvancedAppsQuery): string {
    return `apps/query?page=${Math.max(1, options.page)}` +
        `&page_size=${Math.max(1, options.pageSize)}` +
        `&detail=true&sort=${encodeURIComponent(options.sort)}&desc=${options.desc}`;
}

export function buildDownloadGrowthPath(options: DownloadGrowthQuery = {}): string {
    let query = 'rankings/download_increase?';
    query = appendNumber(query, 'days', options.days);
    query = appendNumber(query, 'months', options.months);
    query = appendNumber(query, 'limit', options.limit);
    query = appendNumber(query, 'page', options.page);
    query = appendNumber(query, 'listed_days', options.listedDays);
    query = appendNumber(query, 'listed_months', options.listedMonths);
    if (options.excludeHuawei === true) query += '&exclude_huawei=true';
    if (options.excludeAtomic === true) query += '&exclude_atomic=true';
    return query.replace('?&', '?').replace(/\?$/, '');
}

export function buildDeveloperRankingPath(limit: number = 10, page: number = 1): string {
    return `rankings/developers?limit=${Math.max(1, Math.floor(limit))}&page=${Math.max(1, Math.floor(page))}`;
}

export function buildCategoryGrowthPath(options: CategoryGrowthQuery): string {
    const endpoint = options.kind === 'early' ? 'new_app_download_growth' : `${options.kind}_download_growth`;
    let path = `rankings/${endpoint}?days=${Math.max(1, Math.floor(options.days))}` +
        `&page=${Math.max(1, Math.floor(options.page))}&limit=${Math.max(1, Math.floor(options.limit))}`;
    if (options.kind === 'early') path += '&level=segment&min_downloads=1000&max_downloads=100000';
    return path;
}
export function buildTopicsPath(page: number, pageSize: number): string {
    return `substance/list/${Math.max(1, Math.floor(page))}?page_size=${Math.max(1, Math.floor(pageSize))}` +
        '&sort=created_at&desc=true';
}

/** 固定 Top 100；分类必须在服务端筛选后截断，不发送分页参数。 */
export function buildReputationPath(options: ReputationQuery = {}): string {
    const days = options.days === 7 || options.days === 30 ? options.days : 1;
    const samples = options.minSamples === 50 || options.minSamples === 100 ? options.minSamples : 10;
    let path = `rankings/reputation?days=${days}&min_samples=${samples}&sort=${options.sort === 'raw' ? 'raw' : 'weighted'}`;
    if (options.kindName?.trim()) path += `&kind_name=${encodeURIComponent(options.kindName.trim())}`;
    if (options.tagName?.trim()) path += `&tag_name=${encodeURIComponent(options.tagName.trim())}`;
    return path;
}
