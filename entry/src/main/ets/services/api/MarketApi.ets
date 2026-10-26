import type { RequestScope } from '../cache/CachedRequest';
import { http } from '@kit.NetworkKit';
import {
    CACHE_TTL_CHART_MS,
    CACHE_TTL_DETAIL_MS,
    CACHE_TTL_HOME_MS,
    CACHE_TTL_LIST_MS,
    SUBMIT_PLATFORM,
} from '../../config/constants';
import { requestJson, postNoCache } from './MarketRequest';
import { buildAppsPagePath } from '../../domain/apps/AppListQuery';
import type { AppsPageQuery } from '../../domain/apps/AppListQuery';
import {
    buildReputationPath,
    buildAdvancedAppsQueryPath,
    buildCategoryGrowthPath,
    buildTopicsPath,
    buildDeveloperRankingPath,
    buildDownloadGrowthPath,
} from '../../domain/rankings/RankingQuery';
import type {
    ReputationPayload,
    ReputationQuery,
    CollectionSearchExpression,
    CategoryGrowth,
    CategoryGrowthQuery,
    TopicSummary,
    TopicDetail,
    AdvancedAppsQuery,
    ApiDataResult,
    AppDetailPayload,
    AppMetric,
    AppRatingHistory,
    BaseAPIResponse,
    DailyMaxDownloadApp,
    DeveloperRankingEntry,
    DownloadGrowthApp,
    DownloadGrowthQuery,
    MarketApp,
    MarketInfo,
    PageInfo,
    RatingDistribution,
    SearchExpression,
    SubmitAppBody,
} from '../../models/types';

type SdkDistribution = number[][];
type ApiHistory = object[];

export function fetchMarketInfo(force: boolean = false, scope?: RequestScope): Promise<ApiDataResult<BaseAPIResponse<MarketInfo>>> {
    return requestJson<BaseAPIResponse<MarketInfo>>('market_info', CACHE_TTL_HOME_MS, force, http.RequestMethod.GET, undefined, undefined, scope);
}

export function fetchAppsPage(
    options: AppsPageQuery, scope?: RequestScope,
): Promise<ApiDataResult<BaseAPIResponse<PageInfo<MarketApp>>>> {
    return requestJson<BaseAPIResponse<PageInfo<MarketApp>>>(
        buildAppsPagePath(options),
        CACHE_TTL_LIST_MS,
        options.force ?? false, http.RequestMethod.GET, undefined, undefined, scope,
    );
}

export function fetchAppsQuery(
    options: AdvancedAppsQuery,
    expression: SearchExpression | CollectionSearchExpression,
    scope?: RequestScope,
): Promise<ApiDataResult<BaseAPIResponse<PageInfo<MarketApp>>>> {
    return requestJson<BaseAPIResponse<PageInfo<MarketApp>>>(
        buildAdvancedAppsQueryPath(options),
        CACHE_TTL_LIST_MS,
        options.force ?? false,
        http.RequestMethod.POST,
        expression,
        undefined, scope,
    );
}

export function fetchDownloadGrowth(
    options: DownloadGrowthQuery = {},
    expression?: SearchExpression,
    scope?: RequestScope,
): Promise<ApiDataResult<BaseAPIResponse<DownloadGrowthApp[]>>> {
    return requestJson<BaseAPIResponse<DownloadGrowthApp[]>>(
        buildDownloadGrowthPath(options),
        CACHE_TTL_CHART_MS,
        options.force ?? false,
        expression ? http.RequestMethod.POST : http.RequestMethod.GET,
        expression,
        undefined, scope,
    );
}

export function fetchDailyMaxDownloads(
    force: boolean = false, scope?: RequestScope,
): Promise<ApiDataResult<BaseAPIResponse<DailyMaxDownloadApp[]>>> {
    return requestJson<BaseAPIResponse<DailyMaxDownloadApp[]>>(
        'rankings/max_download', CACHE_TTL_HOME_MS, force, http.RequestMethod.GET, undefined, undefined, scope,
    );
}

export async function fetchDeveloperRanking(
    limit: number = 10,
    page: number = 1,
    force: boolean = false, scope?: RequestScope,
): Promise<ApiDataResult<BaseAPIResponse<DeveloperRankingEntry[]>>> {
    const result = await requestJson<BaseAPIResponse<Array<Array<string | number>>>>(
        buildDeveloperRankingPath(limit, page), CACHE_TTL_HOME_MS, force, http.RequestMethod.GET, undefined, undefined, scope,
    );
    const entries: DeveloperRankingEntry[] = [];
    for (const tuple of result.data.data ?? []) {
        if (tuple.length < 3) continue;
        entries.push({
            developerId: String(tuple[0] ?? ''),
            developerName: String(tuple[1] ?? '未知开发者'),
            appCount: Number(tuple[2] ?? 0),
        });
    }
    return {
        data: {
            success: result.data.success,
            data: entries,
            total: result.data.total,
            limit: result.data.limit,
            timestamp: result.data.timestamp,
        },
        fromCache: result.fromCache,
        cachedAt: result.cachedAt,
        stale: result.stale,
    };
}

