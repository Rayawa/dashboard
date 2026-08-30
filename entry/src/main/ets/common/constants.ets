import { URL } from "./url";
import { deviceInfo } from "@kit.BasicServicesKit";
import type { FormData } from "./types";

// 持久化与运行时状态键。装饰器要求字面量 key 的位置保留字面量，
// 其余读取和写入一律引用这里的常量。
export const STORAGE_FILE_NAME = 'app_storage';
export const LEGACY_PROFILE_FILE_NAME = 'profile';
export const LEGACY_SETTINGS_FILE_NAME = 'settings';
export const LEGACY_APP_SETTINGS_FILE_NAME = 'myAppSettings';
export const STORAGE_KEY_LEGACY_MIGRATED = 'legacy_migrated';
export const STORAGE_KEY_USERNAME = 'username';
export const STORAGE_KEY_FIRST_LAUNCH = 'isFirstLaunch';
export const STORAGE_KEY_VIBRATION = 'vibrationON';
export const STORAGE_KEY_HOLD_CHECK = 'holdCheckON';
export const STORAGE_KEY_BUTTON_RIGHT = 'buttonPositionRIGHT';
export const STORAGE_KEY_TAB_BAR_AUTO = 'tabBarAutoON';
export const STORAGE_KEY_IMMERSIVE = 'immersiveTextureON';
export const APP_STATE_KEY_PAGE_URL = 'pageUrl';
export const APP_STATE_KEY_SCROLL_DISTANCE = 'scrollDistance';
export const APP_STATE_KEY_QUERY_URL = 'queryUrlFromAbility';
export const APP_STATE_KEY_SHARE_REQUEST = 'shareRequest';
export const APP_STATE_KEY_DETAIL_TARGET = 'detailTarget';
export const APP_STATE_KEY_SEARCH_TARGET = 'searchTarget';
export const APP_STATE_KEY_MAIN_TAB = 'mainTabIndex';
export const LOCAL_STORAGE_KEY_WINDOW_WIDTH = 'winWidth';
export const LOCAL_STORAGE_KEY_WINDOW_HEIGHT = 'winHeight';

export const DEFAULT_VIBRATION_ENABLED = true;
export const DEFAULT_HOLD_CHECK_ENABLED = false;
export const DEFAULT_BUTTON_RIGHT = false;
export const DEFAULT_TAB_BAR_AUTO = false;
export const DEFAULT_IMMERSIVE_TEXTURE = false;
export const DEFAULT_WINDOW_WIDTH = 1260;
export const DEFAULT_WINDOW_HEIGHT = 2224;
export const DEFAULT_SCROLL_DISTANCE = 0;
export const DEFAULT_NETWORK_TIMEOUT_MS = 10000;
export const DEFAULT_QUERY_TIMEOUT_MS = 5000;
export const FORM_DEBOUNCE_DELAY_MS = 800;
export const DASHBOARD_MIN_CONTENT_WIDTH = 423;
export const RESPONSIVE_BREAKPOINT_MEDIUM = '600vp';
export const RESPONSIVE_BREAKPOINT_LARGE = '840vp';
export const CONTENT_MAX_WIDTH = 1440;
export const APP_LIST_PAGE_SIZE = 20;
export const CACHE_DIRECTORY_NAME = 'market_api_v3';
export const CACHE_TTL_HOME_MS = 5 * 60 * 1000;
export const CACHE_TTL_LIST_MS = 2 * 60 * 1000;
export const CACHE_TTL_DETAIL_MS = 30 * 60 * 1000;
export const CACHE_TTL_CHART_MS = 30 * 60 * 1000;
export const CACHE_MAX_STALE_MS = 30 * 24 * 60 * 60 * 1000;
export const BACKGROUND_REFRESH_DELAY_MS = 180;

export function createSubmitFormData(): FormData {
    return { appLink: '', packageName: '', appId: '', remark: '' };
}

export function createQueryFormData(): FormData {
    return { appName: '', appLink: '', packageName: '', appId: '' };
}

// 主要链接
export const mainPage = new URL("https://dashboard.rayawa.top")

