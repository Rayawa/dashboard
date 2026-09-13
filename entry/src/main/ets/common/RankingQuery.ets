import type { AdvancedAppsQuery, DownloadGrowthQuery } from './types';

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
