import { URL } from "./url";
import { deviceInfo } from "@kit.BasicServicesKit";
import http from "@ohos.net.http";
import { SiteMode } from "./types";

export const SBaseURL = new URL("http://shenjack.top:10003/");

export const SAPIBaseURL = new URL("/api/v0/", SBaseURL);

export const TBaseURL = new URL("https://hmos.txit.top/");

export const RBaseURL = new URL("https://appgallery.info/index.html");

export const OBaseURL = new URL("https://next.betahub.tech");

export const NBaseURL = new URL("https://next.vcck.cn/#/apps");

export const TBaseURLDev = new URL("http://192.168.2.9:50000/");

export const TAPIBaseURL = new URL("/api/", TBaseURL);

export const dashboardURL: string = "dashboard";

export const submitURL: string = "submit";

export const changelog: string = "changelog";

export const APP_VERSION: string = "2.0.0-beta.1";

/** 太长了点
 */
const device_model: string = `${deviceInfo.deviceType}|${deviceInfo.productModel}|${deviceInfo.productModelAlias}|${deviceInfo.softwareModel}|${deviceInfo.hardwareModel}`;

/** UA
 */
export const customUserAgent: string = `top.rayawa.dashboard ${APP_VERSION} ${deviceInfo.osFullName} API:${deviceInfo.sdkApiVersion} ${device_model}`;

export const SUBMIT_PLATFORM: string = `ray_dashboard/${APP_VERSION}-${deviceInfo.deviceType}`;

export async function isTSiteDev(): Promise<boolean> {
    const req = http.createHttp();
    try {
        await req.request(TBaseURLDev.toString(), {
            usingCache: false,
            readTimeout: 5000,
        });
        return true;
    } finally {
        req.destroy();
    }
    return false;
}

export const siteMapping = [SBaseURL, TBaseURL, TBaseURLDev];
