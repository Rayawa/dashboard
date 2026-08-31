import { PromptAction } from '@kit.ArkUI';
import {
    CONTENT_MAX_WIDTH,
    CONTINUATION_ROUTE_MAIN,
    MAIN_TAB_HOME,
    RESPONSIVE_BREAKPOINT_LARGE,
    RESPONSIVE_BREAKPOINT_MEDIUM,
} from '../../common/constants';
import { getContinuationState, setContinuationView, setDetailTarget } from '../../common/appState';
import { fetchAppsPage, fetchMarketInfo } from '../../common/MarketApi';
import { formatDateTime, formatExactCount } from '../../common/format';
import { showToastSafely } from '../../common/safeUi';
import type { BaseAPIResponse, MarketApp, MarketInfo, PageInfo } from '../../common/types';

interface HomeStat {
    label: string;
    value: string;
    color: ResourceColor;
}

@Component
struct HomeStatCard {
    stat: HomeStat = { label: '', value: '-', color: $r('app.color.diff_content') };

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
struct RecentAppCard {
    app: MarketApp = {} as MarketApp;
    onOpen: (app: MarketApp) => void = () => {};

    build() {
        Row({ space: 12 }) {
            Image(this.app.icon_url || $r('app.media.startIcon'))
                .width(48)
                .height(48)
                .borderRadius(12)
                .objectFit(ImageFit.Cover)
                .alt($r('app.media.startIcon'))
                .accessibilityText(`${this.app.name || '未知应用'}图标`)
            Column({ space: 4 }) {
                Text(this.app.name || '未知应用')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.v3_text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${this.app.developer_name || '未知开发者'} · ${this.app.version || '未知版本'}`)
                    .fontSize(12)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`收录于 ${formatDateTime(this.app.listed_at)}`)
                    .fontSize(11)
                    .fontColor($r('app.color.v3_text_secondary'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Image($r('sys.symbol.chevron_right'))
                .width(18)
                .height(18)
                .fillColor($r('app.color.v3_text_secondary'))
                .accessibilityText('打开详情')
        }
        .width('100%')
        .padding(14)
        .borderRadius(16)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .onClick(() => this.onOpen(this.app))
        .accessibilityGroup(true)
        .accessibilityText(`新收录应用${this.app.name || '未知应用'}，点击查看详情`)
    }
}

@Component
export struct HomePage {
    @Consume('pageStack') private pageStack: NavPathStack;
    @Prop @Watch('onScrollToTopVersionChanged') scrollToTopVersion: number = 0;
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
    @State private recentApps: MarketApp[] = [];
    @State private refreshing: boolean = false;
    @State private contentWidth: number = 0;
    private restoredScroll: boolean = false;
    private reloadAfterCurrent: boolean = false;

    private onScrollToTopVersionChanged(): void {
        if (this.scrollToTopVersion <= 0) {
            return;
        }
        try {
            this.scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 300 } });
        } catch (error) {
            console.warn('[Dashboard][pages/main/HomePage][WARN]', `返回顶部失败: ${JSON.stringify(error)}`);
        }
    }

    private greeting(): string {
        const hour = new Date().getHours();
        if (hour >= 6 && hour < 12) {
            return '上午好';
        }
        if (hour >= 12 && hour < 18) {
            return '下午好';
        }
        return '晚上好';
    }

    private async load(force: boolean): Promise<void> {
        if (this.loading) {
            this.reloadAfterCurrent = this.reloadAfterCurrent || force;
            return;
        }
        this.loading = true;
        this.errorMessage = '';
        const recentPromise = this.loadRecentApps(force);
        try {
            const result = await fetchMarketInfo(force);
            const response: BaseAPIResponse<MarketInfo> = result.data;
            if (!response.success || !response.data) {
                throw new Error('市场概览数据不可用');
            }
            this.market = response.data;
            this.stale = result.stale;
            this.cachedAt = result.cachedAt;
            this.lastUpdated = response.timestamp;
            this.loaded = true;
        } catch (error) {
            const message = (error as Error).message;
            this.errorMessage = `加载失败：${message}`;
            console.error('[Dashboard][pages/main/HomePage][ERROR]', `首页数据加载失败且无缓存: ${message}`);
            showToastSafely(this.prompt, '网络不佳且没有可用缓存，请稍后重试', 2500, 'V3Home');
        } finally {
            await recentPromise;
            this.loading = false;
            if (this.reloadAfterCurrent) {
                this.reloadAfterCurrent = false;
                setTimeout((): void => { this.load(true); }, 0);
            } else {
                this.refreshing = false;
            }
        }
    }

    private async loadRecentApps(force: boolean): Promise<void> {
        try {
            const result = await fetchAppsPage(1, 6, 'listed_at', true, undefined, undefined, false, force);
            const response = result.data as BaseAPIResponse<PageInfo<MarketApp>>;
            if (response.success && response.data) {
                this.recentApps = response.data.data ?? [];
            }
        } catch (error) {
            console.warn('[Dashboard][pages/main/HomePage][WARN]',
                `新收录应用加载失败: ${(error as Error).message}`);
        }
    }

    private openDetail(app: MarketApp): void {
        setDetailTarget({ appId: app.app_id, packageName: app.pkg_name });
        try {
            this.pageStack.pushPathByName('AppDetailPage', null);
        } catch (error) {
            console.error('[Dashboard][pages/main/HomePage][ERROR]', `打开应用详情失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, '暂时无法打开应用详情', 1800, 'HomePage');
        }
    }

