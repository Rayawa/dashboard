// DiskStorage.ts - 跨Ability数据存储完整实现
import preferences from '@ohos.data.preferences';
import { BusinessError } from '@ohos.base';
import { common } from '@kit.AbilityKit';

const instances: Map<String, DiskStorage> = new Map();

class DiskStorage {
    // 本地存储实例
    private _preference: preferences.Preferences | null = null;
    // 常量定义
    private preference_name: string = 'user_data';
    // 内存缓存，用于快速访问
    // 存储上下文引用
    private _context: common.Context | undefined = undefined;
    private _initializing: boolean = false;
    private _cache: Map<string, preferences.ValueType> = new Map();

    constructor(preference_name: string, context?: common.Context) {
        this.preference_name = preference_name;
        const ctx = context || DiskStorage.tryGetGlobalContext();
        if (!ctx) {
            throw new Error('DiskStorage: Context is required for first-time initialization');
        }
        this._context = ctx;
        console.log('DiskStorage: Instance created');
    }

    // 尝试从全局获取上下文
    private static tryGetGlobalContext(): common.Context | undefined {
        try {
            // 方法1: UIAbility 标准方式
            if (globalThis.abilityContext) {
                console.log('DiskStorage: Got context from abilityContext');
                return globalThis.abilityContext;
            }

            // 方法2: ExtensionAbility 方式
            if (globalThis.extensionContext) {
                console.log('DiskStorage: Got context from extensionContext');
                return globalThis.extensionContext;
            }

            // 方法3: AbilityStage方式
            if (globalThis.abilityStage && globalThis.abilityStage.context) {
                console.log('DiskStorage: Got context from abilityStage');
                return globalThis.abilityStage.context;
            }

            // 方法4: ApplicationContext方式
            if (globalThis.applicationContext) {
                console.log('DiskStorage: Got context from applicationContext');
                return globalThis.applicationContext;
            }

            if (globalThis.getContext) {
                console.log("DiskStorage: Got globalThis context");
                return globalThis.getContext()
            }

            console.warn('DiskStorage: No global context available');
            return undefined;
        } catch (error) {
            console.error('DiskStorage: Error getting global context:', error);
            return undefined;
        }
    }

    // 初始化存储
    private async initialize(): Promise<void> {
        if (this._preference) {
            return;
        }

        if (this._initializing) {
            // 等待其他初始化完成
            await new Promise<string>((resolve) => {
                setTimeout(() => {
                    resolve('ok')
                }, 100)
            });
            return this.initialize();
        }

        try {
            this._initializing = true;

            if (!this._context) {
                this._context = DiskStorage.tryGetGlobalContext();
                if (!this._context) {
                    throw new Error('DiskStorage: Cannot initialize without context');
                }
            }

            console.log('DiskStorage: Initializing with context type:', this._context.constructor.name);

            // 使用上下文初始化preferences
            this._preference = await preferences.getPreferences(this._context, this.preference_name);
            console.log('DiskStorage: Preferences initialized successfully');

            // // 预读用户名到缓存
            // try {
            //     const username = await this._preference.get(DiskStorage.USERNAME_KEY, '');
            //     if (username && typeof username === 'string' && username.trim().length > 0) {
            //         this._usernameCache = username.trim();
            //         console.log('DiskStorage: Cached username:', this._usernameCache);
            //     }
            // } catch (readError) {
            //     console.warn('DiskStorage: Failed to pre-read username:', readError);
            // }

        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`DiskStorage: Failed to initialize: code=${err.code}, message=${err.message}`);
            throw new Error(`Initialization failed: ${err.message}`);
        } finally {
            this._initializing = false;
        }
    }

    // 确保存储已初始化
    private async ensureInitialized(): Promise<void> {
        if (!this._preference) {
            await this.initialize();
        }
    }

    async get(key: string, defaultValue: preferences.ValueType): Promise<preferences.ValueType> {
        if (this._cache.has(key)) {
            return this._cache.get(key)!;
        }
        await this.ensureInitialized();
        if (!this._preference) {
            throw new Error('DiskStorage: Storage not available');
        }
        try {
            return await this._preference.get(key, defaultValue);
        } catch (e) {
            throw new Error('DiskStorage: Failed to get value');
        }
    }

    async set(key: string, value: preferences.ValueType): Promise<void> {
        this._cache.set(key, value);
        await this.ensureInitialized();
        if (!this._preference) {
            throw new Error('DiskStorage: Storage not available');
        }
        try {
            await this._preference.put(key, value);
            await this._preference.flush();
        } catch (e) {
            throw new Error('DiskStorage: Failed to set value');
        }
    }

    async remove(key: string): Promise<void> {
        if (this._cache.has(key)) {
            this._cache.delete(key);
        }
        await this.ensureInitialized();
        if (!this._preference) {
            throw new Error('DiskStorage: Storage not available');
        }
        try {
            await this._preference.delete(key);
            await this._preference.flush();
        } catch (e) {
            throw new Error('DiskStorage: Failed to remove value');
        }
    }

    async hasByPreference(key: string): Promise<boolean> {
        await this.ensureInitialized();
        if (!this._preference) {
            throw new Error('DiskStorage: Storage not available');
        }
        try {
            return await this._preference.has(key);
        } catch (e) {
            throw new Error('DiskStorage: Failed to check if key exists');
        }
    }

    async has(key: string): Promise<boolean> {
        if (this._cache.has(key)) {
            return true;
        }
        return await this.hasByPreference(key);
    }

    // 销毁资源
    async destroy(): Promise<void> {
        if (this._preference) {
            try {
                // 注意：在某些上下文中可能无法删除preferences
                if (this._context && this._context['removePreferencesFromCache']) {
                    this._context['removePreferencesFromCache'](this.preference_name);
                }
            } catch (error) {
                console.warn('DiskStorage: Failed to remove preferences from cache:', error);
            }
        }

        this._preference = null;
        // this._usernameCache = null;
        this._context = undefined;
        instances.delete(this.preference_name);

        console.log('DiskStorage: Destroyed');
    }
}

// export default DiskStorage;
export default function getDiskStorageInstance(
    instance_name: string,
    context?: common.Context
) {
    if (instances.has(instance_name)) {
        return instances.get(instance_name)
    }
    const instance = new DiskStorage(instance_name, context)
    instances.set(instance_name, instance)
    return instance;
}

export async function clearAll(instance_name: string, context: common.Context): Promise<void> {
    try {
        await preferences.deletePreferences(context, instance_name);
        console.log('DiskStorage: All data cleared');
    } catch (error) {
        console.error('DiskStorage: Failed to clear all data:', error);
    }
}