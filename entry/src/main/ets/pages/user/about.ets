import { curves, display, LengthMetrics, PromptAction } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import { APP_VERSION, MIIT_ICP_URL, SBaseURL, TBaseURL } from '../../common/constants';
import { HdsNavDestination, ScrollEffectType } from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { vibration } from '../../common/vibration';
import { warn } from '../../component/warn';
import URL from '../../common/url';
import { fetchDashboardConfig } from '../../common/dashboardConfig';

export class WebViewParam {
  url: string | Resource;
  title: string;
  constructor(url: string | Resource, title: string) {
    this.url = url;
    this.title = title;
  }
}


@Component
struct about {
  @Consume('pageStack') pageStack: NavPathStack;
  private PromptAction: PromptAction = this.getUIContext().getPromptAction();
  @StorageLink("immersiveTextureON") immersiveTextureON: boolean = false;
  @StorageLink("vibrationON") vibrationON: boolean = true;
  @State showWarn: boolean = false;
  @State showTSite: boolean = false;
  private readonly effect: TransitionEffect = TransitionEffect.OPACITY.combine(
    TransitionEffect.move(TransitionEdge.BOTTOM),
  )
    .combine(TransitionEffect.scale({ x: 0, y: 1 }))
    .animation({ curve: curves.springMotion(0.7, 0.8), duration: 1000 });

