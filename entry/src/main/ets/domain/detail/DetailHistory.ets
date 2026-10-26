import type { AppMetric, AppRatingHistory } from '../../models/types';
import type { LineChartPoint } from '../../models/chartTypes';
import { downsampleLinePoints, filterDownloadOutliers } from '../charts/chartDataProcessing';
import { formatDateTime, formatDownloadCount } from '../../utils/format/format';

interface TimedRating { rating: AppRatingHistory; time: number; value: number; }
const DETAIL_CHART_MAX_POINTS: number = 360;

export function detailDownloadPoints(metrics: AppMetric[]): LineChartPoint[] {
    const points = metrics.filter((metric: AppMetric): boolean =>
        Number.isFinite(Number(metric.download_count)) && Number(metric.download_count) >= 0)
        .map((metric: AppMetric): LineChartPoint => ({
            label: metric.created_at, value: Number(metric.download_count), detail: metric.version || '-',
        }));
    return downsampleLinePoints(filterDownloadOutliers(points), DETAIL_CHART_MAX_POINTS)
        .map((point: LineChartPoint): LineChartPoint => ({
            label: formatDateTime(point.label).split(' ')[0], value: point.value,
            detail: `${formatDateTime(point.label)} · 下载量 ${formatDownloadCount(point.value)} · 版本 ${point.detail}`,
        }));
}

export function detailRatingPoints(ratingHistory: AppRatingHistory[]): LineChartPoint[] {
    const timed = ratingHistory.map((rating: AppRatingHistory): TimedRating => ({ rating,
        time: new Date(rating.report_date).getTime(),
        value: Number(rating.cumulative_avg_rating_high_prec ?? rating.cumulative_avg_rating_origin ?? 0),
    })).filter((item: TimedRating): boolean => Number.isFinite(item.time) &&
        Number.isFinite(item.value) && item.value >= 0 && item.value <= 5)
        .sort((left: TimedRating, right: TimedRating): number => left.time - right.time);
    const points = timed.map((item: TimedRating): LineChartPoint => ({ label: item.rating.report_date,
        value: item.value, detail: String(item.rating.cumulative_total_count ?? 0) }));
    return downsampleLinePoints(points, DETAIL_CHART_MAX_POINTS).map((point: LineChartPoint): LineChartPoint => ({
        label: point.label, value: point.value,
        detail: `${point.label} · 平均评分 ${point.value} · 累计 ${point.detail} 条评分`,
    }));
}
