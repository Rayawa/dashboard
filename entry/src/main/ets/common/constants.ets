import { URL } from "./url";
import { deviceInfo } from "@kit.BasicServicesKit";

//主
export const SBaseURL = new URL("http://shenjack.top:10003/");
export const EguiBaseURL = new URL("http://shenjack.top:10003/egui/");
export const TBaseURL = new URL("https://hmos.txit.top/");

//友情链接
export const HapStoreURL = new URL("https://hdc.osbdf.com/");
export const AGstatisticsURL = new URL("https://appgallery.info/index.html");
export const dztapURL = new URL("https://dztap.com/app.html");
export const OpenStoreURL = new URL("https://next.betahub.tech/");
export const NEXTStoreURL = new URL("https://next.vcck.cn/#/");

//dev
export const SAPIBaseURL = new URL("/api/v0/", SBaseURL);
export const TBaseURLDev = new URL("http://192.168.2.9:50000/");
export const TAPIBaseURL = new URL("/api/", TBaseURL);

export const dashboardURL: string = "dashboard";

export const submitURL: string = "submit";

export const changelog: string = "changelog";

export const APP_VERSION: string = "2.0.0-rc.1";

/** 太长了点
 */
const device_model: string = `${deviceInfo.deviceType}|${deviceInfo.productModel}|${deviceInfo.productModelAlias}|${deviceInfo.softwareModel}|${deviceInfo.hardwareModel}`;

/** UA
 */
export const customUserAgent: string = `top.rayawa.dashboard ${APP_VERSION} ${deviceInfo.osFullName} API:${deviceInfo.sdkApiVersion} ${device_model}`;

export const SUBMIT_PLATFORM: string = `ray_dashboard/${APP_VERSION}-${deviceInfo.deviceType}`;