import {
    APP_STATE_KEY_PAGE_URL,
    APP_STATE_KEY_DETAIL_TARGET,
    APP_STATE_KEY_MAIN_TAB,
    APP_STATE_KEY_CONTINUATION_DETAIL_ID,
    APP_STATE_KEY_CONTINUATION_DETAIL_PACKAGE,
    APP_STATE_KEY_CONTINUATION_ROUTE,
    APP_STATE_KEY_QUERY_URL,
    APP_STATE_KEY_SEARCH_TARGET,
    APP_STATE_KEY_SCROLL_DISTANCE,
    APP_STATE_KEY_SHARE_REQUEST,
    DEFAULT_SCROLL_DISTANCE,
    CONTINUATION_ROUTE_MAIN,
    MAIN_TAB_DEFAULT,
    MAIN_TAB_SEARCH,
} from './constants';
import type { AppRouteTarget, SearchTarget } from './types';

export interface ContinuationState {
    pageUrl: string;
    scrollDistance: number;
    mainTab: number;
    routeName: string;
    detailAppId: string;
    detailPackageName: string;
}

export interface ShareRequest {
    sharePackageName: string;
    shareUrl: string;
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
    };
}

export function setContinuationState(state: ContinuationState): void {
    AppStorage.setOrCreate(APP_STATE_KEY_PAGE_URL, state.pageUrl);
    AppStorage.setOrCreate(APP_STATE_KEY_SCROLL_DISTANCE, state.scrollDistance);
    AppStorage.setOrCreate(APP_STATE_KEY_MAIN_TAB, state.mainTab);
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_ROUTE, state.routeName);
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_DETAIL_ID, state.detailAppId);
    AppStorage.setOrCreate(APP_STATE_KEY_CONTINUATION_DETAIL_PACKAGE, state.detailPackageName);
}

export function setContinuationView(
    mainTab: number,
    scrollDistance: number,
    routeName: string = CONTINUATION_ROUTE_MAIN,
    detail: AppRouteTarget = {},
    pageUrl: string = '',
): void {
    setContinuationState({
        pageUrl,
        scrollDistance,
        mainTab,
        routeName,
        detailAppId: detail.appId ?? '',
        detailPackageName: detail.packageName ?? '',
    });
}

export function setContinuationPageUrl(pageUrl: string): void {
    AppStorage.setOrCreate(APP_STATE_KEY_PAGE_URL, pageUrl);
}

export function setContinuationScrollDistance(scrollDistance: number): void {
    AppStorage.setOrCreate(APP_STATE_KEY_SCROLL_DISTANCE, scrollDistance);
}

export function setQueryTargetUrl(url: string): void {
    AppStorage.setOrCreate(APP_STATE_KEY_QUERY_URL, url);
}

export function consumeQueryTargetUrl(): string {
    const url = AppStorage.get<string>(APP_STATE_KEY_QUERY_URL) ?? '';
    AppStorage.setOrCreate(APP_STATE_KEY_QUERY_URL, '');
    return url;
}

export function setShareRequest(request: ShareRequest): void {
    AppStorage.setOrCreate<ShareRequest>(APP_STATE_KEY_SHARE_REQUEST, request);
}

export function consumeShareRequest(): ShareRequest {
    const request = AppStorage.get<ShareRequest>(APP_STATE_KEY_SHARE_REQUEST) ?? {
        sharePackageName: '',
        shareUrl: '',
    };
    AppStorage.setOrCreate<ShareRequest>(APP_STATE_KEY_SHARE_REQUEST, {
        sharePackageName: '',
        shareUrl: '',
    });
    return request;
}

export function setDetailTarget(target: AppRouteTarget): void {
    AppStorage.setOrCreate<AppRouteTarget>(APP_STATE_KEY_DETAIL_TARGET, target);
}

export function consumeDetailTarget(): AppRouteTarget {
    const target = AppStorage.get<AppRouteTarget>(APP_STATE_KEY_DETAIL_TARGET) ?? {};
    AppStorage.setOrCreate<AppRouteTarget>(APP_STATE_KEY_DETAIL_TARGET, {});
    return target;
}

export function setSearchTarget(target: SearchTarget): void {
    AppStorage.setOrCreate<SearchTarget>(APP_STATE_KEY_SEARCH_TARGET, target);
    AppStorage.setOrCreate<number>(APP_STATE_KEY_MAIN_TAB, MAIN_TAB_SEARCH);
}

export function consumeSearchTarget(): SearchTarget {
    const target = AppStorage.get<SearchTarget>(APP_STATE_KEY_SEARCH_TARGET) ?? {};
    AppStorage.setOrCreate<SearchTarget>(APP_STATE_KEY_SEARCH_TARGET, {});
    return target;
}

export function setMainTab(index: number): void {
    AppStorage.setOrCreate<number>(APP_STATE_KEY_MAIN_TAB, index);
}

export function consumeMainTab(defaultIndex: number = MAIN_TAB_DEFAULT): number {
    const index = AppStorage.get<number>(APP_STATE_KEY_MAIN_TAB) ?? defaultIndex;
    AppStorage.setOrCreate<number>(APP_STATE_KEY_MAIN_TAB, defaultIndex);
    return index;
}
