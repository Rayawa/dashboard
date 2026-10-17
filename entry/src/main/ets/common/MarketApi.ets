import { http } from '@kit.NetworkKit';
import {
    CACHE_TTL_CHART_MS,
    CACHE_TTL_DETAIL_MS,
    CACHE_TTL_HOME_MS,
    CACHE_TTL_LIST_MS,
    SUBMIT_PLATFORM,
} from './constants';
import { requestJson, postNoCache } from './MarketRequest';
import { buildAppsPagePath } from './AppListQuery';
import type { AppsPageQuery } from './AppListQuery';
import {
    buildAdvancedAppsQueryPath,
    buildCategoryGrowthPath,
    buildTopicsPath,
    buildDeveloperRankingPath,
    buildDownloadGrowthPath,
} from './RankingQuery';
import type {
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
} from './types';

type SdkDistribution = number[][];
type ApiHistory = object[];

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

export function fetchAppsQuery(
    options: AdvancedAppsQuery,
    expression: SearchExpression | CollectionSearchExpression,
): Promise<ApiDataResult<BaseAPIResponse<PageInfo<MarketApp>>>> {
    return requestJson<BaseAPIResponse<PageInfo<MarketApp>>>(
        buildAdvancedAppsQueryPath(options),
        CACHE_TTL_LIST_MS,
        options.force ?? false,
        http.RequestMethod.POST,
        expression,
    );
}

export function fetchDownloadGrowth(
    options: DownloadGrowthQuery = {},
    expression?: SearchExpression,
): Promise<ApiDataResult<BaseAPIResponse<DownloadGrowthApp[]>>> {
    return requestJson<BaseAPIResponse<DownloadGrowthApp[]>>(
        buildDownloadGrowthPath(options),
        CACHE_TTL_CHART_MS,
        options.force ?? false,
        expression ? http.RequestMethod.POST : http.RequestMethod.GET,
        expression,
    );
}

export function fetchDailyMaxDownloads(
    force: boolean = false,
): Promise<ApiDataResult<BaseAPIResponse<DailyMaxDownloadApp[]>>> {
    return requestJson<BaseAPIResponse<DailyMaxDownloadApp[]>>(
        'rankings/max_download', CACHE_TTL_HOME_MS, force,
    );
}

export async function fetchDeveloperRanking(
    limit: number = 10,
    page: number = 1,
    force: boolean = false,
): Promise<ApiDataResult<BaseAPIResponse<DeveloperRankingEntry[]>>> {
    const result = await requestJson<BaseAPIResponse<Array<Array<string | number>>>>(
        buildDeveloperRankingPath(limit, page), CACHE_TTL_HOME_MS, force,
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

export function fetchCategoryGrowth(options: CategoryGrowthQuery): Promise<ApiDataResult<BaseAPIResponse<CategoryGrowth[]>>> {
    return requestJson<BaseAPIResponse<CategoryGrowth[]>>(
        buildCategoryGrowthPath(options), CACHE_TTL_CHART_MS, options.force ?? false,
    );
}
export function fetchTopics(page: number, pageSize: number, force: boolean = false):
    Promise<ApiDataResult<BaseAPIResponse<PageInfo<TopicSummary>>>> {
    return requestJson<BaseAPIResponse<PageInfo<TopicSummary>>>(
        buildTopicsPath(page, pageSize), CACHE_TTL_LIST_MS, force,
    );
}
export function fetchTopic(id: string, force: boolean = false): Promise<ApiDataResult<BaseAPIResponse<TopicDetail>>> {
    return requestJson<BaseAPIResponse<TopicDetail>>(
        `substance/${encodeURIComponent(id)}`, CACHE_TTL_DETAIL_MS, force,
    );
}
