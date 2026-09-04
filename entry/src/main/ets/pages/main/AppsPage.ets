import { curves, PromptAction } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { CONTINUATION_ROUTE_MAIN, MAIN_TAB_APPS } from '../../common/constants';
import {
    getContinuationState, hasPendingSearchTarget, setContinuationView, setDetailTarget,
} from '../../common/appState';
import { fetchAppsPage } from '../../common/MarketApi';
import { formatBytes, formatCount, formatDateTime } from '../../common/format';
import type { BaseAPIResponse, MarketApp, PageInfo } from '../../common/types';
import { showToastSafely } from '../../common/safeUi';
import { appIconGeometryId } from '../../common/sharedTransition';
import { vibration } from '../../common/vibration';
import { OverviewSection } from '../../component/charts/OverviewSection';
import { SEARCH_SHARED_GEOMETRY_ID, SearchPage } from './SearchPage';

interface SortChoice { label: string; field: string; }
interface FilterChoice { label: string; field: string; }

@Component
struct AppTableRow {
    app: MarketApp = {} as MarketApp;
    index: number = 0;
    @Prop tableWidth: number = 924;
    @Prop developerWidth: number = 150;
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
            Text(String(this.index)).width(44).fontSize(12).textAlign(TextAlign.Center)
                .fontColor($r('app.color.v3_text_secondary')).accessibilityText(`序号${this.index}`)
            Row({ space: 8 }) {
                Image(this.app.icon_url || $r('app.media.startIcon')).width(34).height(34).borderRadius(8)
                    .objectFit(ImageFit.Cover).alt($r('app.media.startIcon'))
                    .geometryTransition(appIconGeometryId(this.app, 'apps'), { follow: true })
                    .accessibilityText(`${this.app.name || '未知应用'}图标`)
                Column({ space: 2 }) {
                    Text(this.app.name || '未知应用').fontSize(13).fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.app.pkg_name || this.app.app_id).fontSize(10)
                        .fontColor($r('app.color.v3_text_secondary')).maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                }.alignItems(HorizontalAlign.Start)
            }.width(220)
            Text(this.app.developer_name || '-').width(this.developerWidth).fontSize(12)
                .fontColor($r('app.color.diff_content')).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .accessibilityText(`开发者${this.app.developer_name || '未知'}`)
            Text(`${this.app.kind_type_name || '-'} · ${this.app.kind_name || '-'}`).width(140).fontSize(12)
                .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .accessibilityText(`分类${this.app.kind_type_name || ''}${this.app.kind_name || ''}`)
            Text(this.rating()).width(70).fontSize(12).fontColor($r('app.color.v3_text_primary'))
                .accessibilityText(`评分${this.rating()}`)
            Text(formatCount(this.app.download_count)).width(100).fontSize(12)
                .fontColor($r('app.color.v3_text_primary'))
                .accessibilityText(`下载量${formatCount(this.app.download_count)}`)
            Text(formatBytes(this.app.size_bytes)).width(90).fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .accessibilityText(`应用大小${formatBytes(this.app.size_bytes)}`)
            Text(formatDateTime(this.app.updated_at).split(' ')[0]).width(110).fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .accessibilityText(`更新时间${formatDateTime(this.app.updated_at)}`)
        }
        .width(this.tableWidth).height(58).padding({ left: 8, right: 8 })
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
        .accessibilityText(`序号${this.index}，${this.app.name || '未知应用'}，开发者${this.app.developer_name || '未知'}，分类${this.app.kind_type_name || ''}${this.app.kind_name || ''}，评分${this.rating()}，下载量${formatCount(this.app.download_count)}，点击打开详情`)
    }
}

@Component
export struct AppsPage {
    @Consume('pageStack') private pageStack: NavPathStack;
    @Prop @Watch('onScrollToTopVersionChanged') scrollToTopVersion: number = 0;
    @Prop @Watch('onSearchCommandVersionChanged') searchCommandVersion: number = 0;
    @Prop @Watch('onRequestVersionChanged') requestVersion: number = 0;
    @Prop @Watch('onSearchCloseVersionChanged') searchCloseVersion: number = 0;
    onSearchVisibilityChanged?: (visible: boolean) => void;
    onSearchOpenChanged?: (open: boolean) => void;
    @Link selectedIndexes: number[];
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private pageScroller: Scroller = new Scroller();
    @State private searchExpanded: boolean = false;
    @State private searchPullRefreshing: boolean = false;
    @State private titleSearchVisible: boolean = false;
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
    @State private typeIndex: number = 0;
    @State private filterIndex: number = 0;
    @State private filterText: string = '';
    @State private appliedFilterText: string = '';
    @State private tableViewportWidth: number = 0;
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;
    private restoredScroll: boolean = false;
    private restoredView: boolean = false;
    private reloadAfterCurrent: boolean = false;
    private reloadForce: boolean = false;

