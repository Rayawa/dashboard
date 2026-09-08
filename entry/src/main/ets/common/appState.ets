import {
    APP_STATE_KEY_PAGE_URL,
    APP_STATE_KEY_DETAIL_TARGET,
    APP_STATE_KEY_MAIN_TAB,
    APP_STATE_KEY_APPS_VIEW,
    APP_STATE_KEY_CONTINUATION_DETAIL_ID,
    APP_STATE_KEY_CONTINUATION_DETAIL_PACKAGE,
    APP_STATE_KEY_CONTINUATION_APPS_LIST,
    APP_STATE_KEY_CONTINUATION_OVERVIEW,
    APP_STATE_KEY_CONTINUATION_DETAIL_CHARTS,
    APP_STATE_KEY_CONTINUATION_ROUTE,
    APP_STATE_KEY_SEARCH_TARGET,
    APP_STATE_KEY_SCROLL_DISTANCE,
    DEFAULT_SCROLL_DISTANCE,
    CONTINUATION_ROUTE_MAIN,
    MAIN_TAB_DEFAULT,
    MAIN_TAB_APPS,
} from './constants';
import type { AppRouteTarget, ChartViewportState, SearchTarget } from './types';

export interface AppsListContinuationState {
    page: number;
    pageSizeIndex: number;
    typeIndex: number;
    filterIndex: number;
    filterText: string;
    appliedFilterText: string;
    sortIndex: number;
    descending: boolean;
}

export interface OverviewContinuationState {
    sdkExpanded: boolean;
    targetSdkExpanded: boolean;
    minSdkExpanded: boolean;
    sdkOtherHidden: boolean;
    apiHistoryViewport: ChartViewportState;
}

export interface DetailChartsContinuationState {
    targetKey: string;
    downloadViewport: ChartViewportState;
    ratingViewport: ChartViewportState;
}

export interface ContinuationState {
    pageUrl: string;
    scrollDistance: number;
    mainTab: number;
    routeName: string;
    detailAppId: string;
    detailPackageName: string;
    appsViewIndex: number;
    appsListState: AppsListContinuationState;
    overviewState: OverviewContinuationState;
    detailChartsState: DetailChartsContinuationState;
}

export function defaultAppsListState(): AppsListContinuationState {
    return {
        page: 1,
        pageSizeIndex: 0,
        typeIndex: 0,
        filterIndex: 0,
        filterText: '',
        appliedFilterText: '',
        sortIndex: 1,
        descending: true,
    };
}

export function defaultOverviewState(): OverviewContinuationState {
    return {
        sdkExpanded: false,
        targetSdkExpanded: false,
        minSdkExpanded: false,
        sdkOtherHidden: false,
        apiHistoryViewport: { zoom: 1, panRatio: 0 },
    };
}

export function defaultDetailChartsState(): DetailChartsContinuationState {
    return {
        targetKey: '',
        downloadViewport: { zoom: 1, panRatio: 0 },
        ratingViewport: { zoom: 1, panRatio: 0 },
    };
}

/**
 * 唯一的跨 UIAbility 瞬态状态边界。
 * 页面和 Ability 均通过这些函数访问，避免应用代码散落地操作 AppStorage。
 */
export function getContinuationState(): ContinuationState {
    return {
        pageUrl: AppStorage.get<string>(APP_STATE_KEY_PAGE_URL) ?? '',
        scrollDistance: AppStorage.get<number>(APP_STATE_KEY_SCROLL_DISTANCE) ?? DEFAULT_SCROLL_DISTANCE,
        mainTab: AppStorage.get<number>(APP_STATE_KEY_MAIN_TAB) ?? MAIN_TAB_DEFAULT,
        routeName: AppStorage.get<string>(APP_STATE_KEY_CONTINUATION_ROUTE) ?? CONTINUATION_ROUTE_MAIN,
        detailAppId: AppStorage.get<string>(APP_STATE_KEY_CONTINUATION_DETAIL_ID) ?? '',
        detailPackageName: AppStorage.get<string>(APP_STATE_KEY_CONTINUATION_DETAIL_PACKAGE) ?? '',
        appsViewIndex: AppStorage.get<number>(APP_STATE_KEY_APPS_VIEW) ?? 0,
        appsListState: AppStorage.get<AppsListContinuationState>(APP_STATE_KEY_CONTINUATION_APPS_LIST) ??
            defaultAppsListState(),
        overviewState: AppStorage.get<OverviewContinuationState>(APP_STATE_KEY_CONTINUATION_OVERVIEW) ??
            defaultOverviewState(),
        detailChartsState:
            AppStorage.get<DetailChartsContinuationState>(APP_STATE_KEY_CONTINUATION_DETAIL_CHARTS) ??
                defaultDetailChartsState(),
    };
}

