import { common, Want } from '@kit.AbilityKit';
import { webview } from '@kit.ArkWeb';
import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import {
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  ScrollEffectType,
  TitleSize,
} from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { customUserAgent } from '../../common/constants';
import { popPathSafely } from '../../common/safeNavigation';
import { showToastSafely } from '../../common/safeUi';
import { vibration } from '../../common/vibration';
import { contentEnterTransition, pageTransition } from '../../common/motion';
import { WebShareManager } from '../../common/shareControl';
import type { WebShareData } from '../../common/shareControl';

export interface AboutWebParams {
  url: string;
  title: string;
}

@Component
struct aboutWeb {
  @Consume('pageStack') pageStack: NavPathStack;
  private controller: webview.WebviewController = new webview.WebviewController();
  private prompt: PromptAction = this.getUIContext().getPromptAction();
  @Prop url: string = '';
  @Prop title: string = '';
  @State progress: number = 0;
  @State loading: boolean = true;
  @State errorMessage: string = '';
  @State currentUrl: string = '';
  @StorageLink('vibrationLevel') vibrationLevel: number = 1;
  @StorageLink('immersiveMaterialLevel') immersiveMaterialLevel: hdsMaterial.MaterialLevel =
    hdsMaterial.MaterialLevel.GENTLE;
  private shareManager?: WebShareManager;

  aboutToAppear(): void {
    this.currentUrl = this.url;
    this.syncShareData();
  }

  aboutToDisappear(): void {
    this.shareManager?.clearShareDataProvider();
    this.shareManager?.disablePassiveShare();
  }

  private refresh(): void {
    if (this.vibrationLevel > 0) vibration.dotVibration();
    this.errorMessage = '';
    this.loading = true;
    try {
      this.controller.loadUrl(this.liveShareData().url);
    } catch (error) {
      console.error('[Dashboard][pages/more/aboutWeb][ERROR]', `刷新失败: ${JSON.stringify(error)}`);
      showToastSafely(this.prompt, '暂时无法刷新网页', 1600, 'AboutWeb');
    }
  }

