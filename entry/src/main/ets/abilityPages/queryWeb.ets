import { webview } from '@kit.ArkWeb';
import { motion } from '@kit.MultimodalAwarenessKit';
import {
  hdsEffect, HdsNavigation, ScrollEffectType
} from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { curves, display, LengthMetrics, PromptAction, router } from '@kit.ArkUI';
import { vibration } from '../common/vibration';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  getButtonPosition,
  getHoldCheckEnabled,
  getVibrationEnabled,
  initializeSettings
} from '../common/SettingsStorage';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct queryWeb {
  PromptAction: PromptAction = this.getUIContext().getPromptAction();
  @Prop url: string = '';

  @State progress: number = 0;
  @State showButton: boolean = true;
  @State buttonOnPageShow: boolean = false;
  @State startY: number = 0;
  @State isPressed1: boolean = false;
  @State isPressed2: boolean = false;
  @State touchX: number = 0;
  @State touchY: number = 0;
  @State isTouching: boolean = false;
  @StorageLink("vibrationON") vibrationON: boolean = true;
  @StorageLink("holdCheckON") holdCheckON: boolean = true;
  @State holdCheckTMP: boolean = false;
  @StorageLink("buttonPositionRIGHT") buttonPositionRIGHT: boolean = false;

  scroller: Scroller = new Scroller();
  private web_controller: webview.WebviewController = new webview.WebviewController();
  @State scrollMode: NestedScrollMode = NestedScrollMode.PARENT_FIRST;
  @State mode: WebDarkMode = WebDarkMode.Auto;
  @State isLoading: boolean = false;

  //动画与振动
  private triggerVibration(): void {
    if (this.vibrationON) {
      vibration.dotVibration()
    }
  }

  private buttonEffect: TransitionEffect = TransitionEffect.asymmetric(
    TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: 0, y: 0 }))
      .animation({ curve: curves.springMotion(0.9, 0.5), duration: 500 }),
    TransitionEffect.IDENTITY
  );
  //智感握持
  @State WVp: number = 376;
  @State HVp: number = 376;
  @State buttonY: number = 300;
  @State buttonShowX: number = 10;
  @State buttonHideX: number = -25 - 10;
  @State showButtonAnimation: boolean = true;
  holdingHandCallback: Callback<motion.HoldingHandStatus> = (data: motion.HoldingHandStatus) => {
    if (this.holdCheckON) {
      switch (data) {
        case 1: // 左手握持
          this.buttonShowX = 10;
          this.buttonHideX = -45 - 10;
          break;
        case 2: // 右手握持
          this.buttonShowX = this.WVp - 45 - 10;
          this.buttonHideX = this.WVp + 10;
          break;
        default:
          break;
      }
    }
  };

  private async loadSettings() {
    try {
      this.vibrationON = await getVibrationEnabled();
      this.holdCheckON = await getHoldCheckEnabled();
      this.buttonPositionRIGHT = await getButtonPosition();
      if(this.buttonPositionRIGHT){
        this.buttonShowX = this.WVp - 45 - 10;
        this.buttonHideX = this.WVp + 10;
      } else {
        this.buttonShowX = 10;
        this.buttonHideX = -45 - 10;
      }
    } catch (error) {
      console.error("加载设置失败:", error);
    }
  }
  async aboutToAppear() {
    //获取屏幕右边位置
    const displayInfo = display.getDefaultDisplaySync();
    const screenWidthVp = px2vp(displayInfo.width);
    const screenHeightVp = px2vp(displayInfo.height);
    this.WVp = screenWidthVp;
    this.HVp = screenHeightVp;
    initializeSettings();
    await this.loadSettings();
    const params = router.getParams() as Record<string, string>;
    if (params && params.url) {
      this.url = params.url;
    }
    else {
      const storageUrl = AppStorage.get<string>('queryUrlFromAbility');
      if (storageUrl) {
        this.url = storageUrl;
        AppStorage.setOrCreate('queryUrlFromAbility', '');
      }
    }
    //握持监听
    try {
      motion.on("holdingHandChanged", this.holdingHandCallback);
    } catch (err) {
      const error = err as BusinessError;
      console.error("订阅失败，错误码: " + error.code);
    }
    this.buttonOnPageShow = false;
    this.buttonPositionRIGHT = await getButtonPosition();
    if(this.buttonPositionRIGHT){
      this.buttonShowX = this.WVp - 45 - 10;
      this.buttonHideX = this.WVp + 10;
    } else {
      this.buttonShowX = 10;
      this.buttonHideX = -45 - 10;
    }
    setTimeout(() => {
      this.buttonOnPageShow = true;
    }, 500);
  }

  @State firstBackTime: number = 0;
  private waitTime: number = 2000;
  private closePage() {
    const context = getContext(this) as common.UIAbilityContext;
    context.terminateSelf().then(() => {
      console.info('Ability 销毁指令发送成功');
    }).catch((err: BusinessError) => {
      console.error(`销毁失败: ${err.code}`);
    });
  }
  onBackPress(): boolean | void {
    const currentTime = new Date().getTime();
    if (currentTime - this.firstBackTime > this.waitTime) {
      this.firstBackTime = currentTime;
      this.PromptAction.showToast({ message: "再按一次退出", duration: this.waitTime });
      this.triggerVibration()
      return true;
    } else {
      this.triggerVibration()
      this.closePage()
      return false;
    }
  }

  aboutToDisappear() {
    try {
      motion.off("holdingHandChanged", this.holdingHandCallback);
    } catch (err) {
      const error = err as BusinessError;
      console.error("Motion off failed: " + error.code);
    }
  }
  build() {
    HdsNavigation() {
      Stack(){
        if (this.isLoading) {
          Progress({ value: this.progress, total: 100 })
            .width("100%")
            .height(90)
            .position({ y: 5 })
            .zIndex(99);
        }
        Scroll(this.scroller) {
          Column() {
            Blank()
              .height(10)
              .width("100%")
              .expandSafeArea(
                [SafeAreaType.SYSTEM],
                [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],
              )
            Web({
              src: this.url,
              controller: this.web_controller,
              renderMode: RenderMode.SYNC_RENDER,
            })
              .id(`HmDashboard_web_user`)
              .onControllerAttached(() => {
                if (this.url !== "") {
                  this.web_controller.loadUrl(this.url);
                }
              })
              .layoutMode(WebLayoutMode.FIT_CONTENT)
              .nestedScroll({
                scrollForward: NestedScrollMode.SELF_FIRST,
                scrollBackward: NestedScrollMode.SELF_FIRST,
              })
              .expandSafeArea(
                [SafeAreaType.SYSTEM],
                [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],
              )
              .domStorageAccess(true)
              .darkMode(this.mode)
              .forceDarkAccess(true)
              .width("100%")
              .backgroundColor($r("app.color.backcolor"))
              .onProgressChange((p) => (this.progress = p.newProgress))
              .onPageBegin(() => (this.isLoading = true))
              .onPageEnd(() => (this.isLoading = false))
              .metaViewport(true)
          }

        }
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        // ==========================悬浮按钮==========================
        if(this.buttonOnPageShow){
          Column({ space: 10 }) {
            Button() {
              Image($r("app.media.arrow_up"))
                .width(24)
                .height(24)
            }
            .onTouch((event: TouchEvent) => {
              if (event && event.touches[0]) {
                if (event.type === TouchType.Down || event.type === TouchType.Move) {
                  this.isPressed1 = true;
                  this.touchX = event.touches[0].x;
                  this.touchY = event.touches[0].y;
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.isPressed1 = false;
                }
              }
            })
            .onClick(() => {
              this.scroller.scrollTo({
                xOffset: 0,
                yOffset: 0,
                animation: { duration: 300, curve: Curve.Ease },
              });
              this.triggerVibration();
              this.PromptAction.showToast({
                message: "回到顶部",
                duration: 500,
              });
            })
            .type(ButtonType.Circle)
            .width(45).height(45)
            .backgroundColor('rgba(255, 255, 255, 0.2)')
            .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN, { colorMode: ThemeColorMode.SYSTEM, adaptiveColor: AdaptiveColor.AVERAGE, scale: 1.0 })
            .linearGradientBlur(60, { fractionStops: [[0, 0], [0.5, 0.8], [1, 0]], direction: GradientDirection.Bottom })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pressShadow(this.isPressed1 ? hdsEffect.PressShadowType.BLEND_GRADIENT : hdsEffect.PressShadowType.NONE)
              .pointLight({
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
                options: {
                  color: $r('app.color.light_color'),
                  intensity: this.isPressed1 ? 40.0 : 0.2,
                  height: 30.0,
                } as hdsEffect.PointLightOptions
              })
              .buildEffect())
            .border({
              width: 1,
              color: $r('app.color.button_border')
            })
            .borderRadius(22.5)

            Button() {
              Image(this.isLoading ? $r("app.media.stop") : $r("app.media.refresh"))
                .width(24)
                .height(24)
            }
            .onTouch((event: TouchEvent) => {
              if (event && event.touches[0]) {
                if (event.type === TouchType.Down || event.type === TouchType.Move) {
                  this.isPressed2 = true;
                  this.touchX = event.touches[0].x;
                  this.touchY = event.touches[0].y;
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.isPressed2 = false;
                }
              }
            })
            .onClick(() => {
              if (this.isLoading) {
                this.web_controller.stop();
                this.isLoading = false;
                this.triggerVibration();
                this.PromptAction.showToast({
                  message: "已停止加载",
                  duration: 1000,
                });
              } else {
                this.web_controller.refresh();
                try {
                  Promise.all([
                    this.web_controller.removeCache(true),
                    this.web_controller.removeCache(false),
                  ]);
                } catch (error) {
                  // man! what can I say
                  console.warn(`hm dashboard 清除缓存失败 e: ${error}`);
                }
                this.isLoading = true;
                this.triggerVibration();
                this.PromptAction.showToast({
                  message: "刷新中...",
                  duration: 1000,
                });
                setTimeout(() => {
                  if (this.isLoading) {
                    this.isLoading = false;
                    this.PromptAction.showToast({
                      message: "加载超时！",
                      duration: 1000,
                    });
                  }
                }, 3000);
              }
            })
            .shadow(ShadowStyle.OUTER_DEFAULT_LG)
            .type(ButtonType.Circle)
            .width(45).height(45)
            .backgroundColor('rgba(255, 255, 255, 0.2)')
            .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN, { colorMode: ThemeColorMode.SYSTEM, adaptiveColor: AdaptiveColor.AVERAGE, scale: 1.0 })
            .linearGradientBlur(60, { fractionStops: [[0, 0], [0.5, 0.8], [1, 0]], direction: GradientDirection.Bottom })
            .shadow(ShadowStyle.OUTER_DEFAULT_MD)
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pressShadow(this.isPressed2 ? hdsEffect.PressShadowType.BLEND_GRADIENT : hdsEffect.PressShadowType.NONE)
              .pointLight({
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
                options: {
                  color: $r('app.color.light_color'),
                  intensity: this.isPressed2 ? 40.0 : 0.2,
                  height: 30.0,
                } as hdsEffect.PointLightOptions
              })
              .buildEffect())
            .border({
              width: 1,
              color: $r('app.color.button_border')
            })
            .borderRadius(22.5)
          }
          .position({
            x: this.showButton ? this.buttonShowX : this.buttonHideX,
            y: this.buttonY,
          })
          .animation(
            this.showButtonAnimation
              ? { curve: curves.springMotion(0.8, 0.8), duration: 400 }
              : { duration: 0 },
          )
          .transition(this.buttonEffect)
          .gesture(
            SwipeGesture({ direction: SwipeDirection.Horizontal }).onAction(
              (move: GestureEvent | undefined) => {
                if (move) {
                  this.showButton = false;
                  setTimeout(() => {
                    this.showButtonAnimation = false;
                  }, 300);
                }
              },
            ),
          )
          .gesture(
            PanGesture({ direction: PanDirection.Vertical })
              .onActionStart(() => {
                if(this.holdCheckON){ this.holdCheckON = false; this.holdCheckTMP = true; }
                this.showButtonAnimation = false;
                this.startY = this.buttonY;
              })
              .onActionUpdate((event: GestureEvent) => {
                //判断实际位置
                let nextY = this.startY + event.offsetY;
                if (nextY > 660) {
                  nextY = 660;
                } else if (nextY < 70) {
                  nextY = 70;
                }
                this.buttonY = nextY;
              })
              .onActionEnd(() => {
                this.showButtonAnimation = true;
                if(this.holdCheckTMP){ this.holdCheckON = true; }
                if (this.buttonY >= 660) {
                  this.PromptAction.showToast({ message: "不能再往下啦", duration: 500 });
                } else if (this.buttonY <= 70) {
                  this.PromptAction.showToast({ message: "不能再往上啦", duration: 500 });
                }
              }),
          )
        }
        if (!this.showButton) {
          Column()
            .backgroundColor(Color.Transparent)
            .height("100%")
            .width(15)
            .zIndex(5)
            .position({ x: 0 })
            .onClick(() => {
              this.showButtonAnimation = true;
              this.showButton = true;
              this.triggerVibration();
            });
          Column()
            .backgroundColor(Color.Transparent)
            .height("100%")
            .width(15)
            .zIndex(5)
            .position({ x: this.WVp - 15 })
            .onClick(() => {
              this.showButtonAnimation = true;
              this.showButton = true;
              this.triggerVibration();
            });
        }
      }
      .backgroundColor($r("app.color.backcolor"))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
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
          mainTitle: "查询结果",
        },
        backIcon: {
          action: () => {
            this.triggerVibration();
            this.closePage()
          },
        },
      },
    });
  }

}