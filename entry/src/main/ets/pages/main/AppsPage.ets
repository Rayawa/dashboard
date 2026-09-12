import { curves, PromptAction } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { CONTINUATION_ROUTE_MAIN, MAIN_TAB_APPS, SEARCH_SHARED_GEOMETRY_ID } from '../../common/constants';
import {
    getContinuationState, hasPendingSearchTarget, setContinuationAppsListState, setContinuationView, setDetailTarget,
} from '../../common/appState';
import type { AppsListContinuationState } from '../../common/appState';
import { fetchAppsPage } from '../../common/MarketApi';
import { formatCount } from '../../common/format';
import { scrollByAxis } from '../../common/scroll';
import type { AppRouteTarget, BaseAPIResponse, MarketApp, PageInfo } from '../../common/types';
import { showToastSafely } from '../../common/safeUi';
import {
    cancelStaggerEnterAnimation,
    contentEnterTransition,
    startStaggerEnterAnimation,
} from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { vibration } from '../../common/vibration';
import { OverviewSection } from '../../component/charts/OverviewSection';
import { AppTableRow } from '../../component/apps/AppTableRow';
import { SearchPage } from './SearchPage';

interface SortChoice { label: string; field: string; }
interface FilterChoice { label: string; field: string; }
const SEARCH_PULL_TRIGGER_DISTANCE_VP: number = 64;

@Component
export struct AppsPage {
    @Prop @Watch('onScrollToTopVersionChanged') scrollToTopVersion: number = 0;
    @Prop @Watch('onSearchCommandVersionChanged') searchCommandVersion: number = 0;
    @Prop @Watch('onRequestVersionChanged') requestVersion: number = 0;
    @Prop @Watch('onSearchCloseVersionChanged') searchCloseVersion: number = 0;
    @Prop @Watch('onActiveChanged') active: boolean = false;
    onSearchOpenChanged?: (open: boolean) => void;
    onOpenAppDetail?: (target: AppRouteTarget) => void;
    @Link selectedIndexes: number[];
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private pageScroller: Scroller = new Scroller();
    private readonly sortChoiceItems: SortChoice[] = [
        { label: '更新时间', field: 'updated_at' }, /* { label: '下载量', field: 'download_count' }, */
        { label: '评分数量', field: 'total_star_rating_count' }, { label: '应用大小', field: 'size_bytes' },
        { label: '上架时间', field: 'listed_at' },
    ];
    private readonly filterChoiceItems: FilterChoice[] = [
        { label: '应用名称', field: 'name' }, { label: '分类', field: 'kind_name' },
        { label: '类型', field: 'kind_type_name' }, { label: '标签', field: 'tag_name' },
        { label: '开发者', field: 'developer_name' },
    ];
    private readonly typeSelectOptions: SelectOption[] = ['全部类型', '应用', '元服务']
        .map((label: string) => ({ value: label } as SelectOption));
    private readonly sortSelectOptions: SelectOption[] = this.sortChoiceItems
        .map((choice: SortChoice) => ({ value: choice.label } as SelectOption));
    private readonly filterSelectOptions: SelectOption[] = this.filterChoiceItems
        .map((choice: FilterChoice) => ({ value: choice.label } as SelectOption));
    private readonly pageSizes: number[] = [20, 50, 100];
    private readonly pageSizeSelectOptions: SelectOption[] = this.pageSizes
        .map((size: number) => ({ value: `每页 ${size} 条` } as SelectOption));
    @State private searchExpanded: boolean = false;
    @State private searchPullRefreshing: boolean = false;
    @State private apps: MarketApp[] = [];
    @State private page: number = 1;
    @State private total: number = 0;
    @State private loading: boolean = false;
    @State private loaded: boolean = false;
    @State private fromCache: boolean = false;
    @State private sortIndex: number = 1;
    @State private pageSizeIndex: number = 0;
    @State private descending: boolean = true;
    @State private jumpText: string = '';
    @State private typeIndex: number = 0;
    @State private filterIndex: number = 0;
    @State private filterText: string = '';
    @State private appliedFilterText: string = '';
    @State private tableViewportWidth: number = 0;
    @State private animStep: number = 0;
    @State private searchPressed: boolean = false;
    @State private pressedControl: string = '';
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    private restoredScroll: boolean = false;
    private restoredView: boolean = false;
    private reloadAfterCurrent: boolean = false;
    private reloadForce: boolean = false;
    private listLoadToken: number = 0;
    private enterAnimationPlayed: boolean = false;
    private enterAnimationTimers: number[] = [];
    private restoreScrollTimer: number = -1;
    private reloadTimer: number = -1;