  private async openBrowser(): Promise<void> {
    if (this.vibrationLevel > 0) vibration.dotVibration();
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: this.liveShareData().url,
      } as Want);
    } catch (error) {
      console.error('[Dashboard][pages/more/aboutWeb][ERROR]', `浏览器打开失败: ${JSON.stringify(error)}`);
      showToastSafely(this.prompt, '打开链接失败', 1600, 'AboutWeb');
    }
  }

  private liveShareData(): WebShareData {
    let url = this.currentUrl || this.url;
    try {
      const liveUrl = this.controller.getUrl();
      if (liveUrl && liveUrl !== 'about:blank') {
        url = liveUrl;
        this.currentUrl = liveUrl;
      }
    } catch (error) {
      console.warn('[Dashboard][pages/more/aboutWeb][WARN]',
        `读取实时分享地址失败，使用已记录地址: ${JSON.stringify(error)}`);
    }
    return {
      url,
      title: `${this.title || 'API 文档说明'}｜Harmony Dashboard`,
      description: url,
    };
  }

  private syncShareData(): void {
    if (!this.url) return;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const data = this.liveShareData();
    this.shareManager = WebShareManager.getInstance(context);
    this.shareManager.updateShareData(data.url, data.title, data.description,
      (): WebShareData => this.liveShareData());
    this.shareManager.enablePassiveShare();
  }

  private showShare(): void {
    if (this.vibrationLevel > 0) vibration.dotVibration();
    this.syncShareData();
    this.shareManager?.showSystemShare();
  }

  private goBack(): boolean {
    if (this.vibrationLevel > 0) vibration.backVibration();
    try {
      if (this.controller.accessBackward()) {
        this.controller.backward();
        return true;
      }
    } catch (error) {
      console.warn('[Dashboard][pages/more/aboutWeb][WARN]', `检查网页后退历史失败: ${JSON.stringify(error)}`);
    }
    popPathSafely(this.pageStack, 'pages/more/aboutWeb');
    return true;
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        Scroll() {
          Column() {
            Blank().height(100).width('100%')
            Web({ src: this.url, controller: this.controller, renderMode: RenderMode.SYNC_RENDER })
            .id('HmDashboard_ApiDocs')
            .width('100%')
            .layoutMode(WebLayoutMode.FIT_CONTENT)
            .backgroundColor($r('app.color.backcolor'))
            .onControllerAttached(() => {
              try {
                this.controller.setCustomUserAgent(customUserAgent);
              } catch (error) {
                this.errorMessage = '网页初始化失败';
                console.error('[Dashboard][pages/more/aboutWeb][ERROR]', `初始化失败: ${JSON.stringify(error)}`);
              }
            })
            .onProgressChange((event) => this.progress = event.newProgress)
            .onNavigationEntryCommitted((event) => {
              if (event?.url && event.url !== 'about:blank') this.currentUrl = event.url;
            })
            .onPageBegin((event) => {
              this.loading = true;
              this.errorMessage = '';
              if (event?.url && event.url !== 'about:blank') this.currentUrl = event.url;
            })
            .onPageEnd((event) => {
              this.loading = false;
              this.errorMessage = '';
              if (event?.url && event.url !== 'about:blank') this.currentUrl = event.url;
              this.syncShareData();
            })
            .onErrorReceive((event) => {
              if (!event) return;
              try {
                if (!event.request.isMainFrame()) return;
              } catch (_error) {
                return;
              }
              this.loading = false;
              this.errorMessage = '网页加载失败，请检查网络连接';
            })
            .domStorageAccess(true)
            .darkMode(WebDarkMode.Auto)
            .forceDarkAccess(true)
            .accessibilityText(`${this.title || 'API文档'}网页内容`)
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .accessibilityText(`可滚动的${this.title || 'API文档'}页面`)

        if (this.loading) {
          Progress({ value: this.progress, total: 100 })
            .width('100%')
            .height(4)
            .position({ y: 96 })
            .color($r('app.color.diff_content'))
            .transition(TransitionEffect.OPACITY.animation({ duration: 160, curve: Curve.EaseOut }))
            .accessibilityText(`网页加载进度百分之${this.progress}`)
        }
        if (this.errorMessage !== '') {
          Column({ space: 10 }) {
            Text(this.errorMessage).fontColor($r('app.color.v3_text_primary'))
            Button('重新加载')
              .backgroundColor($r('app.color.diff_content'))
              .onClick(() => this.refresh())
              .accessibilityText('重新加载API文档')
          }
          .padding(22)
          .borderRadius(18)
          .backgroundColor($r('app.color.v3_surface'))
          .position({ x: '10%', y: '35%' })
          .width('80%')
          .accessibilityGroup(true)
          .accessibilityText(this.errorMessage)
          .transition(contentEnterTransition())
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.backcolor'))
    }
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .transition(pageTransition())
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => this.goBack())
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
            backgroundColor: $r('sys.color.ohos_id_color_background'),
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary'),
            },
            menuStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary'),
            },
            backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary'),
            },
          },
        },
        scrollEffectStyle: {
          backgroundStyle: {
            backgroundColor: $r('sys.color.ohos_id_color_background_transparent'),
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary'),
            },
            menuStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary'),
            },
            backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary'),
            },
          },
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: this.immersiveMaterialLevel,
        },
      },
      content: {
        title: { mainTitle: this.title || 'API 文档说明', mainTitleSize: TitleSize.TITLE_S },
        menu: {
          value: [
            {
              content: {
                label: '刷新',
                icon: $r('app.media.refresh'),
                isEnabled: !this.loading,
                action: () => this.refresh(),
              },
            },
            {
              content: {
                label: '分享当前网页',
                icon: $r('sys.symbol.share'),
                isEnabled: this.currentUrl !== '',
                action: () => this.showShare(),
              },
            },
            {
              content: {
                label: '在浏览器打开',
                icon: $r('sys.symbol.worldclock'),
                isEnabled: true,
                action: () => this.openBrowser(),
              },
            },
          ],
        },
        backIcon: { action: () => this.goBack() },
      },
    })
    .accessibilityText(`${this.title || 'API文档说明'}导航页`)
  }
}

@Builder
export function AboutWebBuilder(params: AboutWebParams): void {
  aboutWeb({ url: params.url, title: params.title })
}
