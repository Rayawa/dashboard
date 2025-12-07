import { prompt, router } from "@kit.ArkUI"
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import { APP_VERSION } from "../global_data";
import preferences from '@ohos.data.preferences';
import { deviceInfo } from '@kit.BasicServicesKit';
import { curves } from '@kit.ArkUI';

interface SubmitFormData {
  appLink: string;
  packageName: string;
  appId: string;
  remark: string;
}
@Entry
@Component
export struct user {
  private effect: TransitionEffect =
    TransitionEffect.OPACITY
      .combine(TransitionEffect.move(TransitionEdge.BOTTOM))
      .combine(TransitionEffect.scale({ x: 0, y: 1 }))
      .animation({ curve: curves.springMotion(0.7, 0.8), duration:1000})
  @State handlePopup: boolean = false;
  @State customPopup: boolean = false;
  @StorageLink('userName') userName: string = ''
  @State deviceName: string = ''
  @State isPresent: boolean = false;
  @State formData: SubmitFormData = {
    appLink: '',
    packageName: '',
    appId: '',
    remark: ''
  };
  async getPreference(): Promise<preferences.Preferences> {
    const context = getContext(this) as common.Context;
    return await preferences.getPreferences(context, 'user_settings');
  }
  async loadUserName() {
    try {
      const pref = await this.getPreference();
      const savedName = await pref.get('userName', '');

      if (savedName && savedName !== '') {
        AppStorage.SetOrCreate('userName', savedName.toString());
      } else {
        await this.loadDeviceName();
        AppStorage.SetOrCreate('userName', this.deviceName);
      }
    } catch (err) {
      console.error('Failed to load user name', err);
      await this.loadDeviceName();
      AppStorage.SetOrCreate('userName', this.deviceName);
    }
  }
  async saveUserName() {
    try {
      const pref = await this.getPreference();
      await pref.put('userName', this.userName);
      await pref.flush();
      AppStorage.SetOrCreate('userName', this.userName);
      console.info('User name saved:', this.userName);
    } catch (err) {
      console.error('Failed to save user name', err);
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
      title: '是否跳转到浏览器',
      message: '即将访问\nICP/IP地址/域名信息备案管理系统',
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

  clearForm(): void {
    this.formData = {
      appLink: '',
      packageName: '',
      appId: '',
      remark: ''
    };
    prompt.showToast({
      message: '表单已清空',
      duration: 1500
    });
  }
  queryForm(): void {
    if (!this.formData.packageName && !this.formData.appId) {
      prompt.showToast({
        message: '请输入包名或app_id进行查询',
        duration: 2000
      });
      return;
    }

    // ->查询逻辑
    console.log('查询数据:', this.formData);

    // ->查询结果
    prompt.showToast({
      message: `查询到应用: ${this.formData.packageName || this.formData.appId}`,
      duration: 2000
    });
  }
  submitForm(): void {
    if (!this.formData.packageName.trim()) {
      prompt.showToast({
        message: '请输入包名',
        duration: 2000
      });
      return;
    }

    if (!this.formData.appId.trim()) {
      prompt.showToast({
        message: '请输入app_id',
        duration: 2000
      });
      return;
    }

    // ->提交逻辑，如调用API等
    console.log('提交数据:', this.formData);
    prompt.showToast({
      message: '提交成功，感谢您的反馈！',
      duration: 3000
    });

    // 清空表单并关闭弹窗
    this.formData = {
      appLink: '',
      packageName: '',
      appId: '',
      remark: ''
    };
    this.isPresent = !this.isPresent;
  }

  aboutToAppear() {
    this.loadUserName();
  }
  build() {
    Column() {
      Stack() {
        if (this.isPresent) {
          Stack(){
            Column().backgroundColor(Color.Transparent).height('200%').width('200%')
              .onClick(() => { this.isPresent = !this.isPresent; })
              .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
              .transition(TransitionEffect.OPACITY.animation({curve :curves.springMotion(0,1), duration:1000}))
            Column({ space: 20 }) {
              Row() {
                Row({ space: 8 }) {
                  Image($r('app.media.submit'))
                    .height(25)
                    .width(25)

                  Text('投稿应用')
                    .fontSize(21)
                    .fontWeight(FontWeight.Bold)
                }
                Blank()
                  .layoutWeight(1)
                Image($r('app.media.close'))
                  .height(26)
                  .width(26)
                  .onClick(() => { this.isPresent = !this.isPresent; })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(VerticalAlign.Center)
              .padding({ bottom: 16 })

              // 应用详情页链接（可选）
              Column({ space: 6 }) {
                Row({ space: 4 }) {
                  Text('应用详情页链接')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)

                  Text('(可选)')
                    .fontSize(14)
                    .fontColor($r('app.color.diff_content'))
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)

                TextInput({
                  placeholder: '请输入应用详情页链接',
                  text: this.formData.appLink
                })
                  .width('100%')
                  .height(40)
                  .margin({ left: 12 })
                  .borderRadius(16)
                  .padding({ left: 12, right: 12 })
                  .borderWidth(0.5)
                  .borderColor($r('app.color.border'))
                  .backgroundColor($r('app.color.diff_background'))
                  .onChange((value: string) => {
                    this.formData.appLink = value
                  })
              }

              // 包名
              Column({ space: 6 }) {
                Text('包名')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')

                TextInput({
                  placeholder: '例如：com.example.app',
                  text: this.formData.packageName
                })
                  .width('100%')
                  .height(40)
                  .margin({ left: 12 })
                  .borderRadius(16)
                  .padding({ left: 12, right: 12 })
                  .borderWidth(0.5)
                  .borderColor($r('app.color.border'))
                  .backgroundColor($r('app.color.diff_background'))
                  .onChange((value: string) => {
                    this.formData.packageName = value
                  })
              }

              // app_id
              Column({ space: 6 }) {
                Text('app_id')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')

                TextInput({
                  placeholder: '例如：123456',
                  text: this.formData.appId
                })
                  .width('100%')
                  .height(40)
                  .margin({ left: 12 })
                  .borderRadius(16)
                  .padding({ left: 12, right: 12 })
                  .borderWidth(0.5)
                  .borderColor($r('app.color.border'))
                  .backgroundColor($r('app.color.diff_background'))
                  .onChange((value: string) => {
                    this.formData.appId = value
                  })
              }


              // 备注（可选）
              Column({ space: 6 }) {
                Row({ space: 4 }) {
                  Text('备注')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)

                  Text('(可选)')
                    .fontSize(14)
                    .fontColor($r('app.color.diff_content'))
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)

                TextInput({
                  placeholder: '请输入备注信息',
                  text: this.formData.remark
                })
                  .width('100%')
                  .height(40)
                  .margin({ left: 12 })
                  .borderRadius(16)
                  .padding({ left: 12, right: 12 })
                  .borderWidth(0.5)
                  .borderColor($r('app.color.border'))
                  .backgroundColor($r('app.color.diff_background'))
                  .onChange((value: string) => {
                    this.formData.remark = value
                  })
              }

              // 按钮区域
              Row() {
                // 清空按钮
                Button('清空', { type: ButtonType.Normal })
                  .margin(2)
                  .width('25%')
                  .height(44)
                  .backgroundColor(Color.Green)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .borderRadius(22)
                  .onClick(() => {
                    this.clearForm()
                  })

                // 查询按钮
                Button('查询', { type: ButtonType.Normal })
                  .margin(2)
                  .width('25%')
                  .height(44)
                  .backgroundColor(Color.Blue)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .borderRadius(22)
                  .onClick(() => {
                    this.queryForm()
                  })

                // 提交按钮
                Button('提交投稿', { type: ButtonType.Capsule })
                  .margin(2)
                  .width('40%')
                  .height(44)
                  .backgroundColor(Color.Red)
                  .fontColor(Color.White)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .onClick(() => {
                    this.submitForm()
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ top: 15 })
            }
            .width('90%')
            .padding({ top: 20, bottom: 20, left: 15, right: 25 })
            .borderRadius(20)
            .backgroundColor($r('app.color.backcolor'))
            .shadow({
              radius: 20,
              color: Color.Gray,
              offsetX: 0,
              offsetY: 4
            })
          }
          .transition(this.effect)
          .gesture(
            SwipeGesture({ direction: SwipeDirection.Vertical })
              .onAction((move: GestureEvent|undefined) => {
                if(move){
                  this.isPresent = !this.isPresent
                }
              })
          )
          .zIndex(2)

          .height('100%')
          .width('100%')

        }

        Scroll(){
          Column() {
            Column() {
              Column() {
                Image($r('app.media.app_icon'))
                  .height(100)
                  .width(100)
                  .borderRadius($r('sys.float.corner_radius_level6'))
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
                  Row() {
                    Image($r('app.media.user'))
                      .height(24)
                      .width(24)
                      .objectFit(ImageFit.Contain)

                    Text('用户名')
                      .fontSize(16)
                      .margin({ left: 12 })
                      .fontWeight(FontWeight.Medium)
                  }
                  .constraintSize({
                    minWidth: 50
                  })

                  TextInput({
                    text: this.userName,
                    placeholder: '设置用户名'
                  })
                    .layoutWeight(1)
                    .constraintSize({
                      maxWidth: '80%'
                    })
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

                  Image($r('app.media.question'))
                    .margin({ left: 12 })
                    .height(24)
                    .width(24)
                    .objectFit(ImageFit.Contain)
                    .onClick(() => {
                      this.handlePopup = !this.handlePopup;
                    })
                    .bindPopup(this.handlePopup, {
                      message: '用于您投稿应用时的默认用户名\n详情见请"使用教程-投稿功能"',
                      placement: Placement.Top,
                      showInSubWindow: false,
                      onStateChange: (e) => {
                        if (!e.isVisible) {
                          this.handlePopup = false;
                        }
                      },
                      transition: TransitionEffect.asymmetric(
                        TransitionEffect.OPACITY
                          .animation({ duration: 500, curve: Curve.Ease })
                          .combine(TransitionEffect.translate({ x: 0, y: 12 })),

                        TransitionEffect.OPACITY
                          .animation({ duration: 300, curve: Curve.EaseOut })
                          .combine(TransitionEffect.translate({ x: 0, y: 12 }))
                      )
                    })

                }
                .height(56)
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center)
                .padding({ top: 2, left: 16, right: 16 })

                Row(){
                  if (this.userName === this.deviceName) {
                    Text(`当前使用设备名称: ${deviceInfo.productModel}`)
                      .fontSize(12)
                      .fontColor('#666')
                      .margin({right:5})
                  }
                  Text('已自动保存')
                    .fontSize(12)
                    .fontColor('#52C41A')
                    .opacity(this.userName ? 1 : 0)
                    .margin({left:3})
                }
                .justifyContent(FlexAlign.Center)
                .margin({bottom:8})

                Divider()
                  .color($r('app.color.border'))
                  .strokeWidth(0.5)
                  .margin({ left: 16, right: 16 })

                Row() {
                  Row() {
                    Image($r('app.media.submit'))
                      .height(24)
                      .width(24)
                      .objectFit(ImageFit.Contain)

                    Text('投稿应用')
                      .fontSize(16)
                      .margin({ left: 12 })
                  }

                  Image($r('app.media.right'))
                    .height(16)
                    .width(16)
                    .objectFit(ImageFit.Contain)
                }
                .onClick(() => {this.isPresent = !this.isPresent;})
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
                .onClick(() => router.pushUrl({ url: 'pages/user/web_log' }))
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

                    Text('API文档说明')
                      .fontSize(16)
                      .margin({ left: 12 })
                  }

                  Image($r('app.media.right'))
                    .height(16)
                    .width(16)
                    .objectFit(ImageFit.Contain)
                }
                .onClick(() => router.pushUrl({ url: 'pages/user/web_api' }))
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

                    Text('问题反馈 & 联系我们')
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
                    Image($r('app.media.info'))
                      .height(24)
                      .width(24)
                      .objectFit(ImageFit.Contain)

                    Text('帮助信息 & 使用教程')
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

                // Row() {
                //   Row() {
                //     Image($r('app.media.issue'))
                //       .height(24)
                //       .width(24)
                //       .objectFit(ImageFit.Contain)
                //
                //     Text('问题与反馈')
                //       .fontSize(16)
                //       .margin({ left: 12 })
                //   }
                //
                //   Image($r('app.media.right'))
                //     .height(16)
                //     .width(16)
                //     .objectFit(ImageFit.Contain)
                // }
                // .onClick(() => router.pushUrl({ url: 'pages/user/feedback' }))
                // .height(56)
                // .width('100%')
                // .justifyContent(FlexAlign.SpaceBetween)
                // .padding({ left: 16, right: 16 })

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
                  .fontColor($r('app.color.diff_content'))
                  .onClick(() => {
                    this.openLink();
                  })
              }
              .margin(5)
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
        .zIndex(3)
        .position({ x: 0, y: 0 })
        .width('100%')
      }
      .backgroundColor($r('app.color.backcolor'))
    }
    .width('100%')
    .height('100%')
  }
}
