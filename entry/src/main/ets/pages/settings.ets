import { prompt, router } from "@kit.ArkUI"
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';

@Entry
@Component
struct settings {

  build() {
    Column() {
      Stack() {
        Column() {
          Column()
            .width('100%')
            .height(90)

          Column() {
            Column() {
              Image($r('app.media.app_icon'))
                .height(100)
                .width(100)
                .borderRadius($r('sys.float.corner_radius_level6'))
                .margin({ top: 10 })
              Text('应用看板').fontWeight(800).fontSize(30).margin({ top: 20 }).fontColor($r('app.color.diff_content'))
              Text('Gallery Dashboard').fontWeight(600).fontSize(20).margin({ top: 10 })
              Divider().margin({top:30,bottom:30}).color($r('app.color.border'))

              Column() {
                Row() {
                  Row() {
                    Image($r('app.media.log'))
                      .height(24)
                      .width(24)
                      .objectFit(ImageFit.Contain)

                    Text('更新日志')
                      .fontSize(16)
                      .margin({ left: 12 })
                  }

                  Image($r('app.media.right'))
                    .height(16)
                    .width(16)
                    .objectFit(ImageFit.Contain)
                }
                .onClick(() => router.pushUrl({ url: 'pages/user/log' }))
                .height(56)
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .padding({ left: 16, right: 16 })

                Divider()
                  .color($r('app.color.border'))
                  .strokeWidth(0.5)
                  .margin({ left: 16, right: 16 })

                Row() {
                  Row() {
                    Image($r('app.media.api'))
                      .height(24)
                      .width(24)
                      .objectFit(ImageFit.Contain)

                    Text('API文档')
                      .fontSize(16)
                      .margin({ left: 12 })
                  }

                  Image($r('app.media.right'))
                    .height(16)
                    .width(16)
                    .objectFit(ImageFit.Contain)
                }
                .onClick(() => router.pushUrl({ url: 'pages/user/api' }))
                .height(56)
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .padding({ left: 16, right: 16 })

                Divider()
                  .strokeWidth(0.5)
                  .color($r('app.color.border'))
                  .margin({ left: 16, right: 16 })

                Row() {
                  Row() {
                    Image($r('app.media.contact'))
                      .height(24)
                      .width(24)
                      .objectFit(ImageFit.Contain)

                    Text('联系我们')
                      .fontSize(16)
                      .margin({ left: 12 })
                  }

                  Image($r('app.media.right'))
                    .height(16)
                    .width(16)
                    .objectFit(ImageFit.Contain)
                }
                .onClick(() => router.pushUrl({ url: 'pages/user/contact' }))
                .height(56)
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .padding({ left: 16, right: 16 })

              }
              .borderWidth(0.5)
              .borderColor($r('app.color.border'))
              .backgroundColor($r('app.color.background'))
              .borderRadius(16)
              .shadow({
                radius: 8,
                color: '#1a000000',
                offsetX: 0,
                offsetY: 2
              })
              .width('90%')
              .margin({ bottom: 20 })

              Text('Version 1.0.0')
                .fontColor('#888')
                .margin(5)
                .fontSize(12)
              Text('本应用备案域名：rayawa.top').fontSize(12).margin(5).fontColor('#888')
              Column() {
                Text('备案号')
                  .fontSize(12)
                  .fontColor(Color.Blue)
                  .onClick(() => {
                    this.openLink();
                  })
              }
              .margin(5)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .height('100%')

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
              .fill($r('app.color.border'))
              .position({ x: 0, y: 77 })

          }
          .backgroundBlurStyle(BlurStyle.Thin)
          .position({ x: 0, y: 0 })
          .width('100%')
        }
        .width('100%')
        .backgroundColor($r('app.color.backcolor'))
      }
    }
  }
  async openLink() {
    const url = 'https://beian.miit.gov.cn/#/Integrated/index';
    try {
      prompt.showToast({ message: '正在跳转...', duration: 500 });
      let context = getContext(this) as common.UIAbilityContext;
      await context.startAbility({
        action: "ohos.want.action.viewData",
        entities: ["entity.system.browsable"],
        uri: url
      } as Want);

    } catch (error) {
      console.error('打开链接失败:', (error as BusinessError).message);
      prompt.showToast({ message: '打开链接失败', duration: 1000 });
    }
  }
}