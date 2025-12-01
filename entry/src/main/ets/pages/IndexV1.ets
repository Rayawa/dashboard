import { webview } from "@kit.ArkWeb";
import { router } from "@kit.ArkUI";
import window from '@ohos.window';
import { BusinessError } from '@kit.BasicServicesKit';
import { APP_UA } from "../global_data";

@Entry
@Component
struct V1 {
  @Builder
  Menu() {
    MenuItemGroup() {
      MenuItem({
        startIcon: $r('app.media.arrow_back'),
        content: "返回上级"
      })
        .onClick(() => {
          this.web_controller.backward();
          const ui_content = this.getUIContext();
          const prompt_action = ui_content.getPromptAction();
          prompt_action.showToast({ message: '返回上级', duration: 500 });
        })

      MenuItem({
        startIcon: this.isLoading ? $r('app.media.close') : $r('app.media.refresh'),
        content: this.isLoading ? "停止刷新" : "刷新页面"
      })
        .onClick(() => {
          const ui_content = this.getUIContext();
          const prompt_action = ui_content.getPromptAction();
          if (this.isLoading) {
            this.web_controller.stop();
            this.isLoading = false;
            prompt_action.showToast({ message: '停止刷新', duration: 500 });
          } else {
            this.web_controller.refresh();
            this.isLoading = true;
            prompt_action.showToast({ message: '刷新页面', duration: 500 });
          }
        })

      MenuItem({
        startIcon: $r('app.media.arrow_up'),
        content: "回到顶部"
      })
        .onClick(() => {
          const ui_content = this.getUIContext();
          const prompt_action = ui_content.getPromptAction();
          prompt_action.showToast({ message: '回到顶部', duration: 500 })
          this.scrollToTop();
        })


      MenuItem({
        startIcon: $r('app.media.switch'),
        content: "切换V2"
      })
        .onClick(() => {
          const ui_content = this.getUIContext();
          const prompt_action = ui_content.getPromptAction();
          ui_content.getRouter().back();
          prompt_action.showToast({ message: '切换V2', duration: 500 });
        })
    }
  }

  private win: window.Window | null = null;
  async aboutToAppear() {
    const customUA = webview.WebviewController.getDefaultUserAgent()
      + " Hm_dashboard" ;
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

  @State url: string = 'http://shenjack.top:10003/dashboard';
  @State mode: WebDarkMode = WebDarkMode.Auto;
  @State isLoading: boolean = false;
  @State progress: number = 0;
  @State scrollY: number = 0;

  private readonly NAV_HEIGHT: number = 72;

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
              this.web_controller.setCustomUserAgent(APP_UA());
            } catch (error) {
              console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
            }
          })
      }
      Column() {
        Column() {
          Text('\n').fontSize(14)
        }
        Row() {
          Text('应用看板V1')
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 15 })
          Row() {
            Image($r('app.media.menu'))
              .height(24).width(24)
              .margin({ right: 30 })
              .bindMenu(this.Menu)
            Image($r('app.media.user'))
              .height(24).width(24)
              .margin({ right: 30 })
              .onClick(() => router.pushUrl({ url: 'pages/user' }))
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .height(45)

        Rect()
          .width('100%')
          .height(0.5)
          .fill($r('app.color.border'))
          .position({ x: 0, y: 77 })

      }
      .backgroundBlurStyle(BlurStyle.Thin)
      .position({ x: 0, y: 0 })
      .width('100%')

      if (this.isLoading) {
        Progress({ value: this.progress, total: 100 })
          .width('100%')
          .height(3)
          .position({ x: 0, y: 77 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
