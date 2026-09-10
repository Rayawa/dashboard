import { URL } from "./url";
import { deviceInfo } from "@kit.BasicServicesKit";
import { DEVICE_CHIP_TYPE } from './platformCompatibility';

// 持久化与运行时状态键。装饰器要求字面量 key 的位置保留字面量，
// 其余读取和写入一律引用这里的常量。
export const STORAGE_FILE_NAME = 'app_storage';
export const LEGACY_PROFILE_FILE_NAME = 'profile';
export const LEGACY_SETTINGS_FILE_NAME = 'settings';
export const LEGACY_APP_SETTINGS_FILE_NAME = 'myAppSettings';
export const STORAGE_KEY_LEGACY_MIGRATED = 'legacy_migrated';
export const STORAGE_KEY_USERNAME = 'username';
export const STORAGE_KEY_FIRST_LAUNCH = 'isFirstLaunch';
export const STORAGE_KEY_NOTICE_VERSION = 'importantNoticeVersion';
export const STORAGE_KEY_VIBRATION_LEVEL = 'vibrationLevel';
export const STORAGE_KEY_LIGHT_FIELD_LEVEL = 'lightFieldLevel';
export const STORAGE_KEY_HOLD_CHECK = 'holdCheckON';
export const STORAGE_KEY_BUTTON_RIGHT = 'buttonPositionRIGHT';
export const STORAGE_KEY_IMMERSIVE_MATERIAL_LEVEL = 'immersiveMaterialLevel';
export const STORAGE_KEY_SEARCH_HISTORY = 'searchHistory';
export const APP_STATE_KEY_PAGE_URL = 'pageUrl';
export const APP_STATE_KEY_SCROLL_DISTANCE = 'scrollDistance';
export const APP_STATE_KEY_DETAIL_TARGET = 'detailTarget';
export const APP_STATE_KEY_SEARCH_TARGET = 'searchTarget';
export const APP_STATE_KEY_MAIN_TAB = 'mainTabIndex';
export const APP_STATE_KEY_APPS_VIEW = 'appsDetailViewIndex';
export const APP_STATE_KEY_CONTINUATION_ROUTE = 'continuationRoute';
export const APP_STATE_KEY_CONTINUATION_DETAIL_ID = 'continuationDetailAppId';
export const APP_STATE_KEY_CONTINUATION_DETAIL_PACKAGE = 'continuationDetailPackage';
export const APP_STATE_KEY_CONTINUATION_APPS_LIST = 'continuationAppsList';
export const APP_STATE_KEY_CONTINUATION_OVERVIEW = 'continuationOverview';
export const APP_STATE_KEY_CONTINUATION_DETAIL_CHARTS = 'continuationDetailCharts';
export const LOCAL_STORAGE_KEY_WINDOW_WIDTH = 'winWidth';
export const LOCAL_STORAGE_KEY_WINDOW_HEIGHT = 'winHeight';

