import { webview } from '@kit.ArkWeb';
import { router } from '@kit.ArkUI';

@Component
export struct TopNavBar {
  @Prop webController: webview.WebviewController;
  @Prop title: string = '';
  @Prop isLoading: boolean = false;
  @Prop scrollY: number = 0;

  build() {
    Column() {
      Column(){ Text('\n').fontSize(13) }

      Row() {
        Text(this.title)
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 30 })
        Row(){
          Image($r('app.media.V1'))
            .height(23).width(23)
            .margin({ right:30 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/IndexV1' })
            })
          Image($r('app.media.V2'))
            .height(23).width(23)
            .margin({ right:30 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/Index' })
            })

          Image($r('app.media.menu'))
            .height(23).width(23)
            .margin({ right:30 })
            .onClick(() => {

            })
        }

      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .height(40)
    }
    .backgroundBlurStyle(BlurStyle.Thin)
  }
}
