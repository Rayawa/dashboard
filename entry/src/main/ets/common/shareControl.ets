import { harmonyShare, systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';
import { window } from '@kit.ArkUI';

const TAG = 'WebShareManager';
const SHARE_THUMBNAIL_MAX_BYTES = 32 * 1024;

export interface WebShareData {
  url: string;
  title: string;
  description: string;
}

export class WebShareManager {
  private static instance: WebShareManager;
  private static nextOwnerId: number = 0;
  private context: common.UIAbilityContext;
  private isListening: boolean = false;
  private enablePromise?: Promise<void>;
  private passiveShareWindowId?: number;
  private activeOwnerId: number = 0;
  private desiredListening: boolean = false;

  private currentUrl: string = "";
  private currentTitle: string = 'Dashboard应用看板链接分享';
  private currentDescription: string = '';
  private currentThumbnail?: Uint8Array;
  private thumbnailPromise?: Promise<void>;
  private currentDataProvider?: () => WebShareData;

  private constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  public static createOwnerId(): number {
    WebShareManager.nextOwnerId++;
    return WebShareManager.nextOwnerId;
  }

  public updateShareData(url: string, title: string = 'Dashboard应用看板链接分享', description: string = '',
    dataProvider?: () => WebShareData, ownerId: number = 0): void {
    this.activeOwnerId = ownerId;
    this.currentUrl = url;
    this.currentTitle = title;
    this.currentDescription = description || url;
    this.currentDataProvider = dataProvider;
    this.loadDefaultThumbnail();
    Logger.info(TAG, `URL 缓存已更新: ${url}`);
  }

  public clearShareDataProvider(ownerId: number = 0): void {
    if (ownerId !== 0 && ownerId !== this.activeOwnerId) return;
    this.currentDataProvider = undefined;
  }

  private refreshShareData(): void {
    if (!this.currentDataProvider) return;
    try {
      const data = this.currentDataProvider();
      if (!data.url || data.url === 'about:blank') return;
      this.currentUrl = data.url;
      this.currentTitle = data.title || 'Dashboard应用看板链接分享';
      this.currentDescription = data.description || data.url;
    } catch (error) {
      Logger.warn(TAG, `实时分享数据读取失败: ${(error as BusinessError).message}`);
    }
  }

  private async loadDefaultThumbnail(): Promise<void> {
    if (this.currentThumbnail) return;
    if (this.thumbnailPromise) {
      await this.thumbnailPromise;
      return;
    }
    this.thumbnailPromise = this.readDefaultThumbnail();
    try {
      await this.thumbnailPromise;
    } finally {
      this.thumbnailPromise = undefined;
    }
  }

  private async readDefaultThumbnail(): Promise<void> {
    try {
      const thumbnail = await this.context.resourceManager.getMediaContent($r('app.media.share_icon').id);
      if (thumbnail.length >= SHARE_THUMBNAIL_MAX_BYTES) {
        Logger.warn(TAG, `分享卡片图标超过32KB限制: ${thumbnail.length} bytes`);
        return;
      }
      this.currentThumbnail = thumbnail;
    } catch (error) {
      Logger.warn(TAG, `分享卡片图标读取失败: ${(error as BusinessError).message}`);
    }
  }

  public static getInstance(context: common.UIAbilityContext): WebShareManager {
    if (!WebShareManager.instance) {
      WebShareManager.instance = new WebShareManager(context);
    } else {
      // 窗口或 Ability 重建后刷新上下文，避免单例继续持有已经失效的旧上下文。
      WebShareManager.instance.context = context;
    }
    return WebShareManager.instance;
  }

  /**
   * 1. 系统分享按钮触发方法 (使用注入的数据)
   */
  public async showSystemShare(url?: string): Promise<void> {
    try {
      this.refreshShareData();
      const finalUrl = url || this.currentUrl;

      if (!finalUrl || finalUrl === "about:blank") {
        Logger.error(TAG, "Share failed: URL is empty");
        return;
      }

      await this.loadDefaultThumbnail();

      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
        content: finalUrl,
        title: this.currentTitle,
        description: this.currentDescription || finalUrl,
        thumbnail: this.currentThumbnail
      });

      const controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      await controller.show(this.context, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.SINGLE,
      });
    } catch (err) {
      Logger.error(TAG, `System share error: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 2. 开启被动分享监听 (碰一碰 + 隔空传送)
   */
  public async enablePassiveShare(ownerId: number = 0): Promise<void> {
    if (ownerId !== 0 && ownerId !== this.activeOwnerId) return;
    this.desiredListening = true;
    if (!canIUse('SystemCapability.Collaboration.HarmonyShare') || this.isListening) return;

    if (this.enablePromise) {
      await this.enablePromise;
      return;
    }

    this.enablePromise = this.registerPassiveShare();
    try {
      await this.enablePromise;
    } finally {
      this.enablePromise = undefined;
    }
  }

  private async registerPassiveShare(): Promise<void> {
    let knockRegistered = false;
    let gesturesRegistered = false;
    let windowId: number | undefined = undefined;
    try {
      const win = await window.getLastWindow(this.context);
      windowId = win.getWindowProperties().id;
      if (!this.desiredListening) return;

      harmonyShare.on('knockShare', (target: harmonyShare.SharableTarget) => {
        this.executePassiveShare(target);
      });
      knockRegistered = true;
      harmonyShare.on('gesturesShare', { windowId: windowId }, (target: harmonyShare.SharableTarget) => {
        this.executePassiveShare(target);
      });
      gesturesRegistered = true;

      this.isListening = true;
      this.passiveShareWindowId = windowId;
      Logger.info(TAG, "HarmonyShare: Knock and Gesture sharing enabled.");
    } catch (err) {
      if (gesturesRegistered && windowId !== undefined) {
        try {
          harmonyShare.off('gesturesShare', { windowId });
        } catch (cleanupError) {
          Logger.warn(TAG,
            `HarmonyShare: Gesture listener rollback failed: ${(cleanupError as BusinessError).message}`);
        }
      }
      if (knockRegistered) {
        try {
          harmonyShare.off('knockShare');
        } catch (cleanupError) {
          Logger.warn(TAG,
            `HarmonyShare: Knock listener rollback failed: ${(cleanupError as BusinessError).message}`);
        }
      }
      this.isListening = false;
      this.passiveShareWindowId = undefined;
      Logger.error(TAG, `HarmonyShare: Enable sharing failed: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 3. 关闭所有监听
   */
  public async disablePassiveShare(ownerId: number = 0): Promise<void> {
    if (ownerId !== 0 && ownerId !== this.activeOwnerId) return;
    this.desiredListening = false;
    if (this.enablePromise) {
      await this.enablePromise;
    }
    // Another page became the active owner while registration was pending.
    if (ownerId !== 0 && ownerId !== this.activeOwnerId) return;
    if (this.desiredListening) return;
    if (!this.isListening) return;
    if (!canIUse('SystemCapability.Collaboration.HarmonyShare')) {
      this.isListening = false;
      Logger.warn(TAG, 'HarmonyShare: Capability unavailable; local listener state reset.');
      return;
    }

    try {
      const windowId = this.passiveShareWindowId;
      try {
        harmonyShare.off('knockShare');
      } catch (err) {
        Logger.error(TAG, `HarmonyShare: Knock listener cleanup failed: ${(err as BusinessError).message}`);
      }
      try {
        if (windowId !== undefined) {
          harmonyShare.off('gesturesShare', { windowId });
        }
      } catch (err) {
        Logger.error(TAG, `HarmonyShare: Gesture listener cleanup failed: ${(err as BusinessError).message}`);
      }
    } catch (err) {
      // 窗口已经销毁时无法取得 windowId；状态仍需复位，避免后续页面无法重新订阅。
      Logger.error(TAG, `HarmonyShare: Window unavailable while disabling listeners: ${(err as BusinessError).message}`);
    } finally {
      this.isListening = false;
      this.passiveShareWindowId = undefined;
      Logger.info(TAG, "HarmonyShare: Passive sharing state reset.");
    }
  }

  /**
   * 内部统一执行被动分享逻辑 (碰一碰、隔空传送)
   */
  private async executePassiveShare(target: harmonyShare.SharableTarget): Promise<void> {
    this.refreshShareData();
    if (!this.currentUrl || this.currentUrl === "about:blank") {
      Logger.error(TAG, "Passive share failed: No URL cached");
      return;
    }

    try {
      await this.loadDefaultThumbnail();
      const shareData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
        content: this.currentUrl,
        title: this.currentTitle,
        description: this.currentDescription || this.currentUrl,
        thumbnail: this.currentThumbnail,
      });

      target.share(shareData).then(() => {
        Logger.info(TAG, "HarmonyShare: Passive share success.");
      }).catch((err: BusinessError) => {
        Logger.error(TAG, `HarmonyShare: Passive share failed: ${err.message}`);
      });
    } catch (err) {
      Logger.error(TAG, `HarmonyShare: Passive share could not start: ${(err as BusinessError).message}`);
    }
  }
}
