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
import {
  customUserAgent,
  WEB_PAGE_DEFAULT_TITLE,
  WEB_PAGE_DEFAULT_TOP_INSET,
  WEB_PAGE_PROGRESS_HEIGHT,
  WEB_PAGE_PROGRESS_TOP_OFFSET,
  WEB_PAGE_TOAST_DURATION_MS,
} from '../../common/constants';
import { contentEnterTransition, pageTransition } from '../../common/motion';
import { popPathSafely } from '../../common/safeNavigation';
import { WebShareManager } from '../../common/shareControl';
import type { WebShareData } from '../../common/shareControl';
import { showToastSafely } from '../../common/safeUi';
import { vibration } from '../../common/vibration';

/** Parameters shared by every in-app remote web page. */
export interface WebPageParams {
  url: string;
  title: string;
  contentInsetTop?: number;
}

/**
 * The single reusable remote-web destination.
 *
 * Page-specific callers only provide content metadata. Loading, error handling,
 * navigation, sharing and external-browser behavior stay consistent here.
 */
@Component
export struct WebPage {
  @Consume('pageStack') private pageStack: NavPathStack;
  @Prop url: string = '';
  @Prop title: string = '';
  @Prop contentInsetTop: number = WEB_PAGE_DEFAULT_TOP_INSET;
  @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
  @StorageLink('immersiveMaterialLevel') private immersiveMaterialLevel: hdsMaterial.MaterialLevel =
    hdsMaterial.MaterialLevel.GENTLE;
  @State private progress: number = 0;
  @State private loading: boolean = true;
  @State private errorMessage: string = '';
  @State private currentUrl: string = '';

  private controller: webview.WebviewController = new webview.WebviewController();
  private scroller: Scroller = new Scroller();
  private prompt: PromptAction = this.getUIContext().getPromptAction();
  private shareManager?: WebShareManager;
  private readonly shareOwnerId: number = WebShareManager.createOwnerId();

  aboutToAppear(): void {
    // Keep component creation light. ArkWeb and passive sharing are initialized
    // only after the controller is attached to the rendered page.
    this.currentUrl = this.url;
  }

  aboutToDisappear(): void {
    this.shareManager?.clearShareDataProvider(this.shareOwnerId);
    this.shareManager?.disablePassiveShare(this.shareOwnerId);
    this.shareManager = undefined;
  }

  private displayTitle(): string {
    return this.title || WEB_PAGE_DEFAULT_TITLE;
  }

  private vibrate(): void {
    if (this.vibrationLevel > 0) vibration.dotVibration();
  }

  private refresh(): void {
    this.vibrate();
    this.errorMessage = '';
    this.loading = true;
    try {
      this.controller.loadUrl(this.liveShareData().url);
    } catch (error) {
      console.error('[Dashboard][pages/web/WebPage][ERROR]', `刷新失败: ${JSON.stringify(error)}`);
      showToastSafely(this.prompt, '暂时无法刷新网页', WEB_PAGE_TOAST_DURATION_MS, 'WebPage');
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
      console.warn('[Dashboard][pages/web/WebPage][WARN]',
        `读取实时分享地址失败，使用已记录地址: ${JSON.stringify(error)}`);
    }
    return {
      url,
      title: `${this.displayTitle()}｜Harmony Dashboard`,
      description: url,
    };
  }

  private syncShareData(): void {
    if (!this.url) return;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const data = this.liveShareData();
    this.shareManager = WebShareManager.getInstance(context);
    this.shareManager.updateShareData(data.url, data.title, data.description,
      (): WebShareData => this.liveShareData(), this.shareOwnerId);
    this.shareManager.enablePassiveShare(this.shareOwnerId);
  }

  private showShare(): void {
    this.vibrate();
    this.syncShareData();
    this.shareManager?.showSystemShare();
  }

  private async openBrowser(): Promise<void> {
    this.vibrate();
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: this.liveShareData().url,
      } as Want);
    } catch (error) {
      console.error('[Dashboard][pages/web/WebPage][ERROR]', `浏览器打开失败: ${JSON.stringify(error)}`);
      showToastSafely(this.prompt, '打开链接失败', WEB_PAGE_TOAST_DURATION_MS, 'WebPage');
    }
  }

  private goBack(): boolean {
    if (this.vibrationLevel > 0) vibration.backVibration();
    try {
      if (this.controller.accessBackward()) {
        this.controller.backward();
        return true;
      }
    } catch (error) {
      console.warn('[Dashboard][pages/web/WebPage][WARN]', `检查网页后退历史失败: ${JSON.stringify(error)}`);
    }
    popPathSafely(this.pageStack, 'pages/web/WebPage');
    return true;
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        Scroll(this.scroller) {
          Column() {
            if (this.contentInsetTop > 0) {
              Blank().height(this.contentInsetTop).width('100%')
            }
            Web({ src: this.url, controller: this.controller, renderMode: RenderMode.SYNC_RENDER })
              .id('HmDashboard_WebPage')
              .width('100%')
              .layoutMode(WebLayoutMode.FIT_CONTENT)
              .nestedScroll({
                scrollForward: NestedScrollMode.SELF_FIRST,
                scrollBackward: NestedScrollMode.SELF_FIRST,
              })
              .overScrollMode(OverScrollMode.NEVER)
              .backgroundColor($r('app.color.backcolor'))
              .onControllerAttached(() => {
                try {
                  this.controller.setCustomUserAgent(customUserAgent);
                  this.syncShareData();
                } catch (error) {
                  this.errorMessage = '网页初始化失败';
                  console.error('[Dashboard][pages/web/WebPage][ERROR]', `初始化失败: ${JSON.stringify(error)}`);
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
              .metaViewport(true)
              .accessibilityText(`${this.displayTitle()}网页内容`)
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .accessibilityText(`可滚动的${this.displayTitle()}网页页面`)

        if (this.loading) {
          Progress({ value: this.progress, total: 100 })
            .width('100%')
            .height(WEB_PAGE_PROGRESS_HEIGHT)
            .position({ y: WEB_PAGE_PROGRESS_TOP_OFFSET })
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
              .accessibilityText(`重新加载${this.displayTitle()}`)
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
          backgroundStyle: { backgroundColor: $r('sys.color.ohos_id_color_background') },
          contentStyle: {
            titleStyle: { mainTitleColor: $r('sys.color.font_primary') },
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
          backgroundStyle: { backgroundColor: $r('sys.color.ohos_id_color_background_transparent') },
          contentStyle: {
            titleStyle: { mainTitleColor: $r('sys.color.font_primary') },
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
        title: { mainTitle: this.displayTitle(), mainTitleSize: TitleSize.TITLE_S },
        menu: { value: [
          { content: { label: '刷新', icon: $r('app.media.refresh'), isEnabled: !this.loading,
            action: () => this.refresh() } },
          { content: { label: '分享当前网页', icon: $r('sys.symbol.share'), isEnabled: this.currentUrl !== '',
            action: () => this.showShare() } },
          { content: { label: '在浏览器打开', icon: $r('sys.symbol.worldclock'), isEnabled: true,
            action: () => this.openBrowser() } },
        ] },
        backIcon: { action: () => this.goBack() },
      },
    })
    .accessibilityText(`${this.displayTitle()}导航页`)
  }
}

@Builder
export function WebPageBuilder(params: WebPageParams): void {
  WebPage({
    url: params.url,
    title: params.title,
    contentInsetTop: params.contentInsetTop ?? WEB_PAGE_DEFAULT_TOP_INSET,
  })
}
