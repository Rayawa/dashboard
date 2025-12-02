import { router } from "@kit.ArkUI"
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import { APP_VERSION } from "../global_data";
import preferences from '@ohos.data.preferences';
import deviceInfo from '@ohos.deviceInfo';
@Entry
@Component
struct user {
  @State userName: string = ''
  @State deviceName: string = ''
  async getPreference(): Promise<preferences.Preferences> {
    const context = getContext(this) as common.Context;
    return await preferences.getPreferences(context, 'user_settings');
  }
  async loadUserName() {
    try {
      const pref = await this.getPreference();
      const savedName = await pref.get('userName', '');

      if (savedName && savedName !== '') {
        this.userName = savedName.toString();
      } else {
        await this.loadDeviceName();
        this.userName = this.deviceName;
      }
    } catch (err) {
      console.error('Failed to load user name', err);
      await this.loadDeviceName();
      this.userName = this.deviceName;
    }
  }
  async loadDeviceName() {
    try {
      this.deviceName = deviceInfo.productModel || 'HarmonyOS设备';
    } catch (err) {
      console.error('Failed to get device name', err);
      this.deviceName = '我的设备';
    }
  }
  async saveUserName() {
    try {
      const pref = await this.getPreference();
      await pref.put('userName', this.userName);
      await pref.flush();
      console.info('User name saved:', this.userName);
    } catch (err) {
      console.error('Failed to save user name', err);
    }
  }
  async resetToDeviceName() {
    await this.loadDeviceName();
    this.userName = this.deviceName;
    await this.saveUserName();
  }

  async openLink() {
    const url = 'https://beian.miit.gov.cn/#/Integrated/index';
    const ui_content = this.getUIContext();
    const prompt_action = ui_content.getPromptAction();
    ui_content.showAlertDialog({
      title: '即将离开本应用',
      message: '是否跳转到浏览器',
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

  aboutToAppear() {
    this.loadUserName();
  }
  build() {
    Column() {
      Stack() {
        Scroll(){
          Column() {
            Column() {
              Column() {
                Image($r('app.media.app_icon'))
                  .height(100)
                  .width(100)
                  .borderRadius($r('sys.float.corner_radius_level6'))
                  .margin({ top: 85 })
                Text('应用看板')
                  .fontWeight(800)
                  .fontSize(30)
                  .margin({ top: 20 })
                  .fontColor($r('app.color.diff_content'))
                Text('Gallery Dashboard').fontWeight(600).fontSize(20).margin({ top: 10 })
              }
              Divider().margin({ top: 20, bottom: 20 }).color($r('app.color.border'))

              Column(){
                Row() {
                  Image($r('app.media.user'))
                    .height(24)
                    .width(24)
                    .objectFit(ImageFit.Contain)

                  Text('用户名')
                    .fontSize(16)
                    .margin({ left: 12 })
                    .fontWeight(FontWeight.Medium)

                  TextInput({
                    text: this.userName,
                    placeholder: '设置用户名'
                  })
                    .width('70%')
                    .height(40)
                    .margin({ left: 12 })
                    .borderRadius(16)
                    .padding({ left: 12, right: 12 })
                    .borderWidth(0.5)
                    .borderColor($r('app.color.border'))
                    .backgroundColor($r('app.color.diff_background'))
                    .border({
                      width: 1,
                      color: this.userName ? '#007DFF' : '#E5E5E5',
                      radius: 16
                    })
                    .onChange((value: string) => {
                      this.userName = value;
                      this.saveUserName();
                    })
                    .onSubmit(() => {
                      this.saveUserName();
                    })
                }
                .height(56)
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .padding({ left: 16, right: 16 })

                Row(){
                  if (this.userName === this.deviceName) {
                    Text(`当前使用设备名称: ${deviceInfo.productModel}`)
                      .fontSize(12)
                      .fontColor('#666')
                      .margin({right:3})
                  }
                  Text('已自动保存')
                    .fontSize(12)
                    .fontColor('#52C41A')
                    .opacity(this.userName ? 1 : 0)
                    .margin({left:3})
                }
                .justifyContent(FlexAlign.Center)
                .margin({bottom:8})
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

              Divider().margin({ top: 20, bottom: 20 }).color($r('app.color.border'))

              Column() {
                Row() {
                  Row() {
                    Image($r('app.media.log'))
                      .height(24)
                      .width(24)
                      .objectFit(ImageFit.Contain)

                    Text('Web更新日志')
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
                    Image($r('app.media.app_log'))
                      .height(24)
                      .width(24)
                      .objectFit(ImageFit.Contain)

                    Text('App更新日志')
                      .fontSize(16)
                      .margin({ left: 12 })
                  }

                  Image($r('app.media.right'))
                    .height(16)
                    .width(16)
                    .objectFit(ImageFit.Contain)
                }
                .onClick(() => router.pushUrl({ url: 'pages/user/app_log' }))
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

                Divider()
                  .color($r('app.color.border'))
                  .strokeWidth(0.5)
                  .margin({ left: 16, right: 16 })

                Row() {
                  Row() {
                    Image($r('app.media.tutorial'))
                      .height(24)
                      .width(24)
                      .objectFit(ImageFit.Contain)

                    Text('使用教程')
                      .fontSize(16)
                      .margin({ left: 12 })
                  }

                  Image($r('app.media.right'))
                    .height(16)
                    .width(16)
                    .objectFit(ImageFit.Contain)
                }
                .onClick(() => router.pushUrl({ url: 'pages/user/tutorial' }))
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
                    Image($r('app.media.issue'))
                      .height(24)
                      .width(24)
                      .objectFit(ImageFit.Contain)

                    Text('问题与反馈')
                      .fontSize(16)
                      .margin({ left: 12 })
                  }

                  Image($r('app.media.right'))
                    .height(16)
                    .width(16)
                    .objectFit(ImageFit.Contain)
                }
                .onClick(() => router.pushUrl({ url: 'pages/user/issue' }))
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

              Divider().margin({ top: 20, bottom: 20 }).color($r('app.color.border'))

              Text(`Version ${APP_VERSION}`)
                .fontColor('#888')
                .fontSize(12)
                .margin(5)
              Text('本应用备案域名：rayawa.top').fontSize(12).fontColor('#888').margin(5)
              Column() {
                Text('京ICP备2025153453号')
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
          .margin({ top: 20, bottom: 20 })
          .width('100%')
        }
        .width('100%')
        .height('100%')

        Column() {
          Column() { Text('\n').fontSize(14) }
          Row() {
            Text('我的')
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
}
