import { PromptAction, SegmentButtonV2Items } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import {
    CONTENT_MAX_WIDTH, CONTINUATION_ROUTE_MAIN, MAIN_TAB_APPS,
} from '../../common/constants';
import { getContinuationState, setAppsViewIndex, setContinuationView, setDetailTarget } from '../../common/appState';
import { fetchAppsPage } from '../../common/MarketApi';
import { formatBytes, formatCount, formatDateTime } from '../../common/format';
import type { BaseAPIResponse, MarketApp, PageInfo } from '../../common/types';
import { showToastSafely } from '../../common/safeUi';
import { vibration } from '../../common/vibration';
import { HdsTitleBarSegment } from '../../component/HdsTitleBarSegment';
import { OverviewSection } from '../../component/charts/OverviewSection';

interface SortChoice {
    label: string;
    field: string;
}

@Component
struct AppTableRow {
    app: MarketApp = {} as MarketApp;
    index: number = 0;
    onOpen: (app: MarketApp) => void = () => {};
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;
    @State private pressed: boolean = false;
    @State private pointLight: hdsEffect.PointLightSourceType = hdsEffect.PointLightSourceType.NONE;

    private rating(): string {
        const value = Number(this.app.average_rating ?? 0);
        return value > 0 ? value.toFixed(1) : '-';
    }

    build() {
        Row() {
            Text(String(this.index))
                .width(44)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .accessibilityText(`序号${this.index}`)
            Row({ space: 8 }) {
                Image(this.app.icon_url || $r('app.media.startIcon'))
                    .width(34)
                    .height(34)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                    .alt($r('app.media.startIcon'))
                    .accessibilityText(`${this.app.name || '未知应用'}图标`)
                Column({ space: 2 }) {
                    Text(this.app.name || '未知应用')
                        .fontSize(13)
                        .fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.v3_text_primary'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .accessibilityText(this.app.name || '未知应用')
                    Text(this.app.pkg_name || this.app.app_id)
                        .fontSize(10)
                        .fontColor($r('app.color.v3_text_secondary'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .accessibilityText(this.app.pkg_name || this.app.app_id)
                }
                .alignItems(HorizontalAlign.Start)
            }
            .width(220)
            Text(this.app.developer_name || '-')
                .width(150)
                .fontSize(12)
                .fontColor($r('app.color.v3_accent_blue'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .accessibilityText(`开发者${this.app.developer_name || '未知'}`)
            Text(`${this.app.kind_type_name || '-'} · ${this.app.kind_name || '-'}`)
                .width(140)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .accessibilityText(`分类${this.app.kind_type_name || ''}${this.app.kind_name || ''}`)
            Text(this.rating())
                .width(70)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_primary'))
                .accessibilityText(`评分${this.rating()}`)
            Text(formatCount(this.app.download_count))
                .width(100)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_primary'))
                .accessibilityText(`下载量${formatCount(this.app.download_count)}`)
            Text(formatBytes(this.app.size_bytes))
                .width(90)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .accessibilityText(`应用大小${formatBytes(this.app.size_bytes)}`)
            Text(formatDateTime(this.app.updated_at).split(' ')[0])
                .width(110)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .accessibilityText(`更新时间${formatDateTime(this.app.updated_at)}`)
        }
        .width(924)
        .height(58)
        .padding({ left: 8, right: 8 })
        .border({ width: { bottom: 1 }, color: $r('app.color.v3_chart_grid') })
        .backgroundColor(this.index % 2 === 0 ? $r('app.color.v3_surface_alt') : $r('app.color.v3_surface'))
        .scale({ x: this.pressed ? 0.99 : 1, y: this.pressed ? 0.99 : 1 })
        .animation({ curve: Curve.EaseOut, duration: 120 })
        .visualEffect(new hdsEffect.HdsEffectBuilder().pointLight({
            sourceType: this.pointLight,
            illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
            options: { color: $r('app.color.diff_content'), intensity: 6, height: 100 },
        }).buildEffect())
        .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
                this.pressed = true;
                this.pointLight = hdsEffect.PointLightSourceType.BRIGHT;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.pressed = false;
                this.pointLight = hdsEffect.PointLightSourceType.NONE;
            }
        })
        .onClick(() => {
            if (this.vibrationEnabled) vibration.dotVibration();
            this.onOpen(this.app);
        })
        .accessibilityGroup(true)
        .accessibilityText(`打开${this.app.name || '未知应用'}详情`)
    }
}

@Component
export struct AppsPage {
    @Consume('pageStack') private pageStack: NavPathStack;
    @Prop @Watch('onRefreshVersionChanged') refreshVersion: number = 0;
    @Prop @Watch('onScrollToTopVersionChanged') scrollToTopVersion: number = 0;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private pageScroller: Scroller = new Scroller();
    private overviewScroller: Scroller = new Scroller();
    private segmentItems: SegmentButtonV2Items = new SegmentButtonV2Items([
        { text: '应用概况', accessibilityText: '应用概况' },
        { text: '应用列表', accessibilityText: '应用列表' },
    ]);
    @State private selectedIndexes: number[] = [0];
    @State private overviewRefreshVersion: number = 0;
    @State private apps: MarketApp[] = [];
    @State private page: number = 1;
    @State private total: number = 0;
    @State private loading: boolean = false;
    @State private loaded: boolean = false;
    @State private fromCache: boolean = false;
    @State private sortIndex: number = 0;
    @State private pageSizeIndex: number = 0;
    @State private descending: boolean = true;
    @State private jumpText: string = '';
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;
    private restoredScroll: boolean = false;
    private restoredView: boolean = false;

