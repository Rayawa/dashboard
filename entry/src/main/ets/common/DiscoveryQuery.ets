import type { AppCollectionTarget, SearchCondition, CollectionSearchExpression, AppMetric, VersionChange } from './types';
import { formatBytes } from './format';

export interface DiscoveryPreset { key: string; title: string; }
export const DISCOVERY_PRESETS: DiscoveryPreset[] = [
    { key: 'listed', title: '最近收录' },
    { key: 'release', title: '最近发布版本' },
    { key: 'rated', title: '高分应用' },
    { key: 'tablet', title: '平板应用' },
    { key: 'pc', title: '电脑应用' },
];

export function collectionExpression(target: AppCollectionTarget): CollectionSearchExpression {
    const conditions: (SearchCondition | CollectionSearchExpression)[] = [];
    if (target.developerId) conditions.push({ key: 'dev_id', op: 'eq', value: target.developerId });
    else if (target.developerName) conditions.push({ key: 'developer_name', op: 'eq', value: target.developerName });
    if (target.category) conditions.push({ key: 'kind_name', op: 'eq', value: target.category });
    // 后端细分赛道将空标签回退为分类名，跳转时保持同一口径。
    if (target.segment) {
        if (target.segment === target.category) {
            conditions.push({ or: [
                { key: 'tag_name', op: 'eq', value: target.segment },
                { key: 'tag_name', op: 'eq', value: '' },
                { key: 'tag_name', op: 'is_null', value: null },
            ] });
        } else conditions.push({ key: 'tag_name', op: 'eq', value: target.segment });
    }
    if (target.early) {
        conditions.push({ key: 'download_count', op: 'gte', value: '1000' });
        conditions.push({ key: 'download_count', op: 'lt', value: '100000' });
    }
    if (target.preset === 'rated') {
        conditions.push({ key: 'average_rating', op: 'gte', value: '4.5' });
        conditions.push({ key: 'total_star_rating_count', op: 'gte', value: '100' });
    }
    if (target.preset === 'tablet' || target.preset === 'pc') {
        conditions.push({ key: 'main_device_codes', op: 'array_contains', value: target.preset === 'tablet' ? '4' : '15' });
    }
    if (target.preset === 'listed' || target.preset === 'release') {
        conditions.push({ key: target.preset === 'listed' ? 'listed_at' : 'release_date', op: 'is_not_null', value: null });
    }
    if (conditions.length === 0) conditions.push({ key: 'app_id', op: 'is_not_null', value: null });
    return { and: conditions };
}

export function collectionSort(target: AppCollectionTarget): string {
    if (target.preset === 'listed') return 'listed_at';
    if (target.preset === 'release') return 'release_date';
    if (target.preset === 'rated') return 'average_rating';
    return 'download_count';
}

/** 相邻采集记录只在版本、体积、SDK 或价格发生变化时保留，避免逐日重复。 */
export function versionChanges(metrics: AppMetric[]): VersionChange[] {
    const sorted = metrics.filter((m: AppMetric) => !!m.created_at && Number.isFinite(new Date(m.created_at).getTime()))
        .slice().sort((a: AppMetric, b: AppMetric) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
    const changes: VersionChange[] = [];
    let prior: AppMetric | undefined = undefined;
    for (const metric of sorted) {
        const fields: string[] = [];
        if (!prior) fields.push('首次采集记录');
        else {
            if (metric.version !== prior.version || metric.version_code !== prior.version_code) fields.push('版本更新');
            if (metric.size_bytes !== prior.size_bytes) fields.push(`大小 ${formatBytes(prior.size_bytes)} → ${formatBytes(metric.size_bytes)}`);
            if (metric.minsdk !== prior.minsdk) fields.push(`最低 SDK ${prior.minsdk} → ${metric.minsdk}`);
            if (metric.target_sdk !== prior.target_sdk) fields.push(`目标 SDK ${prior.target_sdk} → ${metric.target_sdk}`);
            if (metric.compile_sdk_version !== prior.compile_sdk_version) fields.push(`编译 SDK ${prior.compile_sdk_version} → ${metric.compile_sdk_version}`);
            if (metric.min_hmos_api_level !== prior.min_hmos_api_level) fields.push(`最低 API ${prior.min_hmos_api_level} → ${metric.min_hmos_api_level}`);
            if (Number(metric.price) !== Number(prior.price)) fields.push(`价格 ${prior.price} → ${metric.price}`);
        }
        if (fields.length > 0) changes.push({
            key: `${metric.created_at}-${metric.version_code}`,
            version: `${metric.version || '未知版本'} (${metric.version_code})`,
            observedAt: metric.created_at,
            summary: fields.join(' · '),
            notes: metric.new_features || metric.upgrade_msg || '',
        });
        prior = metric;
    }
    return changes.reverse();
}