export function setContinuationState(state: ContinuationState): void {
    AppStorage.setOrCreate(APP_STATE_KEY_PAGE_URL, state.pageUrl);
    AppStorage.setOrCreate(APP_STATE_KEY_SCROLL_DISTANCE, state.scrollDistance);
    AppStorage.setOrCreate(APP_STATE_KEY_MAIN_TAB, state.mainTab);
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_ROUTE, state.routeName);
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_DETAIL_ID, state.detailAppId);
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_DETAIL_PACKAGE, state.detailPackageName);
    AppStorage.setOrCreate(APP_STATE_KEY_APPS_VIEW, state.appsViewIndex);
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_APPS_LIST, state.appsListState);
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_OVERVIEW, state.overviewState);
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_DETAIL_CHARTS, state.detailChartsState);
}

export function setContinuationView(
    mainTab: number,
    scrollDistance: number,
    routeName: string = CONTINUATION_ROUTE_MAIN,
    detail: AppRouteTarget = {},
    pageUrl?: string,
): void {
    const resolvedPageUrl = pageUrl === undefined ?
        (AppStorage.get<string>(APP_STATE_KEY_PAGE_URL) ?? '') : pageUrl;
    setContinuationState({
        pageUrl: resolvedPageUrl,
        scrollDistance,
        mainTab,
        routeName,
        detailAppId: detail.appId ?? '',
        detailPackageName: detail.packageName ?? '',
        appsViewIndex: AppStorage.get<number>(APP_STATE_KEY_APPS_VIEW) ?? 0,
        appsListState: AppStorage.get<AppsListContinuationState>(APP_STATE_KEY_CONTINUATION_APPS_LIST) ??
            defaultAppsListState(),
        overviewState: AppStorage.get<OverviewContinuationState>(APP_STATE_KEY_CONTINUATION_OVERVIEW) ??
            defaultOverviewState(),
        detailChartsState:
            AppStorage.get<DetailChartsContinuationState>(APP_STATE_KEY_CONTINUATION_DETAIL_CHARTS) ??
                defaultDetailChartsState(),
    });
}

export function setContinuationAppsListState(state: AppsListContinuationState): void {
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_APPS_LIST, state);
}

export function setContinuationOverviewState(state: OverviewContinuationState): void {
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_OVERVIEW, state);
}

export function setContinuationDetailChartsState(state: DetailChartsContinuationState): void {
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_DETAIL_CHARTS, state);
}

export function setContinuationPageUrl(pageUrl: string): void {
    AppStorage.setOrCreate(APP_STATE_KEY_PAGE_URL, pageUrl);
}

export function setContinuationScrollDistance(scrollDistance: number): void {
    AppStorage.setOrCreate(APP_STATE_KEY_SCROLL_DISTANCE, scrollDistance);
}

export function setDetailTarget(target: AppRouteTarget): void {
    AppStorage.setOrCreate<AppRouteTarget>(APP_STATE_KEY_DETAIL_TARGET, target);
}

export function peekDetailTarget(): AppRouteTarget {
    return AppStorage.get<AppRouteTarget>(APP_STATE_KEY_DETAIL_TARGET) ?? {};
}

export function consumeDetailTarget(): AppRouteTarget {
    const target = peekDetailTarget();
    AppStorage.setOrCreate<AppRouteTarget>(APP_STATE_KEY_DETAIL_TARGET, {});
    return target;
}

export function setSearchTarget(target: SearchTarget): void {
    AppStorage.setOrCreate<SearchTarget>(APP_STATE_KEY_SEARCH_TARGET, target);
    AppStorage.setOrCreate<number>(APP_STATE_KEY_MAIN_TAB, MAIN_TAB_APPS);
}

export function consumeSearchTarget(): SearchTarget {
    const target = AppStorage.get<SearchTarget>(APP_STATE_KEY_SEARCH_TARGET) ?? {};
    AppStorage.setOrCreate<SearchTarget>(APP_STATE_KEY_SEARCH_TARGET, {});
    return target;
}

export function hasPendingSearchTarget(): boolean {
    const target = AppStorage.get<SearchTarget>(APP_STATE_KEY_SEARCH_TARGET) ?? {};
    return (target.rawText || target.packageName || target.appId || '').length > 0;
}

export function setMainTab(index: number): void {
    AppStorage.setOrCreate<number>(APP_STATE_KEY_MAIN_TAB, index);
}

export function setAppsViewIndex(index: number): void {
    AppStorage.setOrCreate<number>(APP_STATE_KEY_APPS_VIEW, index === 1 ? 1 : 0);
}

export function consumeMainTab(defaultIndex: number = MAIN_TAB_DEFAULT): number {
    const index = AppStorage.get<number>(APP_STATE_KEY_MAIN_TAB) ?? defaultIndex;
    AppStorage.setOrCreate<number>(APP_STATE_KEY_MAIN_TAB, defaultIndex);
    return index;
}
