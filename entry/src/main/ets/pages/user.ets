import { router } from "@kit.ArkUI"

@Entry
@Component
export struct user {
  build() {
    Stack() {
      Column() {
        Column()
          .width('100%')
          .height(90)

        Column() {
          Row() {
            Row(){
              Image($r('app.media.log')).height(25).width(25)
              Text('更新日志').margin({ left: 6 }).fontSize(20)
            }
            Image($r('app.media.right')).height(25).width(25)
          }
          .onClick(() => router.pushUrl({ url: 'pages/user/log' }))
          .height(60)
          .width('90%')
          .justifyContent(FlexAlign.SpaceBetween)

          Divider().margin(5).width('75%')
          Row() {
            Row(){
              Image($r('app.media.api')).height(25).width(25)
              Text('API文档').margin({ left: 6 }).fontSize(20)
            }
            Image($r('app.media.right')).height(25).width(25)
          }
          .onClick(() => router.pushUrl({ url: 'pages/user/api' }))
          .height(60)
          .width('90%')
          .justifyContent(FlexAlign.SpaceBetween)

          Divider().margin(5).width('85%')
          Row() {
            Row(){
              Image($r('app.media.contact')).height(25).width(25)
              Text('联系我们').margin({ left: 6 }).fontSize(20)
            }
            Image($r('app.media.right')).height(25).width(25)
          }
          .onClick(() => router.pushUrl({ url: 'pages/user/contact' }))
          .height(60)
          .width('90%')
          .justifyContent(FlexAlign.SpaceBetween)
      }
        .borderRadius($r('sys.float.corner_radius_level4'))
        .backgroundColor('#05000000')
        .width('90%')
        .margin(10)

        Column() {
          Row() {
            Row(){
              Image($r('app.media.settings')).height(25).width(25)
              Text('设置').margin({ left: 6 }).fontSize(20)
            }
            Image($r('app.media.right')).height(30).width(30)
          }
          .onClick(() => router.pushUrl({ url: 'pages/user/settings' }))
          .height(60)
          .width('90%')
          .justifyContent(FlexAlign.SpaceBetween)
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
          Text('我的')
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