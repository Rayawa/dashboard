import { webview } from '@kit.ArkWeb';
import { motion } from '@kit.MultimodalAwarenessKit';
import {
  hdsEffect, HdsNavigation, HdsNavigationTitleMode, ScrollEffectType
} from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { curves, display, LengthMetrics, PromptAction } from '@kit.ArkUI';
import { vibration } from '../common/vibration';
import { BusinessError } from '@kit.BasicServicesKit';
import { WebShareManager } from '../common/shareControl';
import { customUserAgent } from '../common/constants';
import {
  getButtonPosition,
  getHoldCheckEnabled,
  getVibrationEnabled,
  initializeSettings
} from '../common/storage';
import { harmonyShare } from '@kit.ShareKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct continueWeb {
  private PromptAction: PromptAction = this.getUIContext().getPromptAction();
  private shareManager?: WebShareManager;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @StorageLink('pageUrl') @Watch('onUrlChanged') url: string = '';
  @StorageLink('scrollDistance') scrollDistance: number = 0;
  onUrlChanged() {
    if (this.url && this.web_controller) {
      try {
        this.web_controller.loadUrl(this.url);
      } catch (e) {
        console.error('loadUrl failed:', e);
      }
    }
  }

  @State progress: number = 0;
  @State showButton: boolean = true;
  @State startY: number = 0;
  @State isPressed1: boolean = false;
  @State isPressed2: boolean = false;
  @State touchX: number = 0;
  @State touchY: number = 0;
  @StorageLink("vibrationON") vibrationON: boolean = true;
  @StorageLink("buttonPositionRIGHT") buttonPositionRIGHT: boolean = false;
  @StorageLink("immersiveTextureON") immersiveTextureON: boolean = false;

  private scroller: Scroller = new Scroller();
  private web_controller: webview.WebviewController = new webview.WebviewController();
  @State scrollMode: NestedScrollMode = NestedScrollMode.PARENT_FIRST;
  @State mode: WebDarkMode = WebDarkMode.Auto;
  @State isLoading: boolean = false;
  @StorageLink("holdCheckON") @Watch("onHoldCheckChanged") holdCheckON: boolean = false;
  onHoldCheckChanged() {
    if (this.holdCheckON) {
      this.subscribeHoldingHand();
    } else {
      this.unsubscribeHoldingHand();
    }
  }
  @StorageLink('winWidth') winWidth: number = 1260;
  @StorageLink('winHeight') winHeight: number = 2224;
  @State buttonY: number = 300;
  @State private isRightHand: boolean = false;
  @State private funcTranslateX: number = 0;
  @State private funcScale: number = 1;
  @State private funcOpacity: number = 1;
  @State private isDragging: boolean = false; // 拖拽逻辑锁
  private lastSwitchTime: number = 0;
  private holdingHandCallback: Callback<motion.HoldingHandStatus> | null = null;
  private buttonAnimationTimer: number = -1; // 按钮动画定时器管理
  subscribeHoldingHand() {
    if (this.holdingHandCallback !== null) {
      return;
    }
    try {
      if (canIUse('SystemCapability.MultimodalAwareness.Motion')) {
        this.holdingHandCallback = (data: motion.HoldingHandStatus) => {
          if (this.isDragging) return;
          const isNowRightHand = data === motion.HoldingHandStatus.RIGHT_HAND_HELD;
          if (isNowRightHand !== this.isRightHand) {
            const currentTime = Date.now();
            if (currentTime - this.lastSwitchTime >= 2000) {
              this.lastSwitchTime = currentTime;
              this.getUIContext().animateTo({
                duration: 200,
                curve: Curve.FastOutSlowIn,
                onFinish: () => {
                  this.isRightHand = isNowRightHand;
                  this.funcTranslateX = isNowRightHand ? 120 : -120;
                  this.getUIContext().animateTo({
                    duration: 300,
                    curve: curves.springMotion(0.4, 0.8)
                  }, () => {
                    this.funcTranslateX = 0;
                    this.funcScale = 1;
                    this.funcOpacity = 1;
                  });
                }
              }, () => {
                this.funcTranslateX = this.isRightHand ? 120 : -120;
                this.funcScale = 0.3;
                this.funcOpacity = 0;
              });
            } else {
              console.info('未满2秒，拦截频繁握持手势切换');
            }
          }
          console.info(`握持手状态变化: ${data}`);
        };
        motion.on('holdingHandChanged', this.holdingHandCallback);
        console.info('成功订阅握持手状态变化');
      } else {
        this.buttonPositionRIGHT = false;
        console.warn('当前设备不支持智感握持能力');
      }
    } catch (e) {
      console.error('订阅握持手状态变化失败:', e);
    }
  }
  unsubscribeHoldingHand() {
    if (this.holdingHandCallback !== null) {
      try {
        motion.off('holdingHandChanged', this.holdingHandCallback);
        this.holdingHandCallback = null;
        console.info('已成功取消订阅握持手状态变化');
      } catch (e) {
        console.error('取消订阅握持手状态变化失败:', e);
      }
    }
  }

  private async loadSettings() {
    try {
      this.vibrationON = await getVibrationEnabled();
      this.holdCheckON = await getHoldCheckEnabled();
      this.buttonPositionRIGHT = await getButtonPosition();
    } catch (error) {
      console.error("加载设置失败:", error);
    }
  }
  async aboutToAppear() {
    initializeSettings();
    await this.loadSettings();
    this.isRightHand = this.buttonPositionRIGHT;
    if (this.holdCheckON) this.subscribeHoldingHand();
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
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
    console.log("continueWebReport",this.url," ",this.scrollDistance)
    //分享
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.shareManager = WebShareManager.getInstance(context);
    this.shareManager.enablePassiveShare();
    this.context.eventHub.on("onFocus", () => {
      this.shareManager?.enablePassiveShare();
    });
    this.context.eventHub.on("onBackGround", () => {
      this.onBackGround();
      this.shareManager?.disablePassiveShare();
    });
  }

  private backToMain() {
    if(this.vibrationON) vibration.dotVibration()
    this.getUIContext().getRouter().replaceUrl({
      url: 'pages/Dashboard'
    }).catch((err: BusinessError) => {
      console.error(`Failed to jump to Dashboard. Code: ${err.code}`);
    })
  }
  onBackPress(): boolean | void {
    this.backToMain()
    return true;
  }

  aboutToDisappear() {
    this.shareManager?.disablePassiveShare();
    const hostContext = this.context;
    hostContext.eventHub.off("onFocus");
    hostContext.eventHub.off("onBackGround");
    harmonyShare.on("knockShare", (sharableTarget: harmonyShare.SharableTarget) => {
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    });
    if (this.buttonAnimationTimer !== -1) { clearTimeout(this.buttonAnimationTimer); this.buttonAnimationTimer = -1; }
    this.unsubscribeHoldingHand(); // 取消订阅握持手
  }
  onBackGround() {
    harmonyShare.on("knockShare", (sharableTarget: harmonyShare.SharableTarget) => {
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    });
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
              .height(40)
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
              .id(`HmDashboard_onContinue`)
              .onControllerAttached(() => {
                try {
                  if (this.url !== "") {
                    this.web_controller.loadUrl(this.url);
                  }
                  this.web_controller.setCustomUserAgent(customUserAgent);
                } catch (e) {
                  console.error(`WebController attach error: ${e}`);
                }
              })
              .onPageBegin(() => (this.isLoading = true))
              .onPageEnd(() => {
                this.isLoading = false;
                if (this.scrollDistance > 0) {
                  let attempts = 0;
                  const maxAttempts = 10;
                  const tryScroll = () => {
                    this.scroller.scrollTo({
                      xOffset: 0,
                      yOffset: this.scrollDistance,
                      animation: { duration: 150, curve: Curve.Ease }
                    });
                    if (Math.abs(this.scroller.currentOffset().yOffset - this.scrollDistance) > 5 && attempts < maxAttempts) {
                      attempts++;
                      setTimeout(tryScroll, 100);
                    }
                  };

                  setTimeout(tryScroll, 100);
                }
              })

              .onProgressChange((p) => (this.progress = p.newProgress))
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
              .metaViewport(true)

          }

        }
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        // ==========================悬浮按钮==========================
        if (this.showButton) {
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
              if (this.vibrationON) vibration.dotVibration()
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
                if (this.vibrationON) vibration.dotVibration()
              } else {
                this.web_controller.refresh();
                try {
                  Promise.all([
                    this.web_controller.removeCache(true),
                    this.web_controller.removeCache(false),
                  ]);
                } catch (error) {
                  console.warn(`hm dashboard e: ${error}`);
                }
                this.isLoading = true;
                if (this.vibrationON) vibration.dotVibration()
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
                  this.buttonAnimationTimer = -1;
                }, 3000);
              }
            })
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
            x: this.isRightHand ? (this.getUIContext().px2vp(this.winWidth) - 45 - 8) : 8,
            y: this.buttonY
          })
          .translate({ x: this.funcTranslateX, y: 0 })
          .scale({ x: this.funcScale, y: this.funcScale })
          .opacity(this.funcOpacity)
          .gesture(
            GestureGroup(GestureMode.Exclusive,
              SwipeGesture({ direction: SwipeDirection.Horizontal })
                .onAction((move: GestureEvent | undefined) => {
                  if (move) {
                    const offset = this.isRightHand ? 120 : -120;
                    this.getUIContext().animateTo({
                      duration: 300,
                      curve: Curve.FastOutSlowIn,
                      onFinish: () => {
                        this.showButton = false;
                        this.funcTranslateX = 0;
                        this.funcOpacity = 1;
                        this.funcScale = 1;
                      }
                    }, () => {
                      this.funcTranslateX = offset;
                      this.funcOpacity = 0;
                      this.funcScale = 0.8;
                    });
                  }
                }),

              PanGesture({ direction: PanDirection.Vertical })
                .onActionStart(() => {
                  this.isDragging = true;
                  this.startY = this.buttonY;
                })
                .onActionUpdate((event: GestureEvent) => {
                  let nextY = this.startY + event.offsetY;
                  const topLimit = 100;
                  const bottomLimit = this.getUIContext().px2vp(this.winHeight) - 140;
                  if (nextY > bottomLimit) {
                    nextY = bottomLimit;
                  } else if (nextY < topLimit) {
                    nextY = topLimit;
                  }
                  this.buttonY = nextY;
                })
                .onActionEnd(() => {
                  this.isDragging = false;
                  const topLimit = 100;
                  const bottomLimit = this.getUIContext().px2vp(this.winHeight) - 140;
                  if (this.buttonY >= bottomLimit) {
                    this.PromptAction.showToast({ message: "不能再往下啦", duration: 500 });
                  } else if (this.buttonY <= topLimit) {
                    this.PromptAction.showToast({ message: "不能再往上啦", duration: 500 });
                  }
                })
                .onActionCancel(() => {
                  this.isDragging = false;
                })
            )
          )
        }
        if (!this.showButton) {
          Column()
            .backgroundColor(Color.Transparent)
            .height("100%")
            .width(20)
            .zIndex(5)
            .position({ x: 0, y: 0 })
            .gesture(
              TapGesture()
                .onAction((event: GestureEvent) => {
                  this.showButton = true;
                  const touchY = event.fingerList[0].localY - 50;
                  const topLimit = 100;
                  const bottomLimit = this.getUIContext().px2vp(this.winHeight) - 140;
                  this.buttonY = Math.min(Math.max(touchY, topLimit), bottomLimit);

                  const offset = this.isRightHand ? 120 : -120;
                  this.funcTranslateX = offset;
                  this.funcOpacity = 0;
                  this.funcScale = 0.8;
                  setTimeout(() => {
                    this.getUIContext().animateTo({ duration: 300, curve: curves.springMotion(0.4, 0.8) }, () => {
                      this.funcTranslateX = 0;
                      this.funcOpacity = 1;
                      this.funcScale = 1;
                    });
                  }, 0);
                  if (this.vibrationON)  vibration.dotVibration();
                })
            );
          Column()
            .backgroundColor(Color.Transparent)
            .height("100%")
            .width(20)
            .zIndex(5)
            .position({ x: this.getUIContext().px2vp(this.winWidth) - 20, y: 0 })
            .gesture(
              TapGesture()
                .onAction((event: GestureEvent) => {
                  this.showButton = true;
                  const touchY = event.fingerList[0].localY - 50;
                  const topLimit = 100;
                  const bottomLimit = this.getUIContext().px2vp(this.winHeight) - 140;
                  this.buttonY = Math.min(Math.max(touchY, topLimit), bottomLimit);

                  const offset = this.isRightHand ? 120 : -120;
                  this.funcTranslateX = offset;
                  this.funcOpacity = 0;
                  this.funcScale = 0.8;
                  setTimeout(() => {
                    this.getUIContext().animateTo({ duration: 300, curve: curves.springMotion(0.4, 0.8) }, () => {
                      this.funcTranslateX = 0;
                      this.funcOpacity = 1;
                      this.funcScale = 1;
                    });
                  }, 0);
                  if (this.vibrationON)  vibration.dotVibration();
                })
            );
        }
      }
      .backgroundColor($r("app.color.backcolor"))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .navBarWidth("100%")
    .titleMode(HdsNavigationTitleMode.MINI)
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
          mainTitle: "Dashboard应用看板",
        },
        menu: {
          value: [
            {
              content: {
                label: "share",
                icon: $r("sys.symbol.share"),
                isEnabled: true,
                action: () => {
                  if(this.vibrationON) vibration.dotVibration()
                  this.shareManager?.showSystemShare(this.url);
                },
              },
            },
          ]
        },
        backIcon: {
          action: () => {
            this.backToMain()
          },
        },
      },
    });
  }

}