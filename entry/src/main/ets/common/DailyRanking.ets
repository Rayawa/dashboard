import type { DailyMaxDownloadApp } from './types';

/** The API returns daily records, so one app may appear on several dates. */
export function uniqueDailyMaxApps(records: DailyMaxDownloadApp[], limit: number = 10): DailyMaxDownloadApp[] {
    const sorted = records.slice().sort((left: DailyMaxDownloadApp, right: DailyMaxDownloadApp): number => {
        const byDate = new Date(right.report_date).getTime() - new Date(left.report_date).getTime();
        return byDate || right.download_count - left.download_count;
    });
    const seen: Set<string> = new Set<string>();
    const unique: DailyMaxDownloadApp[] = [];
    for (const app of sorted) {
        const key = app.pkg_name?.trim() || app.app_id?.trim();
        if (!key || seen.has(key)) continue;
        seen.add(key);
        unique.push(app);
        if (unique.length >= limit) break;
    }
    return unique;
}