// 0 = 关闭，1 = 灵动，2 = 硬朗；全新安装默认灵动振动。
export const DEFAULT_VIBRATION_LEVEL = 1;
// 0 = 暗淡，1 = 明亮，2 = 高亮；当前应用光场即“明亮”档。
export const DEFAULT_LIGHT_FIELD_LEVEL = 1;
export const DEFAULT_HOLD_CHECK_ENABLED = false;
export const DEFAULT_BUTTON_RIGHT = false;
// hdsMaterial.MaterialLevel.GENTLE；保持为数字，避免存储层依赖 UI Design Kit。
export const DEFAULT_IMMERSIVE_MATERIAL_LEVEL = 1;
export const DEFAULT_WINDOW_WIDTH = 1260;
export const DEFAULT_WINDOW_HEIGHT = 2224;
export const DEFAULT_SCROLL_DISTANCE = 0;
export const DEFAULT_NETWORK_TIMEOUT_MS = 10000;
export const RESPONSIVE_BREAKPOINT_MEDIUM = '600vp';
export const RESPONSIVE_BREAKPOINT_LARGE = '840vp';
export const CONTENT_MAX_WIDTH = 1440;
export const WEB_PAGE_DEFAULT_TITLE = '网页';
export const WEB_PAGE_DEFAULT_TOP_INSET = 0;
export const WEB_PAGE_FRIEND_LINK_TOP_INSET = 100;
export const WEB_PAGE_PROGRESS_TOP_OFFSET = 96;
export const WEB_PAGE_PROGRESS_HEIGHT = 4;
export const WEB_PAGE_TOAST_DURATION_MS = 1600;
export const SEARCH_SHARED_GEOMETRY_ID = 'apps_search_shared_element';
export const CONTENT_ENTER_DURATION_MS = 280;
export const PAGE_TRANSITION_DURATION_MS = 300;
export const PAGE_EXIT_DURATION_MS = 220;
export const STAGGER_ENTER_DURATION_MS = 500;
export const STAGGER_ENTER_DELAY_MS = 100;
export const STAGGER_ENTER_INTERVAL_MS = 125;
// 卡片列表页的统一布局基准，“我的”和“友情链接”共用。
export const LIST_PAGE_HORIZONTAL_PADDING = 14;
export const LIST_SECTION_SPACING = 14;
export const LIST_SECTION_CONTENT_GAP = 8;
export const LIST_SECTION_TITLE_START_PADDING = 4;
export const LIST_ITEM_PREFIX_MARGIN = 8;
export const LIST_ITEM_SUFFIX_MARGIN = 8;
export const LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN = 16;
export const LIST_SECTION_DIVIDER_VERTICAL_MARGIN = 2;
export const CACHE_DIRECTORY_NAME = 'market_api_v3';
export const CACHE_TTL_HOME_MS = 5 * 60 * 1000;
export const CACHE_TTL_LIST_MS = 2 * 60 * 1000;
export const CACHE_TTL_DETAIL_MS = 30 * 60 * 1000;
export const CACHE_TTL_CHART_MS = 30 * 60 * 1000;
export const CACHE_MAX_STALE_MS = 30 * 24 * 60 * 60 * 1000;
export const BACKGROUND_REFRESH_DELAY_MS = 180;
export const MAIN_TAB_S_STATION = 0;
export const MAIN_TAB_HOME = 1;
export const MAIN_TAB_APPS = 2;
export const MAIN_TAB_MY = 3;
export const MAIN_TAB_DEFAULT = MAIN_TAB_HOME;
export const S_STATION_COMMAND_NONE = 0;
export const S_STATION_COMMAND_SHARE = 1;
export const S_STATION_COMMAND_SCROLL_TOP = 2;
export const S_STATION_COMMAND_HOME = 3;
export const S_STATION_COMMAND_BACK = 4;
export const CONTINUATION_ROUTE_MAIN = 'main';
export const CONTINUATION_ROUTE_DETAIL = 'detail';

// 页面路由名。页面跳转和 Navigation 目标分发必须共用这些值。
export const ROUTE_APP_DETAIL = 'AppDetailPage';
export const ROUTE_WEB_PAGE = 'WebPage';
export const ROUTE_APP_LOG = 'AppLogPage';
export const ROUTE_HTML_PAGE = 'HTMLPage';
export const ROUTE_TUTORIAL = 'TutorialPage';
export const ROUTE_FRIEND_LINKS = 'FriendPage';
export const ROUTE_DEVELOPER = 'DeveloperPage';

// 主要链接
export const mainPage = new URL("https://dashboard.rayawa.top")

export const TBaseURL = new URL("https://hmos.txit.top/");
export const SBaseURL = new URL("https://ddns.shenjack.top:10003/");
export const S_SITE_PUBLIC_BASE_URL = 'https://shenjack.top:10003/';

