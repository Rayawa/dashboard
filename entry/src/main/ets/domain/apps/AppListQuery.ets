/** 应用列表查询参数。具名字段用于避免筛选布尔值发生位置错位。 */
export interface AppsPageQuery {
    page: number;
    pageSize: number;
    sort: string;
    desc: boolean;
    searchKey?: string;
    searchValue?: string;
    exact?: boolean;
    force?: boolean;
    excludeHuawei?: boolean;
    excludeAtomic?: boolean;
}

/** 纯函数，集中维护应用列表 API 的查询参数和编码规则。 */
export function buildAppsPagePath(options: AppsPageQuery): string {
    let query = `page_size=${options.pageSize}&detail=true&sort=${encodeURIComponent(options.sort)}` +
        `&desc=${options.desc}`;
    if (options.searchKey && options.searchValue) {
        query += `&search_key=${encodeURIComponent(options.searchKey)}` +
            `&search_value=${encodeURIComponent(options.searchValue)}`;
        query += `&search_exact=${options.exact ?? false}`;
    }
    if (options.excludeHuawei === true) {
        query += '&exclude_huawei=true';
    }
    if (options.excludeAtomic === true) {
        query += '&exclude_atomic=true';
    }
    return `apps/list/${Math.max(1, options.page)}?${query}`;
}