    private stats(): HomeStat[] {
        if (!this.market) {
            return [];
        }
        return [
            { label: '开发者', value: formatExactCount(this.market.developer_count), color: $r('app.color.v3_accent_purple') },
            { label: '专题', value: formatExactCount(this.market.substance_count), color: $r('app.color.v3_accent_orange') },
        ];
    }

    @Builder
    private totalRelationCard(): void {
        if (this.market) {
            Column({ space: 12 }) {
                Row() {
                    Text('应用总数').fontSize(16).fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.v3_text_primary')).layoutWeight(1)
                    Text(formatExactCount(this.market.app_count.apps + this.market.app_count.atomic_services))
                        .fontSize(28).fontWeight(FontWeight.Bold).fontColor($r('app.color.diff_content'))
                }.width('100%')
                Row({ space: 8 }) {
                    Column({ space: 4 }) {
                        Text('鸿蒙应用').fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text(formatExactCount(this.market.app_count.apps)).fontSize(19).fontWeight(FontWeight.Bold)
                            .fontColor($r('app.color.diff_content'))
                    }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                    Text('+').fontSize(20).fontColor($r('app.color.v3_text_secondary'))
                    Column({ space: 4 }) {
                        Text('元服务').fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text(formatExactCount(this.market.app_count.atomic_services)).fontSize(19)
                            .fontWeight(FontWeight.Bold).fontColor($r('app.color.v3_accent_cyan'))
                    }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                    Text('=').fontSize(20).fontColor($r('app.color.v3_text_secondary'))
                    Text(formatExactCount(this.market.app_count.apps + this.market.app_count.atomic_services))
                        .fontSize(19).fontWeight(FontWeight.Bold).fontColor($r('app.color.diff_content'))
                }.width('100%')
            }
            .width('100%').padding(18).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
            .border({ width: 1, color: $r('app.color.nd_card_border') })
            .accessibilityGroup(true)
            .accessibilityText(`应用总数${this.market.app_count.apps + this.market.app_count.atomic_services}，等于鸿蒙应用${this.market.app_count.apps}加元服务${this.market.app_count.atomic_services}`)
        }
    }

    @Builder
    private statsGrid(): void {
        GridRow({
            columns: { xs: 4, sm: 8, md: 12 }, gutter: { x: 10, y: 10 },
            breakpoints: {
                value: [RESPONSIVE_BREAKPOINT_MEDIUM, RESPONSIVE_BREAKPOINT_LARGE],
                reference: BreakpointsReference.WindowSize,
            },
        }) {
            ForEach(this.stats(), (stat: HomeStat) => {
                GridCol({ span: { xs: 2, sm: 4, md: 6 } }) { HomeStatCard({ stat }) }
            }, (stat: HomeStat) => stat.label)
        }.width('100%').accessibilityText('开发者和专题数据概览')
    }