const packageIdentities: Map<string, string> = new Map();
function rememberDetailIdentity(result: ApiDataResult<BaseAPIResponse<AppDetailPayload>>): ApiDataResult<BaseAPIResponse<AppDetailPayload>> {
    const app = result.data.data?.full_info;
    if (app?.pkg_name && app.app_id) {
        packageIdentities.delete(app.pkg_name); packageIdentities.set(app.pkg_name, app.app_id);
        if (packageIdentities.size > 128) packageIdentities.delete(packageIdentities.keys().next().value as string);
    }
    result.revalidated?.then((fresh) => rememberDetailIdentity(fresh)).catch((): void => {});
    return result;
}

export function fetchAppById(appId: string, force: boolean = false, scope?: RequestScope): Promise<ApiDataResult<BaseAPIResponse<AppDetailPayload>>> {
    const basePath = `apps/app_id/${encodeURIComponent(appId)}`;
    return requestJson<BaseAPIResponse<AppDetailPayload>>(
        `${basePath}?use_cache=${!force}`,
        CACHE_TTL_DETAIL_MS,
        force,
        http.RequestMethod.GET,
        undefined,
        `detail:${basePath}`, scope,
    ).then(rememberDetailIdentity);
}

export function fetchAppByPackage(packageName: string, force: boolean = false, scope?: RequestScope): Promise<ApiDataResult<BaseAPIResponse<AppDetailPayload>>> {
    const knownId = packageIdentities.get(packageName);
    if (knownId) return fetchAppById(knownId, force, scope);
    const basePath = `apps/pkg_name/${encodeURIComponent(packageName)}`;
    return requestJson<BaseAPIResponse<AppDetailPayload>>(
        `${basePath}?use_cache=${!force}`,
        CACHE_TTL_DETAIL_MS,
        force,
        http.RequestMethod.GET,
        undefined,
        `detail:${basePath}`, scope,
    ).then(rememberDetailIdentity);
}

export function fetchRatingDistribution(force: boolean = false, scope?: RequestScope): Promise<ApiDataResult<BaseAPIResponse<RatingDistribution>>> {
    return requestJson<BaseAPIResponse<RatingDistribution>>('charts/rating', CACHE_TTL_CHART_MS, force, http.RequestMethod.GET, undefined, undefined, scope);
}

export function fetchSdkDistribution(kind: 'min_sdk' | 'target_sdk', force: boolean = false, scope?: RequestScope): Promise<ApiDataResult<BaseAPIResponse<SdkDistribution>>> {
    return requestJson<BaseAPIResponse<SdkDistribution>>(`charts/${kind}`, CACHE_TTL_CHART_MS, force, http.RequestMethod.GET, undefined, undefined, scope);
}

export function fetchApiHistory(force: boolean = false, scope?: RequestScope): Promise<ApiDataResult<BaseAPIResponse<ApiHistory>>> {
    return requestJson<BaseAPIResponse<ApiHistory>>('charts/api_history', CACHE_TTL_CHART_MS, force, http.RequestMethod.GET, undefined, undefined, scope);
}

export function fetchAppMetrics(packageName: string, force: boolean = false, scope?: RequestScope): Promise<ApiDataResult<BaseAPIResponse<AppMetric[]>>> {
    return requestJson<BaseAPIResponse<AppMetric[]>>(
        `apps/metrics/${encodeURIComponent(packageName)}`,
        CACHE_TTL_DETAIL_MS,
        force, http.RequestMethod.GET, undefined, undefined, scope,
    );
}

export function fetchAppRatingHistory(packageName: string, force: boolean = false, scope?: RequestScope): Promise<ApiDataResult<BaseAPIResponse<AppRatingHistory[]>>> {
    return requestJson<BaseAPIResponse<AppRatingHistory[]>>(
        `rankings/rate_history?pkg_name=${encodeURIComponent(packageName)}`,
        CACHE_TTL_DETAIL_MS,
        force, http.RequestMethod.GET, undefined, undefined, scope,
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

export function fetchCategoryGrowth(options: CategoryGrowthQuery, scope?: RequestScope): Promise<ApiDataResult<BaseAPIResponse<CategoryGrowth[]>>> {
    return requestJson<BaseAPIResponse<CategoryGrowth[]>>(
        buildCategoryGrowthPath(options), CACHE_TTL_CHART_MS, options.force ?? false,
        http.RequestMethod.GET, undefined, undefined, scope,
    );
}
export function fetchTopics(page: number, pageSize: number, force: boolean = false, scope?: RequestScope):
    Promise<ApiDataResult<BaseAPIResponse<PageInfo<TopicSummary>>>> {
    return requestJson<BaseAPIResponse<PageInfo<TopicSummary>>>(
        buildTopicsPath(page, pageSize), CACHE_TTL_LIST_MS, force,
        http.RequestMethod.GET, undefined, undefined, scope,
    );
}
export function fetchTopic(id: string, force: boolean = false, scope?: RequestScope): Promise<ApiDataResult<BaseAPIResponse<TopicDetail>>> {
    return requestJson<BaseAPIResponse<TopicDetail>>(
        `substance/${encodeURIComponent(id)}`, CACHE_TTL_DETAIL_MS, force,
        http.RequestMethod.GET, undefined, undefined, scope,
    );
}

export function fetchReputation(options: ReputationQuery = {}, scope?: RequestScope): Promise<ApiDataResult<BaseAPIResponse<ReputationPayload>>> {
    return requestJson<BaseAPIResponse<ReputationPayload>>(
        buildReputationPath(options), CACHE_TTL_HOME_MS, options.force ?? false, http.RequestMethod.GET, undefined, undefined, scope,
    );
}
