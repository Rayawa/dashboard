export interface CommentInfo {
    platform?: string;
    user?: string;
}

export interface AppIdOrPackageName {
    app_id?: string;
    pkg_name?: string;
}

export interface SubmitAppBody extends AppIdOrPackageName {
    comment?: CommentInfo;
}

export interface TelemetryDeviceInfo {
    device_type: string;
    manufacture: string;
    brand: string;
    market_name: string;
    product_series: string;
    product_model: string;
    product_model_alias: string;
    software_model: string;
    hardware_model: string;
    bootloader_version: string;
    abi_list: string;
    security_patch_tag: string;
    display_version: string;
    incremental_version: string;
    os_release_type: string;
    os_full_name: string;
    sdk_api_version: number;
    first_api_version: number;
    version_id: string;
    build_type: string;
    build_user: string;
    build_host: string;
    build_time: string;
    build_root_hash: string;
    distribution_os_name: string;
    distribution_os_version: string;
    distribution_os_api_version: number;
    distribution_os_api_name: string;
    distribution_os_release_type: string;
    performance_class: string;
    chip_type: string;
}

export interface TelemetryReportBody {
    app_id: string;
    only_id: string;
    app_version: string;
    submit_platform?: string;
    custom_user_agent?: string;
    event_name?: string;
    device_info: TelemetryDeviceInfo;
}

export interface TelemetryIngestResponse {
    accepted: boolean;
    new_user: boolean;
    app_id: string;
    event_name: string;
    reported_at: string;
}

export interface BaseAPIResponse<T = object> {
    success: boolean;
    data: T;
    total?: number;
    limit?: number;
    timestamp: string;
}

export interface AppInfo {
    app_id: string;
    icon_url: string;
    comment?: CommentInfo;
    created_at: string;
    description: string;
    dev_en_name: string;
    developer_name: string;
    download_count: number;
    kind_name: string;
    kind_type_name: string;
    listed_at: string;
    main_device_codes: string[];
    metrics_created_at: string;
    minsdk: number;
    name: string;
    pkg_name: string;
    release_date: number; // 这玩意是 unix timestamp
    size_bytes: number;
    updated_at: string;
    version: string;
    version_code: number;
    supplier: string;
    tag_name: string;
    target_sdk: number;
    compile_sdk_version: number;
    release_countries?: string[];
    recordal_entity_title?: string;
    recordal_entity_name?: string;
    app_recordal_info?: string;

    // rating
    average_rating?: string;
    full_average_rating?: string;
    only_star_count?: number;
    star_1_rating_count?: number;
    star_2_rating_count?: number;
    star_3_rating_count?: number;
    star_4_rating_count?: number;
    star_5_rating_count?: number;
    total_star_rating_count?: number;
    rating_created_at?: string;
}

export interface AppDetailInfo {
    full_info: AppInfo;
    get_data: boolean;
    new_app: boolean;
    new_info: boolean;
    new_metric: boolean;
    new_rating: boolean;
}

export interface SyncDuration {
    secs: number;
    nanos: number;
}

export interface SyncStatusInfo {
    elapsed_time?: SyncDuration;
    estimated_total_time?: SyncDuration;
    is_syncing_all: boolean;
    next_sync_countdown?: number | null;
    progress?: number[];
    total_failed: number;
    total_inserted: number;
    total_processed: number;
    total_skipped: number;
}

export interface MarketCountInfo {
    apps: number;
    atomic_services: number;
    max_download_count: number;
    total: number;
}

export interface MarketInfo {
    app_count: MarketCountInfo;
    crate_version: string;
    developer_count: number;
    page_size_max: number;
    substance_count: number;
    sync_status: SyncStatusInfo;
}

export interface ScreenshotInfo {
    url: string;
    resolution: string;
    rotated: number;
}

