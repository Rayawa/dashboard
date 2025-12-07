import { webview } from "@kit.ArkWeb";
import { prompt, router } from "@kit.ArkUI";
import window from '@ohos.window';
import { BusinessError } from '@kit.BasicServicesKit';
import { APP_UA } from "../../global_data";

@Entry
@Component
struct api {
  private win: window.Window | null = null;
  async aboutToAppear() {
    const customUA = webview.WebviewController.getDefaultUserAgent()
      + " Hm_dashboard";
    webview.WebviewController.setAppCustomUserAgent(customUA);
    this.win = await window.getLastWindow(getContext());
    const isDark = this.mode === WebDarkMode.On;
    this.win.setWindowSystemBarProperties({
      statusBarColor: '#00000000',
      statusBarContentColor: isDark ? '#FFFFFF' : '#000000'
    });
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

  private web_controller: webview.WebviewController = new webview.WebviewController();
  @State url: string = 'https://hmos.txit.top/changelog';
  @State mode: WebDarkMode = WebDarkMode.Auto;
  @State isLoading: boolean = false;
  @State progress: number = 0;
  @State scrollY: number = 0;
  @State isV2: boolean = true;
  private readonly NAV_HEIGHT: number = 45;

  build() {
    Stack() {
      Column() {
        Column()
          .width('100%')
          .backgroundColor($r('app.color.navcolor'))
          .height(Math.max(this.NAV_HEIGHT - this.scrollY, 0))

        Web({
          src: this.url,
          controller: this.web_controller
        })
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
          .onControllerAttached(() => {
            // for API 17, API 20 可以直接 setAppCustomUserAgent()
            try {
              this.web_controller.setCustomUserAgent(APP_UA);
            } catch (error) {
              console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
            }
          })
      }

      Column() {
        Column() {
          Text('\n').fontSize(14);
          Row() {
            Text("Web更新日志").fontSize(23).fontWeight(FontWeight.Bold).margin({ left: 20 });
            Row() {
              Image(this.isLoading ? $r('app.media.stop') : $r('app.media.refresh')).height(28).width(28).margin({ right: 30 })
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
                })
              Image($r('app.media.arrow_up')).height(28).width(28).margin({ right: 30 }).onClick(() => { prompt.showToast({ message: '回到顶部', duration: 500 }); this.scrollToTop(); });
              Image($r('app.media.arrow_back')).height(28).width(28).margin({ right: 25 }).onClick(() => router.back());
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