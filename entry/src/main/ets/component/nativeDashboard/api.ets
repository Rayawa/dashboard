// 原生看板的数据加载（get_market 后端 /api/v0），请求方式与项目其他页面保持一致
import { http } from '@kit.NetworkKit';
import { SAPIBaseURL, customUserAgent } from '../../common/constants';
import type {
    AppsListResponse,
    AppSummary,
    MarketInfoResponse,
    RatingChartResponse,
    RatingDistribution,
    SdkBucket,
    SdkChartResponse
} from './types';

const API_BASE: string = SAPIBaseURL.toString();

function buildQuery(pairs: string[]): string {
    return pairs.length > 0 ? `?${pairs.join('&')}` : '';
}

async function getJson<T>(path: string): Promise<T> {
    const request = http.createHttp();
    try {
        const response = await request.request(API_BASE + path, {
            method: http.RequestMethod.GET,
            header: { 'User-Agent': customUserAgent },
            expectDataType: http.HttpDataType.STRING,
            usingCache: false,
            connectTimeout: 15000,
            readTimeout: 15000,
        });
        if (response.responseCode < 200 || response.responseCode >= 300) {
            throw new Error(`HTTP ${response.responseCode}: ${path}`);
        }
        return JSON.parse(response.result.toString()) as T;
    } finally {
        request.destroy();
    }
}

// 市场概览：装机量 / 应用总数 / 元服务总数 / 开发者总数 / 专题数量
export async function fetchMarketInfo(): Promise<MarketInfoResponse> {
    return getJson<MarketInfoResponse>('market_info');
}

// 应用列表（也用于总下载榜 / 非华为下载榜）
export async function fetchAppsPage(
    page: number,
    pageSize: number,
    sort: string,
    desc: boolean,
    searchKey?: string,
    searchValue?: string,
    searchExact?: boolean,
    excludeHuawei?: boolean,
): Promise<AppsListResponse> {
    const pairs: string[] = [
        `page_size=${pageSize}`,
        `sort=${encodeURIComponent(sort)}`,
        `desc=${desc}`,
    ];
    if (searchKey && searchValue !== undefined && searchValue !== '') {
        pairs.push(`search_key=${encodeURIComponent(searchKey)}`);
        pairs.push(`search_value=${encodeURIComponent(searchValue)}`);
        if (searchExact) pairs.push('search_exact=true');
    }
    if (excludeHuawei) pairs.push('exclude_huawei=true');
    return getJson<AppsListResponse>(`apps/list/${page}${buildQuery(pairs)}`);
}

export async function fetchTopDownloads(excludeHuawei: boolean): Promise<AppSummary[]> {
    const res = await fetchAppsPage(1, 15, 'download_count', true, undefined, undefined, undefined, excludeHuawei);
    return res.data.data ?? [];
}

// 评分分布
export async function fetchRatingDist(): Promise<RatingDistribution> {
    const res = await getJson<RatingChartResponse>('charts/rating');
    return res.data;
}

// sdk 分布（min_sdk / target_sdk）
export async function fetchSdkDist(kind: 'min_sdk' | 'target_sdk'): Promise<SdkBucket[]> {
    const res = await getJson<SdkChartResponse>(`charts/${kind}`);
    return (res.data ?? []).map((item) => {
        const bucket: SdkBucket = { sdk: Number(item[0]), count: Number(item[1]) };
        return bucket;
    });
}

// 数字格式化：12345 -> 1.2万
export function formatNumber(value: number | undefined): string {
    if (value === undefined || value === null) return '-';
    if (value >= 100000000) return `${(value / 100000000).toFixed(2)}亿`;
    if (value >= 10000) return `${(value / 10000).toFixed(2)}万`;
    return String(value);
}

// 大小格式化：bytes -> MB/GB
export function formatSize(bytes: number | undefined): string {
    if (!bytes || bytes <= 0) return '-';
    const mb = bytes / 1024 / 1024;
    if (mb >= 1024) return `${(mb / 1024).toFixed(2)}GB`;
    return `${mb.toFixed(1)}MB`;
}

// 日期格式化：ISO 字符串 -> yyyy-MM-dd
export function formatDate(iso: string | undefined): string {
    if (!iso) return '-';
    const date = new Date(iso);
    if (Number.isNaN(date.getTime())) return iso;
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
}
