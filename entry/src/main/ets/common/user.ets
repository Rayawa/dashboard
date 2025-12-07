// UserStorage.ts - 跨Ability数据存储完整实现
import preferences from '@ohos.data.preferences';
import { BusinessError } from '@ohos.base';
import { common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';

class UserStorage {
    // 单例实例
    private static _instance: UserStorage | null = null;
    // 本地存储实例
    private _preference: preferences.Preferences | null = null;
    // 常量定义
    private static readonly PREFERENCES_NAME = 'user_data';
    private static readonly USERNAME_KEY = 'username';
    // 内存缓存，用于快速访问
    private _usernameCache: string | null = null;
    // 存储上下文引用
    private _context: common.Context | undefined = undefined;
    // 初始化锁
    private static _initializing: boolean = false;

    // 单例获取方法
    static getInstance(context?: common.Context): UserStorage {
        if (!UserStorage._instance) {
            if (!context) {
                context = UserStorage.tryGetGlobalContext();
                if (!context) {
                    throw new Error('UserStorage: Context is required for first-time initialization');
                }
            }
            UserStorage._instance = new UserStorage(context);
        } else if (context && !UserStorage._instance._context) {
            // 更新现有实例的context（用于ShareAbility场景）
            UserStorage._instance._context = context;
        }
        return UserStorage._instance;
    }

    private constructor(context: common.Context) {
        this._context = context;
        console.log('UserStorage: Instance created');
    }

    // 尝试从全局获取上下文
    private static tryGetGlobalContext(): common.Context | undefined {
        try {
            // 方法1: UIAbility 标准方式
            if (globalThis.abilityContext) {
                console.log('UserStorage: Got context from abilityContext');
                return globalThis.abilityContext;
            }

            // 方法2: ExtensionAbility 方式
            if (globalThis.extensionContext) {
                console.log('UserStorage: Got context from extensionContext');
                return globalThis.extensionContext;
            }

            // 方法3: AbilityStage方式
            if (globalThis.abilityStage && globalThis.abilityStage.context) {
                console.log('UserStorage: Got context from abilityStage');
                return globalThis.abilityStage.context;
            }

            // 方法4: ApplicationContext方式
            if (globalThis.applicationContext) {
                console.log('UserStorage: Got context from applicationContext');
                return globalThis.applicationContext;
            }

            if (globalThis.getContext) {
                console.log("UserStorage: Got globalThis context");
                return globalThis.getContext()
            }

            console.warn('UserStorage: No global context available');
            return undefined;
        } catch (error) {
            console.error('UserStorage: Error getting global context:', error);
            return undefined;
        }
    }

    // 初始化存储
    private async initialize(): Promise<void> {
        if (this._preference) {
            return;
        }

        if (UserStorage._initializing) {
            // 等待其他初始化完成
            await new Promise<string>((resolve) => {
                setTimeout(() => {
                    resolve('ok')
                }, 100)
            });
            return this.initialize();
        }

        try {
            UserStorage._initializing = true;

            if (!this._context) {
                this._context = UserStorage.tryGetGlobalContext();
                if (!this._context) {
                    throw new Error('UserStorage: Cannot initialize without context');
                }
            }

            console.log('UserStorage: Initializing with context type:', this._context.constructor.name);

            // 使用上下文初始化preferences
            this._preference = await preferences.getPreferences(this._context, UserStorage.PREFERENCES_NAME);
            console.log('UserStorage: Preferences initialized successfully');

            // 预读用户名到缓存
            try {
                const username = await this._preference.get(UserStorage.USERNAME_KEY, '');
                if (username && typeof username === 'string' && username.trim().length > 0) {
                    this._usernameCache = username.trim();
                    console.log('UserStorage: Cached username:', this._usernameCache);
                }
            } catch (readError) {
                console.warn('UserStorage: Failed to pre-read username:', readError);
            }

        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`UserStorage: Failed to initialize: code=${err.code}, message=${err.message}`);
            throw new Error(`Initialization failed: ${err.message}`);
        } finally {
            UserStorage._initializing = false;
        }
    }

    // 确保存储已初始化
    private async ensureInitialized(): Promise<void> {
        if (!this._preference) {
            await this.initialize();
        }
    }

    // 获取用户名
    async getUsername(): Promise<string> {
        try {
            // 首先检查内存缓存
            if (this._usernameCache) {
                console.log("getUsername", this._usernameCache.toString())
                return this._usernameCache;
            }

            // 确保存储已初始化
            await this.ensureInitialized();

            if (this._preference) {
                const username = await this._preference.get(UserStorage.USERNAME_KEY, '');

                if (username && typeof username === 'string' && username.trim().length > 0) {
                    this._usernameCache = username.trim();
                    return this._usernameCache;
                }
            }

            // 如果没有存储的用户名，返回设备名
            const deviceName = this.getDeviceName();
            console.log('UserStorage: No stored username, returning device name:', deviceName);
            return deviceName;

        } catch (error) {
            console.error('UserStorage: Failed to get username:', error);
            // 降级方案：返回设备名
            return this.getDeviceName();
        }
    }

    // 设置用户名
    async setUsername(username: string | undefined): Promise<void> {
        await this.ensureInitialized();

        if (!this._preference) {
            throw new Error('UserStorage: Storage not available');
        }

        let finalUsername: string;
        if (!username || username.trim().length === 0) {
            finalUsername = this.getDeviceName();
        } else {
            finalUsername = username.trim();
        }

        try {
            // 保存到preferences
            await this._preference.put(UserStorage.USERNAME_KEY, finalUsername);
            await this._preference.flush();

            // 更新内存缓存
            this._usernameCache = finalUsername;

            console.log(`UserStorage: Username saved successfully: ${finalUsername}`);
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`UserStorage: Failed to save username: code=${err.code}, message=${err.message}`);
            throw new Error(`Save failed: ${err.message}`);
        }
    }

    // 清除用户名
    async clearUsername(): Promise<void> {
        await this.ensureInitialized();

        if (!this._preference) {
            throw new Error('UserStorage: Storage not available');
        }

        try {
            await this._preference.delete(UserStorage.USERNAME_KEY);
            await this._preference.flush();

            // 清除缓存
            this._usernameCache = null;

            console.log('UserStorage: Username cleared');
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`UserStorage: Failed to clear username: code=${err.code}, message=${err.message}`);
            throw new Error(`Clear failed: ${err.message}`);
        }
    }

    // 检查是否有用户名
    async hasUsername(): Promise<boolean> {
        try {
            const username = await this.getUsername();
            const deviceName = this.getDeviceName();
            return username !== deviceName && username.trim().length > 0;
        } catch (error) {
            console.error('UserStorage: Failed to check username:', error);
            return false;
        }
    }

    // 获取设备名
    private getDeviceName(): string {
        try {
            const productModel = deviceInfo.productModel;
            return productModel && productModel.trim().length > 0 ?
                productModel : 'HarmonyOS用户';
        } catch (error) {
            console.error('UserStorage: Failed to get device name:', error);
            return '我的设备';
        }
    }

    // 销毁资源
    async destroy(): Promise<void> {
        if (this._preference) {
            try {
                // 注意：在某些上下文中可能无法删除preferences
                if (this._context && this._context['removePreferencesFromCache']) {
                    this._context['removePreferencesFromCache'](UserStorage.PREFERENCES_NAME);
                }
            } catch (error) {
                console.warn('UserStorage: Failed to remove preferences from cache:', error);
            }
        }

        this._preference = null;
        this._usernameCache = null;
        this._context = undefined;
        UserStorage._instance = null;

        console.log('UserStorage: Destroyed');
    }

    // 静态方法：清除所有数据（用于测试）
    static async clearAll(context: common.Context): Promise<void> {
        try {
            await preferences.deletePreferences(context, UserStorage.PREFERENCES_NAME);
            console.log('UserStorage: All data cleared');
        } catch (error) {
            console.error('UserStorage: Failed to clear all data:', error);
        }
    }
}

export default UserStorage;