import { LengthMetrics, PromptAction, promptAction } from '@kit.ArkUI';
import { HdsNavDestination, ScrollEffectType } from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { vibration } from '../../common/vibration';
import { webview } from '@kit.ArkWeb';
import { WebViewParam } from './about';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { setFirstLaunch } from '../../common/storage';
import { privacyManager } from '@kit.StoreKit';

@Component
export struct HTML {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink("vibrationON") vibrationON: boolean = true;
  @StorageLink("immersiveTextureON") immersiveTextureON: boolean = false;
  controller: webview.WebviewController = new webview.WebviewController();
  @State params: WebViewParam = new WebViewParam('', '');

  aboutToAppear() {
    const pathInfo = this.pageStack.getParamByName('HTMLPage') as Array<WebViewParam>;
    if (pathInfo && pathInfo.length > 0) {
      this.params = pathInfo[0];
    }
  }
  private PromptAction: PromptAction = this.getUIContext().getPromptAction();

  private async closePage() {
    this.PromptAction.showDialog({
      title: `撤销${this.params.title}`,
      message: '撤销后应用将清除本地缓存退出，确定要撤销吗？',
      buttons: [
        { text: '取消', color: '#1E6FCD' },
        { text: '撤销', color: '#E60012' }
      ]
    }).then(async (result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        try {
          await setFirstLaunch(true);
          const context = getContext(this) as common.UIAbilityContext;
          privacyManager.disableService();
          this.PromptAction.showToast({ message: `${this.params.title}已撤销，即将退出` });
          context.terminateSelf().then(() => {
            console.info('Ability 销毁指令发送成功');
          }).catch((err: BusinessError) => {
            console.error(`销毁失败: ${err.code}`);
          });
        } catch (error) {
          const err = error as BusinessError;
          this.PromptAction.showToast({ message: `撤销失败: ${err.message} (Code: ${err.code})` });
        }
      }
    });
  }

  build() {
    HdsNavDestination() {
      Column() {
        Blank()
          .height(80)
          .width("100%")
          .expandSafeArea(
            [SafeAreaType.SYSTEM],
            [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],
          )
        Web({ src: this.params.url, controller: this.controller })
          .domStorageAccess(true)
          .fileAccess(true)
          .mixedMode(MixedMode.All)
          .width('100%')
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      if(this.vibrationON) vibration.dotVibration()
      this.pageStack.pop();
      return true;
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
          mainTitle: this.params.title,
        },
        menu: {
          value: [
            {
              content: {
                label: "recall",
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
            this.pageStack.pop()
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
