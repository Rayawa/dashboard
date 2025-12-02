import { harmonyShare, systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';
import { WebView } from '../pages/WebView';

const TAG = 'KnockController';

export class KnockController {
  private static controller: KnockController;
  private context: common.UIAbilityContext | undefined = undefined;
  private webViewPage?: WebView;
  private isKnockListening: boolean = false;

  public static getInstance(context: common.UIAbilityContext, webViewPage?: WebView): KnockController {
    if (!KnockController.controller) {
      KnockController.controller = new KnockController(context, webViewPage);
    }
    return KnockController.controller;
  }

  constructor(context: common.UIAbilityContext, webViewPage?: WebView) {
    this.context = context;
    this.webViewPage = webViewPage;
  }

  /**
   * 碰一碰分享回调
   */
  public async immersiveCallback(target: harmonyShare.SharableTarget) {
    try {
      let url = '';

      if (this.webViewPage) {
        url = await this.webViewPage.getCurrentWebUrl();
      }

      if (!url) {
        Logger.error(TAG, 'WebView URL 获取失败，分享中止');
        return;
      }

      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
        content: url,
        title: '来自应用看板',
        description: '使用碰一碰分享的应用看板链接'
      });

      target.share(shareData).then(() => {
        Logger.info(TAG, `分享成功: ${url}`);
      }).catch((error: BusinessError) => {
        Logger.error(TAG, `分享失败: code=${error.code}, message=${error.message}`);
      });
    } catch (err) {
      Logger.error(TAG, `分享异常: ${err}`);
    }
  }

  /**
   * 开启碰一碰监听
   */
  public immersiveListening() {
    if (canIUse('SystemCapability.Collaboration.HarmonyShare') && !this.isKnockListening) {
      harmonyShare.on('knockShare', (target: harmonyShare.SharableTarget) => {
        this.immersiveCallback(target);
      });
      this.isKnockListening = true;
    }
  }

  /**
   * 关闭碰一碰监听
   */
  public immersiveDisableListening() {
    if (canIUse('SystemCapability.Collaboration.HarmonyShare') && this.isKnockListening) {
      harmonyShare.off('knockShare');
      this.isKnockListening = false;
    }
  }

  /**
   * 2in1 设备开启监听
   */
  public immersiveListeningPC() {
    try {
      if (canIUse('SystemCapability.Collaboration.HarmonyShare') && !this.isKnockListening) {
        window.getLastWindow(this.context).then((data) => {
          const mainWindowID: number = data.getWindowProperties().id;
          harmonyShare.on('knockShare', { windowId: mainWindowID }, (target: harmonyShare.SharableTarget) => {
            this.immersiveCallback(target);
          });
        });
        this.isKnockListening = true;
      }
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(TAG, `getWindowProperties err, code=${error.code}, message=${error.message}`);
    }
  }

  /**
   * 2in1 设备关闭监听
   */
  public immersiveDisableListeningPC() {
    try {
      if (canIUse('SystemCapability.Collaboration.HarmonyShare') && this.isKnockListening) {
        window.getLastWindow(this.context).then((data) => {
          const mainWindowID: number = data.getWindowProperties().id;
          harmonyShare.off('knockShare', { windowId: mainWindowID });
        });
        this.isKnockListening = false;
      }
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(TAG, `getWindowProperties err, code=${error.code}, message=${error.message}`);
    }
  }
}