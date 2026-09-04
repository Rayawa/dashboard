import { webview } from '@kit.ArkWeb';
import {
    customUserAgent,
    CONTINUATION_ROUTE_MAIN,
    MAIN_TAB_S_STATION,
    SBaseURL,
    S_STATION_COMMAND_HOME,
    S_STATION_COMMAND_SCROLL_TOP,
} from '../../common/constants';
import {
    getContinuationState,
    setContinuationPageUrl,
    setContinuationScrollDistance,
    setMainTab,
} from '../../common/appState';
import { vibration } from '../../common/vibration';
import { contentEnterTransition, runPageEnterAnimation } from '../../common/motion';

@Component
export struct SStationPage {
    private controller: webview.WebviewController = new webview.WebviewController();
    private scroller: Scroller = new Scroller();
    @Prop command: number = 0;
    @Prop @Watch('onCommandVersionChanged') commandVersion: number = 0;
    @StorageLink('vibrationLevel') private vibrationLevel: number = 0;
    @State private progress: number = 0;
    @State private loading: boolean = true;
    @State private errorMessage: string = '';
    @State private currentUrl: string = SBaseURL.toString();
    @State private initialUrl: string = SBaseURL.toString();
    @State private pageVisible: boolean = false;
    private pendingScrollDistance: number = 0;
    private restoredScroll: boolean = false;

    aboutToAppear(): void {
        this.pageVisible = false;
        runPageEnterAnimation(this.getUIContext(), (): void => { this.pageVisible = true; });
        try {
            const continuation = getContinuationState();
            if (continuation.mainTab === MAIN_TAB_S_STATION &&
                continuation.routeName === CONTINUATION_ROUTE_MAIN) {
                this.currentUrl = continuation.pageUrl || SBaseURL.toString();
                this.initialUrl = this.currentUrl;
                this.pendingScrollDistance = Math.max(0, continuation.scrollDistance);
            }
        } catch (error) {
            console.warn('[Dashboard][pages/main/SStationPage][WARN]',
                `读取S站接续位置失败: ${JSON.stringify(error)}`);
        }
    }

    private restoreScrollPosition(): void {
        if (this.restoredScroll || this.pendingScrollDistance <= 0) {
            return;
        }
        this.restoredScroll = true;
        setTimeout((): void => {
            try {
                this.scroller.scrollTo({ xOffset: 0, yOffset: this.pendingScrollDistance, animation: { duration: 0 } });
            } catch (error) {
                console.warn('[Dashboard][pages/main/SStationPage][WARN]',
                    `恢复S站滚动位置失败: ${JSON.stringify(error)}`);
            }
        }, 80);
    }

