import type { AppCollectionTarget, MarketApp } from './types';
import { formatDateTime } from './format';

function versionLabel(app: MarketApp): string {
    return app.version ? `版本 ${app.version}` : '';
}
function releaseLabel(timestamp: number): string {
    if (!Number.isFinite(timestamp) || timestamp <= 0) return '发布时间未知';
    const milliseconds = timestamp < 1000000000000 ? timestamp * 1000 : timestamp;
    return `发布于 ${formatDateTime(new Date(milliseconds).toISOString())}`;
}
export function appCollectionSubtitle(app: MarketApp, target: AppCollectionTarget): string {
    if (target.preset === 'listed') return [app.developer_name, `收录于 ${formatDateTime(app.listed_at)}`].filter(Boolean).join(' · ');
    if (target.preset === 'release') return [versionLabel(app), releaseLabel(app.release_date)].filter(Boolean).join(' · ');
    if (target.preset === 'rated') return `评分 ${app.average_rating || '暂无'} · ${app.total_star_rating_count || 0} 条评分`;
    if (target.developerId || target.developerName) return [app.kind_name, versionLabel(app)].filter(Boolean).join(' · ');
    if (target.category) return [app.developer_name, versionLabel(app)].filter(Boolean).join(' · ');
    if (target.preset === 'tablet' || target.preset === 'pc') return [app.developer_name, app.kind_name].filter(Boolean).join(' · ');
    return [app.developer_name, app.kind_name, versionLabel(app)].filter(Boolean).join(' · ');
}
