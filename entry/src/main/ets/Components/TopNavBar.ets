import { webview } from '@kit.ArkWeb';

@Component
export struct TopNavBar {
  @Prop webController: webview.WebviewController;
  @Prop title: string = '';
  @Prop isLoading: boolean = false;
  @Prop scrollY: number = 0;

  private maxHideHeight: number = 120;

  private get navOpacity(): number {
    return 1 - Math.min(this.scrollY / this.maxHideHeight, 1);
  }

  // 限定最大上移 40px
  private get translateYOffset(): number {
    const MAX_OFFSET = 40;
    return -Math.min(this.scrollY / 2, MAX_OFFSET);
  }

  private get navBgColor(): number {
    const alpha = Math.floor(this.navOpacity * 180); // 半透明
    return (alpha << 24) | 0xFFFFFF;
  }

  build() {
    // 顶部悬浮栏（只保留标题 + 三按钮）
    Column() {
      Column(){Text('\n').fontSize(13)}
      Row() {
        // 标题
        Text(this.title)
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 20 })

        // 三个功能按钮
        Row() {
          Image($r('app.media.arrow_back'))
            .width(28).height(28)
            .margin({ left: 8, right: 8 })
            .onClick(() => this.webController.backward())

          Image(this.isLoading ? $r('app.media.close') : $r('app.media.refresh'))
            .width(28).height(28)
            .margin({ left: 8, right: 8 })
            .onClick(() => {
              if (this.isLoading) this.webController.stop();
              else this.webController.refresh();
            })

          Image($r('app.media.arrow_up'))
            .width(28).height(28)
            .margin({ left: 8, right: 20 })
            .onClick(() => this.webController.scrollTo(0, 0))
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .height(40) // 规范化导航条高度
    }
    .backgroundColor(this.navBgColor)
    .backgroundBlurStyle(BlurStyle.Thin)
    .opacity(this.navOpacity)
    .translate({ y: this.translateYOffset })
    .animation({
      duration: 140,
      curve: Curve.EaseOut
    })
  }
}
