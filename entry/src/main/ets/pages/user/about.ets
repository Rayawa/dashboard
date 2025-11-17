import { router } from "@kit.ArkUI"

@Entry
@Component
export struct about {
  build() {
    Stack() {
      Column() {
        Column()
          .width('100%')
          .height(90)


        Column() {
          Image($r('app.media.rocket')).height(100).width(100).borderRadius($r('sys.float.corner_radius_level6')).margin({top:10})
          Text('应用看板').fontWeight(800).fontSize(30).margin({top:10})
          Text('Gallery Dashboard').fontWeight(600).fontSize(20).margin({top:5,bottom:10})
          Divider().margin(5)
          Row() {
            Text('版本信息').margin({ left: 7 }).fontSize(20)
            Text('1.0.0').margin({ left: 7 }).fontSize(15).fontColor(Color.Grey)
          }
          .height(60)
          .width('90%')
          .justifyContent(FlexAlign.SpaceBetween)

          Divider().margin(5)
          Row() {
            Text('作者').margin({ left: 7 }).fontSize(20)
            Text('Rayawa').margin({ left: 7 }).fontSize(15).fontColor(Color.Grey)
          }
          .height(60)
          .width('90%')
          .justifyContent(FlexAlign.SpaceBetween)
          Divider().margin(5)
        }
        .borderRadius($r('sys.float.corner_radius_level4'))
        .backgroundColor('#05000000')
        .width('90%')
        .margin(10)


        Column() {
          Column() {
            Text('\n').fontSize(14)
          }

          Row() {
            Text('关于')
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