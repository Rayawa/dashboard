import { LengthMetrics, PromptAction, promptAction } from '@kit.ArkUI';
import { HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit';
import { vibration } from '../../common/vibration';
import { pageTransition } from '../../common/motion';
import { webview } from '@kit.ArkWeb';
import { WebViewParam } from '../../common/types';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { setFirstLaunch } from '../../common/storage';
import { privacyManager } from '@kit.StoreKit';
import { showToastSafely } from '../../common/safeUi';
import { customUserAgent, ROUTE_HTML_PAGE } from '../../common/constants';
import { getPathParamsSafely, popPathSafely } from '../../common/safeNavigation';
import {
  HDS_MATERIAL_LEVEL_GENTLE,
  HDS_MATERIAL_TYPE_ADAPTIVE,
  HDS_TITLE_SIZE_SMALL,
  SUPPORTS_HARMONY_API_23,
} from '../../common/platformCompatibility';

@Component
export struct LocalHtmlPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('vibrationLevel') vibrationLevel: number = 1;
  @StorageLink('immersiveMaterialLevel') immersiveMaterialLevel: number = HDS_MATERIAL_LEVEL_GENTLE;
  controller: webview.WebviewController = new webview.WebviewController();
  @State params: WebViewParam = new WebViewParam('', '');
  @State private topPlaceholderHeight: number = 100;

  aboutToAppear() {
    const pathInfo = getPathParamsSafely<WebViewParam>(this.pageStack, ROUTE_HTML_PAGE,
      'pages/more/LocalHtmlPage');
    if (pathInfo && pathInfo.length > 0) {
      this.params = pathInfo[0];
    }
  }
  private prompt: PromptAction = this.getUIContext().getPromptAction();

  private async closePage() {
    try {
      const result: promptAction.ShowDialogSuccessResponse = await this.prompt.showDialog({
        title: `撤销${this.params.title}`,
        message: '撤销后应用将清除本地缓存退出，确定要撤销吗？',
        buttons: [
          { text: '取消', color: $r('app.color.diff_content') },
          { text: '撤销', color: $r('app.color.v3_accent_red') }
        ]
      });
      if (result.index === 0 || result.index === 1) {
        if (this.vibrationLevel > 0) vibration.dotVibration();
      }
      if (result.index === 1) {
        try {
          await setFirstLaunch(true);
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          privacyManager.disableService();
          showToastSafely(this.prompt, `${this.params.title}已撤销，即将退出`, 2000, 'HtmlPage');
          context.terminateSelf().then(() => {
            console.info('[Dashboard][pages/more/LocalHtmlPage][INFO]', 'Ability 销毁指令发送成功');
          }).catch((err: BusinessError) => {
            console.error('[Dashboard][pages/more/LocalHtmlPage][ERROR]', `销毁失败: ${err.code}`);
          });
        } catch (error) {
          const err = error as BusinessError;
          console.error('[Dashboard][pages/more/LocalHtmlPage][ERROR]', `撤销服务失败: ${err.message} (Code: ${err.code})`);
          showToastSafely(
            this.prompt,
            `撤销失败: ${err.message} (Code: ${err.code})`,
            2500,
            'HtmlPage',
          );
        }
      }
    } catch (error) {
      console.error('[Dashboard][pages/more/LocalHtmlPage][ERROR]',
        `撤销确认弹窗显示失败: ${JSON.stringify(error)}`);
      showToastSafely(this.prompt, '暂时无法打开确认窗口，请稍后重试', 2000, 'HtmlPage');
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
                console.warn('[Dashboard][pages/more/LocalHtmlPage][WARN]',
                  `设置网页User-Agent失败: ${JSON.stringify(error)}`);
              }
            })
            .domStorageAccess(true)
            .fileAccess(true)
            .mixedMode(MixedMode.All)
            .overScrollMode(OverScrollMode.ALWAYS)
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
    .transition(pageTransition())
    .onBackPressed(() => {
      if(this.vibrationLevel > 0) vibration.backVibration()
      popPathSafely(this.pageStack, 'pages/more/LocalHtmlPage');
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
            backgroundColor: Color.Transparent,
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
            backgroundColor: Color.Transparent,
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
        systemMaterialEffect: SUPPORTS_HARMONY_API_23 ? {
          materialType: HDS_MATERIAL_TYPE_ADAPTIVE,
          materialLevel: this.immersiveMaterialLevel
        } : undefined
      },
      content: {
        title: {
          mainTitle: this.params.title,
          mainTitleSize: SUPPORTS_HARMONY_API_23 ? HDS_TITLE_SIZE_SMALL : undefined,
        },
        menu: {
          value: [
            {
              content: {
                label: "撤销隐私同意",
                icon: $r("sys.symbol.xmark_circle"),
                isEnabled: true,
                action: () => {
                  if(this.vibrationLevel > 0) vibration.dotVibration()
                  this.closePage();
                },
              },
            },
          ],
        },
        backIcon: {
          action: () => {
            if(this.vibrationLevel > 0) vibration.backVibration()
            popPathSafely(this.pageStack, 'pages/more/LocalHtmlPage')
          },
        },
      },
    });
  }
}

@Builder
export function HTMLBuilder() {
  LocalHtmlPage().expandSafeArea(
    [SafeAreaType.SYSTEM],
    [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],)
}
