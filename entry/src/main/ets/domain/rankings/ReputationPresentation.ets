import type { ReputationItem } from '../../models/types';
import { formatScore } from '../../utils/format/format';

/** 保留带符号指标原值，修正标记与实际基线跨度必须可见。 */
export function reputationSubtitle(item: ReputationItem): string {
    return `${item.developer_name} · ${item.tag_name || item.kind_name}\n` +
        `${item.baseline_date} → ${item.snapshot_date}（实际 ${item.actual_days} 天）\n` +
        `净样本 ${item.sample_count} · 正样本 ${item.positive_sample_count}` +
        ` · 可信权重 ${(item.confidence_weight * 100).toFixed(1)}%` +
        (item.has_correction ? '\n含数据修正' : '');
}
export function reputationValue(item: ReputationItem): string {
    return `加权 ${formatScore(item.weighted_score)}\n指标 ${formatScore(item.rating)}`;
}

export function reputationSummary(item: ReputationItem): string {
    return `${item.tag_name || item.kind_name} · ${item.sample_count} 个净样本` +
        (item.has_correction ? ' · 含修正' : '');
}
