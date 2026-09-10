import type { LineChartPoint } from './InteractiveLineChart';

const DOWNLOAD_OUTLIER_WINDOW: number = 4;
const DOWNLOAD_OUTLIER_THRESHOLD: number = 0.35;
const DOWNLOAD_BASELINE_TOLERANCE: number = 0.12;

function relativeDifference(left: number, right: number): number {
    return Math.abs(left - right) / Math.max(1, Math.abs(right));
}

function median(values: number[]): number {
    const sorted = values.slice().sort((left: number, right: number) => left - right);
    const middle = Math.floor(sorted.length / 2);
    if (sorted.length % 2 === 0) {
        return (sorted[middle - 1] + sorted[middle]) / 2;
    }
    return sorted[middle];
}

/**
 * 下载量本应是累计值。只剔除在一个很短窗口内明显偏离、且前后都回到同一基线的点，
 * 从而过滤数据库中的短时上下跳，同时保留真实且持续的量级增长或数据修正。
 */
export function filterDownloadOutliers(points: LineChartPoint[]): LineChartPoint[] {
    if (points.length < 5) return points;
    return points.filter((point: LineChartPoint, index: number): boolean => {
        const start = Math.max(0, index - DOWNLOAD_OUTLIER_WINDOW);
        const end = Math.min(points.length, index + DOWNLOAD_OUTLIER_WINDOW + 1);
        if (index - start < 2 || end - index - 1 < 2) return true;

        const windowValues: number[] = [];
        for (let cursor = start; cursor < end; cursor++) {
            windowValues.push(points[cursor].value);
        }
        const baseline = median(windowValues);
        if (relativeDifference(point.value, baseline) < DOWNLOAD_OUTLIER_THRESHOLD) return true;

        let matchesBefore = false;
        let matchesAfter = false;
        for (let cursor = start; cursor < index; cursor++) {
            if (relativeDifference(points[cursor].value, baseline) <= DOWNLOAD_BASELINE_TOLERANCE) {
                matchesBefore = true;
                break;
            }
        }
        for (let cursor = index + 1; cursor < end; cursor++) {
            if (relativeDifference(points[cursor].value, baseline) <= DOWNLOAD_BASELINE_TOLERANCE) {
                matchesAfter = true;
                break;
            }
        }
        return !(matchesBefore && matchesAfter);
    });
}

/**
 * Largest-Triangle-Three-Buckets 降采样：固定保留首尾点，并优先保留能体现趋势转折的点。
 */
export function downsampleLinePoints(points: LineChartPoint[], maxPoints: number): LineChartPoint[] {
    if (maxPoints < 3 || points.length <= maxPoints) return points;

    const sampled: LineChartPoint[] = [points[0]];
    const bucketSize = (points.length - 2) / (maxPoints - 2);
    let anchorIndex = 0;

    for (let bucket = 0; bucket < maxPoints - 2; bucket++) {
        const averageStart = Math.min(points.length - 1, Math.floor((bucket + 1) * bucketSize) + 1);
        const averageEnd = Math.min(points.length, Math.floor((bucket + 2) * bucketSize) + 1);
        let averageX = 0;
        let averageY = 0;
        const averageLength = Math.max(1, averageEnd - averageStart);
        for (let index = averageStart; index < averageEnd; index++) {
            averageX += index;
            averageY += points[index].value;
        }
        if (averageEnd <= averageStart) {
            averageX = points.length - 1;
            averageY = points[points.length - 1].value;
        } else {
            averageX /= averageLength;
            averageY /= averageLength;
        }

        const rangeStart = Math.floor(bucket * bucketSize) + 1;
        const rangeEnd = Math.min(points.length - 1, Math.floor((bucket + 1) * bucketSize) + 1);
        const anchorValue = points[anchorIndex].value;
        let selectedIndex = rangeStart;
        let largestArea = -1;
        for (let index = rangeStart; index < rangeEnd; index++) {
            const area = Math.abs(
                (anchorIndex - averageX) * (points[index].value - anchorValue) -
                (anchorIndex - index) * (averageY - anchorValue),
            );
            if (area > largestArea) {
                largestArea = area;
                selectedIndex = index;
            }
        }
        sampled.push(points[selectedIndex]);
        anchorIndex = selectedIndex;
    }

    sampled.push(points[points.length - 1]);
    return sampled;
}
