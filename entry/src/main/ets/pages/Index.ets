import { webview } from '@kit.ArkWeb'; // 导入ArkWeb模块

@Entry
@Component
struct MyWebViewPage {
  // 创建Web控制器，用于后续控制网页
  private webController: webview.WebviewController = new webview.WebviewController();
  // 定义要加载的网址
  @State url: string = 'http://shenjack.top:10003/dashboard';

  build() {
    Column() {
      // Web组件本身
      Web({
        src: this.url, // 指定网页地址
        controller: this.webController // 绑定控制器
      })
        // .onPageFinished((url) => {
        //   // 网页加载完成时的回调，可用于隐藏加载进度条等
        //   console.info(`页面加载完成: ${url}`);
        // })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }

}