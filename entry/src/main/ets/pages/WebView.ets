import { webview } from "@kit.ArkWeb";
import { prompt, router } from "@kit.ArkUI";
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import { APP_UA } from "../global_data"; //shenjack的UA
import { KnockController } from '../controller/KnockController'; //Rayawa的分享
import { Logger } from '../utils/Logger'; //Rayawa的分享
import { common } from "@kit.AbilityKit"; //Rayawa的分享
import systemShare from '@hms.collaboration.systemShare'; //Rayawa的分享
import { uniformTypeDescriptor } from '@kit.ArkData';



@Entry
@Component
export struct WebView {
  private web_controller: webview.WebviewController = new webview.WebviewController();
  private win: window.Window | null = null; //Rayawa的状态栏颜色
  private knockController: KnockController | undefined = undefined; //Rayawa的分享

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
    // const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    // if (params.url) {
    //   this.url = params.url;
    // }
    const uiAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.knockController = KnockController.getInstance(uiAbilityContext, this);
    this.knockController.immersiveListening();
  }
  aboutToDisappear() {
    this.knockController?.immersiveDisableListening();
  }
  public async getCurrentWebUrl(): Promise<string> {
    try {
      return await this.web_controller.getUrl();
    } catch (err) {
      Logger.error('WebView', '获取 WebView URL 失败: ' + (err as BusinessError).message);
      return '';
    }
  }
  private async sharePage() {
    try {
      const currentUrl = await this.getCurrentWebUrl();
      const appLink = `dashboard://openPage?url=${encodeURIComponent(currentUrl)}`;

      let data: systemShare.SharedData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
        content: currentUrl,
        title: '应用看板链接分享',
        description: `${currentUrl}`,
      });

      let controller: systemShare.ShareController = new systemShare.ShareController(data);
      const context = getContext(this) as common.UIAbilityContext;
      await controller.show(context, {});
      Logger.info('WebView', '分享成功: ' + currentUrl);
    } catch (error) {
        Logger.error('WebView', '分享失败: ' + JSON.stringify(error));
      }
    }
  //分享结束

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
  @Builder
  Menu() {
    MenuItemGroup() {
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
      }

      Column() {
        Column() {
          Text('\n').fontSize(14);
          Row() {
            Text(this.isV2 ? "应用看板V2" : "应用看板V1").fontSize(23).fontWeight(FontWeight.Bold).margin({ left: 20 });
            Row() {
              Image($r('app.media.share')).height(28).width(28).margin({ right: 30 }).onClick(() => { this.sharePage(); });
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