  @State WVp: number = 376;
  @State HVp: number = 376;
  aboutToAppear() {
    fetchDashboardConfig().then((config) => {
      this.showTSite = config.showTSite;
    }).catch((error: Error) => {
      console.warn('[Dashboard][pages/user/about][WARN]', `Dashboard config load failed on about page: ${error.message}`);
      this.showTSite = false;
    });
    //获取屏幕尺寸
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.WVp = this.getUIContext().px2vp(displayInfo.width);
      this.HVp = this.getUIContext().px2vp(displayInfo.height);
    } catch (error) {
      this.WVp = 376;
      this.HVp = 376;
      console.warn('[Dashboard][pages/user/about][WARN]', `屏幕尺寸读取失败，使用默认布局尺寸: ${JSON.stringify(error)}`);
    }
  }

  build() {
    HdsNavDestination() {
      Stack() {
        Scroll(){
          Column() {
            Column() {
              Image($r("app.media.app_icon"))
                .height(100)
                .width(100)
                .borderRadius($r("sys.float.corner_radius_level6"))
              Text("Dashboard应用看板")
                .fontWeight(800)
                .fontSize(30)
                .margin({ top: 20 })
                .fontColor($r("app.color.diff_content"))
              Text("Harmony Dashboard")
                .fontWeight(600)
                .fontSize(20)
                .margin({ top: 10 })
            }.margin({ top: 60 })

            Divider().margin({ top: 20, bottom: 20 }).color($r("app.color.border"))

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
                if(this.vibrationON) vibration.dotVibration()
                this.showWarn = true;
              })
              .height(52)
              .width("100%")
              .justifyContent(FlexAlign.SpaceBetween)
              .padding({ left: 16, right: 16 })

              Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })

              AboutItem({
                icon: $r("app.media.api"),
                title: "API文档说明",
                onClickAction: () =>{
                  const APIURL = new URL("docs", SBaseURL)
                  let param = new WebViewParam(APIURL.toString(), 'API文档说明');
                  this.pageStack.pushPathByName("AboutWebPage", param);
                }
              })

              if (this.showTSite) {
                Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })

                AboutItem({
                  icon: $r("app.media.log"),
                  title: "Web更新日志",
                  onClickAction: () =>{
                    const changeLogURL = new URL("changelog", TBaseURL)
                    let param = new WebViewParam(changeLogURL.toString(), 'Web更新日志');
                    this.pageStack.pushPathByName("AboutWebPage", param);
                  }
                })
              }

              Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })

              AboutItem({
                icon: $r("app.media.app_log"),
                title: "App更新日志",
                onClickAction: () =>{
                  this.pageStack.pushPathByName("AppLogPage", null)
                }
              })

              // Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })
              //
              // AboutItem({
              //   icon: $r("app.media.approve"),
              //   title: "用户协议",
              //   onClickAction: () => {
              //     this.pageStack.pushPathByName("HTMLPage", new WebViewParam($rawfile('approve.html'), "用户协议"));
              //   }
              // })

              Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })

              AboutItem({
                icon: $r("app.media.privacy"),
                title: "隐私政策",
                onClickAction: () => {
                  this.pageStack.pushPathByName("HTMLPage", new WebViewParam($rawfile('privacy.html'), "隐私政策"));
                }
              })
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
              .margin({ top: 20, bottom: 10 })
              .color($r("app.color.border"))

            Text(`版本 ${APP_VERSION}`)
              .fontColor("#888")
              .fontSize(12)
              .margin(2)
            Blank().height(5)
            Text('Designed & Developed by Ray Chen (Rayawa)')
              .fontColor("#888")
              .fontSize(12)
              .margin(2)
            Text('Copyright ©️2026. All rights reserved.')
              .fontColor("#888")
              .fontSize(12)
              .margin(2)
            Blank().height(5)
            Text("本应用备案域名：rayawa.top")
              .fontSize(12)
              .fontColor("#888")
              .margin(2)
            Column() {
              Text("京ICP备2025153453号")
                .fontSize(12)
                .fontColor($r("app.color.diff_content"))
                .decoration({ type: TextDecorationType.Underline, color: $r('app.color.diff_content') })
                .onClick(async () => {
                  if(this.vibrationON) vibration.dotVibration()
                  const url = MIIT_ICP_URL.toString();
                  const ui_content = this.getUIContext();
                  try {
                    this.PromptAction.showToast({ message: "正在跳转...", duration: 500 });
                    let context = ui_content.getHostContext() as common.UIAbilityContext;
                    await context.startAbility({
                      action: "ohos.want.action.viewData",
                      entities: ["entity.system.browsable"],
                      uri: url,
                    } as Want);
                  } catch (error) {
                    console.error('[Dashboard][pages/user/about][ERROR]', "打开链接失败:", (error as BusinessError).message);
                    this.PromptAction.showToast({ message: "打开链接失败", duration: 1000 });
                  }
                })
            }.margin(2)

          }
          .width("100%")
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 30, bottom: 20 })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .height("100%")
        }.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.END]).width("100%").height("100%")
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
              if(this.vibrationON) vibration.dotVibration()
            })
        }
        warn({ isShow: this.showWarn }).transition(this.effect)
      }
      .backgroundColor($r("app.color.backcolor"))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .width("100%")
      .height("100%")
    }
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      if( this.vibrationON ) vibration.dotVibration()
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
        systemMaterialEffect: this.immersiveTextureON ? {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        } : undefined
      },
      content: {
        title: {
          mainTitle: "关于应用",
        },
        backIcon: {
          action: () => {
            if(this.vibrationON) vibration.dotVibration()
            this.pageStack.pop()
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

@Component
struct AboutItem {
  @Prop icon: Resource;
  @Prop title: string;
  @StorageProp("vibrationON") vibrationON: boolean = true;
  onClickAction: () => void = () => {};
  build() {
    Column() {
      Row() {
        Row() {
          Image(this.icon)
            .height(24)
            .width(24)
            .objectFit(ImageFit.Contain)
          Text(this.title)
            .fontSize(16)
            .margin({ left: 12 })
        }

        Image($r("app.media.right"))
          .height(16)
          .width(16)
          .objectFit(ImageFit.Contain)
      }
      .height(52)
      .width("100%")
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        if (this.vibrationON) {
          vibration.dotVibration();
        }
        this.onClickAction();
      })
    }
  }
}
