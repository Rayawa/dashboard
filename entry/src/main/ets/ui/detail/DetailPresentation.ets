import type { MarketApp, ScreenshotInfo } from '../../models/types';
import type { DetailField } from '../../models/detailTypes';
import { formatSdkVersion, formatBytes, formatCount, formatDateTime, formatDownloadCount } from '../../utils/format/format';

export function detailFields(app?: MarketApp): DetailField[] {
    if (!app) {
        return [];
    }
    return [
        { label: '应用 ID', value: app.app_id || '-' },
        { label: '包名', value: app.pkg_name || '-' },
        { label: '开发者', value: app.developer_name || '-' },
        { label: '分类', value: `${app.kind_type_name || '-'} · ${app.kind_name || '-'}` },
        { label: '版本', value: `${app.version || '-'} (${app.version_code || 0})` },
        { label: '应用大小', value: formatBytes(app.size_bytes) },
        { label: '最低 SDK', value: formatSdkVersion(app.minsdk) },
        { label: '目标 SDK', value: formatSdkVersion(app.target_sdk) },
        { label: '编译 SDK', value: formatSdkVersion(app.compile_sdk_version) },
        { label: '最低 API 版本', value: String(app.min_hmos_api_level ?? '-') },
        { label: '下载量', value: formatDownloadCount(app.download_count) },
        { label: '评分', value: app.average_rating ? `${app.average_rating} / 5` : '-' },
        { label: '评分数量', value: formatCount(app.total_star_rating_count) },
        { label: '供应商', value: app.supplier || '-' },
        { label: '标签', value: app.tag_name || '-' },
        { label: '支持设备', value: app.main_device_codes?.join('、') || '-' },
        { label: '应用内购买', value: app.iap ? '支持' : '不支持' },
        { label: '付费状态', value: app.is_pay ? '付费应用' : '免费应用' },
        { label: '价格', value: String(app.price ?? '免费') },
        { label: '发行国家/地区', value: app.release_countries?.join('、') || '-' },
        { label: '备案主体', value: app.recordal_entity_name || app.recordal_entity_title || '-' },
        { label: '备案信息', value: app.app_recordal_info || '-' },
        { label: '上架时间', value: formatDateTime(app.listed_at) },
        { label: '数据更新', value: formatDateTime(app.updated_at) },
    ];
}

export function detailScreenshots(app?: MarketApp): ScreenshotInfo[] {
    if (!app) {
        return [];
    }
    if (app.new_screen_shots && app.new_screen_shots.length > 0) {
        return app.new_screen_shots;
    }
    return (app.screen_shots ?? []).map((url: string) => ({
        url,
        resolution: '',
        rotated: 0,
    } as ScreenshotInfo));
}
