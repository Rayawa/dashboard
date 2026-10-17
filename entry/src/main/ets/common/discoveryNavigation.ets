import { peekDetailTarget, setDetailTarget } from './appState';
import { ROUTE_APP_DETAIL, ROUTE_APP_COLLECTION, ROUTE_RANKINGS, ROUTE_TOPICS } from './constants';
import { pushPathSafely } from './safeNavigation';
import type { AppRouteTarget, AppCollectionTarget, RankingTarget, TopicTarget } from './types';

export function openDiscoveryApp(stack: NavPathStack, target: AppRouteTarget): void {
    // 与首页、搜索沿用同一传参通道；目标页在首帧构建前也能取得标识。
    const previous = peekDetailTarget();
    setDetailTarget(target);
    if (!pushPathSafely(stack, ROUTE_APP_DETAIL, target)) setDetailTarget(previous);
}
export function openAppCollection(stack: NavPathStack, target: AppCollectionTarget): void {
    pushPathSafely(stack, ROUTE_APP_COLLECTION, target);
}
export function openMarketRanking(stack: NavPathStack, target: RankingTarget): void {
    pushPathSafely(stack, ROUTE_RANKINGS, target);
}
export function openMarketTopic(stack: NavPathStack, target: TopicTarget = {}): void {
    pushPathSafely(stack, ROUTE_TOPICS, target);
}
