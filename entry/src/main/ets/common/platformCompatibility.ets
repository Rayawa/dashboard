import { deviceInfo } from '@kit.BasicServicesKit';

/** HarmonyOS 6.1 / API 23 才提供的 HDS 材质与浮动栏能力。 */
export const SUPPORTS_HARMONY_API_23: boolean =
  deviceInfo.sdkApiVersion >= 23 && deviceInfo.distributionOSApiVersion >= 60100;

/** Web.forceDarkAccess 不支持 2in1。 */
export const IS_2IN1_DEVICE: boolean = deviceInfo.deviceType === '2in1';

/** deviceInfo.chipType 从 API 21 起提供。 */
function resolveDeviceChipType(): string {
  if (deviceInfo.distributionOSApiVersion >= 60001) {
    return deviceInfo.chipType;
  }
  return 'unknown';
}

export const DEVICE_CHIP_TYPE: string = resolveDeviceChipType();

// 使用稳定数值隔离 API 23 枚举，避免 API 20 启动时解析 hdsMaterial/TitleSize。
export const HDS_MATERIAL_TYPE_IMMERSIVE: number = 100;
export const HDS_MATERIAL_LEVEL_GENTLE: number = 1;
export const HDS_TITLE_SIZE_SMALL: number = 0;
