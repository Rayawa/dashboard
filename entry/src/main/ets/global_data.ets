// shenjack
import { deviceInfo } from '@kit.BasicServicesKit';

export const APP_VERSION: string = "1.1.0-beta.2";
export const APP_UA: string = (() => {
  return `top.rayawa.dashboard ${APP_VERSION} ${deviceInfo.osFullName} ${deviceInfo.productModel} ${deviceInfo.sdkApiVersion}`
})();
export function SUBMIT_USERNAME(): string {
  return AppStorage.get('userName') || '';
};
export const SUBMIT_PLATFORM: string = `ray_dashboard ${APP_VERSION}`

