import { PromptAction } from '@kit.ArkUI';
import {
    CONTENT_MAX_WIDTH,
    CONTINUATION_ROUTE_MAIN,
    MAIN_TAB_HOME,
    RESPONSIVE_BREAKPOINT_LARGE,
    RESPONSIVE_BREAKPOINT_MEDIUM,
} from '../../common/constants';
import { getContinuationState, setContinuationView } from '../../common/appState';
import { fetchMarketInfo } from '../../common/MarketApi';
import { formatCount, formatDateTime, formatPercent } from '../../common/format';
import { showToastSafely } from '../../common/safeUi';
import type { BaseAPIResponse, MarketInfo } from '../../common/types';
import { vibration } from '../../common/vibration';
import { OverviewSection } from '../../component/charts/OverviewSection';

interface HomeStat {
    label: string;
    value: string;
    color: ResourceColor;
}

@Component
struct HomeStatCard {
    stat: HomeStat = { label: '', value: '-', color: $r('app.color.v3_accent_blue') };

    build() {
        Column({ space: 8 }) {
            Text(this.stat.label)
                .fontSize(13)
                .fontColor($r('app.color.v3_text_secondary'))
                .maxLines(1)
                .accessibilityText(this.stat.label)
            Text(this.stat.value)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.stat.color)
                .maxLines(1)
                .accessibilityText(`${this.stat.label}${this.stat.value}`)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .borderRadius(16)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .shadow({ radius: 12, color: $r('app.color.v3_shadow'), offsetY: 3 })
        .accessibilityGroup(true)
        .accessibilityText(`${this.stat.label}，${this.stat.value}`)
    }
}

@Component
export struct HomePage {
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private scroller: Scroller = new Scroller();
    @StorageLink('username') private username: string = '';
    @State private market: MarketInfo | undefined = undefined;
    @State private loading: boolean = false;
    @State private errorMessage: string = '';
    @State private stale: boolean = false;
    @State private cachedAt: number = 0;
    @State private lastUpdated: string = '';
    @State private loaded: boolean = false;
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;
    private restoredScroll: boolean = false;

    private vibrate(): void {
        if (this.vibrationEnabled) {
            vibration.dotVibration();
        }
    }

    private load(force: boolean): void {
        if (this.loading) {
            return;
        }
        this.loading = true;
        this.errorMessage = '';
        fetchMarketInfo(force).then((result) => {
            const response: BaseAPIResponse<MarketInfo> = result.data;
            if (!response.success || !response.data) {
                throw new Error('市场概览数据不可用');
            }
            this.market = response.data;
            this.stale = result.stale;
            this.cachedAt = result.cachedAt;
            this.lastUpdated = response.timestamp;
            this.loaded = true;
        }).catch((error: Error) => {
            this.errorMessage = `加载失败：${error.message}`;
            console.error('[Dashboard][pages/main/HomePage][ERROR]', `首页数据加载失败且无缓存: ${error.message}`);
            showToastSafely(this.prompt, '网络不佳且没有可用缓存，请稍后重试', 2500, 'V3Home');
        }).finally(() => {
            this.loading = false;
        });
    }

    private stats(): HomeStat[] {
        if (!this.market) {
            return [];
        }
        return [
            { label: '鸿蒙应用', value: formatCount(this.market.app_count.apps), color: $r('app.color.v3_accent_blue') },
            { label: '元服务', value: formatCount(this.market.app_count.atomic_services), color: $r('app.color.v3_accent_cyan') },
            { label: '开发者', value: formatCount(this.market.developer_count), color: $r('app.color.v3_accent_purple') },
            { label: '专题', value: formatCount(this.market.substance_count), color: $r('app.color.v3_accent_orange') },
        ];
    }