    private onScrollToTopVersionChanged(): void {
        if (this.scrollToTopVersion <= 0) return;
        try {
            this.pageScroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 300 } });
        } catch (error) {
            console.warn('[Dashboard][pages/main/AppsPage][WARN]', `返回顶部失败: ${JSON.stringify(error)}`);
        }
    }
    private onSearchCommandVersionChanged(): void { if (this.searchCommandVersion > 0) this.openSearch(false); }
    private onRequestVersionChanged(): void {
        if (this.requestVersion > 0 && hasPendingSearchTarget()) this.openSearch(false);
    }
    private onSearchCloseVersionChanged(): void {
        if (this.searchCloseVersion > 0 && this.searchExpanded) this.closeSearch();
    }
    private openSearch(withFeedback: boolean = true): void {
        if (this.searchExpanded) return;
        if (withFeedback) this.vibrate();
        this.titleSearchVisible = false;
        if (this.onSearchVisibilityChanged) this.onSearchVisibilityChanged(false);
        this.getUIContext().animateTo({
            curve: curves.interpolatingSpring(0, 1, 342, 38),
        }, (): void => {
            this.searchExpanded = true;
            if (this.onSearchOpenChanged) this.onSearchOpenChanged(true);
        });
    }
    private pullOpenSearch(): void {
        this.searchPullRefreshing = true;
        this.openSearch();
    }
    private closeSearch(): void {
        this.searchPullRefreshing = false;
        this.getUIContext().animateTo({
            curve: curves.interpolatingSpring(0, 1, 342, 38),
        }, (): void => {
            this.searchExpanded = false;
            if (this.onSearchOpenChanged) this.onSearchOpenChanged(false);
            this.updateTitleSearch(this.pageScroller);
        });
    }
    private safeOffset(scroller: Scroller): number {
        try { return scroller.currentOffset().yOffset; } catch (_error) { return 0; }
    }
    private updateTitleSearch(scroller: Scroller): void {
        const offset = this.safeOffset(scroller);
        const visible = offset > 10;
        if (visible === this.titleSearchVisible) return;
        this.titleSearchVisible = visible;
        if (this.onSearchVisibilityChanged) this.onSearchVisibilityChanged(visible);
    }
    private vibrate(): void { if (this.vibrationEnabled) vibration.dotVibration(); }
    private sortChoices(): SortChoice[] {
        return [
            { label: '更新时间', field: 'updated_at' }, { label: '下载量', field: 'download_count' },
            { label: '评分数量', field: 'total_star_rating_count' }, { label: '应用大小', field: 'size_bytes' },
            { label: '上架时间', field: 'listed_at' },
        ];
    }
    private filterChoices(): FilterChoice[] {
        return [
            { label: '应用名称', field: 'name' }, { label: '分类', field: 'kind_name' },
            { label: '类型', field: 'kind_type_name' }, { label: '标签', field: 'tag_name' },
            { label: '开发者', field: 'developer_name' },
        ];
    }
    private typeOptions(): SelectOption[] {
        return ['全部类型', '鸿蒙应用', '元服务'].map((label: string) => ({ value: label } as SelectOption));
    }
    private sortOptions(): SelectOption[] {
        return this.sortChoices().map((choice: SortChoice) => ({ value: choice.label } as SelectOption));
    }
    private filterOptions(): SelectOption[] {
        return this.filterChoices().map((choice: FilterChoice) => ({ value: choice.label } as SelectOption));
    }
    private pageSizeChoices(): number[] { return [20, 50, 100]; }
    private pageSizeOptions(): SelectOption[] {
        return this.pageSizeChoices().map((size: number) => ({ value: `每页 ${size} 条` } as SelectOption));
    }
    private pageSize(): number { return this.pageSizeChoices()[this.pageSizeIndex]; }
    private totalPages(): number { return Math.max(1, Math.ceil(this.total / this.pageSize())); }
    private tableWidth(): number { return Math.max(924, this.tableViewportWidth); }
    private developerWidth(): number { return 150 + Math.max(0, this.tableViewportWidth - 924); }

    private async load(force: boolean = false): Promise<void> {
        if (this.loading) {
            this.reloadAfterCurrent = true;
            this.reloadForce = this.reloadForce || force;
            return;
        }
        this.loading = true;
        const sort = this.sortChoices()[this.sortIndex].field;
        let searchKey: string | undefined = undefined;
        let searchValue: string | undefined = undefined;
        let excludeAtomic = false;
        if (this.typeIndex === 2) {
            searchKey = 'pkg_name';
            searchValue = 'com.atomicservice';
        } else {
            excludeAtomic = this.typeIndex === 1;
            if (this.appliedFilterText.length > 0) {
                searchKey = this.filterChoices()[this.filterIndex].field;
                searchValue = this.appliedFilterText;
            }
        }
        try {
            const result = await fetchAppsPage(this.page, this.pageSize(), sort, this.descending,
                searchKey, searchValue, false, force, false, excludeAtomic);
            const response = result.data as BaseAPIResponse<PageInfo<MarketApp>>;
            if (!response.success || !response.data) throw new Error('应用列表数据不可用');
            this.apps = response.data.data ?? [];
            this.total = response.data.total_count ?? 0;
            this.fromCache = result.stale;
            this.loaded = true;
        } catch (error) {
            const message = (error as Error).message;
            console.error('[Dashboard][pages/main/AppsPage][ERROR]', `应用列表加载失败: ${message}`);
            showToastSafely(this.prompt, `应用列表加载失败：${message}`, 2500, 'V3Apps');
        } finally {
            this.loading = false;
            if (this.reloadAfterCurrent) {
                const forceNext = this.reloadForce;
                this.reloadAfterCurrent = false;
                this.reloadForce = false;
                setTimeout((): void => { this.load(forceNext); }, 0);
            }
        }
    }
    private applyFilter(): void {
        this.vibrate();
        this.appliedFilterText = this.filterText.trim();
        this.page = 1;
        this.load(false);
    }
    private clearFilter(): void {
        this.vibrate();
        this.typeIndex = 0;
        this.filterText = '';
        this.appliedFilterText = '';
        this.page = 1;
        this.load(false);
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
        try {
            this.getUIContext().animateTo({
                curve: curves.interpolatingSpring(0, 1, 342, 38),
            }, (): void => {
                setDetailTarget({
                    appId: app.app_id,
                    packageName: app.pkg_name,
                    previewApp: app,
                    geometryId: appIconGeometryId(app, 'apps'),
                });
                this.pageStack.pushPath({ name: 'AppDetailPage', param: null }, true);
            });
        }
        catch (error) {
            console.error('[Dashboard][pages/main/AppsPage][ERROR]',
                `打开应用详情失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, '暂时无法打开应用详情，请重试', 1800, 'AppsPage');
        }
    }
    private recordScroll(scroller: Scroller): void {
        try {
            const offset = scroller.currentOffset().yOffset;
            this.updateTitleSearch(scroller);
            setContinuationView(MAIN_TAB_APPS, offset);
        } catch (error) {
            console.warn('[Dashboard][pages/main/AppsPage][WARN]', `保存滚动位置失败: ${JSON.stringify(error)}`);
        }
    }

    @Builder
    private searchPullHint(): void {
        Column()
            .width('100%')
            .height(36)
            .accessibilityText('下拉打开应用搜索')
    }

    @Builder
    private commonHeader(): void {
        Column() {
            Search({ placeholder: '搜索应用名称、包名、App ID 或链接' })
                .width('100%').height(48).defaultFocus(false)
                .backgroundColor($r('app.color.v3_surface_alt'))
                .geometryTransition(SEARCH_SHARED_GEOMETRY_ID, { follow: true })
                .onClick(() => this.openSearch())
                .accessibilityText('打开应用搜索')
        }
        .width('100%')
        .accessibilityText('应用搜索入口')
    }

    @Builder
    private filterBar(): void {
        Column({ space: 8 }) {
            Flex({ wrap: FlexWrap.Wrap }) {
                Select(this.typeOptions()).selected(this.typeIndex)
                    .value(['全部类型', '鸿蒙应用', '元服务'][this.typeIndex]).height(42).margin(4)
                    .backgroundColor($r('app.color.v3_surface'))
                    .onSelect((index: number) => { this.typeIndex = index; this.page = 1; this.load(false); })
                    .accessibilityText('筛选全部类型鸿蒙应用或元服务')
                Select(this.filterOptions()).selected(this.filterIndex)
                    .value(this.filterChoices()[this.filterIndex].label).height(42).margin(4)
                    .backgroundColor($r('app.color.v3_surface'))
                    .onSelect((index: number) => this.filterIndex = index)
                    .accessibilityText('选择筛选字段')
                TextInput({ text: this.filterText, placeholder: '输入筛选内容' }).height(42).margin(4)
                    .constraintSize({ minWidth: 170, maxWidth: 280 }).backgroundColor($r('app.color.v3_surface'))
                    .onChange((value: string) => this.filterText = value).onSubmit(() => this.applyFilter())
                    .accessibilityText(`按${this.filterChoices()[this.filterIndex].label}输入筛选内容`)
                Button('筛选').height(42).margin(4).backgroundColor($r('app.color.diff_content'))
                    .onClick(() => this.applyFilter()).accessibilityText('应用筛选条件')
                Button('清除').height(42).margin(4).fontColor($r('app.color.diff_content'))
                    .backgroundColor($r('app.color.v3_surface')).onClick(() => this.clearFilter())
                    .accessibilityText('清除全部筛选条件')
            }.width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
                Select(this.sortOptions()).selected(this.sortIndex).value(this.sortChoices()[this.sortIndex].label)
                    .height(42).margin(4).backgroundColor($r('app.color.v3_surface'))
                    .onSelect((index: number) => { this.sortIndex = index; this.page = 1; this.load(false); })
                    .accessibilityText('选择应用列表排序字段')
                Select(this.pageSizeOptions()).selected(this.pageSizeIndex).value(`每页 ${this.pageSize()} 条`)
                    .height(42).margin(4).backgroundColor($r('app.color.v3_surface'))
                    .onSelect((index: number) => { this.pageSizeIndex = index; this.page = 1; this.load(false); })
                    .accessibilityText(`选择每页显示数量，当前每页${this.pageSize()}条`)
                Button(this.descending ? '降序 ↓' : '升序 ↑').height(42).margin(4)
                    .fontColor($r('app.color.diff_content')).backgroundColor($r('app.color.v3_surface'))
                    .onClick(() => { this.descending = !this.descending; this.page = 1; this.load(false); })
                    .accessibilityText(this.descending ? '当前降序，点击改为升序' : '当前升序，点击改为降序')
            }.width('100%')
        }.width('100%').accessibilityText('应用列表筛选与排序控件')
    }

    @Builder
    private table(): void {
        Stack() {
            Scroll() {
                Column() {
                    Row() {
                        Text('序号').width(44).fontSize(12).textAlign(TextAlign.Center)
                            .fontColor($r('app.color.v3_text_secondary'))
                        Text('应用').width(220).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text('开发者').width(this.developerWidth()).fontSize(12)
                            .fontColor($r('app.color.v3_text_secondary'))
                        Text('分类').width(140).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text('评分').width(70).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text('下载量').width(100).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text('大小').width(90).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text('更新时间').width(110).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                    }
                    .height(42).width(this.tableWidth()).padding({ left: 8, right: 8 })
                    .backgroundColor($r('app.color.v3_surface_alt')).accessibilityText('应用列表表头')
                    ForEach(this.apps, (app: MarketApp, index: number) => {
                        AppTableRow({
                            app, index: (this.page - 1) * this.pageSize() + index + 1,
                            tableWidth: this.tableWidth(), developerWidth: this.developerWidth(),
                            onOpen: (target: MarketApp) => this.openDetail(target),
                        })
                    }, (app: MarketApp) => `${app.app_id}-${app.updated_at}`)
                }.width(this.tableWidth())
            }
            .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.None)
            .width('100%').accessibilityText('应用列表，窄屏可横向滚动')
            if (this.loading) {
                Column({ space: 8 }) {
                    LoadingProgress().width(32).height(32).color($r('app.color.diff_content'))
                        .accessibilityText('应用列表加载中')
                    Text('正在加载…').fontColor($r('app.color.v3_text_secondary'))
                }.padding(22).borderRadius(14).backgroundColor($r('app.color.v3_surface')).accessibilityGroup(true)
            }
        }
        .width('100%').borderRadius(16).clip(true).backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .onAreaChange((_oldValue: Area, newValue: Area): void => {
            const width = Number(newValue.width);
            if (width > 0) this.tableViewportWidth = width;
        })
    }

    @Builder
    private pagination(): void {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
            Button('上一页').margin(4).enabled(this.page > 1 && !this.loading)
                .backgroundColor($r('app.color.v3_surface_alt')).fontColor($r('app.color.v3_text_primary'))
                .onClick(() => { this.page--; this.load(false); }).accessibilityText('上一页')
            Text(`第 ${this.page} / ${this.totalPages()} 页`).fontSize(13)
                .fontColor($r('app.color.v3_text_secondary')).margin(8)
                .accessibilityText(`第${this.page}页，共${this.totalPages()}页`)
            Button('下一页').margin(4).enabled(this.page < this.totalPages() && !this.loading)
                .backgroundColor($r('app.color.diff_content'))
                .onClick(() => { this.page++; this.load(false); }).accessibilityText('下一页')
            TextInput({ text: this.jumpText, placeholder: '页码' }).type(InputType.Number)
                .width(84).height(40).margin(4).backgroundColor($r('app.color.v3_surface'))
                .onChange((value: string) => this.jumpText = value).onSubmit(() => this.jump())
                .accessibilityText('输入要跳转的页码')
            Button('跳转').margin(4).height(40).backgroundColor($r('app.color.v3_accent_cyan'))
                .onClick(() => this.jump()).accessibilityText('跳转到指定页')
        }.width('100%').padding({ bottom: 110 }).accessibilityText('应用列表分页控件')
    }

    build() {
        Stack({ alignContent: Alignment.Top }) {
            Refresh({ refreshing: $$this.searchPullRefreshing, builder: this.searchPullHint() }) {
                Scroll(this.pageScroller) {
                    Column({ space: 12 }) {
                        Blank().height(148).width('100%')
                        if (!this.searchExpanded) {
                            this.commonHeader()
                        }
                        if (this.selectedIndexes[0] === 0) {
                            Column({ space: 12 }) {
                                OverviewSection()
                                Blank().height(110).width('100%')
                            }
                            .width('100%')
                            .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
                        } else {
                            Column({ space: 12 }) {
                                Text(`共 ${formatCount(this.total)} 条应用数据`).fontSize(13)
                                    .fontColor($r('app.color.v3_text_secondary')).width('100%')
                                    .accessibilityText(`共${formatCount(this.total)}条应用数据`)
                                this.filterBar()
                                if (this.typeIndex === 2 && this.appliedFilterText.length > 0) {
                                    Text('元服务类型筛选优先，字段筛选将在切换到全部类型或鸿蒙应用后生效')
                                        .fontSize(12).fontColor($r('app.color.v3_accent_orange')).width('100%')
                                }
                                if (this.fromCache) {
                                    Text('当前列表来自本地缓存；恢复网络后重新加载即可获取最新数据')
                                        .fontSize(13).fontColor($r('app.color.v3_text_primary')).padding(10)
                                        .width('100%').borderRadius(10).backgroundColor($r('app.color.v3_warning_bg'))
                                        .accessibilityText('当前应用列表来自本地缓存')
                                }
                                this.table()
                                this.pagination()
                            }
                            .width('100%')
                            .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
                            .onAppear(() => {
                                if (!this.loaded) this.load(false);
                            })
                        }
                    }
                    .width('100%').padding({ left: 14, right: 14 })
                    .onAppear(() => {
                        if (!this.restoredScroll) {
                            this.restoredScroll = true;
                            const continuation = getContinuationState();
                            if (continuation.mainTab === MAIN_TAB_APPS &&
                                continuation.routeName === CONTINUATION_ROUTE_MAIN && continuation.scrollDistance > 0) {
                                setTimeout((): void => this.pageScroller.scrollTo({
                                    xOffset: 0, yOffset: continuation.scrollDistance, animation: { duration: 0 },
                                }), 80);
                            }
                        }
                    })
                }
                .width('100%').height('100%').scrollBar(BarState.Auto).edgeEffect(EdgeEffect.Spring)
                .onDidScroll((): void => this.recordScroll(this.pageScroller))
                .accessibilityText('可滚动并支持下拉打开应用搜索的应用页面')
            }
            .width('100%').height('100%')
            .refreshOffset(36)
            .onRefreshing((): void => this.pullOpenSearch())
            .accessibilityText('下拉可打开应用搜索')

            if (this.searchExpanded) {
                SearchPage({
                    requestVersion: this.requestVersion,
                    geometryId: SEARCH_SHARED_GEOMETRY_ID,
                    onClose: (): void => this.closeSearch(),
                })
                .width('100%').height('100%').zIndex(100)
            }
        }
        .width('100%').height('100%').backgroundColor($r('app.color.background'))
        .onAppear(() => {
            if (!this.restoredView) {
                this.restoredView = true;
                const continuation = getContinuationState();
                this.selectedIndexes = [continuation.appsViewIndex === 1 ? 1 : 0];
            }
            if (this.requestVersion > 0 && hasPendingSearchTarget()) this.openSearch(false);
        })
    }
}
