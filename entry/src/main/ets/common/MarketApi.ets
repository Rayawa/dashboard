import { http } from '@kit.NetworkKit';
import {
    CACHE_TTL_CHART_MS,
    CACHE_TTL_DETAIL_MS,
    CACHE_TTL_HOME_MS,
    CACHE_TTL_LIST_MS,
    createApiRequestHeaders,
    DEFAULT_NETWORK_TIMEOUT_MS,
    SAPIBaseURL,
    SUBMIT_PLATFORM,
} from './constants';
import { readCache, writeCache } from './CacheService';
import { buildAppsPagePath } from './AppListQuery';
import type { AppsPageQuery } from './AppListQuery';
import type {
    ApiDataResult,
    AppDetailPayload,
    AppMetric,
    AppRatingHistory,
    BaseAPIResponse,
    MarketApp,
    MarketInfo,
    PageInfo,
    RatingDistribution,
    SubmitAppBody,
} from './types';

type SdkDistribution = number[][];
type ApiHistory = object[];

async function requestJson<T>(
    path: string,
    ttlMs: number,
    forceNetwork: boolean = false,
    method: http.RequestMethod = http.RequestMethod.GET,
    body?: object,
    cacheIdentity?: string,
): Promise<ApiDataResult<T>> {
    const cacheKey = cacheIdentity ?? `${method}:${path}:${body ? JSON.stringify(body) : ''}`;
    const cached = readCache<T>(cacheKey, ttlMs);
    if (!forceNetwork && cached?.fresh) {
        return { data: cached.data, fromCache: true, cachedAt: cached.savedAt, stale: false };
    }

    let request: http.HttpRequest | undefined = undefined;
    try {
        request = http.createHttp();
        const options: http.HttpRequestOptions = {
            method,
            header: createApiRequestHeaders(body !== undefined),
            expectDataType: http.HttpDataType.STRING,
            usingCache: false,
            connectTimeout: DEFAULT_NETWORK_TIMEOUT_MS,
            readTimeout: DEFAULT_NETWORK_TIMEOUT_MS,
        };
        if (body) {
            options.extraData = JSON.stringify(body);
        }
        const response = await request.request(`${SAPIBaseURL.toString()}${path}`, options);
        if (response.responseCode < 200 || response.responseCode >= 300) {
            throw new Error(`服务器返回 ${response.responseCode}`);
        }
        const parsed = JSON.parse(response.result.toString()) as T;
        writeCache(cacheKey, parsed);
        return { data: parsed, fromCache: false, cachedAt: Date.now(), stale: false };
    } catch (error) {
        if (cached) {
            console.warn('[Dashboard][common/MarketApi][WARN]', `API 请求失败，使用离线缓存 ${path}: ${JSON.stringify(error)}`);
            return { data: cached.data, fromCache: true, cachedAt: cached.savedAt, stale: true };
        }
        console.error('[Dashboard][common/MarketApi][ERROR]', `API 请求失败且无可用缓存 ${path}: ${JSON.stringify(error)}`);
        throw error as Error;
    } finally {
        if (request) {
            try {
                request.destroy();
            } catch (error) {
                console.warn('[Dashboard][common/MarketApi][WARN]', `HTTP 请求对象释放失败 ${path}: ${JSON.stringify(error)}`);
            }
        }
    }
}

async function postNoCache<T>(path: string, body: object): Promise<T> {
    let request: http.HttpRequest | undefined = undefined;
    try {
        request = http.createHttp();
        const response = await request.request(`${SAPIBaseURL.toString()}${path}`, {
            method: http.RequestMethod.POST,
            header: createApiRequestHeaders(true),
            extraData: JSON.stringify(body),
            expectDataType: http.HttpDataType.STRING,
            usingCache: false,
            connectTimeout: DEFAULT_NETWORK_TIMEOUT_MS,
            readTimeout: DEFAULT_NETWORK_TIMEOUT_MS,
        });
        if (response.responseCode < 200 || response.responseCode >= 300) {
            throw new Error(`服务器返回 ${response.responseCode}`);
        }
        return JSON.parse(response.result.toString()) as T;
    } catch (error) {
        console.error('[Dashboard][common/MarketApi][ERROR]', `API 写操作失败 ${path}: ${JSON.stringify(error)}`);
        throw new Error('网络连接失败，本次操作未提交，请稍后重试');
    } finally {
        if (request) {
            try {
                request.destroy();
            } catch (error) {
                console.warn('[Dashboard][common/MarketApi][WARN]', `HTTP 写请求对象释放失败 ${path}: ${JSON.stringify(error)}`);
            }
        }
    }
}

