import { common } from "@kit.AbilityKit";
import getDiskStorageInstance, { DiskStorageInstance } from "./DiskStorage";

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

// 默认站点设置
export async function getDefaultSite(): Promise<boolean> {
    const settings = getSettingsInstance();
    // false = S站, true = T站
    return (await settings.get("defaultSiteT", true)) as boolean;
}

export async function setDefaultSite(isT: boolean): Promise<void> {
    const settings = getSettingsInstance();
    await settings.set("defaultSiteT", isT);
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
    return (await settings.get("holdCheckON", true)) as boolean;
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
    return (await settings.get("tabBarAuto", false)) as boolean;
}

export async function setTabBarAuto(enabled: boolean): Promise<void> {
    const settings = getSettingsInstance();
    await settings.set("tabBarAuto", enabled);
}

// 主题设置（如果需要存储主题）
export async function getThemeColor(): Promise<string> {
    const settings = getSettingsInstance();
    return (await settings.get("themeColor", "blue")) as string;
}

export async function setThemeColor(color: string): Promise<void> {
    const settings = getSettingsInstance();
    await settings.set("themeColor", color);
}

export async function setTDev(val: boolean): Promise<void> {
    const settings = getSettingsInstance();
    await settings.set("TSideDev", val);
}

export async function getTDev(): Promise<boolean> {
    try {
        return (await getSettingsInstance().get("TSideDev", false)) as boolean;
    } catch (e) {
        return false;
    }
}

// 清除所有设置（恢复默认）
export async function resetAllSettings(): Promise<void> {
    const settings = getSettingsInstance();
    await settings.set("defaultSiteT", false);
    await settings.set("vibrationON", true);
    await settings.set("holdCheckON", true);
    await settings.set("buttonPositionRIGHT", false);
    await settings.set("themeColor", "blue");
    await setTDev(false);
}

// 获取所有设置
export interface AppSettings {
    defaultSiteT: boolean;
    vibrationON: boolean;
    holdCheckON: boolean;
    buttonPositionRIGHT: boolean;
    themeColor: string;
}

export async function getAllSettings(): Promise<AppSettings> {
    return {
        defaultSiteT: await getDefaultSite(),
        vibrationON: await getVibrationEnabled(),
        holdCheckON: await getHoldCheckEnabled(),
        buttonPositionRIGHT: await getButtonPosition(),
        themeColor: await getThemeColor(),
    };
}

// 批量更新设置
export async function updateSettings(settings: Partial<AppSettings>): Promise<void> {
    if (settings.defaultSiteT !== undefined) {
        await setDefaultSite(settings.defaultSiteT);
    }
    if (settings.vibrationON !== undefined) {
        await setVibrationEnabled(settings.vibrationON);
    }
    if (settings.holdCheckON !== undefined) {
        await setHoldCheckEnabled(settings.holdCheckON);
    }
    if (settings.buttonPositionRIGHT !== undefined) {
        await setButtonPosition(settings.buttonPositionRIGHT);
    }
    if (settings.themeColor !== undefined) {
        await setThemeColor(settings.themeColor);
    }
}
