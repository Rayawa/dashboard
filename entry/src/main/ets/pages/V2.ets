import { webview } from "@kit.ArkWeb";
import { TopNavBar } from '../Components/TopNavBar'

@Entry
@Component
export struct V2 {
  private webController: webview.WebviewController = new webview.WebviewController();
  @State url: string = 'https://hmos.txit.top/dashboard';
  @State isLoading: boolean = false;
  @State progress: number = 0;
  @State scrollY: number = 0;   // 关键：接收 WebView 滚动量

  build() {
    Stack() {
      Column(){
        Web({
          src: this.url,
          controller: this.webController
        })
          .domStorageAccess(true)
          .width('100%')
          .height('100%')
          .onPageBegin(() => this.isLoading = true)
          .onProgressChange((p) => this.progress = p.newProgress)
          .onPageEnd(() => this.isLoading = false)
          .onScroll((e) => this.scrollY = e.yOffset)
      }
      .padding({top:60})

      // 顶层导航栏（悬浮）
      TopNavBar({
        title: 'V2',
        isLoading: this.isLoading,
        scrollY: this.scrollY,
        webController: this.webController
      })
        .position({ x: 0, y: 0 })  // ← 必须加
        .width('100%')

      // 顶层进度条
      if (this.isLoading) {
        Progress({ value: this.progress, total: 100 })
          .width('100%')
          .height(3)
          .position({ x: 0, y: 0 })  // 与导航栏齐平
      }
    }
    .width('100%')
    .height('100%')
  }
}
