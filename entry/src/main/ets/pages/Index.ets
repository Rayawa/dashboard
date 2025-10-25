import { webview } from '@kit.ArkWeb';
import prompt from '@ohos.prompt';
@Entry
@Component
struct WebViewWithButtons {
  private webController: webview.WebviewController = new webview.WebviewController();
  @State url: string = 'http://shenjack.top:10003/dashboard';
  @State isLoading: boolean = false;
  @State progress: number = 0;
  @State showBackToTop: boolean = false;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // Web组件
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
          // 滚动超过300px显示回到顶部按钮
          this.showBackToTop = event.yOffset > 300;
        })
        .width('100%')
        .height('100%')

      // 顶部进度条
      if (this.isLoading) {
        Progress({ value: this.progress, total: 100 })
          .width('100%')
          .height(3)
          .color($r('sys.color.point_color_checked'))
        //          .style(ProgressStyle.Linear)
      }

      // 右下角按钮组
      Column() {
        // 刷新/停止加载按钮
        Button() {
          Image(this.isLoading ? $r('app.media.close') : $r('app.media.refresh'))
            .width(24)
            .height(24)
            .fillColor(this.isLoading ? '#ff3b30' : Color.White)
        }
        .onClick(() => {
          if (this.isLoading) {
            // 正在加载时点击停止加载
            this.webController.stop();
            this.isLoading = false;
            prompt.showToast({
              message: '已停止加载',
              duration: 1000
            });
          } else {
            // 否则刷新页面
            this.webController.refresh();
            this.isLoading = true; // 开始加载
            prompt.showToast({
              message: '刷新中...',
              duration: 1000
            });

            // 3秒后如果还在加载，自动重置状态（防止加载失败时状态卡住）
            setTimeout(() => {
              if (this.isLoading) {
                this.isLoading = false;
              }
            }, 3000);
          }
        })
        .type(ButtonType.Circle)
        .backgroundColor(this.isLoading ? '#ffffffff' : '#ffffffff') // 加载中时背景色变化更明显
        .width(50)
        .height(50)
        .shadow({
          radius: 4,
          color: '#182431',
          offsetX: 2,
          offsetY: 4
        })
        .margin({ bottom: 12 })
        .stateEffect(true) // 添加状态效果
        //------------------------------------------------------
        // 回到顶部按钮（滚动时显示）
        if (this.showBackToTop) {
          Button() {
            Image($r('app.media.arrow_up'))
              .width(24)
              .height(24)
              .fillColor(Color.White)
          }
          .onClick(() => {
            this.webController.scrollTo(0, 0);

            // 添加点击反馈
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
      .position({ x: '90%', y: '80%' })
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .height('100%')
  }
}