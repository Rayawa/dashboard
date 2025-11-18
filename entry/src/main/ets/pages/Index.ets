import { webview } from "@kit.ArkWeb";
import { router, prompt } from "@kit.ArkUI";
import window from '@ohos.window';

@Entry
@Component
export struct V2 {
  @Builder
  Menu() {
    MenuItemGroup() {
      MenuItem({
        startIcon: $r('app.media.arrow_back'),
        content: "返回上级"
      })
        .onClick(() => {
          this.webController.backward();
          prompt.showToast({ message: '返回上级', duration: 500 });
        })

      MenuItem({
        startIcon: this.isLoading ? $r('app.media.close') : $r('app.media.refresh'),
        content: this.isLoading ? "停止刷新" : "刷新页面"
      })
        .onClick(() => {
          if (this.isLoading) {
            this.webController.stop();
            this.isLoading = false;
            prompt.showToast({ message: '停止刷新', duration: 500 });
          } else {
            this.webController.refresh();
            this.isLoading = true;
            prompt.showToast({ message: '刷新页面', duration: 500 });
          }
        })

      MenuItem({
        startIcon: $r('app.media.arrow_up'),
        content: "回到顶部"
      })
        .onClick(() => {
          prompt.showToast({ message: '回到顶部', duration: 500 })
          this.scrollToTop();
        })


      MenuItem({
        startIcon: $r('app.media.switch'),
        content: "切换V1"
      })
        .onClick(() => {
          router.pushUrl({ url: 'pages/IndexV1' });
          prompt.showToast({ message: '切换V1', duration: 500 });
        })
    }
  }

  private win: window.Window | null = null;
  async aboutToAppear() {
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
      this.webController.scrollTo(0, newY);

      if (frame >= frames) {
        clearInterval(timer);
        this.webController.scrollTo(0, 0);
      }
    }, interval);
  }
  private webController: webview.WebviewController = new webview.WebviewController();

  @State url: string = 'https://hmos.txit.top/dashboard';
  @State mode: WebDarkMode = WebDarkMode.Auto;
  @State isLoading: boolean = false;
  @State progress: number = 0;
  @State scrollY: number = 0;

  private readonly NAV_HEIGHT: number = 70;

  build() {
    Stack() {
      Column() {
        Column()
          .width('100%')
          .height(Math.max(this.NAV_HEIGHT - this.scrollY, 0))

        Web({
          src: this.url,
          controller: this.webController
        })
          .domStorageAccess(true)
          .darkMode(this.mode)
          .forceDarkAccess(true)
          .width('100%')
          .height('100%')
          .onPageBegin(() => this.isLoading = true)
          .onProgressChange((p) => this.progress = p.newProgress)
          .onPageEnd(() => this.isLoading = false)
          .onScroll((e) => this.scrollY = e.yOffset)
      }

      Column() {
        Column() {
          Text('\n').fontSize(14)
        }
        Row() {
          Text('应用看板')
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 15 })
          Row() {
            Image($r('app.media.user'))
              .height(24).width(24)
              .margin({ right: 30 })
              .onClick(() => router.pushUrl({ url: 'pages/user' }))
            Image($r('app.media.menu'))
              .height(24).width(24)
              .margin({ right: 30 })
              .bindMenu(this.Menu)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .height(45)

        Rect()
          .width('100%')
          .height(0.5)
          .fill("#a6d5d5d5")
          .position({ x: 0, y: 78 })

      }
      .backgroundBlurStyle(BlurStyle.Thin)
      .position({ x: 0, y: 0 })
      .width('100%')

      if (this.isLoading) {
        Progress({ value: this.progress, total: 100 })
          .width('100%')
          .height(3)
          .position({ x: 0, y: 78 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
