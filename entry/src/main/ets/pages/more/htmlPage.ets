import { LengthMetrics, PromptAction, promptAction } from '@kit.ArkUI';
import { HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType, TitleSize } from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { vibration } from '../../common/vibration';
import { webview } from '@kit.ArkWeb';
import { WebViewParam } from '../../common/types';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { setFirstLaunch } from '../../common/storage';
import { privacyManager } from '@kit.StoreKit';
import { showToastSafely } from '../../common/safeUi';
import { customUserAgent } from '../../common/constants';
import { getPathParamsSafely, popPathSafely } from '../../common/safeNavigation';

@Component
export struct HTML {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink("vibrationON") vibrationON: boolean = true;
  @StorageLink("immersiveTextureON") immersiveTextureON: boolean = false;
  controller: webview.WebviewController = new webview.WebviewController();
  @State params: WebViewParam = new WebViewParam('', '');
  @State private topPlaceholderHeight: number = 100;

  aboutToAppear() {
    const pathInfo = getPathParamsSafely<WebViewParam>(this.pageStack, 'HTMLPage', 'pages/more/htmlPage');
    if (pathInfo && pathInfo.length > 0) {
      this.params = pathInfo[0];
    }
  }
  private PromptAction: PromptAction = this.getUIContext().getPromptAction();

  private async closePage() {
    try {
      const result: promptAction.ShowDialogSuccessResponse = await this.PromptAction.showDialog({
        title: `撤销${this.params.title}`,
        message: '撤销后应用将清除本地缓存退出，确定要撤销吗？',
        buttons: [
          { text: '取消', color: $r('app.color.diff_content') },
          { text: '撤销', color: $r('app.color.v3_accent_red') }
        ]
      });
      if (result.index === 1) {
        try {
          await setFirstLaunch(true);
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          privacyManager.disableService();
          showToastSafely(this.PromptAction, `${this.params.title}已撤销，即将退出`, 2000, 'HtmlPage');
          context.terminateSelf().then(() => {
            console.info('[Dashboard][pages/more/htmlPage][INFO]', 'Ability 销毁指令发送成功');
          }).catch((err: BusinessError) => {
            console.error('[Dashboard][pages/more/htmlPage][ERROR]', `销毁失败: ${err.code}`);
          });
        } catch (error) {
          const err = error as BusinessError;
          console.error('[Dashboard][pages/more/htmlPage][ERROR]', `撤销服务失败: ${err.message} (Code: ${err.code})`);
          showToastSafely(
            this.PromptAction,
            `撤销失败: ${err.message} (Code: ${err.code})`,
            2500,
            'HtmlPage',
          );
        }
      }
    } catch (error) {
      console.error('[Dashboard][pages/more/htmlPage][ERROR]', `撤销确认弹窗显示失败: ${JSON.stringify(error)}`);
      showToastSafely(this.PromptAction, '暂时无法打开确认窗口，请稍后重试', 2000, 'HtmlPage');
    }
  }

  build() {
    HdsNavDestination() {
      Column() {
          Blank()
            .height(this.topPlaceholderHeight)
            .width("100%")
            .expandSafeArea(
              [SafeAreaType.SYSTEM],
              [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],
            )
          Web({ src: this.params.url, controller: this.controller })
            .onControllerAttached(() => {
              try {
                this.controller.setCustomUserAgent(customUserAgent);
              } catch (error) {
                console.warn('[Dashboard][pages/more/htmlPage][WARN]',
                  `设置网页User-Agent失败: ${JSON.stringify(error)}`);
              }
            })
            .domStorageAccess(true)
            .fileAccess(true)
            .mixedMode(MixedMode.All)
            .onScroll((event) => {
              if (event) {
                const nextHeight = Math.max(0, 100 - Math.max(0, event.yOffset));
                if (Math.abs(nextHeight - this.topPlaceholderHeight) > 0.5) {
                  this.topPlaceholderHeight = nextHeight;
                }
              }
            })
            .width('100%')
            .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .accessibilityText('顶部占位会随正文滚动收起的协议页面')
    }
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .onBackPressed(() => {
      if(this.vibrationON) vibration.dotVibration()
      popPathSafely(this.pageStack, 'pages/more/htmlPage');
      return true;
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
          mainTitle: this.params.title,
          mainTitleSize: TitleSize.TITLE_S,
        },
        menu: {
          value: [
            {
              content: {
                label: "撤销隐私同意",
                icon: $r("sys.symbol.xmark_circle"),
                isEnabled: true,
                action: () => {
                  if(this.vibrationON) vibration.dotVibration()
                  this.closePage();
                },
              },
            },
          ],
        },
        backIcon: {
          action: () => {
            if(this.vibrationON) vibration.dotVibration()
            popPathSafely(this.pageStack, 'pages/more/htmlPage')
          },
        },
      },
    });
  }
}

@Builder
export function HTMLBuilder() {
  HTML().expandSafeArea(
    [SafeAreaType.SYSTEM],
    [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],)
}
