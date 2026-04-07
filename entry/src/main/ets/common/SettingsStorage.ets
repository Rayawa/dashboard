import { common } from '@kit.AbilityKit';
import getDiskStorageInstance, { DiskStorageInstance } from './DiskStorage';

let instance: DiskStorageInstance | undefined = undefined;

// 初始化设置存储
export function initializeSettings(ctx?: common.Context) {
    instance = getDiskStorageInstance("settings", ctx);
    if (!instance) {
        throw new Error("Failed to initialize settings storage");
    }
}
// 获取设置存储实例
export function getSettingsInstance(): DiskStorageInstance {
    if (!instance) {
        throw new Error("Settings storage is not initialized");
    }
    return instance;
}
// 获取所有设置
export interface AppSettings {
    vibrationON: boolean;
    holdCheckON: boolean;
    buttonPositionRIGHT: boolean;
    tabBarAutoON: boolean;
    immersiveTextureON: boolean;
}
// 默认设置
const DEFAULT_SETTINGS: AppSettings = {
    vibrationON: true,
    holdCheckON: false,
    buttonPositionRIGHT: false,
    tabBarAutoON: false,
    immersiveTextureON: false
};
// 恢复出厂设置
export async function resetAllSettings(): Promise<void> {
    await updateSettings(DEFAULT_SETTINGS);
}
// 获取当前设置
export async function getAllSettings(): Promise<AppSettings> {
    return {
        vibrationON: await getVibrationEnabled(),
        holdCheckON: await getHoldCheckEnabled(),
        buttonPositionRIGHT: await getButtonPosition(),
        tabBarAutoON: await getTabBarAuto(),
        immersiveTextureON: await getImmersiveTexture(),
    };
}
// 批量更新设置
export async function updateSettings(settings: Partial<AppSettings>): Promise<void> {
    if (settings.vibrationON !== undefined) {
        await setVibrationEnabled(settings.vibrationON);
    }
    if (settings.holdCheckON !== undefined) {
        await setHoldCheckEnabled(settings.holdCheckON);
    }
    if (settings.buttonPositionRIGHT !== undefined) {
        await setButtonPosition(settings.buttonPositionRIGHT);
    }
    if(settings.tabBarAutoON !== undefined) {
        await setTabBarAuto(settings.tabBarAutoON);
    }
    if(settings.immersiveTextureON !== undefined) {
        await setImmersiveTexture(settings.immersiveTextureON);
    }
}


// 震感反馈设置
export async function getVibrationEnabled(): Promise<boolean> {
    const settings = getSettingsInstance();
    // true = 开, false = 关
    return (await settings.get("vibrationON", true)) as boolean;
}
export async function setVibrationEnabled(enabled: boolean): Promise<void> {
    const settings = getSettingsInstance();
    await settings.set("vibrationON", enabled);
}

// 智感握持设置
export async function getHoldCheckEnabled(): Promise<boolean> {
    const settings = getSettingsInstance();
    // true = 开, false = 关
    return (await settings.get("holdCheckON", false)) as boolean;
}
export async function setHoldCheckEnabled(enabled: boolean): Promise<void> {
    const settings = getSettingsInstance();
    await settings.set("holdCheckON", enabled);
}

// 按钮位置设置
export async function getButtonPosition(): Promise<boolean> {
    const settings = getSettingsInstance();
    // false = 左, true = 右
    return (await settings.get("buttonPositionRIGHT", false)) as boolean;
}
export async function setButtonPosition(isRight: boolean): Promise<void> {
    const settings = getSettingsInstance();
    await settings.set("buttonPositionRIGHT", isRight);
}

// 底部栏自动隐藏设置
export async function getTabBarAuto(): Promise<boolean> {
    const settings = getSettingsInstance();
    // false = 不自动, true = 自动
    return (await settings.get("tabBarAutoON", false)) as boolean;
}
export async function setTabBarAuto(enabled: boolean): Promise<void> {
    const settings = getSettingsInstance();
    await settings.set("tabBarAutoON", enabled);
}

// 沉浸式材质设置
export async function getImmersiveTexture(): Promise<boolean> {
    const settings = getSettingsInstance();
    // false = 关, true = 开
    return (await settings.get("immersiveTextureON", false)) as boolean;
}
export async function setImmersiveTexture(enabled: boolean): Promise<void> {
    const settings = getSettingsInstance();
    await settings.set("immersiveTextureON", enabled);
}