export interface MarketApp extends AppInfo {
    alliance_app_id?: string;
    brief_desc?: string;
    privacy_url?: string;
    screen_shots?: string[];
    new_screen_shots?: ScreenshotInfo[];
    new_features?: string;
    upgrade_msg?: string;
    price?: number | string;
    iap?: boolean;
    hms?: boolean;
    is_pay?: boolean;
    min_hmos_api_level?: number;
    api_release_type?: string;
    info_score?: number | string;
    info_rate_count?: number;
}

export interface AppDetailPayload extends AppDetailInfo {
    full_info: MarketApp;
    cached?: boolean;
}

export interface PageInfo<T> {
    data: T[];
    total_count: number;
    page: number;
    page_size: number;
    total_pages: number;
}

export type SearchOperator = 'eq' | 'ne' | 'like' | 'not_like' | 'i_like' | 'not_i_like' |
    'gt' | 'lt' | 'gte' | 'lte' | 'is_null' | 'is_not_null' |
    'array_contains' | 'array_overlaps' | 'array_contained_by';

export interface SearchCondition {
    key: string;
    op: SearchOperator;
    value?: string | null;
}

/** 当前客户端提供一层 AND/OR 组合；每个条件均可使用完整的 API 搜索操作符。 */
export interface SearchExpression {
    and?: SearchCondition[];
    or?: SearchCondition[];
}

export interface AdvancedAppsQuery {
    page: number;
    pageSize: number;
    sort: string;
    desc: boolean;
    force?: boolean;
}

export interface DownloadGrowthQuery {
    days?: number;
    months?: number;
    limit?: number;
    page?: number;
    listedDays?: number;
    listedMonths?: number;
    excludeHuawei?: boolean;
    excludeAtomic?: boolean;
    force?: boolean;
}

export interface DownloadGrowthApp {
    app_id: string;
    name: string;
    pkg_name: string;
    current_period_date: string;
    prior_period_date: string;
    current_download_count: number;
    prior_download_count: number;
    download_increment: number;
}

export interface DailyMaxDownloadApp {
    app_id: string;
    app_name: string;
    pkg_name: string;
    download_count: number;
    report_date: string;
}

export interface DeveloperRankingEntry {
    developerId: string;
    developerName: string;
    appCount: number;
}

/**
 * 折线图可跨不同画布宽度恢复的视口状态。
 * panRatio 使用可平移范围中的相对位置，避免跨设备接续后因屏幕宽度变化而错位。
 */
export interface ChartViewportState {
    zoom: number;
    panRatio: number;
}

export interface RatingDistribution {
    star_1: number;
    star_2: number;
    star_3: number;
    star_4: number;
    star_5: number;
}

export interface AppMetric {
    version: string;
    version_code: number;
    size_bytes: number;
    download_count: number;
    price: number | string;
    release_date: number;
    target_sdk: number;
    minsdk: number;
    compile_sdk_version: number;
    min_hmos_api_level: number;
    api_release_type: string;
    created_at: string;
    info_score?: number | string;
    info_rate_count?: number;
}

export interface AppRatingHistory {
    report_date: string;
    app_id: string;
    pkg_name: string;
    daily_new_count: number;
    daily_new_average: number | string;
    cumulative_total_count: number;
    cumulative_avg_rating_origin?: number | string;
    cumulative_avg_rating_high_prec: number | string;
}

export interface ApiDataResult<T> {
    data: T;
    fromCache: boolean;
    cachedAt: number;
    stale: boolean;
}

export interface AppRouteTarget {
    appId?: string;
    packageName?: string;
    backgroundRefreshHandled?: boolean;
    previewApp?: MarketApp;
}

export class WebViewParam {
    url: string | Resource;
    title: string;

    constructor(url: string | Resource, title: string) {
        this.url = url;
        this.title = title;
    }
}

export interface SearchTarget extends AppRouteTarget {
    rawText?: string;
    autoRun?: boolean;
    openDetailOnSuccess?: boolean;
    recordHistory?: boolean;
}
