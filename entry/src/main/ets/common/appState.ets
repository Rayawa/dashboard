import {
    APP_STATE_KEY_PAGE_URL,
    APP_STATE_KEY_DETAIL_TARGET,
    APP_STATE_KEY_MAIN_TAB,
    APP_STATE_KEY_APPS_VIEW,
    APP_STATE_KEY_CONTINUATION_DETAIL_ID,
    APP_STATE_KEY_CONTINUATION_DETAIL_PACKAGE,
    APP_STATE_KEY_CONTINUATION_ROUTE,
    APP_STATE_KEY_SEARCH_TARGET,
    APP_STATE_KEY_SCROLL_DISTANCE,
    DEFAULT_SCROLL_DISTANCE,
    CONTINUATION_ROUTE_MAIN,
    MAIN_TAB_DEFAULT,
    MAIN_TAB_APPS,
} from './constants';
import type { AppRouteTarget, SearchTarget } from './types';

export interface ContinuationState {
    pageUrl: string;
    scrollDistance: number;
    mainTab: number;
    routeName: string;
    detailAppId: string;
    detailPackageName: string;
    appsViewIndex: number;
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
    });
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
