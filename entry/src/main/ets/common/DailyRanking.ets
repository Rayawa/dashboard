import type { DailyMaxDownloadApp } from './types';

/** 每个应用仅保留最近一次最高记录；先去重，再截取首页摘要或分页。 */
export function latestDailyMaxRecords(records: DailyMaxDownloadApp[], limit?: number): DailyMaxDownloadApp[] {
    const sorted = records.slice().sort((a: DailyMaxDownloadApp, b: DailyMaxDownloadApp): number =>
        b.report_date.localeCompare(a.report_date) || b.download_count - a.download_count);
    const appIds: Set<string> = new Set<string>();
    const packages: Set<string> = new Set<string>();
    const result: DailyMaxDownloadApp[] = [];
    for (const app of sorted) {
        const id = app.app_id?.trim() || '';
        const pkg = app.pkg_name?.trim() || '';
        if (!id && !pkg) continue;
        if ((id && appIds.has(id)) || (pkg && packages.has(pkg))) continue;
        if (id) appIds.add(id);
        if (pkg) packages.add(pkg);
        result.push(app);
    }
    return limit === undefined ? result : result.slice(0, Math.max(0, limit));
}