    private onRefreshVersionChanged(): void {
        if (this.refreshVersion <= 0) {
            return;
        }
        this.overviewRefreshVersion = this.refreshVersion;
        this.load(true);
    }

    private onScrollToTopVersionChanged(): void {
        if (this.scrollToTopVersion <= 0) {
            return;
        }
        try {
            const activeScroller = this.selectedIndexes[0] === 0 ? this.overviewScroller : this.pageScroller;
            activeScroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 300 } });
        } catch (error) {
            console.warn('[Dashboard][pages/main/AppsPage][WARN]', `返回顶部失败: ${JSON.stringify(error)}`);
        }
    }

    private vibrate(): void {
        if (this.vibrationEnabled) vibration.dotVibration();
    }

    private sortChoices(): SortChoice[] {
        return [
            { label: '更新时间', field: 'updated_at' },
            { label: '下载量', field: 'download_count' },
            { label: '评分数量', field: 'total_star_rating_count' },
            { label: '应用大小', field: 'size_bytes' },
            { label: '上架时间', field: 'listed_at' },
        ];
    }

    private sortOptions(): SelectOption[] {
        return this.sortChoices().map((choice: SortChoice) => ({ value: choice.label } as SelectOption));
    }

    private pageSizeChoices(): number[] {
        return [20, 50, 100];
    }

    private pageSizeOptions(): SelectOption[] {
        return this.pageSizeChoices().map((size: number) => ({ value: `每页 ${size} 条` } as SelectOption));
    }

    private pageSize(): number {
        return this.pageSizeChoices()[this.pageSizeIndex];
    }

    private totalPages(): number {
        return Math.max(1, Math.ceil(this.total / this.pageSize()));
    }

    private load(force: boolean = false): void {
        if (this.loading) {
            return;
        }
        this.loading = true;
        const sort = this.sortChoices()[this.sortIndex].field;
        fetchAppsPage(
            this.page,
            this.pageSize(),
            sort,
            this.descending,
            undefined,
            undefined,
            false,
            force,
        ).then((result) => {
            const response = result.data as BaseAPIResponse<PageInfo<MarketApp>>;
            if (!response.success || !response.data) {
                throw new Error('应用列表数据不可用');
            }
            this.apps = response.data.data ?? [];
            this.total = response.data.total_count ?? 0;
            this.fromCache = result.stale;
            this.loaded = true;
        }).catch((error: Error) => {
            console.error('[Dashboard][pages/main/AppsPage][ERROR]', `应用列表加载失败: ${error.message}`);
            showToastSafely(this.prompt, `应用列表加载失败：${error.message}`, 2500, 'V3Apps');
        }).finally(() => this.loading = false);
    }

    private jump(): void {
        this.vibrate();
        const target = Number(this.jumpText);
        if (!Number.isInteger(target) || target < 1 || target > this.totalPages()) {
            showToastSafely(this.prompt, `请输入 1 到 ${this.totalPages()} 之间的页码`, 1800, 'V3Apps');
            return;
        }
        this.page = target;
        this.load(false);
    }

    private openDetail(app: MarketApp): void {
        setDetailTarget({ appId: app.app_id, packageName: app.pkg_name });
        try {
            this.pageStack.pushPathByName('AppDetailPage', null);
        } catch (error) {
            console.error('[Dashboard][pages/main/AppsPage][ERROR]', `打开应用详情失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, '暂时无法打开应用详情，请重试', 1800, 'AppsPage');
        }
    }

    build() {
        Stack({ alignContent: Alignment.Top }) {
            if (this.selectedIndexes[0] === 0) {
                Scroll(this.overviewScroller) {
                    Column({ space: 12 }) {
                        Blank().height(170).width('100%')
                        OverviewSection({ refreshVersion: this.overviewRefreshVersion })
                        Blank().height(20).width('100%')
                    }
                    .width('100%')
                    .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
                    .padding({ left: 14, right: 14 })
                }
                .width('100%')
                .height('100%')
                .scrollBar(BarState.Off)
                .edgeEffect(EdgeEffect.Spring)
                .onDidScroll((): void => {
                    try {
                        setContinuationView(MAIN_TAB_APPS, this.overviewScroller.currentOffset().yOffset);
                    } catch (error) {
                        console.warn('[Dashboard][pages/main/AppsPage][WARN]', `保存应用概况滚动位置失败: ${JSON.stringify(error)}`);
                    }
                })
                .backgroundColor($r('app.color.background'))
                .accessibilityText('可滚动的应用概况页面')
            }
            else {
                Scroll(this.pageScroller) {
                    Column({ space: 12 }) {
                        Blank().height(170).width('100%')
                        Row() {
                            Column({ space: 4 }) {
                                Text(`共 ${formatCount(this.total)} 条应用数据`)
                                    .fontSize(13)
                                    .fontColor($r('app.color.v3_text_secondary'))
                                    .accessibilityText(`共${formatCount(this.total)}条应用数据`)
                            }
                            .alignItems(HorizontalAlign.Start)
                            .layoutWeight(1)
                        }
                        .width('100%')
                        .padding({ left: 4, right: 4 })

                        Flex({ wrap: FlexWrap.Wrap }) {
                            Select(this.sortOptions())
                                .selected(this.sortIndex)
                                .value(this.sortChoices()[this.sortIndex].label)
                                .height(42)
                                .margin(4)
                                .backgroundColor($r('app.color.v3_surface'))
                                .onSelect((index: number) => {
                                    this.vibrate();
                                    this.sortIndex = index;
                                    this.page = 1;
                                    this.load(false);
                                })
                                .accessibilityText('选择应用列表排序字段')
                            Select(this.pageSizeOptions())
                                .selected(this.pageSizeIndex)
                                .value(`每页 ${this.pageSize()} 条`)
                                .height(42)
                                .margin(4)
                                .backgroundColor($r('app.color.v3_surface'))
                                .onSelect((index: number) => {
                                    this.vibrate();
                                    this.pageSizeIndex = index;
                                    this.page = 1;
                                    this.load(false);
                                })
                                .accessibilityText(`选择每页显示数量，当前每页${this.pageSize()}条`)
                            Button(this.descending ? '降序 ↓' : '升序 ↑')
                                .height(42)
                                .margin(4)
                                .fontColor($r('app.color.v3_accent_blue'))
                                .backgroundColor($r('app.color.v3_surface'))
                                .onClick(() => {
                                    this.vibrate();
                                    this.descending = !this.descending;
                                    this.page = 1;
                                    this.load(false);
                                })
                                .accessibilityText(this.descending ? '当前降序，点击改为升序' : '当前升序，点击改为降序')
                        }
                        .width('100%')
                        .accessibilityText('应用列表筛选与排序控件')

                        if (this.fromCache) {
                            Text('当前列表来自本地缓存；恢复网络后点击刷新可获取最新数据')
                                .fontSize(13)
                                .fontColor($r('app.color.v3_text_primary'))
                                .padding(10)
                                .width('100%')
                                .borderRadius(10)
                                .backgroundColor($r('app.color.v3_warning_bg'))
                                .accessibilityText('当前应用列表来自本地缓存')
                        }

                        Stack() {
                            Scroll() {
                                Column() {
                                    Row() {
                                        Text('序号').width(44).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                                        Text('应用').width(220).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                                        Text('开发者').width(150).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                                        Text('分类').width(140).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                                        Text('评分').width(70).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                                        Text('下载量').width(100).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                                        Text('大小').width(90).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                                        Text('更新时间').width(110).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                                    }
                                    .height(42)
                                    .width(924)
                                    .padding({ left: 8, right: 8 })
                                    .backgroundColor($r('app.color.v3_surface_alt'))
                                    .accessibilityText('应用列表表头')
                                    ForEach(this.apps, (app: MarketApp, index: number) => {
                                        AppTableRow({
                                            app,
                                            index: (this.page - 1) * this.pageSize() + index + 1,
                                            onOpen: (target: MarketApp) => this.openDetail(target),
                                        })
                                    }, (app: MarketApp) => `${app.app_id}-${app.updated_at}`)
                                }
                                .width(924)
                            }
                            .scrollable(ScrollDirection.Horizontal)
                            .scrollBar(BarState.Auto)
                            .edgeEffect(EdgeEffect.None)
                            .width('100%')
                            .accessibilityText('可横向滚动的应用列表')

                            if (this.loading) {
                                Column({ space: 8 }) {
                                    LoadingProgress()
                                        .width(32)
                                        .height(32)
                                        .color($r('app.color.v3_accent_blue'))
                                        .accessibilityText('应用列表加载中')
                                    Text('正在加载…')
                                        .fontColor($r('app.color.v3_text_secondary'))
                                        .accessibilityText('正在加载应用列表')
                                }
                                .padding(22)
                                .borderRadius(14)
                                .backgroundColor($r('app.color.v3_surface'))
                                .accessibilityGroup(true)
                            }
                        }
                        .width('100%')
                        .borderRadius(16)
                        .clip(true)
                        .backgroundColor($r('app.color.v3_surface'))
                        .border({ width: 1, color: $r('app.color.nd_card_border') })

                        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
                            Button('上一页')
                                .margin(4)
                                .enabled(this.page > 1 && !this.loading)
                                .backgroundColor($r('app.color.v3_surface_alt'))
                                .fontColor($r('app.color.v3_text_primary'))
                                .onClick(() => {
                                    this.vibrate();
                                    this.page--;
                                    this.load(false);
                                })
                                .accessibilityText('上一页')
                            Text(`第 ${this.page} / ${this.totalPages()} 页`)
                                .fontSize(13)
                                .fontColor($r('app.color.v3_text_secondary'))
                                .margin(8)
                                .accessibilityText(`第${this.page}页，共${this.totalPages()}页`)
                            Button('下一页')
                                .margin(4)
                                .enabled(this.page < this.totalPages() && !this.loading)
                                .backgroundColor($r('app.color.v3_accent_blue'))
                                .onClick(() => {
                                    this.vibrate();
                                    this.page++;
                                    this.load(false);
                                })
                                .accessibilityText('下一页')
                            TextInput({ text: this.jumpText, placeholder: '页码' })
                                .type(InputType.Number)
                                .width(84)
                                .height(40)
                                .margin(4)
                                .backgroundColor($r('app.color.v3_surface'))
                                .onChange((value: string) => this.jumpText = value)
                                .onSubmit(() => this.jump())
                                .accessibilityText('输入要跳转的页码')
                            Button('跳转')
                                .margin(4)
                                .height(40)
                                .backgroundColor($r('app.color.v3_accent_cyan'))
                                .onClick(() => this.jump())
                                .accessibilityText('跳转到指定页')
                        }
                        .width('100%')
                        .padding({ bottom: 110 })
                        .accessibilityText('应用列表分页控件')
                    }
                    .width('100%')
                    .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
                    .padding({ left: 14, right: 14 })
                    .backgroundColor($r('app.color.background'))
                    .onAppear(() => {
                        if (!this.loaded) {
                            this.load(false);
                        }
                        if (!this.restoredScroll) {
                            this.restoredScroll = true;
                            const continuation = getContinuationState();
                            if (continuation.mainTab === MAIN_TAB_APPS && continuation.routeName === CONTINUATION_ROUTE_MAIN &&
                                continuation.scrollDistance > 0) {
                                setTimeout((): void => {
                                    try {
                                        this.pageScroller.scrollTo({
                                            xOffset: 0,
                                            yOffset: continuation.scrollDistance,
                                            animation: { duration: 0 },
                                        });
                                    } catch (error) {
                                        console.warn('[Dashboard][pages/main/AppsPage][WARN]',
                                            `恢复滚动位置失败: ${JSON.stringify(error)}`);
                                    }
                                }, 80);
                            }
                        }
                    })
                    .accessibilityText('应用列表页面')
                }
                .width('100%')
                .height('100%')
                .scrollBar(BarState.Auto)
                .edgeEffect(EdgeEffect.Spring)
                .onDidScroll((): void => {
                    try {
                        setContinuationView(MAIN_TAB_APPS, this.pageScroller.currentOffset().yOffset);
                    } catch (error) {
                        console.warn('[Dashboard][pages/main/AppsPage][WARN]',
                            `保存滚动位置失败: ${JSON.stringify(error)}`);
                    }
                })
                .backgroundColor($r('app.color.background'))
                .accessibilityText('可上下滚动的应用列表页面')
            }

            Row() {
                HdsTitleBarSegment({
                    items: this.segmentItems,
                    selectedIndexes: $selectedIndexes,
                    onItemClicked: (index: number): void => {
                        this.vibrate();
                        this.selectedIndexes = [index];
                        setAppsViewIndex(index);
                    },
                })
            }
            .width('100%')
            .height(58)
            .justifyContent(FlexAlign.Center)
            .position({ x: 0, y: 100 })
            .zIndex(20)
            .accessibilityText('应用概况与应用列表切换栏')
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))
        .onAppear(() => {
            if (!this.restoredView) {
                this.restoredView = true;
                const continuation = getContinuationState();
                this.selectedIndexes = [continuation.appsViewIndex === 1 ? 1 : 0];
                if (continuation.mainTab === MAIN_TAB_APPS && continuation.appsViewIndex === 0 &&
                    continuation.scrollDistance > 0) {
                    setTimeout((): void => {
                        try {
                            this.overviewScroller.scrollTo({ xOffset: 0, yOffset: continuation.scrollDistance,
                                animation: { duration: 0 } });
                        } catch (error) {
                            console.warn('[Dashboard][pages/main/AppsPage][WARN]', `恢复应用概况滚动位置失败: ${JSON.stringify(error)}`);
                        }
                    }, 80);
                }
            }
        })
    }
}
