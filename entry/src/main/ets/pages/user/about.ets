import { curves, display, LengthMetrics, PromptAction } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import { APP_VERSION } from '../../common/constants';
import { HdsNavDestination, ScrollEffectType } from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { vibration } from '../../common/vibration';
import { warn } from '../../component/warn';
import { blurPopup } from '../../component/blurPopup';

@Component
struct about {
  @Consume('pageStack') pageStack: NavPathStack;
  PromptAction: PromptAction = this.getUIContext().getPromptAction();
  @StorageLink("vibrationON") vibrationON: boolean = true;
  private triggerVibration(): void {
    if (this.vibrationON) {
      vibration.dotVibration()
    }
  }

  @State showWarn: boolean = false;

  @State WVp: number = 376;
  @State HVp: number = 376;
  aboutToAppear() {
    //获取屏幕尺寸
    const displayInfo = display.getDefaultDisplaySync();
    const screenWidthVp = px2vp(displayInfo.width);
    const screenHeightVp = px2vp(displayInfo.height);
    this.WVp = screenWidthVp;
    this.HVp = screenHeightVp;
  }

  async openLink() {
    const url = "https://beian.miit.gov.cn/#/Integrated/index";
    const ui_content = this.getUIContext();
    ui_content.showAlertDialog({
      title: "是否跳转到浏览器",
      message: "即将访问\nICP/IP地址/域名信息备案管理系统",
      primaryButton: {
        value: "取消",
        fontColor: Color.Red,
        action: () => {
          console.log("点击了取消按钮");
        },
      },
      secondaryButton: {
        value: "确定",
        fontColor: Color.Blue,
        action: async (): Promise<void> => {
          try {
            this.PromptAction.showToast({ message: "正在跳转...", duration: 500 });
            let context = ui_content.getHostContext() as common.UIAbilityContext;
            await context.startAbility({
              action: "ohos.want.action.viewData",
              entities: ["entity.system.browsable"],
              uri: url,
            } as Want);
          } catch (error) {
            console.error("打开链接失败:", (error as BusinessError).message);
            this.PromptAction.showToast({ message: "打开链接失败", duration: 1000 });
          }
        },
      },
    });
  }

