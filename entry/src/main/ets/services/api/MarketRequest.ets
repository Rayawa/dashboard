import { PerformanceTrace } from '../../utils/diagnostics/PerformanceTrace';
import { http } from '@kit.NetworkKit';
import { createApiRequestHeaders, DEFAULT_NETWORK_TIMEOUT_MS, SAPIBaseURL } from '../../config/constants';
import { readCache, writeCache, getCacheGeneration } from '../cache/CacheService';
import { CachedRequest, RequestScope, validApiResponse } from '../cache/CachedRequest';
import type { RequestCache, CachedValue } from '../cache/CachedRequest';
import type { ApiDataResult, BaseAPIResponse } from '../../models/types';

class ApiResponseCache implements RequestCache<BaseAPIResponse> {
    read(key: string, ttlMs: number): Promise<CachedValue<BaseAPIResponse> | undefined> {
        return readCache<BaseAPIResponse>(key, ttlMs);
    }
    write(key: string, value: BaseAPIResponse, generation: number): Promise<void> {
        return writeCache(key, value, generation);
    }
    generation(): number { return getCacheGeneration(); }
}
const client = new CachedRequest<BaseAPIResponse>(new ApiResponseCache(), validApiResponse);

export function requestJson<T>(
    path: string, ttlMs: number, forceNetwork: boolean = false,
    method: http.RequestMethod = http.RequestMethod.GET, body?: object, cacheIdentity?: string, scope?: RequestScope,
): Promise<ApiDataResult<T>> {
    const cacheKey = cacheIdentity ?? `${method}:${path}:${body ? JSON.stringify(body) : ''}`;
    return client.request(cacheKey, ttlMs, forceNetwork,
        (cancellation: RequestScope, refresh: boolean): Promise<BaseAPIResponse> =>
            fetchJson(refresh ? path.replace('use_cache=true', 'use_cache=false') : path, method, body, cancellation),
        path.startsWith('apps/app_id/') || path.startsWith('apps/pkg_name/') || path.startsWith('apps/metrics/') || path.startsWith('rankings/rate_history'), scope) as Promise<ApiDataResult<T>>;
}

async function fetchJson(path: string, method: http.RequestMethod, body?: object, scope?: RequestScope): Promise<BaseAPIResponse> {
    let request: http.HttpRequest | undefined = undefined;
    const trace = PerformanceTrace.begin('Dashboard.API.Request');
    let unsubscribe: (() => void) | undefined = undefined;
    try {
        request = http.createHttp();
        const currentRequest = request;
        unsubscribe = scope?.onCancel((): void => { currentRequest.destroy(); });
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
        const operation = request.request(`${SAPIBaseURL.toString()}${path}`, options);
        const response = await (scope ? scope.waitFor(operation) : operation);
        if (response.responseCode < 200 || response.responseCode >= 300) {
            throw new Error(`服务器返回 ${response.responseCode}`);
        }
        const parsed = PerformanceTrace.measure('Dashboard.API.Parse', (): BaseAPIResponse => JSON.parse(response.result.toString()) as BaseAPIResponse);
        return parsed;
    } catch (error) {
        if (!scope?.cancelled) console.warn('[Dashboard][common/MarketRequest][WARN]', `API 请求失败 ${path}: ${JSON.stringify(error)}`);
        throw error as Error;
    } finally {
        PerformanceTrace.finish('Dashboard.API.Request', trace);
        unsubscribe?.();
        if (request && !scope?.cancelled) {
            try {
                request.destroy();
            } catch (error) {
                console.warn('[Dashboard][common/MarketRequest][WARN]', `HTTP 请求对象释放失败 ${path}: ${JSON.stringify(error)}`);
            }
        }
    }
}

export async function postNoCache<T>(path: string, body: object): Promise<T> {
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
        console.error('[Dashboard][common/MarketRequest][ERROR]', `API 写操作失败 ${path}: ${JSON.stringify(error)}`);
        throw new Error('网络连接失败，本次操作未提交，请稍后重试');
    } finally {
        if (request) {
            try {
                request.destroy();
            } catch (error) {
                console.warn('[Dashboard][common/MarketRequest][WARN]', `HTTP 写请求对象释放失败 ${path}: ${JSON.stringify(error)}`);
            }
        }
    }
}

