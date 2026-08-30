import { harmonyShare, systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';
import { window } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';

const TAG = 'WebShareManager';

export class WebShareManager {
  private static instance: WebShareManager;
  private context: common.UIAbilityContext;
  private isListening: boolean = false;

  private currentUrl: string = "";
  private currentTitle: string = '应用看板链接分享';
  private currentDescription: string = '';
  private currentThumbnail?: Uint8Array;

  private constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  public updateShareData(url: string, title: string = '应用看板链接分享', description: string = '') {
    this.currentUrl = url;
    this.currentTitle = title;
    this.currentDescription = description || url;
    this.loadDefaultThumbnail();
    Logger.info(TAG, `URL 缓存已更新: ${url}`);
  }

  private async loadDefaultThumbnail(): Promise<void> {
    if (this.currentThumbnail) return;
    try {
      this.currentThumbnail = await this.context.resourceManager.getMediaContent($r('app.media.share_icon').id);
    } catch (error) {
      Logger.warn(TAG, `分享卡片图标读取失败: ${(error as BusinessError).message}`);
    }
  }

  public static getInstance(context: common.UIAbilityContext): WebShareManager {
    if (!WebShareManager.instance) {
      WebShareManager.instance = new WebShareManager(context);
    }
    return WebShareManager.instance;
  }

  /**
   * 1. 系统分享按钮触发方法 (使用注入的数据)
   */
  public async showSystemShare(url?: string) {
    try {
      const finalUrl = url || this.currentUrl;

      if (!finalUrl || finalUrl === "about:blank") {
        Logger.error(TAG, "Share failed: URL is empty");
        return;
      }

      await this.loadDefaultThumbnail();

      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
        content: finalUrl,
        title: this.currentTitle,
        description: this.currentDescription || finalUrl,
        thumbnail: this.currentThumbnail
      });

      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      await controller.show(this.context, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE,
      });
    } catch (err) {
      Logger.error(TAG, `System share error: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 2. 开启被动分享监听 (碰一碰 + 隔空传送)
   */
  public async enablePassiveShare() {
    if (!canIUse('SystemCapability.Collaboration.HarmonyShare') || this.isListening) return;

    try {
      const win = await window.getLastWindow(this.context);
      const windowId = win.getWindowProperties().id;

      harmonyShare.on('knockShare', (target: harmonyShare.SharableTarget) => {
        this.executePassiveShare(target);
      });
      harmonyShare.on('gesturesShare', { windowId: windowId }, (target: harmonyShare.SharableTarget) => {
        this.executePassiveShare(target);
      });

      this.isListening = true;
      Logger.info(TAG, "HarmonyShare: Knock and Gesture sharing enabled.");
    } catch (err) {
      Logger.error(TAG, `HarmonyShare: Enable sharing failed: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 3. 关闭所有监听
   */
  public async disablePassiveShare() {
    if (!this.isListening) return;
    if (!canIUse('SystemCapability.Collaboration.HarmonyShare')) {
      this.isListening = false;
      Logger.warn(TAG, 'HarmonyShare: Capability unavailable; local listener state reset.');
      return;
    }

    try {
      const win = await window.getLastWindow(this.context);
      const windowId = win.getWindowProperties().id;
      try {
        harmonyShare.off('knockShare');
      } catch (err) {
        Logger.error(TAG, `HarmonyShare: Knock listener cleanup failed: ${(err as BusinessError).message}`);
      }
      try {
        harmonyShare.off('gesturesShare', { windowId });
      } catch (err) {
        Logger.error(TAG, `HarmonyShare: Gesture listener cleanup failed: ${(err as BusinessError).message}`);
      }
    } catch (err) {
      // 窗口已经销毁时无法取得 windowId；状态仍需复位，避免后续页面无法重新订阅。
      Logger.error(TAG, `HarmonyShare: Window unavailable while disabling listeners: ${(err as BusinessError).message}`);
    } finally {
      this.isListening = false;
      Logger.info(TAG, "HarmonyShare: Passive sharing state reset.");
    }
  }

  /**
   * 内部统一执行被动分享逻辑 (碰一碰、隔空传送)
   */
  private executePassiveShare(target: harmonyShare.SharableTarget) {
    if (!this.currentUrl || this.currentUrl === "about:blank") {
      Logger.error(TAG, "Passive share failed: No URL cached");
      return;
    }

    try {
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
