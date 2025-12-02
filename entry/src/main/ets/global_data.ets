import { deviceInfo } from '@kit.BasicServicesKit';

export const APP_VERSION: string = "1.1.0-alpha.2";

/**
 * 生成程序 UA
 * 其实应该用个 lazy 的, 懒了
 * @returns
 */
export const APP_UA: string = (() => {
  return `top.rayawa.dashboard ${APP_VERSION} ${deviceInfo.osFullName} ${deviceInfo.productModel} ${deviceInfo.sdkApiVersion}`
})();

export const SUBMIT_PLATFORM: string = `ray_dashboard ${APP_VERSION}`
