import { webview } from '@kit.ArkWeb';
import prompt from '@ohos.prompt';

@Component
export struct WebViewButtons {
  @Link isLoading: boolean
  @Link showBackToTop: boolean

  @Prop onBack: () => void
  @Prop onRefresh: () => void
  @Prop onStop: () => void
  @Prop onScrollToTop: () => void

  build() {
    Column() {
      // 网页返回按钮
      Button() {
        Image($r('app.media.arrow_back'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
      }
      .onClick(() => {
        this.onBack();
        prompt.showToast({
          message: '返回上一页',
          duration: 500
        });
      })
      .type(ButtonType.Circle)
      .backgroundColor('#ffffffff')
      .width(50)
      .height(50)
      .shadow({
        radius: 4,
        color: '#182431',
        offsetX: 2,
        offsetY: 4
      })
      .margin({ bottom: 12 })
      .stateEffect(true)

      // 刷新/停止加载按钮
      Button() {
        Image(this.isLoading ? $r('app.media.close') : $r('app.media.refresh'))
          .width(24)
          .height(24)
          .fillColor(this.isLoading ? '#ff3b30' : Color.White)
      }
      .onClick(() => {
        if (this.isLoading) {
          this.onStop();
        } else {
          this.onRefresh();
        }
      })
      .type(ButtonType.Circle)
      .backgroundColor('#ffffffff')
      .width(50)
      .height(50)
      .shadow({
        radius: 4,
        color: '#182431',
        offsetX: 2,
        offsetY: 4
      })
      .margin({ bottom: 12 })
      .stateEffect(true)

      // 回到顶部按钮
      if (this.showBackToTop) {
        Button() {
          Image($r('app.media.arrow_up'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .onClick(() => {
          this.onScrollToTop();
          prompt.showToast({
            message: '回到顶部',
            duration: 500
          });
        })
        .type(ButtonType.Circle)
        .backgroundColor($r('sys.color.point_color_checked'))
        .width(50)
        .height(50)
        .shadow({
          radius: 4,
          color: '#182431',
          offsetX: 2,
          offsetY: 4
        })
        .stateEffect(true)
      }
    }
    .position({ x: 20, y: '70%' })
    .alignItems(HorizontalAlign.Start)
  }
}