  build() {
    HdsNavDestination() {
      Stack() {
        Column() {
          Column() {
            Image($r("app.media.app_icon"))
              .height(100)
              .width(100)
              .borderRadius($r("sys.float.corner_radius_level6"))
            Text("鸿蒙应用看板")
              .fontWeight(800)
              .fontSize(30)
              .margin({ top: 20 })
              .fontColor($r("app.color.diff_content"))
            Text("HmDashboard")
              .fontWeight(600)
              .fontSize(20)
              .margin({ top: 10 })
          }.margin({ top: 50 })
          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))
          Column() {
            Row() {
              Row() {
                Image($r("app.media.attention"))
                  .height(24)
                  .width(24)
                  .objectFit(ImageFit.Contain)
                Text("重要提示")
                  .fontSize(16)
                  .margin({ left: 12 })
                  .fontColor(Color.Red)
              }
              Image($r("app.media.right"))
                .height(16)
                .width(16)
                .objectFit(ImageFit.Contain)
            }
            .onClick(() => {
              this.triggerVibration();
              this.showWarn = true;
            })
            .height(52)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })

            Divider()
              .color($r("app.color.border"))
              .strokeWidth(0.5)
              .margin({ left: 16, right: 16 })

            Row() {
              Row() {
                Image($r("app.media.api"))
                  .height(24)
                  .width(24)
                  .objectFit(ImageFit.Contain)
                Text("API文档说明")
                  .fontSize(16)
                  .margin({ left: 12 })
              }
              Image($r("app.media.right"))
                .height(16)
                .width(16)
                .objectFit(ImageFit.Contain)
            }
            .onClick(() => {
              this.pageStack.pushPathByName("WebApiPage", null)
              this.triggerVibration();
            })
            .height(52)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })


            Divider()
              .color($r("app.color.border"))
              .strokeWidth(0.5)
              .margin({ left: 16, right: 16 })

            Row() {
              Row() {
                Image($r("app.media.log"))
                  .height(24)
                  .width(24)
                  .objectFit(ImageFit.Contain)
                Text("Web更新日志")
                  .fontSize(16)
                  .margin({ left: 12 })
              }
              Image($r("app.media.right"))
                .height(16)
                .width(16)
                .objectFit(ImageFit.Contain)
            }
            .onClick(() => {
              this.pageStack.pushPathByName("WebLogPage", null)
              this.triggerVibration();
            })
            .height(52)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })
            Divider()
              .color($r("app.color.border"))
              .strokeWidth(0.5)
              .margin({ left: 16, right: 16 })
            Row() {
              Row() {
                Image($r("app.media.app_log"))
                  .height(24)
                  .width(24)
                  .objectFit(ImageFit.Contain)
                Text("App更新日志")
                  .fontSize(16)
                  .margin({ left: 12 })
              }
              Image($r("app.media.right"))
                .height(16)
                .width(16)
                .objectFit(ImageFit.Contain)
            }
            .onClick(() => {
              this.pageStack.pushPathByName("AppLogPage", null)
              this.triggerVibration();
            })
            .height(52)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })
            Divider()
              .color($r("app.color.border"))
              .strokeWidth(0.5)
              .margin({ left: 16, right: 16 })
            Row() {
              Row() {
                Image($r("app.media.approve"))
                  .height(24)
                  .width(24)
                  .objectFit(ImageFit.Contain)
                Text("用户协议")
                  .fontSize(16)
                  .margin({ left: 12 })
              }
              Image($r("app.media.right"))
                .height(16)
                .width(16)
                .objectFit(ImageFit.Contain)
            }
            .onClick(() => {
              this.pageStack.pushPathByName("AppLogPage", null)
              this.triggerVibration();
            })
            .height(52)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })
            Divider()
              .color($r("app.color.border"))
              .strokeWidth(0.5)
              .margin({ left: 16, right: 16 })
            Row() {
              Row() {
                Image($r("app.media.privacy"))
                  .height(24)
                  .width(24)
                  .objectFit(ImageFit.Contain)
                Text("隐私协议")
                  .fontSize(16)
                  .margin({ left: 12 })
              }
              Image($r("app.media.right"))
                .height(16)
                .width(16)
                .objectFit(ImageFit.Contain)
            }
            .onClick(() => {
              this.pageStack.pushPathByName("AppLogPage", null)
              this.triggerVibration();
            })
            .height(52)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })

          }
          .borderWidth(0.5)
          .borderColor($r("app.color.border"))
          .backgroundColor($r("app.color.background"))
          .borderRadius(16)
          .shadow({
            radius: 8,
            color: "#1a000000",
            offsetX: 0,
            offsetY: 2,
          })
          .width("90%")
          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))

          Text(`版本 ${APP_VERSION}`)
            .fontColor("#888")
            .fontSize(12)
            .margin(2)
          Blank().height(10)
          Text('Designed & Developed by Ray Chen (Rayawa)')
            .fontColor("#888")
            .fontSize(12)
            .margin(2)
          Text('Copyright ©2026. All rights reserved.')
            .fontColor("#888")
            .fontSize(12)
            .margin(2)
          Blank().height(10)
          Text("本应用备案域名：rayawa.top")
            .fontSize(12)
            .fontColor("#888")
            .margin(2)
          Column() {
            Text("京ICP备2025153453号")
              .fontSize(12)
              .fontColor($r("app.color.diff_content"))
              .onClick(() => {
                this.triggerVibration();
                this.openLink();
              })
          }.margin(2)



        }
        .width("100%")
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 30, bottom: 20 })

        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .width("100%")
        .height("100%")

        if (this.showWarn) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(Color.Transparent)
            .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .transition(
              TransitionEffect.OPACITY.animation({
                curve: curves.springMotion(0, 1),
                duration: 1000,
              }),
            )
            .onClick(() => {
              this.showWarn = false;
              this.triggerVibration();
            })
        }
        blurPopup({ isShow: this.showWarn }) { warn() }

      }
      .backgroundColor($r("app.color.backcolor"))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .width("100%")
      .height("100%")
    }
    .onBackPressed(() => {
      this.triggerVibration();
      if ( this.showWarn ) {
        this.showWarn = false;
        return true;
      } else {
        return false;
      }
    })
    .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20),
        },
        originalStyle: {
          backgroundStyle: {
            backgroundColor: $r("sys.color.ohos_id_color_background"),
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r("sys.color.font_primary"),
              subTitleColor: $r("sys.color.font_secondary"),
            },
            menuStyle: {
              backgroundColor: $r("sys.color.comp_background_tertiary"),
              iconColor: $r("sys.color.icon_primary"),
            },
            backIconStyle: {
              backgroundColor: $r("sys.color.comp_background_tertiary"),
              iconColor: $r("sys.color.icon_primary"),
            },
          },
        },
        scrollEffectStyle: {
          backgroundStyle: {
            backgroundColor: $r("sys.color.ohos_id_color_background_transparent"),
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r("sys.color.font_primary"),
              subTitleColor: $r("sys.color.font_secondary"),
            },
            menuStyle: {
              backgroundColor: $r("sys.color.comp_background_tertiary"),
              iconColor: $r("sys.color.icon_primary"),
            },
            backIconStyle: {
              backgroundColor: $r("sys.color.comp_background_tertiary"),
              iconColor: $r("sys.color.icon_primary"),
            },
          },
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        },
      },
      content: {
        title: {
          mainTitle: "关于应用",
        },
        backIcon: {
          action: () => {
            this.pageStack.pop()
            this.triggerVibration();
          },
        },
      },
    });
  }
}

@Builder
export function AboutPageBuilder(){
  about()
}
