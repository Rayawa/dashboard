// 统一存储入口：全 app 唯一的偏好数据通道
// - 磁盘：单一 preferences 文件 app_storage（引擎仍是 DiskStorage）
// - 兼容：首次访问时一次性迁移旧文件（profile / settings / myAppSettings），用户名等旧数据全部保留
// - 内存：持久化 key 的 setter 同步写入 AppStorage，@StorageLink 消费方无需再手动双写
// - 瞬态 key（winWidth、pageUrl、nativeRefreshTick 等）不属于本模块，只活在 AppStorage 里
import { common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import getDiskStorageInstance, { DiskStorageInstance } from './DiskStorage';
import {
    DEFAULT_BUTTON_RIGHT,
    DEFAULT_HOLD_CHECK_ENABLED,
    DEFAULT_IMMERSIVE_TEXTURE,
    DEFAULT_TAB_BAR_AUTO,
    DEFAULT_VIBRATION_ENABLED,
    LEGACY_APP_SETTINGS_FILE_NAME,
    LEGACY_PROFILE_FILE_NAME,
    LEGACY_SETTINGS_FILE_NAME,
    STORAGE_FILE_NAME,
    STORAGE_KEY_BUTTON_RIGHT,
    STORAGE_KEY_FIRST_LAUNCH,
    STORAGE_KEY_HOLD_CHECK,
    STORAGE_KEY_IMMERSIVE,
    STORAGE_KEY_LEGACY_MIGRATED,
    STORAGE_KEY_TAB_BAR_AUTO,
    STORAGE_KEY_USERNAME,
    STORAGE_KEY_VIBRATION,
} from './constants';

// ===== 偏好 key（唯一事实来源，同时是对应的 AppStorage key 名）=====
const STORE_NAME = STORAGE_FILE_NAME;
const KEY_MIGRATED = STORAGE_KEY_LEGACY_MIGRATED;
const KEY_USERNAME = STORAGE_KEY_USERNAME;
const KEY_FIRST_LAUNCH = STORAGE_KEY_FIRST_LAUNCH;
const KEY_VIBRATION = STORAGE_KEY_VIBRATION;
const KEY_HOLD_CHECK = STORAGE_KEY_HOLD_CHECK;
const KEY_BUTTON_RIGHT = STORAGE_KEY_BUTTON_RIGHT;
const KEY_TAB_BAR_AUTO = STORAGE_KEY_TAB_BAR_AUTO;
const KEY_IMMERSIVE = STORAGE_KEY_IMMERSIVE;

export interface AppSettings {
    vibrationON: boolean;
    holdCheckON: boolean;
    buttonPositionRIGHT: boolean;
    tabBarAutoON: boolean;
    immersiveTextureON: boolean;
}

// 所有持久化 key 的默认值；@StorageLink 装饰器的初始值必须与此保持一致
const DEFAULT_SETTINGS: AppSettings = {
    vibrationON: DEFAULT_VIBRATION_ENABLED,
    holdCheckON: DEFAULT_HOLD_CHECK_ENABLED,
    buttonPositionRIGHT: DEFAULT_BUTTON_RIGHT,
    tabBarAutoON: DEFAULT_TAB_BAR_AUTO,
    immersiveTextureON: DEFAULT_IMMERSIVE_TEXTURE
};

// ===== 单例与一次性迁移 =====
let store: DiskStorageInstance | undefined = undefined;
let readyPromise: Promise<void> | undefined = undefined;

function getStore(ctx?: common.Context): DiskStorageInstance {
    if (!store) {
        const instance = getDiskStorageInstance(STORE_NAME, ctx);
        if (!instance) {
            throw new Error('storage: create app_storage instance failed');
        }
        store = instance;
    }
    return store;
}

// 所有公开读写都经过这里：旧数据迁移必然先于首次访问完成
async function ensureReady(ctx?: common.Context): Promise<DiskStorageInstance> {
    if (readyPromise) {
        await readyPromise;
        return getStore(ctx);
    }
    try {
        const migrate = migrateLegacyData(ctx);
        readyPromise = migrate;
        await migrate;
    } catch (error) {
        // 初始化/迁移失败不缓存 readyPromise：后续携带 context 的调用仍可重试
        readyPromise = undefined;
        throw error as Error;
    }
    return getStore(ctx);
}

async function migrateLegacyData(ctx?: common.Context): Promise<void> {
    // 无 context 且实例尚未创建时，DiskStorage 构造在此抛出明确错误（由 ensureReady 处理）
    const target = getStore(ctx);
    if (await target.has(KEY_MIGRATED)) {
        return;
    }
    const copied: string[] = [];
    // 旧 profile 文件：用户名（唯一必须保住的旧数据）
    if (await copyLegacyKey(target, LEGACY_PROFILE_FILE_NAME, KEY_USERNAME, ctx) ||
        await copyLegacyKey(target, LEGACY_PROFILE_FILE_NAME, 'userName', ctx, KEY_USERNAME)) {
        copied.push(KEY_USERNAME);
    }
    // 旧 settings 文件：设置开关（新旧 key 同名）
    const settingKeys: string[] = [KEY_VIBRATION, KEY_HOLD_CHECK, KEY_BUTTON_RIGHT, KEY_TAB_BAR_AUTO, KEY_IMMERSIVE];
    for (const key of settingKeys) {
        if (await copyLegacyKey(target, LEGACY_SETTINGS_FILE_NAME, key, ctx)) {
            copied.push(key);
        }
    }
    // 旧 myAppSettings 文件：首启标志
    if (await copyLegacyKey(target, LEGACY_APP_SETTINGS_FILE_NAME, KEY_FIRST_LAUNCH, ctx)) {
        copied.push(KEY_FIRST_LAUNCH);
    }
    await target.set(KEY_MIGRATED, true);
    console.info('[Dashboard][common/storage][INFO]', `[storage] 旧数据迁移完成: ${copied.length > 0 ? copied.join(', ') : '全新安装，无需迁移'}`);
}

async function copyLegacyKey(target: DiskStorageInstance, legacyFile: string, key: string, ctx?: common.Context, targetKey: string = key): Promise<boolean> {
    try {
        const legacy = getDiskStorageInstance(legacyFile, ctx);
        if (legacy && await legacy.has(key)) {
            const value = await legacy.get(key, '');
            await target.set(targetKey, value);
            return true;
        }
    } catch (error) {
        console.warn('[Dashboard][common/storage][WARN]', `[storage] 跳过旧文件 ${legacyFile} 的 ${key}: ${JSON.stringify(error)}`);
    }
    return false;
}

// ===== 初始化（幂等；也可以完全不调用，首次读写会自动初始化并迁移）=====
export function initializeSettings(ctx?: common.Context): void {
    ensureReady(ctx).catch(() => {
    });
}

// 兼容旧 profile.ets 的初始化入口
export function initialize(ctx?: common.Context): void {
    ensureReady(ctx).catch(() => {
    });
}

// ===== 首启标志（原 myAppSettings 文件 / isFirstLaunch）=====
export async function getFirstLaunch(): Promise<boolean> {
    const s = await ensureReady();
    return (await s.get(KEY_FIRST_LAUNCH, true)) as boolean;
}

export async function setFirstLaunch(first: boolean): Promise<void> {
    const s = await ensureReady();
    await s.set(KEY_FIRST_LAUNCH, first);
}

// ===== 用户名（原 profile 文件 / username）=====
export function getDeviceName(): string {
    try {
        const productModel = deviceInfo.productModel;
        return productModel && productModel.trim().length > 0 ? productModel : "HarmonyOS设备";
    } catch (error) {
        console.error('[Dashboard][common/storage][ERROR]', "Failed to get device name:", error);
        return "我的设备";
    }
}

export async function getUsername(): Promise<string> {
    const s = await ensureReady();
    return (await s.get(KEY_USERNAME, getDeviceName())) as string;
}

export async function setUsername(username?: string): Promise<void> {
    const s = await ensureReady();
    if (username === undefined) {
        await s.remove(KEY_USERNAME);
        AppStorage.setOrCreate(KEY_USERNAME, getDeviceName());
        return;
    }
    await s.set(KEY_USERNAME, username);
    AppStorage.setOrCreate(KEY_USERNAME, username);
}

export async function clearUsername(): Promise<void> {
    await setUsername(undefined);
}

export async function hasUsername(): Promise<boolean> {
    const username = await getUsername();
    return username !== getDeviceName() && username.trim().length > 0;
}

// ===== 设置开关（原 settings 文件）=====
export async function getVibrationEnabled(): Promise<boolean> {
    const s = await ensureReady();
    return (await s.get(KEY_VIBRATION, DEFAULT_SETTINGS.vibrationON)) as boolean;
}

export async function setVibrationEnabled(enabled: boolean): Promise<void> {
    const s = await ensureReady();
    await s.set(KEY_VIBRATION, enabled);
    AppStorage.setOrCreate(KEY_VIBRATION, enabled);
}

export async function getHoldCheckEnabled(): Promise<boolean> {
    const s = await ensureReady();
    return (await s.get(KEY_HOLD_CHECK, DEFAULT_SETTINGS.holdCheckON)) as boolean;
}

export async function setHoldCheckEnabled(enabled: boolean): Promise<void> {
    const s = await ensureReady();
    await s.set(KEY_HOLD_CHECK, enabled);
    AppStorage.setOrCreate(KEY_HOLD_CHECK, enabled);
}

// false = 左, true = 右
export async function getButtonPosition(): Promise<boolean> {
    const s = await ensureReady();
    return (await s.get(KEY_BUTTON_RIGHT, DEFAULT_SETTINGS.buttonPositionRIGHT)) as boolean;
}

export async function setButtonPosition(isRight: boolean): Promise<void> {
    const s = await ensureReady();
    await s.set(KEY_BUTTON_RIGHT, isRight);
    AppStorage.setOrCreate(KEY_BUTTON_RIGHT, isRight);
}

export async function getTabBarAuto(): Promise<boolean> {
    const s = await ensureReady();
    return (await s.get(KEY_TAB_BAR_AUTO, DEFAULT_SETTINGS.tabBarAutoON)) as boolean;
}

export async function setTabBarAuto(enabled: boolean): Promise<void> {
    const s = await ensureReady();
    await s.set(KEY_TAB_BAR_AUTO, enabled);
    AppStorage.setOrCreate(KEY_TAB_BAR_AUTO, enabled);
}

export async function getImmersiveTexture(): Promise<boolean> {
    const s = await ensureReady();
    return (await s.get(KEY_IMMERSIVE, DEFAULT_SETTINGS.immersiveTextureON)) as boolean;
}

export async function setImmersiveTexture(enabled: boolean): Promise<void> {
    const s = await ensureReady();
    await s.set(KEY_IMMERSIVE, enabled);
    AppStorage.setOrCreate(KEY_IMMERSIVE, enabled);
}

export async function getAllSettings(): Promise<AppSettings> {
    return {
        vibrationON: await getVibrationEnabled(),
        holdCheckON: await getHoldCheckEnabled(),
        buttonPositionRIGHT: await getButtonPosition(),
        tabBarAutoON: await getTabBarAuto(),
        immersiveTextureON: await getImmersiveTexture(),
    };
}

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
    if (settings.tabBarAutoON !== undefined) {
        await setTabBarAuto(settings.tabBarAutoON);
    }
    if (settings.immersiveTextureON !== undefined) {
        await setImmersiveTexture(settings.immersiveTextureON);
    }
}

// 恢复出厂设置（只重置开关，不动用户名和首启标志）
export async function resetAllSettings(): Promise<void> {
    await updateSettings(DEFAULT_SETTINGS);
}

// ===== AppStorage 水合（EntryAbility 启动时调用一次，UI 绑定前填入磁盘真值）=====
export async function loadPersistedState(ctx?: common.Context): Promise<void> {
    try {
        await ensureReady(ctx);
        AppStorage.setOrCreate(KEY_VIBRATION, await getVibrationEnabled());
        AppStorage.setOrCreate(KEY_HOLD_CHECK, await getHoldCheckEnabled());
        AppStorage.setOrCreate(KEY_BUTTON_RIGHT, await getButtonPosition());
        AppStorage.setOrCreate(KEY_TAB_BAR_AUTO, await getTabBarAuto());
        AppStorage.setOrCreate(KEY_IMMERSIVE, await getImmersiveTexture());
        AppStorage.setOrCreate(KEY_USERNAME, await getUsername());
    } catch (error) {
        console.error('[Dashboard][common/storage][ERROR]', `[storage] AppStorage 水合失败: ${JSON.stringify(error)}`);
    }
}
