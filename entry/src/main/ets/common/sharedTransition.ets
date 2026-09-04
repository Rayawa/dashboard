import type { MarketApp } from './types';

/**
 * 应用卡片与详情头图共用的几何转场标识。
 * appId 优先，兼容仅有包名的搜索/接续结果；来源作用域避免常驻 Tab 产生重复 id。
 */
export function appIconGeometryId(app: MarketApp, source: string = 'app'): string {
    const identity = app.app_id || app.pkg_name || 'unknown';
    const safeSource = source.replace(/[^a-zA-Z0-9_-]/g, '_');
    return `app_icon_${safeSource}_${identity.replace(/[^a-zA-Z0-9_-]/g, '_')}`;
}
