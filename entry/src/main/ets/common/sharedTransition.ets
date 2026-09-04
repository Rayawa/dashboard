import type { MarketApp } from './types';

/**
 * 应用卡片与详情头图共用的几何转场标识。
 * appId 优先，兼容仅有包名的搜索/接续结果。
 */
export function appIconGeometryId(app: MarketApp): string {
    const identity = app.app_id || app.pkg_name || 'unknown';
    return `app_icon_${identity.replace(/[^a-zA-Z0-9_-]/g, '_')}`;
}
