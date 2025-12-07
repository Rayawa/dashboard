import { prompt, router } from '@kit.ArkUI'
import { pasteboard, BusinessError } from '@kit.BasicServicesKit'
import { common, Want } from '@kit.AbilityKit'

@Entry
@Component
struct contact {
  build() {
    Column() {
      Stack() {
        Scroll() {
          Column() {
            Column({ space: 20 }) {
              // 主要负责人
              Column() {
                Text('主要负责人')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 6 })

                Text('shenjack')
                  .fontSize(15)
                  .margin({ bottom: 8 })

                Text('3695888@qq.com')
                  .fontSize(16)
                  .fontColor($r('app.color.diff_content'))
                  .fontWeight(FontWeight.Medium)
              }
              .width('95%')
              .borderRadius(16)
              .padding({ top: 12, bottom: 12, left: 12, right: 12 })
              .backgroundColor($r('app.color.diff_background'))
              .onClick(async () => {
                await this.copyToClipboard('3695888@qq.com', '邮箱：3695888@qq.com')
              })

              // T站网页负责人
              Column() {
                Text('T站网页负责人')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 6 })

                Text('tianxiu2b2t')
                  .fontSize(15)
                  .margin({ bottom: 8 })

                Text('administrator@ttb-network.top')
                  .fontSize(16)
                  .fontColor($r('app.color.diff_content'))
                  .fontWeight(FontWeight.Medium)
              }
              .width('95%')
              .borderRadius(16)
              .padding({ top: 12, bottom: 12, left: 12, right: 12 })
              .backgroundColor($r('app.color.diff_background'))
              .onClick(async () => {
                await this.copyToClipboard('administrator@ttb-network.top', '邮箱：administrator@ttb-network.top')
              })

              // 鸿蒙应用开发
              Column() {
                Text('鸿蒙应用开发')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 6 })

                Text('Rayawa')
                  .fontSize(15)
                  .margin({ bottom: 8 })

                Text('rayawa.work@outlook.com')
                  .fontSize(16)
                  .fontColor($r('app.color.diff_content'))
                  .fontWeight(FontWeight.Medium)
              }
              .width('95%')
              .borderRadius(16)
              .padding({ top: 12, bottom: 12, left: 12, right: 12 })
              .backgroundColor($r('app.color.diff_background'))
              .onClick(async () => {
                await this.copyToClipboard('rayawa.work@outlook.com', '邮箱：rayawa.work@outlook.com')
              })

              // QQ群
              Column() {
                Text('QQ群')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 6 })

                Text('Harmony Gallery 官方交流群')
                  .fontSize(15)
                  .margin({ bottom: 8 })

                Text('757273833')
                  .fontSize(16)
                  .fontColor($r('app.color.diff_content'))
                  .fontWeight(FontWeight.Medium)
              }
              .width('95%')
              .borderRadius(16)
              .padding({ top: 12, bottom: 12, left: 12, right: 12 })
              .backgroundColor($r('app.color.diff_background'))
              .onClick(async () => {
                await this.copyToClipboard('757273833', 'QQ群号：757273833')
              })
              //赞助
              Column() {
                Text('赞助我们')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 6 })
                Text('支持项目发展')
                  .fontSize(15)
                  .margin({ bottom: 8 })
                Text('点击跳转到爱发电赞助页面')
                  .fontSize(16)
                  .fontColor($r('app.color.diff_content'))
                  .fontWeight(FontWeight.Medium)
              }
              .width('95%')
              .borderRadius(16)
              .padding({ top: 12, bottom: 12, left: 12, right: 12 })
              .backgroundColor($r('app.color.diff_background'))
              .onClick(() => {
                this.openLink()
              })
            }
            .padding({ left: 12, right: 12 })

            Column() {
              Divider()
                .strokeWidth(1)
                .color($r('app.color.border'))
                .margin({ top: 24, bottom: 24 })
                .width('80%')

              Text('我们将尽快回复您的消息')
                .fontSize(12)
                .margin({ bottom: 4 })

              Text('感谢您的支持！')
                .fontSize(12)
                .margin({ bottom: 10 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
          .margin({ top: 100, bottom: 20 })
          .width('100%')
        }
        .width('100%')
        .height('100%')

        Column() {
          Column() { Text('\n').fontSize(14) }
          Row() {
            Text('问题反馈 & 联系我们')
              .fontSize(23)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 20 })

            Image($r('app.media.arrow_back'))
              .height(28)
              .width(28)
              .margin({ right: 25 })
              .onClick(() => router.back())
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .height(55)

          Rect()
            .width('100%')
            .height(0.5)
            .fill($r('app.color.border'))
            .position({ x: 0, y: 87 })
        }
        .backgroundBlurStyle(BlurStyle.Thin)
        .position({ x: 0, y: 0 })
        .width('100%')
      }
      .backgroundColor($r('app.color.backcolor'))
    }
    .width('100%')
    .height('100%')
  }
  async openLink() {
    const url = 'https://afdian.com/a/shenjack';
    const ui_content = this.getUIContext();
    const prompt_action = ui_content.getPromptAction();
    ui_content.showAlertDialog({
      title: '是否跳转到浏览器',
      message: '即将访问爱发电',
      primaryButton: {
        value: '取消',
        fontColor:Color.Red,
        action: () => {
          console.log('点击了取消按钮');
        },
      },
      secondaryButton: {
        value: '确定',
        fontColor:Color.Blue,
        action: async (): Promise<void> => {
          try {
            prompt_action.showToast({ message: '正在跳转...', duration: 500 });
            let context = ui_content.getHostContext() as common.UIAbilityContext;
            await context.startAbility({
              action: "ohos.want.action.viewData",
              entities: ["entity.system.browsable"],
              uri: url
            } as Want);
          } catch (error) {
            console.error('打开链接失败:', (error as BusinessError).message);
            prompt_action.showToast({ message: '打开链接失败', duration: 1000 });
          }
        }
      },
    })
  }
  async copyToClipboard(text: string, message: string): Promise<void> {
    try {

      let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)

      let systemPasteboard = pasteboard.getSystemPasteboard()
      await systemPasteboard.setData(pasteData)
      prompt.showToast({
        message: `已复制${message}`,
        duration: 2000
      })
    } catch (error) {
      const err: BusinessError = error as BusinessError
      console.error(`复制失败，错误码：${err.code}, 信息：${err.message}`)
      prompt.showToast({
        message: '复制失败，请重试',
        duration: 2000
      })
    }
  }
}