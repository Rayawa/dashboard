import { URL } from "./url";
import { deviceInfo } from "@kit.BasicServicesKit";

// 主要链接
export const mainPage =new URL("https://dashboard.rayawa.top")

export const TBaseURL = new URL("https://hmos.txit.top/");
export const SBaseURL = new URL("http://ddns.shenjack.top:10003/");
export const EguiBaseURL = new URL("http://ddns.shenjack.top:10003/egui/");

// 友情链接
export const HapStoreURL = new URL("https://hdc.osbdf.com/");
export const AGstatisticsURL = new URL("https://appgallery.info/index.html");
export const dztapURL = new URL("https://dztap.com/app.html");
export const OpenStoreURL = new URL("https://next.betahub.tech/");
export const NEXTStoreURL = new URL("https://next.vcck.cn/#/");

// dev
export const APP_VERSION: string = "2.0.2";

// 太长了点
const device_model: string = `${deviceInfo.deviceType}|${deviceInfo.productModel}|${deviceInfo.productModelAlias}|${deviceInfo.softwareModel}|${deviceInfo.marketName}|${deviceInfo.hardwareModel}`;

/** UA
 */
export const customUserAgent: string = `${APP_BUNDLE_NAME} ${APP_VERSION} ${deviceInfo.osFullName} ${deviceInfo.incrementalVersion} API:${deviceInfo.sdkApiVersion} ${device_model}`;

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
    public fist_api_version: number = deviceInfo.firstApiVersion
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
