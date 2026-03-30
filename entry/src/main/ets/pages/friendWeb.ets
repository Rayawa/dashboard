import { webview } from '@kit.ArkWeb';
import { motion } from '@kit.MultimodalAwarenessKit';
import {
  hdsEffect,
  HdsNavDestination,
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsSnackBar,
  ScrollEffectType,
  SnackBarIconOptions,
  SnackBarMessageOptions,
  SnackBarOperationOptions,
  SnackBarOperationType,
  SnackBarStyleOptions
} from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { curves, display, LengthMetrics, PromptAction } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';
import { harmonyShare } from '@kit.ShareKit';
import { WebShareManager } from '../common/shareControl';
import {
  getButtonPosition,
  getHoldCheckEnabled,
  getVibrationEnabled,
  initializeSettings
} from '../common/SettingsStorage';

@Component
export struct friendWeb {
  @Consume('pageStack') pageStack: NavPathStack;
  PromptAction: PromptAction = this.getUIContext().getPromptAction();

  @State url: string = '';
  @State title: string = '';

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
  private triggerVibration(): void {
    if (this.vibrationON) {
      vibrator.isSupportEffect("haptic.effect.hard", (err: BusinessError, state: boolean) => {
        if (err) {
          console.error(
            `Failed to query effect. Code: ${err.code}, message: ${err.message}`,
          );
          return;
        }
        console.info("Succeed in querying effect");
        if (state) {
          try {
            vibrator.startVibration(
              {
                type: "preset",
                effectId: "haptic.effect.hard",
                count: 1,
                intensity: 50,
              },
              { usage: "touch" },
              (error: BusinessError) => {
                if (error) {
                  console.error(
                    `Failed to start vibration. Code: ${error.code}, message: ${error.message}`,
                  );
                } else {
                  console.info("Succeed in starting vibration");
                }
              },
            );
          } catch (tryError) {
            console.error(`An unexpected error occurred in try block: ${tryError}`);
          }
        }
      });
    }
  }
  uiContext: UIContext = this.getUIContext();
  hdsSnackBar: HdsSnackBar = new HdsSnackBar(this.uiContext);
  icon: SnackBarIconOptions = {
    icon: $r('sys.symbol.exclamationmark_circle')
  }
  message: SnackBarMessageOptions = {
    title: "您正在访问其他站点",
    content: "网站设计与展示内容均与看板无关！",
  }
  operation: SnackBarOperationOptions = {
    operationType: SnackBarOperationType.TEXT_WITH_CLOSE,
  }
  style: SnackBarStyleOptions = {
    backgroundBlurStyle: BlurStyle.Thin,
    nextFocusId: 'button',
    duration: 7000
  }

  //动画与振动
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

  private shareManager?: WebShareManager;
  private context = getContext(this) as common.UIAbilityContext;
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
  async openLink() {
    const url = this.url;
    const ui_content = this.getUIContext();
    ui_content.showAlertDialog({
      title: "是否跳转到浏览器",
      message: `即将访问${this.title}`,
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
  async aboutToAppear() {
    //获取屏幕右边位置
    const displayInfo = display.getDefaultDisplaySync();
    const screenWidthVp = px2vp(displayInfo.width);
    const screenHeightVp = px2vp(displayInfo.height);
    this.WVp = screenWidthVp;
    this.HVp = screenHeightVp;
    initializeSettings();
    await this.loadSettings();
    //握持监听
    try {
      motion.on("holdingHandChanged", this.holdingHandCallback);
    } catch (err) {
      const error = err as BusinessError;
      console.error("订阅失败，错误码: " + error.code);
    }

    //分享
    const context = getContext(this) as common.UIAbilityContext;
    this.shareManager = WebShareManager.getInstance(context, this.web_controller);
    this.shareManager.enablePassiveShare();
    this.context.eventHub.on("onFocus", () => {
      this.shareManager?.enablePassiveShare();
    });
    this.context.eventHub.on("onBackGround", () => {
      this.onBackGround();
      this.shareManager?.disablePassiveShare();
    });
  }
  async onPageShow(): Promise<void> {
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
      console.log("buttonshow")
    }, 500);
    setTimeout(() => {
      this.hdsSnackBar.show(this.icon, this.message, this.operation, this.style);
    },1000)
  }
  onBackGround() {
    harmonyShare.on("knockShare", (sharableTarget: harmonyShare.SharableTarget) => {
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    });
  }
  aboutToDisappear() {
    this.shareManager?.disablePassiveShare();
    const hostContext = this.context;
    hostContext.eventHub.off("onFocus");
    hostContext.eventHub.off("onBackGround");
    harmonyShare.on("knockShare", (sharableTarget: harmonyShare.SharableTarget) => {
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    });
    try {
      motion.off("holdingHandChanged", this.holdingHandCallback);
    } catch (err) {
      const error = err as BusinessError;
      console.error("Motion off failed: " + error.code);
    }
  }

  onBackPress(): boolean | void {
    if (this.web_controller.accessStep(-1)) {
      console.info("网页可以返回，执行后退");
      this.web_controller.backward();
      this.triggerVibration();
      this.PromptAction.showToast({ message: "返回上一页", duration: 1000 });
      return true;
    } else {
      return false;
    }
  }

  build() {

      HdsNavDestination() {
        Stack(){
          if (this.isLoading) {
            Progress({ value: this.progress, total: 100 })
              .width("100%")
              .height(90)
              .position({ y: 5 })
              .zIndex(99);
          }
          Scroll(this.scroller) {
            Column(){
              Blank()
                .height(80)
                .width("100%")
                .expandSafeArea(
                  [SafeAreaType.SYSTEM],
                  [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],)
              Web({
                src: this.url,
                controller: this.web_controller,
                renderMode: RenderMode.SYNC_RENDER,
              })
                .id(`HmDashboard_web_friends`)
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
            mainTitle: this.title,
          },
          menu: {

            value: [
              {
                content: {
                  label: "openlink",
                  icon: $r("sys.symbol.worldclock"),
                  isEnabled: true,
                  action: () => {
                    this.triggerVibration();
                    this.openLink();
                  },
                },
              },
              {
                content: {
                  label: "share",
                  icon: $r("sys.symbol.share"),
                  isEnabled: true,
                  action: () => {
                    this.shareManager?.showSystemShare();
                    this.triggerVibration();
                  },
                },
              },
            ],
          },
          backIcon: {
            action: () => {
              this.triggerVibration();
              this.pageStack.pop()
            },
          },
        },
      })

    .onReady((context: NavDestinationContext) => {
      const params = context.pathInfo.param as Record<string, string>;
      if (params) {
        this.url = params.url;
        this.title = params.title;
        console.info(`成功加载网页: ${this.title}, 地址: ${this.url}`);
      }
    })
  }
}

@Builder
export function FriendPageWebBuilder(){
  friendWeb()
}