export const TBaseURL = new URL("https://hmos.txit.top/");
export const SBaseURL = new URL("https://ddns.shenjack.top:10003/");
export const EguiBaseURL = new URL("https://ddns.shenjack.top:10003/egui/");

// 友情链接
export const HapStoreURL = new URL("https://hdc.osbdf.com/");
export const AGstatisticsURL = new URL("https://appgallery.info/index.html");
export const dztapURL = new URL("https://dztap.com/app.html");
export const OpenStoreURL = new URL("https://next.betahub.tech/");
export const NEXTStoreURL = new URL("https://next.vcck.cn/#/");

// dev
export const APP_VERSION: string = "3.0.0";
export const APP_BUILD_NUMBER: number = 30000001;
export const APP_BUNDLE_NAME: string = "top.rayawa.dashboard"
export const SAPIBaseURL = new URL("/api/v0/", SBaseURL);
export const SAPIReportURL = new URL("/telemtry/report", SAPIBaseURL);
export const telemetryReportURL = new URL("", SBaseURL)
export const TELEMETRY_INGEST_URL = new URL("/api/v0/telemetry/report", SBaseURL);
export const MEOW_CHANNEL_URL = new URL("https://www.chuckfang.com/MeoW/appLinking?channelId=8bbba7f53bf9458284a41d04f295450b");
export const MIIT_ICP_URL = new URL("https://beian.miit.gov.cn/#/Integrated/index");
export const HUAWEI_APP_DETAIL_URL_PREFIX = "https://appgallery.huawei.com/app/detail?id=";

// UA
export const customUserAgent: string = `${APP_BUNDLE_NAME}(${APP_VERSION}) | ${deviceInfo.osFullName}(${deviceInfo.incrementalVersion}) API:${deviceInfo.sdkApiVersion} | ${deviceInfo.productModel}/${deviceInfo.productModelAlias}/${deviceInfo.softwareModel}/${deviceInfo.hardwareModel} | ${deviceInfo.deviceType}/${deviceInfo.marketName}/${deviceInfo.chipType}`;

// 额, 邪恶 device_info (确信)
export class FullDeviceInfo {
    public device_type: string = deviceInfo.deviceType
    public manufacture: string = deviceInfo.manufacture
    public brand: string = deviceInfo.brand
    public market_name: string = deviceInfo.marketName
    public product_series: string = deviceInfo.productSeries
    public product_model: string = deviceInfo.productModel
    public product_model_alias: string = deviceInfo.productModelAlias
    public software_model: string = deviceInfo.softwareModel
    public hardware_model: string = deviceInfo.hardwareModel
    public bootloader_version: string = deviceInfo.bootloaderVersion
    public abi_list: string = deviceInfo.abiList
    public security_patch_tag: string = deviceInfo.securityPatchTag
    public display_version: string = deviceInfo.displayVersion
    public incremental_version: string = deviceInfo.incrementalVersion
    public os_release_type: string = deviceInfo.osReleaseType
    public os_full_name: string = deviceInfo.osFullName
    public sdk_api_version: number = deviceInfo.sdkApiVersion
    public first_api_version: number = deviceInfo.firstApiVersion
    public version_id: string = deviceInfo.versionId
    public build_type: string = deviceInfo.buildType
    public build_user: string = deviceInfo.buildUser
    public build_host: string = deviceInfo.buildHost
    public build_time: string = deviceInfo.buildTime
    public build_root_hash: string = deviceInfo.buildRootHash
    public distribution_os_name: string = deviceInfo.distributionOSName
    public distribution_os_version: string = deviceInfo.distributionOSVersion
    public distribution_os_api_version: number = deviceInfo.distributionOSApiVersion
    public distribution_os_api_name: string = deviceInfo.distributionOSApiName
    public distribution_os_release_type: string = deviceInfo.distributionOSReleaseType
    public performance_class: string = deviceInfo.performanceClass.toString()
    public chip_type: string = deviceInfo.chipType
}

// 用户标识符
export const ONLY_ID: string = deviceInfo.ODID;

export const SUBMIT_PLATFORM: string = `ray_dashboard/${APP_VERSION}-${deviceInfo.deviceType}`;
