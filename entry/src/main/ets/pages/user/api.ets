import { router } from "@kit.ArkUI"

@Entry
@Component
struct api {
  build() {
    Stack() {
      Column() {
        Column()
          .width('100%')
          .height(90)



        Column() {
          Column() {
            Text('\n').fontSize(14)
          }

          Row() {
            Text('API文档')
              .fontSize(21)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 25 })
            Image($r('app.media.arrow_back'))
              .height(24).width(24)
              .margin({ right: 30 })
              .onClick(() => router.back())
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

      }
      .width('100%')
      .height('100%')
    }
  }
}