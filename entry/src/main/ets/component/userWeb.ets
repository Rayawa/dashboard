import { webview } from '@kit.ArkWeb';
import { common } from '@kit.AbilityKit';
import {
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
import { LengthMetrics, prompt, router } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { WebShareManager } from '../common/shareControl';
import { harmonyShare } from '@kit.ShareKit';

@Component
export struct userWeb {
  @Prop url: string = '';
  @Prop title: string = '';

  @StorageLink("vibrationON") vibrationON: boolean = true;
  @State progress: number = 0;
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
  private shareManager?: WebShareManager;
  private context = getContext(this) as common.UIAbilityContext;
  @State isContinuation: boolean = false;
  aboutToAppear() {
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

  onBackGround() {
    harmonyShare.on("knockShare", (sharableTarget: harmonyShare.SharableTarget) => {
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    });
  }

  onBackPress(): boolean | void {
    if (this.web_controller.accessStep(-1)) {
      console.info("网页可以返回，执行后退");
      this.web_controller.backward();
      this.triggerVibration();
      prompt.showToast({ message: "返回上一页", duration: 1000 });
      return true;
    } else {
      return false;
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

          Web({
            src: this.url,
            controller: this.web_controller,
            renderMode: RenderMode.SYNC_RENDER,
          })
            .id(`HmDashboard_web_api`)
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
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
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
                label: "share",
                icon: $r("sys.symbol.share"),
                isEnabled: true,
                action: () => {
                  this.shareManager?.showSystemShare();
                  this.triggerVibration();
                },
              },
            },
            {
              content: {
                label: "refresh",
                icon: this.isLoading
                  ? $r("sys.symbol.xmark_circle")
                  : $r("sys.symbol.arrow_clockwise"),
                isEnabled: true,
                action: () => {
                  if (this.isLoading) {
                    this.web_controller.stop();
                    this.isLoading = false;
                    this.triggerVibration();
                    prompt.showToast({
                      message: "已停止加载",
                      duration: 1000,
                    });
                  } else {
                    this.web_controller.refresh();
                    this.isLoading = true;
                    this.triggerVibration();
                    prompt.showToast({
                      message: "刷新中...",
                      duration: 1000,
                    });

                    setTimeout(() => {
                      if (this.isLoading) {
                        this.isLoading = false;
                      }
                    }, 3000);
                  }
                },
              },
            },
            {
              content: {
                label: "top",
                icon: $r("sys.symbol.arrow_up_to_line"),
                isEnabled: true,
                action: () => {
                  this.scroller.scrollTo({
                    xOffset: 0,
                    yOffset: 0,
                    animation: { duration: 300, curve: Curve.Ease },
                  });
                  prompt.showToast({
                    message: "回到顶部",
                    duration: 500,
                  });
                  this.triggerVibration();
                },
              },
            },
          ],
        },
        backIcon: {
          action: () => {
            router.back();
            this.triggerVibration();

          },
        },
      },
    });
  }
}
