import type { AppRouteTarget, MarketApp } from '../../models/types';
import { parseInputSplitLinksPkgsAndAppIds } from '../../utils/links/parseAppLinks';

function decodeValue(value: string): string {
    try { return decodeURIComponent(value); }
    catch (_) { return value; }
}

/** 明确的看板参数优先，其次为市场链接、App ID 和包名；空目标交给名称搜索。 */
export function searchTargetFromInput(input: string): AppRouteTarget {
    const appIdParameter = input.match(/[?&#]app_id=([^&#]+)/);
    if (appIdParameter) return { appId: decodeValue(appIdParameter[1]) };
    const packageParameter = input.match(/[?&#]pkg=([^&#]+)/);
    if (packageParameter) return { packageName: decodeValue(packageParameter[1]) };

    const parsed = parseInputSplitLinksPkgsAndAppIds(input);
    if (parsed.app_ids.length > 0) {
        const appId = parsed.app_ids[parsed.app_ids.length - 1];
        return { appId: appId.replace(/^[Cc]/, 'C') };
    }
    if (parsed.pkgs.length > 0) return { packageName: parsed.pkgs[parsed.pkgs.length - 1] };
    const marketId = input.match(/[?&]id=([^&#]+)/);
    return marketId ? { packageName: decodeValue(marketId[1]) } : {};
}

function relevance(app: MarketApp, normalized: string): number {
    const name = (app.name || '').toLowerCase();
    const packageName = (app.pkg_name || '').toLowerCase();
    if (name === normalized || packageName === normalized) return 0;
    if (name.startsWith(normalized)) return 1;
    if (packageName.startsWith(normalized)) return 2;
    if (name.includes(normalized)) return 3;
    if (packageName.includes(normalized)) return 4;
    return 5;
}

export function sortSearchResults(apps: MarketApp[], query: string): MarketApp[] {
    const normalized = query.trim().toLowerCase();
    return apps.slice().sort((left: MarketApp, right: MarketApp): number =>
        relevance(left, normalized) - relevance(right, normalized));
}
