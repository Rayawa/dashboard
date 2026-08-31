import { common, Want } from '@kit.AbilityKit';
import { webview } from '@kit.ArkWeb';
import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import {
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  ScrollEffectType,
  TitleSize,
} from '@kit.UIDesignKit';
import { customUserAgent } from '../../common/constants';
import { popPathSafely } from '../../common/safeNavigation';
import { showToastSafely } from '../../common/safeUi';
import { vibration } from '../../common/vibration';

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
  @StorageLink('vibrationON') vibrationON: boolean = true;

  private refresh(): void {
    if (this.vibrationON) vibration.dotVibration();
    this.errorMessage = '';
    this.loading = true;
    try {
      this.controller.loadUrl(this.url);
    } catch (error) {
      console.error('[Dashboard][pages/more/aboutWeb][ERROR]', `刷新失败: ${JSON.stringify(error)}`);
      showToastSafely(this.prompt, '暂时无法刷新网页', 1600, 'AboutWeb');
    }
  }

  private async openBrowser(): Promise<void> {
    if (this.vibrationON) vibration.dotVibration();
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: this.url,
      } as Want);
    } catch (error) {
      console.error('[Dashboard][pages/more/aboutWeb][ERROR]', `浏览器打开失败: ${JSON.stringify(error)}`);
      showToastSafely(this.prompt, '打开链接失败', 1600, 'AboutWeb');
    }
  }

  private goBack(): boolean {
    if (this.vibrationON) vibration.dotVibration();
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

  private loadInitialUrl(): void {
    if (this.url === '') return;
    try {
      this.controller.loadUrl(this.url);
    } catch (error) {
      this.loading = false;
      this.errorMessage = '网页初始化失败';
      console.error('[Dashboard][pages/more/aboutWeb][ERROR]', `加载初始地址失败: ${JSON.stringify(error)}`);
    }
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        Scroll() {
          Column() {
            Blank().height(100).width('100%')
            Web({ src: 'about:blank', controller: this.controller, renderMode: RenderMode.SYNC_RENDER })
            .id('HmDashboard_ApiDocs')
            .width('100%')
            .layoutMode(WebLayoutMode.FIT_CONTENT)
            .backgroundColor($r('app.color.backcolor'))
            .onControllerAttached(() => {
              try {
                this.controller.setCustomUserAgent(customUserAgent);
                if (this.url !== '') this.controller.loadUrl(this.url);
              } catch (error) {
                this.errorMessage = '网页初始化失败';
                console.error('[Dashboard][pages/more/aboutWeb][ERROR]', `初始化失败: ${JSON.stringify(error)}`);
              }
            })
            .onProgressChange((event) => this.progress = event.newProgress)
            .onPageBegin(() => {
              this.loading = true;
              this.errorMessage = '';
            })
            .onPageEnd(() => {
              this.loading = false;
              this.errorMessage = '';
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
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.backcolor'))
    }
    .titleMode(HdsNavDestinationTitleMode.MINI)
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
    .onReady((context: NavDestinationContext) => {
      const params = context.pathInfo.param as Record<string, string>;
      if (params) {
        this.url = params.url || '';
        this.title = params.title || 'API 文档说明';
        this.loadInitialUrl();
      }
    })
    .accessibilityText(`${this.title || 'API文档说明'}导航页`)
  }
}

@Builder
export function AboutWebBuilder(): void {
  aboutWeb()
}