    build() {
        Scroll(this.scroller) {
            Column({ space: 14 }) {
                Row() {
                    Column({ space: 5 }) {
                        Text(`你好，${this.username || 'HarmonyOS 用户'}`)
                            .fontSize(26)
                            .margin({top:100})
                            .fontWeight(FontWeight.Bold)
                            .fontColor($r('app.color.v3_text_primary'))
                            .accessibilityText(`欢迎，${this.username || 'HarmonyOS 用户'}`)
                        Text('欢迎来到鸿蒙应用市场数据看板')
                            .fontSize(14)
                            .fontColor($r('app.color.v3_text_secondary'))
                            .accessibilityText('欢迎来到鸿蒙应用市场数据看板')
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    Button({ type: ButtonType.Circle }) {
                        Text('↻')
                            .fontSize(24)
                            .fontColor($r('app.color.v3_accent_blue'))
                            .accessibilityText('刷新图标')
                    }
                    .width(44)
                    .height(44)
                    .backgroundColor($r('app.color.v3_surface_alt'))
                    .enabled(!this.loading)
                    .onClick(() => {
                        this.vibrate();
                        this.load(true);
                    })
                    .accessibilityText(this.loading ? '正在刷新' : '刷新首页数据')
                }
                .width('100%')
                .padding({ top: 20, left: 4, right: 4 })
                .accessibilityGroup(true)

                if (this.stale) {
                    Row({ space: 8 }) {
                        Image($r('app.media.attention'))
                            .width(18)
                            .height(18)
                            .objectFit(ImageFit.Contain)
                            .accessibilityText('离线缓存图标')
                        Text(`当前显示离线缓存 · ${formatDateTime(new Date(this.cachedAt).toISOString())}`)
                            .fontSize(13)
                            .fontColor($r('app.color.v3_text_primary'))
                            .layoutWeight(1)
                            .accessibilityText('当前显示离线缓存数据')
                    }
                    .width('100%')
                    .padding(12)
                    .borderRadius(12)
                    .backgroundColor($r('app.color.v3_warning_bg'))
                    .accessibilityGroup(true)
                    .accessibilityText('离线缓存提示')
                }

                if (this.loading && !this.market) {
                    Row({ space: 10 }) {
                        LoadingProgress()
                            .width(26)
                            .height(26)
                            .color($r('app.color.v3_accent_blue'))
                            .accessibilityText('首页数据加载中')
                        Text('正在获取最新市场状态…')
                            .fontColor($r('app.color.v3_text_secondary'))
                            .accessibilityText('正在获取最新市场状态')
                    }
                    .padding(30)
                    .accessibilityGroup(true)
                }

                if (this.errorMessage !== '') {
                    Column({ space: 10 }) {
                        Text(this.errorMessage)
                            .fontColor($r('app.color.v3_accent_red'))
                            .accessibilityText(this.errorMessage)
                        Button('重试')
                            .backgroundColor($r('app.color.v3_accent_blue'))
                            .onClick(() => this.load(true))
                            .accessibilityText('重试加载首页')
                    }
                    .padding(18)
                    .width('100%')
                    .borderRadius(14)
                    .backgroundColor($r('app.color.v3_surface'))
                    .accessibilityGroup(true)
                }

                GridRow({
                    columns: { xs: 4, sm: 8, md: 12 },
                    gutter: { x: 10, y: 10 },
                    breakpoints: {
                        value: [RESPONSIVE_BREAKPOINT_MEDIUM, RESPONSIVE_BREAKPOINT_LARGE],
                        reference: BreakpointsReference.WindowSize,
                    },
                }) {
                    ForEach(this.stats(), (stat: HomeStat) => {
                        GridCol({ span: { xs: 2, sm: 4, md: 3 } }) {
                            HomeStatCard({ stat })
                        }
                    }, (stat: HomeStat) => stat.label)
                }
                .width('100%')
                .accessibilityText('市场数据概览卡片')

                if (this.market) {
                    Column({ space: 12 }) {
                        Row() {
                            Text('当前状态')
                                .fontSize(18)
                                .fontWeight(FontWeight.Bold)
                                .fontColor($r('app.color.v3_text_primary'))
                                .accessibilityText('当前状态')
                            Blank()
                            Text(this.market.sync_status.is_syncing_all ? '全量同步中' : '服务正常')
                                .fontSize(13)
                                .fontColor(this.market.sync_status.is_syncing_all ?
                                    $r('app.color.v3_accent_orange') : $r('app.color.v3_accent_green'))
                                .accessibilityText(this.market.sync_status.is_syncing_all ? '全量同步中' : '服务正常')
                        }
                        .width('100%')

                        if (this.market.sync_status.progress && this.market.sync_status.progress!.length >= 2) {
                            Progress({
                                value: this.market.sync_status.progress![0],
                                total: Math.max(1, this.market.sync_status.progress![1]),
                                type: ProgressType.Linear,
                            })
                                .width('100%')
                                .height(10)
                                .color($r('app.color.v3_accent_blue'))
                                .backgroundColor($r('app.color.v3_chart_grid'))
                                .accessibilityText(`同步进度${formatPercent(this.market.sync_status.progress![0], this.market.sync_status.progress![1])}`)
                            Text(`已处理 ${formatCount(this.market.sync_status.total_processed)} · 新增 ${formatCount(this.market.sync_status.total_inserted)} · 失败 ${formatCount(this.market.sync_status.total_failed)}`)
                                .fontSize(13)
                                .fontColor($r('app.color.v3_text_secondary'))
                                .accessibilityText('同步处理统计')
                        }

                        Divider()
                            .color($r('app.color.v3_chart_grid'))
                            .accessibilityText('状态分隔线')
                        Text(`最后更新时间：${formatDateTime(this.lastUpdated)}`)
                            .fontSize(13)
                            .fontColor($r('app.color.v3_text_secondary'))
                            .accessibilityText(`最后更新时间${formatDateTime(this.lastUpdated)}`)
                        Text(`后端版本：${this.market.crate_version}`)
                            .fontSize(13)
                            .fontColor($r('app.color.v3_text_secondary'))
                            .accessibilityText(`后端版本${this.market.crate_version}`)
                    }
                    .width('100%')
                    .padding(18)
                    .borderRadius(18)
                    .backgroundColor($r('app.color.v3_surface'))
                    .border({ width: 1, color: $r('app.color.nd_card_border') })
                    .accessibilityGroup(true)
                    .accessibilityText('服务当前状态')
                }

                Divider()
                    .margin({ top: 8, bottom: 2 })
                    .color($r('app.color.border'))
                    .accessibilityText('首页概览与图表分隔线')

                OverviewSection()

                Blank().height(96)
            }
            .width('100%')
            .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
            .padding({ left: 14, right: 14 })
            .onAppear(() => {
                if (!this.loaded) {
                    this.load(false);
                }
                if (!this.restoredScroll) {
                    this.restoredScroll = true;
                    const continuation = getContinuationState();
                    if (continuation.mainTab === MAIN_TAB_HOME && continuation.routeName === CONTINUATION_ROUTE_MAIN &&
                        continuation.scrollDistance > 0) {
                        setTimeout((): void => {
                            try {
                                this.scroller.scrollTo({
                                    xOffset: 0,
                                    yOffset: continuation.scrollDistance,
                                    animation: { duration: 0 },
                                });
                            } catch (error) {
                                console.warn('[Dashboard][pages/main/HomePage][WARN]',
                                    `恢复滚动位置失败: ${JSON.stringify(error)}`);
                            }
                        }, 80);
                    }
                }
            })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .onDidScroll(() => {
            setContinuationView(MAIN_TAB_HOME, this.scroller.currentOffset().yOffset);
        })
        .backgroundColor($r('app.color.background'))
        .accessibilityText('首页')
    }
}
