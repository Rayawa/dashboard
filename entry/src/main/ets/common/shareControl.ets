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
  private webController: webview.WebviewController;
  private isListening: boolean = false;

  private constructor(context: common.UIAbilityContext, webController: webview.WebviewController) {
    this.context = context;
    this.webController = webController;
  }

  public static getInstance(context: common.UIAbilityContext, webController: webview.WebviewController): WebShareManager {
    if (!WebShareManager.instance) {
      WebShareManager.instance = new WebShareManager(context, webController);
    }
    WebShareManager.instance.webController = webController;
    return WebShareManager.instance;
  }

  /**
   * 1. 系统分享按钮触发方法 (主动调用)
   */
  public async showSystemShare() {
    try {
      const currentUrl = this.webController.getUrl();

      let iconData: Uint8Array | undefined = undefined;
      try {
        iconData = await this.context.resourceManager.getMediaContent($r("app.media.share_icon").id);
      } catch (e) {
        Logger.error(TAG, "HarmonyShare: Get icon failed");
      }

      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
        content: currentUrl,
        title: "应用看板链接分享",
        description: `${currentUrl}`,
        thumbnail: iconData
      });

      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      await controller.show(this.context, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE,
      });
      Logger.info(TAG, "HarmonyShare: System share panel showed.");
    } catch (err) {
      Logger.error(TAG, `HarmonyShare: System share error: ${(err as BusinessError).message}`);
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

    const win = await window.getLastWindow(this.context);
    const windowId = win.getWindowProperties().id;

    harmonyShare.off('knockShare');
    harmonyShare.off('gesturesShare', { windowId: windowId });

    this.isListening = false;
    Logger.info(TAG, "HarmonyShare: Passive sharing disabled.");
  }

  /**
   * 内部统一执行分享逻辑
   */
  private executePassiveShare(target: harmonyShare.SharableTarget) {
    const shareData = new systemShare.SharedData({
      utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
      content: this.webController.getUrl(),
      title: "应用看板链接分享",
      description: `${this.webController.getUrl()}`,
    });

    target.share(shareData).then(() => {
      Logger.info(TAG, "HarmonyShare: Passive share success.");
    }).catch((err: BusinessError) => {
      Logger.error(TAG, `HarmonyShare: Passive share failed: ${err.message}`);
    });
  }
}