    private onActiveChanged(): void {
        if (this.active) this.startPageAnimationOnce();
    }

    private startPageAnimationOnce(): void {
        if (this.enterAnimationPlayed) return;
        this.enterAnimationPlayed = true;
        this.animStep = 0;
        this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 5, (step: number): void => {
            this.animStep = step;
        });
    }

    aboutToDisappear(): void {
        this.listLoadToken++;
        this.reloadAfterCurrent = false;
        this.reloadForce = false;
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.enterAnimationTimers = [];
        if (this.restoreScrollTimer >= 0) {
            clearTimeout(this.restoreScrollTimer);
            this.restoreScrollTimer = -1;
        }
        if (this.reloadTimer >= 0) {
            clearTimeout(this.reloadTimer);
            this.reloadTimer = -1;
        }
    }

    private validIndex(value: number, count: number): number {
        const index = Number(value);
        return Number.isInteger(index) && index >= 0 && index < count ? index : 0;
    }

    private restoredSortIndex(state: AppsListContinuationState): number {
        const legacySortFields: string[] = [
            'updated_at', 'download_count', 'total_star_rating_count', 'size_bytes', 'listed_at',
        ];
        let field = state.sortField ?? '';
        if (field.length === 0) {
            const legacyIndex = Number(state.sortIndex);
            if (Number.isInteger(legacyIndex) && legacyIndex >= 0 && legacyIndex < legacySortFields.length) {
                field = legacySortFields[legacyIndex];
            }
        }
        // 下载量排序不再对外提供；旧状态平滑迁移到当前默认的评分数量排序。
        if (field === 'download_count') {
            field = 'total_star_rating_count';
        }
        for (let index = 0; index < this.sortChoices().length; index++) {
            if (this.sortChoices()[index].field === field) {
                return index;
            }
        }
        return 0;
    }

    private restoreContinuationListState(): void {
        const state = getContinuationState().appsListState;
        const restoredPage = Number(state.page);
        this.page = Number.isInteger(restoredPage) && restoredPage > 0 ? restoredPage : 1;
        this.pageSizeIndex = this.validIndex(state.pageSizeIndex, this.pageSizeChoices().length);
        this.typeIndex = this.validIndex(state.typeIndex, this.typeOptions().length);
        this.filterIndex = this.validIndex(state.filterIndex, this.filterChoices().length);
        this.filterText = typeof state.filterText === 'string' ? state.filterText : '';
        this.appliedFilterText = typeof state.appliedFilterText === 'string' ? state.appliedFilterText : '';
        this.sortIndex = this.restoredSortIndex(state);
        this.descending = state.descending !== false;
    }

    private recordListState(): void {
        const state: AppsListContinuationState = {
            page: this.page,
            pageSizeIndex: this.pageSizeIndex,
            typeIndex: this.typeIndex,
            filterIndex: this.filterIndex,
            filterText: this.filterText,
            appliedFilterText: this.appliedFilterText,
            sortIndex: this.sortIndex,
            sortField: this.sortChoices()[this.sortIndex].field,
            descending: this.descending,
        };
        setContinuationAppsListState(state);
    }

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
        try {
            this.getUIContext().getFocusController().clearFocus();
        } catch (error) {
            console.warn('[Dashboard][pages/main/AppsPage][WARN]',
                `打开搜索页前清除焦点失败: ${JSON.stringify(error)}`);
        }
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
        });
    }
    private vibrate(): void { if (this.vibrationLevel > 0) vibration.dotVibration(); }
    private sortChoices(): SortChoice[] {
        return this.sortChoiceItems;
    }
    private filterChoices(): FilterChoice[] {
        return this.filterChoiceItems;
    }
    private typeOptions(): SelectOption[] {
        return this.typeSelectOptions;
    }
    private sortOptions(): SelectOption[] {
        return this.sortSelectOptions;
    }
    private filterOptions(): SelectOption[] {
        return this.filterSelectOptions;
    }
    private pageSizeChoices(): number[] { return this.pageSizes; }
    private pageSizeOptions(): SelectOption[] {
        return this.pageSizeSelectOptions;
    }
    private pageSize(): number { return this.pageSizeChoices()[this.pageSizeIndex]; }
    private totalPages(): number { return Math.max(1, Math.ceil(this.total / this.pageSize())); }
    private tableWidth(): number { return Math.max(924, this.tableViewportWidth); }
    private developerWidth(): number { return 150 + Math.max(0, this.tableViewportWidth - 924); }

    private async load(force: boolean = false): Promise<void> {
        const loadToken = ++this.listLoadToken;
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
            const result = await fetchAppsPage({
                page: this.page,
                pageSize: this.pageSize(),
                sort,
                desc: this.descending,
                searchKey,
                searchValue,
                exact: false,
                force,
                excludeHuawei: false,
                excludeAtomic,
            });
            const response = result.data as BaseAPIResponse<PageInfo<MarketApp>>;
            if (!response.success || !response.data) throw new Error('应用列表数据不可用');
            if (loadToken !== this.listLoadToken) return;
            this.apps = response.data.data ?? [];
            this.total = response.data.total_count ?? 0;
            this.fromCache = result.stale;
            this.loaded = true;
        } catch (error) {
            if (loadToken !== this.listLoadToken) return;
            const message = (error as Error).message;
            console.error('[Dashboard][pages/main/AppsPage][ERROR]', `应用列表加载失败: ${message}`);
            showToastSafely(this.prompt, `应用列表加载失败：${message}`, 2500, 'V3Apps');
        } finally {
            this.loading = false;
            if (this.reloadAfterCurrent) {
                const forceNext = this.reloadForce;
                this.reloadAfterCurrent = false;
                this.reloadForce = false;
                this.reloadTimer = setTimeout((): void => {
                    this.reloadTimer = -1;
                    this.load(forceNext);
                }, 0);
            }
        }
    }
    private applyFilter(): void {
        this.vibrate();
        this.appliedFilterText = this.filterText.trim();
        this.page = 1;
        this.recordListState();
        this.load(false);
    }
    private clearFilter(): void {
        this.vibrate();
        this.typeIndex = 0;
        this.filterText = '';
        this.appliedFilterText = '';
        this.page = 1;
        this.recordListState();
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
        this.recordListState();
        this.load(false);
    }
    private openDetail(app: MarketApp): void {
        const target: AppRouteTarget = {
            appId: app.app_id,
            packageName: app.pkg_name,
            previewApp: app,
        };
        try {
            setDetailTarget(target);
            this.onOpenAppDetail?.(target);
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
            setContinuationView(MAIN_TAB_APPS, offset);
        } catch (error) {
            console.warn('[Dashboard][pages/main/AppsPage][WARN]', `保存滚动位置失败: ${JSON.stringify(error)}`);
        }
    }

    @Builder
    private searchPullHint(): void {
        Column()
            .width('100%')
            .height(SEARCH_PULL_TRIGGER_DISTANCE_VP)
            .accessibilityText('下拉打开应用搜索')
    }

    @Builder
    private commonHeader(): void {
        Column() {
            Search({ placeholder: '搜索应用名称、包名、App ID 或链接' })
                .width('100%').height(48).defaultFocus(false).enableKeyboardOnFocus(false)
                .backgroundColor($r('app.color.v3_surface_alt'))
                .border({ width: 1, color: $r('app.color.nd_card_border') })
                .geometryTransition(SEARCH_SHARED_GEOMETRY_ID, { follow: true })
                .transition(TransitionEffect.OPACITY)
                .scale({ x: this.searchPressed ? 0.985 : 1, y: this.searchPressed ? 0.985 : 1 })
                .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
                .onTouch((event: TouchEvent): void => {
                    if (event.type === TouchType.Down) {
                        this.searchPressed = true;
                    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                        this.searchPressed = false;
                    }
                })
                .onClick(() => this.openSearch())
                .accessibilityText('打开应用搜索')
        }
        .width('100%')
        .opacity(this.animStep >= 1 ? 1 : 0)
        .translate({ y: this.animStep >= 1 ? 0 : 20 })
        .accessibilityText('应用搜索入口')
    }

    @Builder
    private filterBar(): void {
        Column({ space: 8 }) {
            Flex({ wrap: FlexWrap.Wrap }) {
                Select(this.typeOptions()).selected(this.typeIndex)
                    .value(['全部类型', '应用', '元服务'][this.typeIndex]).height(42).margin(4)
                    .backgroundColor($r('app.color.v3_surface'))
                    .scale({ x: this.pressedControl === 'type' ? 0.97 : 1,
                        y: this.pressedControl === 'type' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(
                        this.pressedControl === 'type', hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === 'type'))
                    .onTouch((event: TouchEvent): void => {
                        if (event.type === TouchType.Down) this.pressedControl = 'type';
                        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                            this.pressedControl = '';
                        }
                    })
                    .onSelect((index: number) => {
                        this.vibrate();
                        this.typeIndex = index;
                        this.page = 1;
                        this.recordListState();
                        this.load(false);
                    })
                    .accessibilityText('筛选全部类型应用或元服务')
                Select(this.filterOptions()).selected(this.filterIndex)
                    .value(this.filterChoices()[this.filterIndex].label).height(42).margin(4)
                    .backgroundColor($r('app.color.v3_surface'))
                    .scale({ x: this.pressedControl === 'filter-kind' ? 0.97 : 1,
                        y: this.pressedControl === 'filter-kind' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedControl === 'filter-kind',
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === 'filter-kind'))
                    .onTouch((event: TouchEvent): void => {
                        if (event.type === TouchType.Down) this.pressedControl = 'filter-kind';
                        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                            this.pressedControl = '';
                        }
                    })
                    .onSelect((index: number) => {
                        this.vibrate();
                        this.filterIndex = index;
                        this.recordListState();
                    })
                    .accessibilityText('选择筛选字段')
                TextInput({ text: this.filterText, placeholder: '输入筛选内容' }).height(42).margin(4)
                    .constraintSize({ minWidth: 170, maxWidth: 280 }).backgroundColor($r('app.color.v3_surface'))
                    .border({ width: 1, color: $r('app.color.nd_card_border') })
                    .scale({ x: this.pressedControl === 'filter-text' ? 0.97 : 1,
                        y: this.pressedControl === 'filter-text' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .onTouch((event: TouchEvent): void => {
                        if (event.type === TouchType.Down) this.pressedControl = 'filter-text';
                        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                            this.pressedControl = '';
                        }
                    })
                    .onChange((value: string) => {
                        this.filterText = value;
                        this.recordListState();
                    }).onSubmit(() => {
                        this.vibrate();
                        this.applyFilter();
                    })
                    .accessibilityText(`按${this.filterChoices()[this.filterIndex].label}输入筛选内容`)
                Button('筛选', { stateEffect: false }).height(42).margin(4)
                    .backgroundColor($r('app.color.diff_content'))
                    .scale({ x: this.pressedControl === 'apply-filter' ? 0.97 : 1,
                        y: this.pressedControl === 'apply-filter' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedControl === 'apply-filter',
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === 'apply-filter'))
                    .onTouch((event: TouchEvent): void => {
                        if (event.type === TouchType.Down) this.pressedControl = 'apply-filter';
                        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                            this.pressedControl = '';
                        }
                    })
                    .onClick(() => { this.vibrate(); this.applyFilter(); }).accessibilityText('应用筛选条件')
                Button('清除', { stateEffect: false }).height(42).margin(4).fontColor($r('app.color.diff_content'))
                    .backgroundColor($r('app.color.v3_surface')).onClick(() => {
                        this.vibrate();
                        this.clearFilter();
                    })
                    .scale({ x: this.pressedControl === 'clear-filter' ? 0.97 : 1,
                        y: this.pressedControl === 'clear-filter' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedControl === 'clear-filter',
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === 'clear-filter'))
                    .onTouch((event: TouchEvent): void => {
                        if (event.type === TouchType.Down) this.pressedControl = 'clear-filter';
                        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                            this.pressedControl = '';
                        }
                    })
                    .accessibilityText('清除全部筛选条件')
            }.width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
                Select(this.sortOptions()).selected(this.sortIndex).value(this.sortChoices()[this.sortIndex].label)
                    .height(42).margin(4).backgroundColor($r('app.color.v3_surface'))
                    .scale({ x: this.pressedControl === 'sort' ? 0.97 : 1,
                        y: this.pressedControl === 'sort' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(
                        this.pressedControl === 'sort', hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === 'sort'))
                    .onTouch((event: TouchEvent): void => {
                        if (event.type === TouchType.Down) this.pressedControl = 'sort';
                        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                            this.pressedControl = '';
                        }
                    })
                    .onSelect((index: number) => {
                        this.vibrate();
                        this.sortIndex = index;
                        this.page = 1;
                        this.recordListState();
                        this.load(false);
                    })
                    .accessibilityText('选择应用列表排序字段')
                Select(this.pageSizeOptions()).selected(this.pageSizeIndex).value(`每页 ${this.pageSize()} 条`)
                    .height(42).margin(4).backgroundColor($r('app.color.v3_surface'))
                    .scale({ x: this.pressedControl === 'page-size' ? 0.97 : 1,
                        y: this.pressedControl === 'page-size' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedControl === 'page-size',
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === 'page-size'))
                    .onTouch((event: TouchEvent): void => {
                        if (event.type === TouchType.Down) this.pressedControl = 'page-size';
                        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                            this.pressedControl = '';
                        }
                    })
                    .onSelect((index: number) => {
                        this.vibrate();
                        this.pageSizeIndex = index;
                        this.page = 1;
                        this.recordListState();
                        this.load(false);
                    })
                    .accessibilityText(`选择每页显示数量，当前每页${this.pageSize()}条`)
                Button(this.descending ? '降序 ↓' : '升序 ↑', { stateEffect: false }).height(42).margin(4)
                    .fontColor($r('app.color.diff_content')).backgroundColor($r('app.color.v3_surface'))
                    .scale({ x: this.pressedControl === 'sort-direction' ? 0.97 : 1,
                        y: this.pressedControl === 'sort-direction' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedControl === 'sort-direction',
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === 'sort-direction'))
                    .onTouch((event: TouchEvent): void => {
                        if (event.type === TouchType.Down) this.pressedControl = 'sort-direction';
                        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                            this.pressedControl = '';
                        }
                    })
                    .onClick(() => {
                        this.vibrate();
                        this.descending = !this.descending;
                        this.page = 1;
                        this.recordListState();
                        this.load(false);
                    })
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
                        // Text('下载量').width(100).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
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
                        .transition(contentEnterTransition(6))
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
                    .accessibilityText('应用列表加载中')
                    .transition(contentEnterTransition(8))
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
            Button('上一页', { stateEffect: false }).margin(4).enabled(this.page > 1 && !this.loading)
                .backgroundColor($r('app.color.v3_surface_alt')).fontColor($r('app.color.v3_text_primary'))
                .scale({ x: this.pressedControl === 'previous-page' ? 0.97 : 1,
                    y: this.pressedControl === 'previous-page' ? 0.97 : 1 })
                .animation({ duration: 120, curve: Curve.EaseOut })
                .visualEffect(pressVisualEffect(this.pressedControl === 'previous-page',
                    hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                .compositingFilter(pressLightFieldFilter(this.pressedControl === 'previous-page'))
                .onTouch((event: TouchEvent): void => {
                    if (event.type === TouchType.Down) this.pressedControl = 'previous-page';
                    else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                        this.pressedControl = '';
                    }
                })
                .onClick(() => {
                    this.vibrate();
                    this.page--;
                    this.recordListState();
                    this.load(false);
                }).accessibilityText('上一页')
            Text(`第 ${this.page} / ${this.totalPages()} 页`).fontSize(13)
                .fontColor($r('app.color.v3_text_secondary')).margin(8)
                .accessibilityText(`第${this.page}页，共${this.totalPages()}页`)
            Button('下一页', { stateEffect: false }).margin(4).enabled(this.page < this.totalPages() && !this.loading)
                .backgroundColor($r('app.color.diff_content'))
                .scale({ x: this.pressedControl === 'next-page' ? 0.97 : 1,
                    y: this.pressedControl === 'next-page' ? 0.97 : 1 })
                .animation({ duration: 120, curve: Curve.EaseOut })
                .visualEffect(pressVisualEffect(this.pressedControl === 'next-page',
                    hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                .compositingFilter(pressLightFieldFilter(this.pressedControl === 'next-page'))
                .onTouch((event: TouchEvent): void => {
                    if (event.type === TouchType.Down) this.pressedControl = 'next-page';
                    else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                        this.pressedControl = '';
                    }
                })
                .onClick(() => {
                    this.vibrate();
                    this.page++;
                    this.recordListState();
                    this.load(false);
                }).accessibilityText('下一页')
            TextInput({ text: this.jumpText, placeholder: '页码' }).type(InputType.Number)
                .width(84).height(40).margin(4).backgroundColor($r('app.color.v3_surface'))
                .border({ width: 1, color: $r('app.color.nd_card_border') })
                .scale({ x: this.pressedControl === 'jump-page' ? 0.97 : 1,
                    y: this.pressedControl === 'jump-page' ? 0.97 : 1 })
                .animation({ duration: 120, curve: Curve.EaseOut })
                .onTouch((event: TouchEvent): void => {
                    if (event.type === TouchType.Down) this.pressedControl = 'jump-page';
                    else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                        this.pressedControl = '';
                    }
                })
                .onChange((value: string) => this.jumpText = value).onSubmit(() => {
                    this.vibrate();
                    this.jump();
                })
                .accessibilityText('输入要跳转的页码')
            Button('跳转', { stateEffect: false }).margin(4).height(40)
                .backgroundColor($r('app.color.v3_accent_cyan'))
                .scale({ x: this.pressedControl === 'jump' ? 0.97 : 1,
                    y: this.pressedControl === 'jump' ? 0.97 : 1 })
                .animation({ duration: 120, curve: Curve.EaseOut })
                .visualEffect(pressVisualEffect(this.pressedControl === 'jump',
                    hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                .compositingFilter(pressLightFieldFilter(this.pressedControl === 'jump'))
                .onTouch((event: TouchEvent): void => {
                    if (event.type === TouchType.Down) this.pressedControl = 'jump';
                    else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                        this.pressedControl = '';
                    }
                })
                .onClick(() => { this.vibrate(); this.jump(); }).accessibilityText('跳转到指定页')
        }.width('100%').padding({ bottom: 110 }).accessibilityText('应用列表分页控件')
    }

    build() {
        Stack({ alignContent: Alignment.Top }) {
            Refresh({ refreshing: $$this.searchPullRefreshing, builder: this.searchPullHint() }) {
                Scroll(this.pageScroller) {
                    Column({ space: 12 }) {
                        Blank().height(100).width('100%')
                        if (!this.searchExpanded) {
                            this.commonHeader()
                        }
                        if (this.selectedIndexes[0] === 0) {
                            Column({ space: 12 }) {
                                OverviewSection({ enterStep: this.animStep })
                                Blank().height(110).width('100%')
                            }
                            .width('100%')
                        } else {
                            Column({ space: 12 }) {
                                Text(`共 ${formatCount(this.total)} 条应用数据`).fontSize(13)
                                    .fontColor($r('app.color.v3_text_secondary')).width('100%')
                                    .accessibilityText(`共${formatCount(this.total)}条应用数据`)
                                this.filterBar()
                                if (this.typeIndex === 2 && this.appliedFilterText.length > 0) {
                                    Text('元服务类型筛选优先，字段筛选将在切换到全部类型或应用后生效')
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
                            .opacity(this.animStep >= 1 ? 1 : 0)
                            .translate({ y: this.animStep >= 1 ? 0 : 20 })
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
                                this.restoreScrollTimer = setTimeout((): void => {
                                    this.restoreScrollTimer = -1;
                                    this.pageScroller.scrollTo({
                                        xOffset: 0,
                                        yOffset: continuation.scrollDistance,
                                        animation: { duration: 0 },
                                    });
                                }, 80);
                            }
                        }
                    })
                }
                .width('100%').height('100%').scrollBar(BarState.Auto)
                .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true, effectEdge: EffectEdge.END })
                .onDidScroll((): void => this.recordScroll(this.pageScroller))
                .accessibilityText('可滚动并支持下拉打开应用搜索的应用页面')
            }
            .width('100%').height('100%')
            .refreshOffset(SEARCH_PULL_TRIGGER_DISTANCE_VP)
            .onRefreshing((): void => this.pullOpenSearch())
            .accessibilityText('下拉可打开应用搜索')

            if (this.searchExpanded) {
                SearchPage({
                    requestVersion: this.requestVersion,
                    geometryId: SEARCH_SHARED_GEOMETRY_ID,
                    onClose: (): void => this.closeSearch(),
                    onOpenAppDetail: (target: AppRouteTarget): void => this.onOpenAppDetail?.(target),
                })
                .width('100%').height('100%').zIndex(100)
                .transition(TransitionEffect.OPACITY)
            }
        }
        .width('100%').height('100%').backgroundColor($r('app.color.background'))
        .onAxisEvent((event: AxisEvent): void => scrollByAxis(this.pageScroller, event))
        .onAppear(() => {
            if (!this.restoredView) {
                this.restoredView = true;
                this.restoreContinuationListState();
                const continuation = getContinuationState();
                this.selectedIndexes = [continuation.appsViewIndex === 1 ? 1 : 0];
            }
            if (this.active) this.startPageAnimationOnce();
            if (this.requestVersion > 0 && hasPendingSearchTarget()) this.openSearch(false);
        })
        .accessibilityText('概况与总表页面')
    }
}
