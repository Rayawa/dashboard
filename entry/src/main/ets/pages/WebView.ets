import { webview } from "@kit.ArkWeb";
import { prompt, router } from "@kit.ArkUI";
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import { APP_UA } from "../global_data"; //shenjack的UA
import { Logger } from '../utils/Logger'; //Rayawa的分享
import { common } from "@kit.AbilityKit"; //Rayawa的分享
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { resourceManager } from '@kit.LocalizationKit';

@Entry
@Component
export struct WebView {
  private web_controller: webview.WebviewController = new webview.WebviewController();
  private win: window.Window | null = null; //Rayawa的状态栏颜色
  @State ShareStatus: boolean = false;
  @State rejectStatus: boolean = false;
  @State updateStatus: boolean = false;
  @State url: string = 'https://hmos.txit.top/dashboard';
  @State mode: WebDarkMode = WebDarkMode.Auto;
  @State isLoading: boolean = false;
  @State progress: number = 0;
  @State scrollY: number = 0;
  @State isV2: boolean = true;
  private readonly NAV_HEIGHT: number = 82;

  async aboutToAppear() {
    //shenjack的UA
    const customUA = webview.WebviewController.getDefaultUserAgent() + " Hm_dashboard";
    webview.WebviewController.setAppCustomUserAgent(customUA);
    this.win = await window.getLastWindow(getContext());
    //UA结束

    //Rayawa的状态栏颜色
    const isDark = this.mode === WebDarkMode.On;
    this.win.setWindowSystemBarProperties({
      statusBarColor: '#00000000',
      statusBarContentColor: isDark ? '#FFFFFF' : '#000000'
    });
    //状态栏颜色结束

    //Rayawa的分享
    if (this.isNoListening()) {
      this.shareListening();
    }
    const uiContext: UIContext = this.getUIContext();
    const context: Context = uiContext.getHostContext() as Context;
    context.eventHub.on('onFocus', () => {
      if (this.isNoListening()) {
        this.shareListening();
      }
    });
    context.eventHub.on('onBackGround', () => {
      this.onBackGround();
    });
  }
  aboutToDisappear() {
    this.shareDisablingListening();
    const uiContext: UIContext = this.getUIContext();
    const context: Context = uiContext.getHostContext() as Context;
    context.eventHub.off('onFocus');
    context.eventHub.off('onBackGround');
  }
  public async getCurrentWebUrl(): Promise<string> {
    try {
      return await this.web_controller.getUrl();
    } catch (err) {
      Logger.error('WebView', '获取 WebView URL 失败: ' + (err as BusinessError).message);
      return '';
    }
  }
  private async share() {
    const uiContext: UIContext = this.getUIContext();
    const contextFaker: Context = uiContext.getHostContext() as Context;
    const currentUrl = await this.getCurrentWebUrl();
    const resourceMgr: resourceManager.ResourceManager = contextFaker.resourceManager;
    let fileData: Uint8Array | undefined = undefined;

    try {
      fileData = await resourceMgr.getMediaContent($r('app.media.share').id);
    } catch (error) {
      Logger.error(`getMediaContent error. Code: ${error?.code}, message: ${error?.message}`);
    }

    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: this.url,
      title: '应用看板链接分享',
      description: `${currentUrl}`,
      thumbnail: fileData,
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      Logger.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      Logger.error(`ShareController show error. code: ${error?.code}, message: ${error?.message}`);
    });
  }
  private purityCallback = (sharableTarget: harmonyShare.SharableTarget) => {
  const uiContext: UIContext = this.getUIContext();
  const currentUrl = this.getCurrentWebUrl();
  let shareData: systemShare.SharedData = new systemShare.SharedData({
    utd: utd.UniformDataType.HYPERLINK,
    content: 'https://dashboard.drcn.agconnect.link/ZB3p',
    title: '应用看板链接分享',
    description: `${currentUrl}`,

  });
  sharableTarget.share(shareData);
}
  @Builder
  Dashboard(){
    Stack() {
      Column() {
        Column().width('100%').backgroundColor($r('app.color.navcolor')).height(Math.max(this.NAV_HEIGHT - this.scrollY, 0));
        Web({ src: this.url, controller: this.web_controller })
          .domStorageAccess(true)
          .darkMode(this.mode)
          .forceDarkAccess(true)
          .width('100%')
          .backgroundColor($r('app.color.backcolor'))
          .height('100%')
          .onPageBegin(() => this.isLoading = true)
          .onProgressChange((p) => this.progress = p.newProgress)
          .onPageEnd(() => this.isLoading = false)
          .onScroll((e) => this.scrollY = e.yOffset)
          .onControllerAttached(() => { try { this.web_controller.setCustomUserAgent(APP_UA); } catch {} });//shenjack的UA
        Column().width('100%').backgroundColor($r('app.color.backcolor')).height(200);
      }

      Column() {
        Column() {
          Text('\n').fontSize(14);
          Row() {
            Text(this.isV2 ? "应用看板V2" : "应用看板V1").fontSize(23).fontWeight(FontWeight.Bold).margin({ left: 20 });
            Row() {
              Image($r('app.media.share')).height(28).width(28).margin({ right: 30 }).onClick(() => { this.share(); });
              Image($r('app.media.menu')).height(28).width(28).margin({ right: 30 }).bindMenu(this.Menu);
              Image($r('app.media.user')).height(28).width(28).margin({ right: 25 }).onClick(() => router.pushUrl({ url: 'pages/user' }));
            }
          }
          .width('100%').justifyContent(FlexAlign.SpaceBetween).height(55);
          Rect().width('100%').height(0.5).fill($r('app.color.border')).position({ x: 0, y: 87 });
        }
        .backgroundBlurStyle(BlurStyle.Thin).position({ x: 0, y: 0 }).width('100%');

        if (this.isLoading) {
          Progress({ value: this.progress, total: 100 }).width('100%').height(3).position({ x: 0, y: 87 });
        }
      }
      .position({ x: 0, y: 0 }).width('100%');
    }
  }
  @Builder
  Menu() {
    MenuItemGroup() {
      MenuItem({ startIcon: $r('app.media.app_log'), content: "(dev)API" })
        .onClick(() => { router.pushUrl({ url: 'pages/index' }); prompt.showToast({ message: '原生版本', duration: 500 }); });
      MenuItem({ startIcon: $r('app.media.arrow_back'), content: "返回上级" })
        .onClick(() => { this.web_controller.backward(); prompt.showToast({ message: '返回上级', duration: 500 }); });
      MenuItem({ startIcon: this.isLoading ? $r('app.media.close') : $r('app.media.refresh'), content: this.isLoading ? "停止刷新" : "刷新页面" })
        .onClick(() => {
          if (this.isLoading) {
            this.web_controller.stop();
            this.isLoading = false;
            prompt.showToast({ message: '停止刷新', duration: 500 });
          } else {
            this.web_controller.refresh();
            this.isLoading = true;
            prompt.showToast({ message: '刷新页面', duration: 500 });
          }
        });
      MenuItem({ startIcon: $r('app.media.arrow_up'), content: "回到顶部" })
        .onClick(() => { prompt.showToast({ message: '回到顶部', duration: 500 }); this.scrollToTop(); });
      MenuItem({ startIcon: $r('app.media.switch'), content: this.isV2 ? "切换到V1" : "切换到V2" })
        .onClick(() => { this.switchWebVersion(); });
    }
  }
  private scrollToTop() {
    const duration = 500;
    const frames = 60;
    const interval = duration / frames;
    const startY = this.scrollY;
    let frame = 0;
    const timer = setInterval(() => {
      frame++;
      const progress = frame / frames;
      const easing = 1 - Math.pow(1 - progress, 3);
      const newY = startY * (1 - easing);
      this.web_controller.scrollTo(0, newY);
      if (frame >= frames) {
        clearInterval(timer);
        this.web_controller.scrollTo(0, 0);
      }
    }, interval);
  }
  private switchWebVersion(): void {
    const switchVersion = this.isV2 ? 'V1' : 'V2';
    this.url = this.isV2 ? 'http://shenjack.top:10003/dashboard' : 'https://hmos.txit.top/dashboard';
    this.isV2 = !this.isV2;
    this.web_controller.loadUrl(this.url);
    prompt.showToast({ message: `切换至${switchVersion}`, duration: 500 });
  }
  private onBackGround() {
    this.shareDisablingListening();
  }
  private shareListening() {
    if (this.isNoListening()) {
      harmonyShare.on('knockShare', this.purityCallback);
      this.ShareStatus = true;
    } else {
      try {
        const uiContext: UIContext = this.getUIContext();
        uiContext.getPromptAction().showToast({ message: $r('app.string.knock_close_other') });
      } catch (error) {
        Logger.error(`showToast error. Code: ${error?.code}, message: ${error?.message}`);
      }
    }
  }
  private shareDisablingListening() {
    harmonyShare.off('knockShare', this.purityCallback);
    this.ShareStatus = false;
  }
  private isNoListening() {
    return !this.ShareStatus && !this.rejectStatus && !this.updateStatus;
  }

  build() {
    Column(){
      this.Dashboard()
    }
  }
}