import { webview } from '@kit.ArkWeb';
import prompt from '@ohos.prompt';
@Entry
@Component
export struct V2 {
  private webController: webview.WebviewController = new webview.WebviewController();
  @State url: string = 'https://hmos.txit.top/dashboard';
  @State isLoading: boolean = false;
  @State progress: number = 0;
  @State showBackToTop: boolean = false;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Web({
        src: this.url,
        controller: this.webController
      })
        .onPageBegin(() => {
          this.isLoading = true;
          this.progress = 10;
        })
        .onProgressChange((newProgress) => {
          this.progress = newProgress.newProgress;
        })
        .onPageEnd(() => {
          this.isLoading = false;
          this.progress = 100;
        })
        .onScroll((event) => {
          this.showBackToTop = event.yOffset > 300;
        })
        .width('100%')
        .height('100%')

      if (this.isLoading) {
        Progress({ value: this.progress, total: 100 })
          .width('100%')
          .height(3)
          .color($r('sys.color.point_color_checked'))
      }

      Column() {
        Button() {
          Image($r('app.media.arrow_back'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .onClick(() => {
          this.webController.backward();
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

        Button() {
          Image(this.isLoading ? $r('app.media.close') : $r('app.media.refresh'))
            .width(24)
            .height(24)
            .fillColor(this.isLoading ? '#ff3b30' : Color.White)
        }
        .onClick(() => {
          if (this.isLoading) {
            this.webController.stop();
            this.isLoading = false;
            prompt.showToast({
              message: '已停止加载',
              duration: 1000
            });
          } else {
            this.webController.refresh();
            this.isLoading = true; // 开始加载
            prompt.showToast({
              message: '刷新中...',
              duration: 1000
            });

            setTimeout(() => {
              if (this.isLoading) {
                this.isLoading = false;
              }
            }, 3000);
          }
        })
        .type(ButtonType.Circle)
        .backgroundColor(this.isLoading ? '#ffffffff' : '#ffffffff')
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

          Button() {
            Image($r('app.media.arrow_up'))
              .width(24)
              .height(24)
              .fillColor(Color.White)
          }
          .onClick(() => {
            this.webController.scrollTo(0, 0);
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
      .position({ x: 20, y: '70%' })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }
}