// 友情链接
export const PROJECT_HOME_URL = new URL("https://dashboard.rayawa.top/");
export const S_DASHBOARD_URL = new URL("dashboard", SBaseURL);
export const EGUI_URL = new URL("https://shenjack.top:10003/egui/");
export const T_DASHBOARD_URL = new URL("dashboard", TBaseURL);
export const GETRACE_URL = new URL("https://appgallery.huawei.com/app/detail?id=cn.biandangroup.getrace");
export const SUBSCRIPTION_URL = new URL("https://appgallery.huawei.com/app/detail?id=com.xxtstudio.accountDL");
export const SUBSCRIPTION_ATOMIC_URL = new URL("https://appgallery.huawei.com/app/detail?id=com.atomicservice.6917600885144283966");
export const PAPER_TALK_URL = new URL("https://appgallery.huawei.com/app/detail?id=com.my.papertalk");
export const HapStoreURL = new URL("https://sydxky.cn/");
export const AGstatisticsURL = new URL("https://appgallery.info/index.html");
export const dztapURL = new URL("https://home.dztap.com/index");
export const OpenStoreURL = new URL("https://next.betahub.tech/");
export const NEXTStoreURL = new URL("https://next.vcck.cn/#/");
export const FANGZHOU_URL = new URL("https://fangzhou.club/");

// dev
export const APP_VERSION: string = "3.0.1";
export const APP_BUILD_NUMBER: number = 30000005;
export const APP_BUNDLE_NAME: string = "top.rayawa.dashboard"
export const SAPIBaseURL = new URL("/api/v0/", SBaseURL);
export const MEOW_CHANNEL_URL = new URL("https://www.chuckfang.com/MeoW/appLinking?channelId=8bbba7f53bf9458284a41d04f295450b");
export const MIIT_ICP_URL = new URL("https://beian.miit.gov.cn/#/Integrated/index");
export const HUAWEI_APP_DETAIL_URL_PREFIX = "https://appgallery.huawei.com/app/detail?id=";
export const S_SITE_APP_DETAIL_QUERY = 'dashboard?app_id=';
export const CONTINUATION_MIN_VERSION: string = '3.0.0';
export const CONTINUATION_MIN_VERSION_CODE: number = 30000000;

// HTTP User-Agent 必须能安全转换为文本。保留可见 ASCII 原文，仅编码设备名称中的中文等字符。
function encodeUserAgentText(value: string): string {
    let encoded = '';
    for (let index = 0; index < value.length; index++) {
        const codeUnit = value.charCodeAt(index);
        let character = value.charAt(index);
        if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF && index + 1 < value.length) {
            const nextCodeUnit = value.charCodeAt(index + 1);
            if (nextCodeUnit >= 0xDC00 && nextCodeUnit <= 0xDFFF) {
                character = value.substring(index, index + 2);
                index++;
            }
        }
        if (codeUnit >= 0x20 && codeUnit <= 0x7E) {
            encoded += character;
        } else {
            encoded += encodeURIComponent(character);
        }
    }
    return encoded;
}

const rawCustomUserAgent: string = `${APP_BUNDLE_NAME}(${APP_VERSION}) | ${deviceInfo.osFullName}(${deviceInfo.incrementalVersion}) API:${deviceInfo.sdkApiVersion} | ${deviceInfo.productModel}/${deviceInfo.productModelAlias}/${deviceInfo.softwareModel}/${deviceInfo.hardwareModel} | ${deviceInfo.deviceType}/${deviceInfo.marketName}/${DEVICE_CHIP_TYPE}`;
export const customUserAgent: string = encodeUserAgentText(rawCustomUserAgent);

// 遥测上报使用的完整设备信息，字段与 2.x 版本保持一致。
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
    public chip_type: string = DEVICE_CHIP_TYPE
}

// 用户标识符
export const ONLY_ID: string = deviceInfo.ODID;

/**
 * 所有原生 API 请求统一从这里取得请求头，避免不同接口遗漏应用 User-Agent。
 */
export function createApiRequestHeaders(hasJsonBody: boolean = false): Record<string, string> {
    if (hasJsonBody) {
        return {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'User-Agent': customUserAgent,
        };
    }
    return {
        'Accept': 'application/json',
        'User-Agent': customUserAgent,
    };
}

export const SUBMIT_PLATFORM: string = `ray_dashboard/${APP_VERSION}-${deviceInfo.deviceType}`;
