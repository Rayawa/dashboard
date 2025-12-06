import { webview } from "@kit.ArkWeb";
import { prompt, router } from "@kit.ArkUI";
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import { APP_UA } from "../global_data";
import { Logger } from '../utils/Logger';
import { common } from "@kit.AbilityKit";
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { resourceManager } from '@kit.LocalizationKit';

@Entry
@Component
export struct WebView {
  @State url: string = 'https://hmos.txit.top/dashboard';//entry
  @State mode: WebDarkMode = WebDarkMode.Auto;
  @State isLoading: boolean = false;
  @State progress: number = 0;
  private readonly NAV_HEIGHT: number = 82;
  private web_controller: webview.WebviewController = new webview.WebviewController();
  private win: window.Window | null = null;

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
        this.shareListening();//启用两种监听
      }
    });
    context.eventHub.on('onBackGround', () => {
      this.onBackGround();
    });

  }
  aboutToDisappear() {
    this.shareDisablingListening();//关闭监听
    const uiContext: UIContext = this.getUIContext();
    const context: Context = uiContext.getHostContext() as Context;
    context.eventHub.off('onFocus');
    context.eventHub.off('onBackGround');
    this.shareDisablingListening();
    harmonyShare.on('knockShare', (sharableTarget: harmonyShare.SharableTarget) => {
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    });
  }
  private onBackGround() {
    this.shareDisablingListening();
    harmonyShare.on('knockShare', (sharableTarget: harmonyShare.SharableTarget) => {
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    });
  }

  //回到顶部方法
  @State scrollY: number = 0;
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

  //切换V1V2方法
  @State isT: boolean = true;
  private switchWebVersion(): void {
    const switchVersion = this.isT ? 'S站' : ' T站';
    this.url = this.isT ? 'http://shenjack.top:10003/dashboard' : 'https://hmos.txit.top/dashboard';
    this.isT = !this.isT;
    this.web_controller.loadUrl(this.url);
    prompt.showToast({ message: `切换至${switchVersion}`, duration: 500 });
  }

  //开启关闭监听方法
  private shareListening() {
    if (this.isNoListening()) {
      harmonyShare.on('knockShare', this.purityCallback);
      harmonyShare.on('gesturesShare', this.immersiveCallback);
      this.ShareStatus = true;
    } else {
      try {
        const uiContext: UIContext = this.getUIContext();
        uiContext.getPromptAction().showToast({ message: 'Disable other knock events.' });
      } catch (error) {
        Logger.error(`showToast error. Code: ${error?.code}, message: ${error?.message}`);
      }
    }
  }
  private shareDisablingListening() {
    harmonyShare.off('knockShare', this.purityCallback);
    harmonyShare.off('gesturesShare', this.immersiveCallback);
    this.ShareStatus = false;
  }

  //监听状态控制
  @State ShareStatus: boolean = false;//监听状态控制
  @State rejectStatus: boolean = false;//监听状态控制
  @State updateStatus: boolean = false;//监听状态控制
  private isNoListening() {
    return !this.ShareStatus && !this.rejectStatus && !this.updateStatus;
  }

  //获得页面URL
  @State currentUrl: string = '';//分享URL注册
  public async getCurrentWebUrl(): Promise<string> {
    try {
      return this.web_controller.getUrl();
    } catch (err) {
      Logger.error('WebView', '获取 WebView URL 失败: ' + (err as BusinessError).message);
      return '';
    }
  }

  //按钮分享URL方法
  private async shareUrl() {
    const uiContext: UIContext = this.getUIContext();
    const contextFaker: Context = uiContext.getHostContext() as Context;
    const resourceMgr: resourceManager.ResourceManager = contextFaker.resourceManager;
    this.currentUrl = await this.getCurrentWebUrl();
    let fileData: Uint8Array | undefined = undefined;
    try {
      fileData = await resourceMgr.getMediaContent($r('app.media.app_icon').id);
    } catch (error) {
      Logger.error(`getMediaContent error. Code: ${error?.code}, message: ${error?.message}`);
    }
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: `${this.currentUrl}`,
      title: '应用看板链接分享',
      description: `${this.currentUrl}`,
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
  //碰一碰分享方法
  private purityCallback = async (sharableTarget: harmonyShare.SharableTarget) => {
    this.currentUrl = await this.getCurrentWebUrl();
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: `${this.currentUrl}`,
      title: '应用看板链接分享',
      description: this.currentUrl,
    });
    sharableTarget.share(shareData);
  }
  //隔空抓取方法
  private immersiveCallback = async (sharableTarget: harmonyShare.SharableTarget) => {
    const uiContext: UIContext = this.getUIContext();
    const contextFaker: Context = uiContext.getHostContext() as Context;
    const resourceMgr: resourceManager.ResourceManager = contextFaker.resourceManager;
    this.currentUrl = await this.getCurrentWebUrl();
    let fileData: Uint8Array | undefined = undefined;
    try {
      fileData = await resourceMgr.getMediaContent($r('app.media.app_icon').id);
    } catch (error) {
      Logger.error(`getMediaContent error. Code: ${error?.code}, message: ${error?.message}`);
    }
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: `${this.currentUrl}`,
      title: '应用看板链接分享',
      description: this.currentUrl,
      thumbnail: fileData,
    });
    sharableTarget.share(shareData);
  }

  //菜单栏
  @Builder
  Menu() {
    MenuItemGroup() {
      MenuItem({ startIcon: $r('app.media.api'), content: "(dev)API" })
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
      MenuItem({ startIcon: $r('app.media.switch'), content: this.isT ? "切换到S版本" : "切换到T版本" })
        .onClick(() => { this.switchWebVersion(); });
    }
  }

  build() {
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
            Text(this.isT ? "应用看板 - T站" : "应用看板 - S站").fontSize(23).fontWeight(FontWeight.Bold).margin({ left: 20 });
            Row() {
              Image($r('app.media.share')).height(28).width(28).margin({ right: 30 }).onClick(() => { this.shareUrl(); });
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
}