export function fetchMarketInfo(force: boolean = false): Promise<ApiDataResult<BaseAPIResponse<MarketInfo>>> {
    return requestJson<BaseAPIResponse<MarketInfo>>('market_info', CACHE_TTL_HOME_MS, force);
}

export function fetchAppsPage(
    options: AppsPageQuery,
): Promise<ApiDataResult<BaseAPIResponse<PageInfo<MarketApp>>>> {
    return requestJson<BaseAPIResponse<PageInfo<MarketApp>>>(
        buildAppsPagePath(options),
        CACHE_TTL_LIST_MS,
        options.force ?? false,
    );
}

export function fetchAppById(appId: string, force: boolean = false): Promise<ApiDataResult<BaseAPIResponse<AppDetailPayload>>> {
    const basePath = `apps/app_id/${encodeURIComponent(appId)}`;
    return requestJson<BaseAPIResponse<AppDetailPayload>>(
        `${basePath}?use_cache=${!force}`,
        CACHE_TTL_DETAIL_MS,
        force,
        http.RequestMethod.GET,
        undefined,
        `detail:${basePath}`,
    );
}

export function fetchAppByPackage(packageName: string, force: boolean = false): Promise<ApiDataResult<BaseAPIResponse<AppDetailPayload>>> {
    const basePath = `apps/pkg_name/${encodeURIComponent(packageName)}`;
    return requestJson<BaseAPIResponse<AppDetailPayload>>(
        `${basePath}?use_cache=${!force}`,
        CACHE_TTL_DETAIL_MS,
        force,
        http.RequestMethod.GET,
        undefined,
        `detail:${basePath}`,
    );
}

export function fetchRatingDistribution(force: boolean = false): Promise<ApiDataResult<BaseAPIResponse<RatingDistribution>>> {
    return requestJson<BaseAPIResponse<RatingDistribution>>('charts/rating', CACHE_TTL_CHART_MS, force);
}

export function fetchSdkDistribution(kind: 'min_sdk' | 'target_sdk', force: boolean = false): Promise<ApiDataResult<BaseAPIResponse<SdkDistribution>>> {
    return requestJson<BaseAPIResponse<SdkDistribution>>(`charts/${kind}`, CACHE_TTL_CHART_MS, force);
}

export function fetchApiHistory(force: boolean = false): Promise<ApiDataResult<BaseAPIResponse<ApiHistory>>> {
    return requestJson<BaseAPIResponse<ApiHistory>>('charts/api_history', CACHE_TTL_CHART_MS, force);
}

export function fetchAppMetrics(packageName: string, force: boolean = false): Promise<ApiDataResult<BaseAPIResponse<AppMetric[]>>> {
    return requestJson<BaseAPIResponse<AppMetric[]>>(
        `apps/metrics/${encodeURIComponent(packageName)}`,
        CACHE_TTL_DETAIL_MS,
        force,
    );
}

export function fetchAppRatingHistory(packageName: string, force: boolean = false): Promise<ApiDataResult<BaseAPIResponse<AppRatingHistory[]>>> {
    return requestJson<BaseAPIResponse<AppRatingHistory[]>>(
        `rankings/rate_history?pkg_name=${encodeURIComponent(packageName)}`,
        CACHE_TTL_DETAIL_MS,
        force,
    );
}

export async function submitApp(data: SubmitAppBody): Promise<BaseAPIResponse<AppDetailPayload>> {
    const body: SubmitAppBody = {
        app_id: data.app_id,
        pkg_name: data.pkg_name,
        comment: {
            user: data.comment?.user,
            platform: SUBMIT_PLATFORM,
        },
    };
    return postNoCache<BaseAPIResponse<AppDetailPayload>>('submit', body);
}
