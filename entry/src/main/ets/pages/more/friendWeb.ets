import { webview } from '@kit.ArkWeb';
import {
  hdsEffect,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  HdsSnackBar,
  ScrollEffectType,
  SnackBarIconOptions,
  SnackBarMessageOptions,
  SnackBarOperationOptions,
  SnackBarOperationType,
  SnackBarStyleOptions,
  TitleSize,
} from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { curves, LengthMetrics, PromptAction } from '@kit.ArkUI';
import { vibration } from '../../common/vibration';
import { BusinessError } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';
import { customUserAgent, DEFAULT_WINDOW_HEIGHT, DEFAULT_WINDOW_WIDTH } from '../../common/constants';
import {
  getButtonPosition,
  getVibrationEnabled,
  initializeSettings
} from '../../common/storage';
import { popPathSafely, pushPathSafely } from '../../common/safeNavigation';

@Component
export struct friendWeb {
  @Consume('pageStack') pageStack: NavPathStack;
  private PromptAction: PromptAction = this.getUIContext().getPromptAction();
  @State url: string = '';
  @State title: string = '';

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
  @LocalStorageLink('winWidth') winWidth: number = DEFAULT_WINDOW_WIDTH;
  @LocalStorageLink('winHeight') winHeight: number = DEFAULT_WINDOW_HEIGHT;
  @State buttonY: number = 300;
  @State private isRightHand: boolean = false;
  @State private funcTranslateX: number = 0;
  @State private funcScale: number = 1;
  @State private funcOpacity: number = 1;
  @State private isDragging: boolean = false; // 拖拽逻辑锁
  private buttonAnimationTimer: number = -1; // 按钮动画定时器管理

  private async loadSettings() {
    try {
      this.vibrationON = await getVibrationEnabled();
      this.buttonPositionRIGHT = await getButtonPosition();
    } catch (error) {
      console.error('[Dashboard][pages/more/friendWeb][ERROR]', "加载设置失败:", error);
    }
  }
  private uiContext: UIContext = this.getUIContext();
  private hdsSnackBar: HdsSnackBar = new HdsSnackBar(this.uiContext);
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

  async aboutToAppear() {
    initializeSettings();
    await this.loadSettings();
    this.isRightHand = this.buttonPositionRIGHT;
  }
  async onPageShow(): Promise<void> {
    setTimeout(() => {
      this.hdsSnackBar.show(this.icon, this.message, this.operation, this.style);
    },1000)
  }
  aboutToDisappear() {
    if (this.buttonAnimationTimer !== -1) { clearTimeout(this.buttonAnimationTimer); this.buttonAnimationTimer = -1; }
  }

  build() {
    HdsNavDestination() {
      Stack(){
        if (this.isLoading) {
          Progress({ value: this.progress, total: 100 })
            .width("100%")
            .height(90)
            .position({ y: 5 })
            .zIndex(99)
            .accessibilityText(`友情链接网页加载进度百分之${this.progress}`);
        }
        Scroll(this.scroller) {
          Column(){
            Blank()
              .height(40)
              .width("100%")
              .expandSafeArea(
                [SafeAreaType.SYSTEM],
                [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],)
            Web({
              src: 'about:blank',
              controller: this.web_controller,
              renderMode: RenderMode.SYNC_RENDER,
            })
              .id(`HmDashboard_web_friends`)
              .onControllerAttached(() => {
                try {
                  this.web_controller.setCustomUserAgent(customUserAgent);
                  if (this.url !== "") {
                    this.web_controller.loadUrl(this.url);
                  }
                } catch (e) {
                  console.error('[Dashboard][pages/more/friendWeb][ERROR]', `WebController attach error: ${e}`);
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
              .accessibilityText(`${this.title || '友情链接'}网页内容`)
          }

        }
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .accessibilityText(`可滚动的${this.title || '友情链接'}网页`)
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
            .accessibilityText('友情链接网页回到顶部')
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
                  console.warn('[Dashboard][pages/more/friendWeb][WARN]', `网页加载过程异常: ${error}`);
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
            .accessibilityText(this.isLoading ? '停止加载友情链接网页' : '刷新友情链接网页')
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
  .titleMode(HdsNavDestinationTitleMode.MINI)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      if(this.vibrationON) vibration.dotVibration()
      if (this.web_controller.accessStep(-1)) {
        console.info('[Dashboard][pages/more/friendWeb][INFO]', "网页可以返回，执行后退");
        this.web_controller.backward();
        this.PromptAction.showToast({ message: "返回上一页", duration: 1000 });
        return true;
      } else {
        return false;
      }
    })

    .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: false,
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
          mainTitle: this.title,
          mainTitleSize: TitleSize.TITLE_S,
        },
        menu: {

          value: [
            {
              content: {
                label: '教程',
                icon: $r('sys.symbol.questionmark_circle'),
                isEnabled: true,
                action: () => {
                  if (this.vibrationON) vibration.dotVibration();
                  pushPathSafely(this.pageStack, 'TutorialPage');
                },
              },
            },
            {
              content: {
                label: "在浏览器打开",
                icon: $r("sys.symbol.worldclock"),
                isEnabled: true,
                action: async () => {
                  if(this.vibrationON) vibration.dotVibration()
                  const url = this.url;
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
                    console.error('[Dashboard][pages/more/friendWeb][ERROR]', "打开链接失败:", (error as BusinessError).message);
                    this.PromptAction.showToast({ message: "打开链接失败", duration: 1000 });
                  }
                },
              },
            },
          ],
        },
        backIcon: {
          action: () => {
            if(this.vibrationON) vibration.dotVibration()
            popPathSafely(this.pageStack, 'pages/more/friendWeb')
          },
        },
      },
    })
    .onReady((context: NavDestinationContext) => {
      const params = context.pathInfo.param as Record<string, string>;
      if (params) {
        this.url = params.url;
        this.title = params.title;
        console.info('[Dashboard][pages/more/friendWeb][INFO]', `成功加载网页: ${this.title}, 地址: ${this.url}`);
      }
    })
    .accessibilityText(`${this.title || '友情链接'}网页导航页`)
  }
}

@Builder
export function FriendPageWebBuilder(){
  friendWeb()
}