    private onCommandVersionChanged(): void {
        if (this.commandVersion <= 0) {
            return;
        }
        try {
            if (this.command === S_STATION_COMMAND_SCROLL_TOP) {
                this.scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 300 } });
            } else if (this.command === S_STATION_COMMAND_HOME) {
                this.errorMessage = '';
                this.loading = true;
                this.currentUrl = SBaseURL.toString();
                setContinuationPageUrl(this.currentUrl);
                this.scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 0 } });
                this.controller.loadUrl(this.currentUrl);
                setContinuationScrollDistance(0);
            }
        } catch (error) {
            console.warn('[Dashboard][pages/main/SStationPage][WARN]', `执行S站标题栏操作失败: ${JSON.stringify(error)}`);
        }
    }

    build() {
        Stack({ alignContent: Alignment.Top }) {
            Scroll(this.scroller) {
                Column() {
                    Blank()
                        .height(100)
                        .width('100%')
                        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                        .accessibilityText('S站标题栏安全区域')
                    Web({
                        src: this.initialUrl,
                        controller: this.controller,
                        renderMode: RenderMode.SYNC_RENDER,
                    })
                        .id('HmDashboard_SStation')
                        .width('100%')
                        .layoutMode(WebLayoutMode.FIT_CONTENT)
                        .overScrollMode(OverScrollMode.NEVER)
                        .backgroundColor($r('app.color.s_station_placeholder'))
                        .onControllerAttached(() => {
                            try {
                                this.controller.setCustomUserAgent(customUserAgent);
                            } catch (error) {
                                console.warn('[Dashboard][pages/main/SStationPage][WARN]',
                                    `初始化ArkWeb失败: ${JSON.stringify(error)}`);
                            }
                        })
                        .onNavigationEntryCommitted((event) => {
                            if (event?.url && event.url !== 'about:blank') {
                                this.currentUrl = event.url;
                                setContinuationPageUrl(event.url);
                            }
                        })
                        .onPageBegin((event) => {
                            this.loading = true;
                            this.errorMessage = '';
                            if (event?.url && event.url !== 'about:blank') {
                                this.currentUrl = event.url;
                                setContinuationPageUrl(event.url);
                            }
                        })
                        .onPageEnd((event) => {
                            this.loading = false;
                            this.errorMessage = '';
                            if (event?.url && event.url !== 'about:blank') {
                                this.currentUrl = event.url;
                                setContinuationPageUrl(event.url);
                                this.restoreScrollPosition();
                            }
                        })
                        .onErrorReceive((event) => {
                            if (!event) {
                                return;
                            }
                            try {
                                if (!event.request.isMainFrame()) {
                                    return;
                                }
                            } catch (error) {
                                console.warn('[Dashboard][pages/main/SStationPage][WARN]',
                                    `无法判断网页错误来源，忽略本次错误提示: ${JSON.stringify(error)}`);
                                return;
                            }
                            this.loading = false;
                            this.errorMessage = '网页主页面加载失败，请检查网络连接后重试';
                            console.warn('[Dashboard][pages/main/SStationPage][WARN]',
                                `S站主页面加载失败: ${JSON.stringify(event.error)}`);
                        })
                        .onProgressChange((event) => {
                            this.progress = event.newProgress;
                        })
                        .metaViewport(true)
                        .domStorageAccess(true)
                        .darkMode(WebDarkMode.Auto)
                        .forceDarkAccess(true)
                        .accessibilityText('S站网页内容')
                }
                .width('100%')
                .backgroundColor($r('app.color.s_station_placeholder'))
              }
              .width('100%').height('100%').scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
              .onDidScroll((): void => {
                  setMainTab(MAIN_TAB_S_STATION);
                  setContinuationScrollDistance(this.scroller.currentOffset().yOffset);
              })
              .accessibilityText('可滚动的S站网页视图')

            if (this.loading) {
                Progress({ value: this.progress, total: 100 })
                    .width('100%')
                    .height(4)
                    .position({ y: 96 })
                    .color($r('app.color.diff_content'))
                    .transition(TransitionEffect.OPACITY.animation({ duration: 160, curve: Curve.EaseOut }))
                    .accessibilityText(`S站加载进度百分之${this.progress}`)
            }

            if (this.errorMessage !== '') {
                Column({ space: 12 }) {
                    Text('S站暂时无法连接')
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.v3_text_primary'))
                        .accessibilityText('S站暂时无法连接')
                    Text(this.errorMessage)
                        .fontSize(13)
                        .fontColor($r('app.color.v3_text_secondary'))
                        .textAlign(TextAlign.Center)
                        .accessibilityText(this.errorMessage)
                    Button('重新加载')
                        .backgroundColor($r('app.color.diff_content'))
                        .onClick(() => {
                            if (this.vibrationLevel > 0) vibration.dotVibration();
                            this.errorMessage = '';
                            this.loading = true;
                            try {
                                this.controller.loadUrl(this.currentUrl);
                            } catch (error) {
                                console.warn('[Dashboard][pages/main/SStationPage][WARN]',
                                    `重新加载S站失败: ${JSON.stringify(error)}`);
                            }
                        })
                        .accessibilityText('重新加载S站')
                }
                .padding(24)
                .borderRadius(20)
                .backgroundColor($r('app.color.v3_surface'))
                .position({ x: '10%', y: '35%' })
                .width('80%')
                .accessibilityGroup(true)
                .accessibilityText('S站主页面网络错误提示')
                .transition(contentEnterTransition())
            }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.s_station_placeholder'))
        .opacity(this.pageVisible ? 1 : 0.01)
        .translate({ y: this.pageVisible ? 0 : 10 })
        .accessibilityGroup(true)
        .accessibilityText('S站页面')
    }
}
