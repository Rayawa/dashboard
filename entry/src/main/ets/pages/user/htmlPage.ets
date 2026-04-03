import { LengthMetrics } from '@kit.ArkUI';
import { HdsNavDestination, ScrollEffectType } from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { vibration } from '../../common/vibration';
import { webview } from '@kit.ArkWeb';
import { WebViewParam } from './about';

@Component
export struct HTML {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink("vibrationON") vibrationON: boolean = true;
  @StorageLink("immersiveTextureON") immersiveTextureON: boolean = true;
  private triggerVibration(): void {
    if (this.vibrationON) {
      vibration.dotVibration()
    }
  }
  controller: webview.WebviewController = new webview.WebviewController();
  @State params: WebViewParam = new WebViewParam('', '');

  aboutToAppear() {
    const pathInfo = this.pageStack.getParent()?.getParamByName('PrivacyPage') as Array<WebViewParam>;
    if (pathInfo && pathInfo.length > 0) {
      this.params = pathInfo[0];
    }
  }

  build() {
    HdsNavDestination() {
      Column() {
        Web({ src: this.params.url, controller: this.controller })
          .domStorageAccess(true)
          .fileAccess(true)
          .mixedMode(MixedMode.All)
          .width('100%')
          .layoutWeight(1)
      }
      .expandSafeArea(
        [SafeAreaType.SYSTEM],
        [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],
      )
      .width('100%')
      .height('100%')
    }
    .onBackPressed((e) => {
      this.triggerVibration();
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
        backIcon: {
          action: () => {
            this.triggerVibration();
            this.pageStack.pop()
          },
        },
      },
    });
  }
}

@Builder
export function HTMLBuilder() {
  HTML()
}