    @Builder
    private statusCard(): void {
        if (this.market) {
            Column({ space: 12 }) {
                Row() {
                    Text('当前状态').fontSize(18).fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.v3_text_primary'))
                    Blank()
                    Text(this.market.sync_status.is_syncing_all ? '全量同步中' : '服务正常').fontSize(13)
                        .fontColor(this.market.sync_status.is_syncing_all ?
                            $r('app.color.v3_accent_orange') : $r('app.color.v3_accent_green'))
                }.width('100%')
                if (this.market.sync_status.is_syncing_all) {
                    Text(`已处理 ${formatExactCount(this.market.sync_status.total_processed)} · 新增 ${formatExactCount(this.market.sync_status.total_inserted)} · 失败 ${formatExactCount(this.market.sync_status.total_failed)}`)
                        .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
                }
                Divider().color($r('app.color.v3_chart_grid')).accessibilityText('状态分隔线')
                Text(`最后更新时间：${formatDateTime(this.lastUpdated)}`).fontSize(13)
                    .fontColor($r('app.color.v3_text_secondary'))
                Text(`后端版本：${this.market.crate_version}`).fontSize(13)
                    .fontColor($r('app.color.v3_text_secondary'))
            }
            .width('100%').padding(18).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
            .border({ width: 1, color: $r('app.color.nd_card_border') })
            .accessibilityGroup(true)
            .accessibilityText(this.market.sync_status.is_syncing_all ? '服务当前正在全量同步' : '服务当前状态正常')
        }
    }

    @Builder
    private dataAndStatus(): void {
        Column({ space: 14 }) {
            this.totalRelationCard()
            this.statsGrid()
            this.statusCard()
        }.width('100%')
    }

    @Builder
    private recentSection(): void {
        if (this.recentApps.length > 0) {
            Column({ space: 10 }) {
                Text('最近收录').width('100%').fontSize(18).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).accessibilityText('最近收录应用')
                ForEach(this.recentApps, (app: MarketApp) => {
                    RecentAppCard({ app, onOpen: (target: MarketApp) => this.openDetail(target) })
                }, (app: MarketApp) => `${app.app_id}-${app.updated_at}`)
            }.width('100%').accessibilityGroup(true).accessibilityText('最近收录的应用')
        }
    }

    build() {
        Refresh({ refreshing: $$this.refreshing }) {
          Scroll(this.scroller) {
            Column({ space: 14 }) {
                Blank().height(100).width('100%')
                Row() {
                    Column({ space: 5 }) {
                        Text(`${this.greeting()}，${this.username || 'HarmonyOS用户'}`)
                            .fontSize(26)
                            .fontWeight(FontWeight.Bold)
                            .fontColor($r('app.color.v3_text_primary'))
                            .accessibilityText(`${this.greeting()}，${this.username || 'HarmonyOS用户'}`)
                        Text('欢迎来到鸿蒙应用市场数据看板')
                            .fontSize(14)
                            .fontColor($r('app.color.v3_text_secondary'))
                            .accessibilityText('欢迎来到鸿蒙应用市场数据看板')
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                }
                .width('100%')
                .padding({ left: 4, right: 4 })
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
                            .color($r('app.color.diff_content'))
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
                            .backgroundColor($r('app.color.diff_content'))
                            .onClick(() => { this.load(true); })
                            .accessibilityText('重试加载首页')
                    }
                    .padding(18)
                    .width('100%')
                    .borderRadius(14)
                    .backgroundColor($r('app.color.v3_surface'))
                    .accessibilityGroup(true)
                }

                if (this.contentWidth >= 840) {
                    Row({ space: 16 }) {
                        Column() { this.dataAndStatus() }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                        Column() { this.recentSection() }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                    }.width('100%').alignItems(VerticalAlign.Top)
                        .accessibilityText('左侧市场数据和状态，右侧最近收录应用')
                } else {
                    this.dataAndStatus()
                    this.recentSection()
                }

                Blank().height(96)
            }
            .width('100%')
            .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
            .padding({ left: 14, right: 14 })
            .onAreaChange((_oldValue: Area, newValue: Area): void => {
                this.contentWidth = Number(newValue.width);
            })
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
          .onDidScroll((): void => {
              try {
                  setContinuationView(MAIN_TAB_HOME, this.scroller.currentOffset().yOffset);
              } catch (error) {
                  console.warn('[Dashboard][pages/main/HomePage][WARN]',
                      `保存滚动位置失败: ${JSON.stringify(error)}`);
              }
          })
          .backgroundColor($r('app.color.background'))
          .accessibilityText('可下拉刷新的首页')
        }
        .width('100%').height('100%')
        .onRefreshing((): void => {
            this.refreshing = true;
            this.load(true);
        })
    }
}
