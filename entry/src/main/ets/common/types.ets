import { SBaseURL, TBaseURL, TBaseURLDev } from "./constants";

export interface CommentInfo {
    platform?: string;
    user?: string;
    note?: string;
}

export interface appIdOrPkgName {
    app_id?: string;
    pkg_name?: string;
}

export interface SubmitAppBody extends appIdOrPkgName {
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
    fist_api_version: number;
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

export function checkAppIdOrPkgName(value: appIdOrPkgName, raise_error: boolean = false): boolean {
    const res = Number(value.app_id != undefined) + Number(value.pkg_name != undefined);
    if (!raise_error) {
        return res == 1;
    }
    if (res == 0) {
        throw new Error("app_id and pkg_name are both undefined");
    }
    if (res > 1) {
        throw new Error("app_id and pkg_name are both defined");
    }
    return true;
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

export interface FormData {
    appName?: string,
    appLink: string;
    packageName: string;
    appId: string;
    remark?: string;
}

export enum SiteMode {
    SSite = 0,
    TSite = 1,
    TDevSite = 2,
}
