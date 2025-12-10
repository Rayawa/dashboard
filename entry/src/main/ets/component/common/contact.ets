import { prompt } from '@kit.ArkUI'
import { pasteboard, BusinessError } from '@kit.BasicServicesKit'
import { common, Want } from '@kit.AbilityKit'
import { vibrator } from '@kit.SensorServiceKit';

@Component
export struct contact {
  build() {
    Column() {
      Column() {
        Text('联系我们').fontSize(24).fontColor($r('app.color.diff_content')).fontWeight(FontWeight.Bold).margin(({top:8,bottom:20}))
        Column({space:5}){
          Text('👥 主要负责人').fontSize(18).fontWeight(FontWeight.Bold)
          Text('shenjack').fontSize(14)
          Text('  邮箱：3695888@qq.com').fontSize(14).fontColor($r('app.color.diff_content'))
        }.width('95%').backgroundColor($r('app.color.background')).margin({bottom:10}).padding(12).borderRadius(16).onClick(async () => {
          vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
            if (err) {
              console.error(`Failed to query effect. Code: ${err.code}, message: ${err.message}`);
              return;
            }
            console.info('Succeed in querying effect');
            if (state) {
              try {
                vibrator.startVibration({
                  type: 'preset',
                  effectId: 'haptic.effect.hard',
                  count: 1,
                  intensity: 50,
                }, { usage: 'touch' }, (error: BusinessError) => {
                  if (error) { console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`); }
                  else { console.info('Succeed in starting vibration'); }
                });
              } catch (tryError) { console.error(`An unexpected error occurred in try block: ${tryError}`); }
            }
          });
          await this.copyToClipboard('3695888@qq.com', '邮箱：3695888@qq.com')
        })
        Column({space:5}){
          Text('🌐 T站网页负责人').fontSize(18).fontWeight(FontWeight.Bold)
          Text('tianxiu2b2t').fontSize(14)
          Text('  邮箱：administrator@ttb-network.top').fontSize(14).fontColor($r('app.color.diff_content'))
        }.width('95%').backgroundColor($r('app.color.background')).margin({bottom:10}).padding(12).borderRadius(16).onClick(async () => {
          vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
            if (err) {
              console.error(`Failed to query effect. Code: ${err.code}, message: ${err.message}`);
              return;
            }
            console.info('Succeed in querying effect');
            if (state) {
              try {
                vibrator.startVibration({
                  type: 'preset',
                  effectId: 'haptic.effect.hard',
                  count: 1,
                  intensity: 50,
                }, { usage: 'touch' }, (error: BusinessError) => {
                  if (error) { console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`); }
                  else { console.info('Succeed in starting vibration'); }
                });
              } catch (tryError) { console.error(`An unexpected error occurred in try block: ${tryError}`); }
            }
          });
          await this.copyToClipboard('administrator@ttb-network.top', '邮箱：administrator@ttb-network.top')
        })
        Column({space:5}){
          Text('📱 鸿蒙应用开发').fontSize(18).fontWeight(FontWeight.Bold)
          Text('Rayawa').fontSize(14)
          Text('  邮箱：rayawa.work@outlook.com').fontSize(14).fontColor($r('app.color.diff_content'))
        }.width('95%').backgroundColor($r('app.color.background')).margin({bottom:10}).padding(12).borderRadius(16).onClick(async () => {
          vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
            if (err) {
              console.error(`Failed to query effect. Code: ${err.code}, message: ${err.message}`);
              return;
            }
            console.info('Succeed in querying effect');
            if (state) {
              try {
                vibrator.startVibration({
                  type: 'preset',
                  effectId: 'haptic.effect.hard',
                  count: 1,
                  intensity: 50,
                }, { usage: 'touch' }, (error: BusinessError) => {
                  if (error) { console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`); }
                  else { console.info('Succeed in starting vibration'); }
                });
              } catch (tryError) { console.error(`An unexpected error occurred in try block: ${tryError}`); }
            }
          });
          await this.copyToClipboard('rayawa.work@outlook.com', '邮箱：rayawa.work@outlook.com')
        })
        Column({space:5}){
          Text('💬 QQ群').fontSize(18).fontWeight(FontWeight.Bold)
          Text('Harmony Gallery 官方交流群').fontSize(14)
          Text('  群号：757273833').fontSize(14).fontColor($r('app.color.diff_content'))
        }.width('95%').backgroundColor($r('app.color.background')).margin({bottom:10}).padding(12).borderRadius(16).onClick(async () => {
          vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
            if (err) {
              console.error(`Failed to query effect. Code: ${err.code}, message: ${err.message}`);
              return;
            }
            console.info('Succeed in querying effect');
            if (state) {
              try {
                vibrator.startVibration({
                  type: 'preset',
                  effectId: 'haptic.effect.hard',
                  count: 1,
                  intensity: 50,
                }, { usage: 'touch' }, (error: BusinessError) => {
                  if (error) { console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`); }
                  else { console.info('Succeed in starting vibration'); }
                });
              } catch (tryError) { console.error(`An unexpected error occurred in try block: ${tryError}`); }
            }
          });
          await this.copyToClipboard('757273833', 'QQ群号：757273833')
        })
        Column({space:5}){
          Text('❤️ 赞助我们').fontSize(18).fontWeight(FontWeight.Bold)
          Text('支持项目发展').fontSize(14)
          Text('  点击跳转到爱发电赞助页面').fontSize(14).fontColor($r('app.color.diff_content'))
        }.width('95%').backgroundColor($r('app.color.background')).margin({bottom:5}).padding(12).borderRadius(16).onClick(() => { vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
          if (err) {
            console.error(`Failed to query effect. Code: ${err.code}, message: ${err.message}`);
            return;
          }
          console.info('Succeed in querying effect');
          if (state) {
            try {
              vibrator.startVibration({
                type: 'preset',
                effectId: 'haptic.effect.hard',
                count: 1,
                intensity: 50,
              }, { usage: 'touch' }, (error: BusinessError) => {
                if (error) { console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`); }
                else { console.info('Succeed in starting vibration'); }
              });
            } catch (tryError) { console.error(`An unexpected error occurred in try block: ${tryError}`); }
          }
        });this.openLink() })

      }.padding(12)


      Column() {
        Divider()
          .strokeWidth(1)
          .color($r('app.color.border'))
          .margin({ bottom: 20 })
          .width('100%')

        Text('我们将尽快回复您的消息')
          .fontSize(12)
          .margin({ bottom: 4 })

        Text('感谢您的支持！')
          .fontSize(12)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 8 })
    }
    .height('80%')
    .margin({ top: 10, bottom: 10 })
    .width('90%')
    .borderRadius(20)
    .backgroundColor($r('app.color.backcolor'))
    .shadow({
      radius: 20,
      color: Color.Gray,
      offsetX: 0,
      offsetY: 4
    })
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
        fontColor: Color.Red,
        action: () => {
          console.log('点击了取消按钮');
        },
      },
      secondaryButton: {
        value: '确定',
        fontColor: Color.Blue,
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