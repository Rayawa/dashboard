import { SearchRecommendationCard, SearchResultCard } from '../../components/search/SearchAppCards';
import { RequestScope } from '../../services/cache/CachedRequest';
import { PromptAction } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { BACKGROUND_REFRESH_DELAY_MS, SEARCH_SHARED_GEOMETRY_ID } from '../../config/constants';
import { consumeSearchTarget, setDetailTarget } from '../../state/appState';
import { fetchAppById, fetchAppByPackage, fetchAppsPage, submitApp } from '../../services/api/MarketApi';
import { clearSearchHistory, getSearchHistory, setSearchHistory } from '../../services/storage/storage';
import { searchTargetFromInput, sortSearchResults } from '../../domain/search/SearchInput';
import { SearchResultDataSource } from '../../models/SearchResultDataSource';
import { DeferredTask } from '../../utils/runtime/DeferredTask';
import { showToastSafely } from '../../ui/feedback/safeUi';
import {
    cancelStaggerEnterAnimation,
    contentEnterTransition,
    startStaggerEnterAnimation,
} from '../../ui/animation/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../ui/theme/visualEffects';
import type {
    ApiDataResult, AppDetailPayload, AppRouteTarget, BaseAPIResponse, MarketApp, PageInfo, SearchTarget,
    SubmitAppBody,
} from '../../models/types';
import { vibration } from '../../utils/device/vibration';
import { scrollByAxis } from '../../ui/interaction/scroll';

const SEARCH_DISMISS_SWIPE_DISTANCE_VP: number = 96;
// HdsTabs floats above its content: 56vp bar + 28vp bottom margin + 16vp clearance.
const SEARCH_BOTTOM_CLEARANCE_VP: number = 100;

interface NameSearchResult {
    apps: MarketApp[];
    stale: boolean;
    totalPages: number;
    total: number;
}

@Component
export struct SearchPage {
    @Prop @Watch('onRequestVersionChanged') requestVersion: number = 0;
    @Prop geometryId: string = SEARCH_SHARED_GEOMETRY_ID;
    onClose?: () => void;
    onOpenAppDetail?: (target: AppRouteTarget) => void;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private resultSource: SearchResultDataSource = new SearchResultDataSource();
    @StorageLink('username') private username: string = '';
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    @StorageLink('statusBarHeight') private statusBarHeight: number = 38;
    @State private input: string = '';
    @State private loading: boolean = false;
    @State private status: string = '输入应用名称、包名、App ID 或应用市场链接';
    @State private errorMessage: string = '';
    @State private resultCount: number = 0;
    @State private resultColumns: number = 1;
    @State private resultApp: MarketApp | undefined = undefined;
    @State private fromCache: boolean = false;
    @State private history: string[] = [];
    @State private recommendedApps: MarketApp[] = [];
    @State private transitionEffect: TransitionEffect =
        TransitionEffect.OPACITY.animation({ duration: 180, curve: Curve.EaseOut });
    @State private pressedControl: string = '';
    @State private animStep: number = 0;
    @State private namePage: number = 1;
    @State private namePages: number = 0;
    @State private nameTotal: number = 0;
    private nameQuery: string = '';
    private requestScope: RequestScope = new RequestScope();
    private recommendationScope: RequestScope = new RequestScope();
    private pendingSearch: DeferredTask = new DeferredTask();
    private backgroundRefresh: DeferredTask = new DeferredTask();
    private pendingDetail: DeferredTask = new DeferredTask();
    private pendingFocus: DeferredTask = new DeferredTask();
    private activeTarget: AppRouteTarget = {};
    private openDetailAfterSearch: boolean = false;
    private backgroundUpdateToken: number = 0;
    private lifecycleToken: number = 0;
    private searchRequestToken: number = 0;
    private visible: boolean = false;
    private enterTimers: number[] = [];
    private resultScroller: Scroller = new Scroller();

    aboutToDisappear(): void {
        this.requestScope.cancel();
        this.recommendationScope.cancel();
        this.pendingSearch.cancel();
        this.backgroundRefresh.cancel();
        this.pendingDetail.cancel();
        this.pendingFocus.cancel();
        this.visible = false;
        this.lifecycleToken++;
        this.searchRequestToken++;
        this.backgroundUpdateToken++;
        this.loading = false;
        this.openDetailAfterSearch = false;
        cancelStaggerEnterAnimation(this.enterTimers);
        this.enterTimers = [];
    }

    private isVisible(lifecycleToken: number): boolean {
        return this.visible && lifecycleToken === this.lifecycleToken;
    }

    private isSearchCurrent(searchToken: number, lifecycleToken: number): boolean {
        return searchToken === this.searchRequestToken && this.isVisible(lifecycleToken);
    }

    private updatePageAnimation(visible: boolean): void {
        cancelStaggerEnterAnimation(this.enterTimers);
        this.enterTimers = [];
        this.animStep = 0;
        if (!visible) return;
        this.enterTimers = startStaggerEnterAnimation(this.getUIContext(), 1, (step: number): void => {
            this.animStep = step;
        });
    }

    private clearInitialFocus(): void {
        try {
            this.getUIContext().getFocusController().clearFocus();
        } catch (error) {
            console.warn('[Dashboard][pages/search/SearchPage][WARN]',
                `清除搜索框初始焦点失败: ${JSON.stringify(error)}`);
        }
    }

    private async loadRecommendations(lifecycleToken: number): Promise<void> {
        try {
            const result = await fetchAppsPage({
                page: 1,
                pageSize: 8,
                sort: 'download_count',
                desc: true,
            }, this.recommendationScope);
            const response = result.data as BaseAPIResponse<PageInfo<MarketApp>>;
            if (this.isVisible(lifecycleToken) && response.success && response.data) {
                this.recommendedApps = response.data.data ?? [];
            }
        } catch (error) {
            console.warn('[Dashboard][pages/search/SearchPage][WARN]',
                `搜索推荐应用加载失败: ${(error as Error).message}`);
        }
    }

    private updateControlPress(key: string, event: TouchEvent): void {
        if (event.type === TouchType.Down) this.pressedControl = key;
        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedControl = '';
    }

    private vibrate(): void { if (this.vibrationLevel > 0) vibration.dotVibration(); }
    private setResults(results: MarketApp[]): void {
        this.resultSource.replace(results);
        this.resultCount = results.length;
    }
    private onRequestVersionChanged(): void { this.consumePendingTarget(); }
    private consumePendingTarget(): void {
        if (!this.visible) return;
        const target: SearchTarget = consumeSearchTarget();
        const raw = target.rawText || target.packageName || target.appId || '';
        if (!raw) return;
        this.requestScope.cancel();
        this.requestScope = new RequestScope();
        this.searchRequestToken++;
        this.backgroundUpdateToken++;
        this.backgroundRefresh.cancel();
        this.pendingDetail.cancel();
        this.pendingSearch.cancel();
        this.loading = false;
        this.input = raw;
        this.openDetailAfterSearch = target.openDetailOnSuccess === true;
        if (target.autoRun !== false) {
            this.pendingSearch.schedule((): void => { this.search(target.recordHistory === true); });
        }
    }
    private detailRequest(target: AppRouteTarget, force: boolean): Promise<ApiDataResult<BaseAPIResponse<AppDetailPayload>>> {
        if (target.appId) return fetchAppById(target.appId, force, this.requestScope);
        if (target.packageName) return fetchAppByPackage(target.packageName, force, this.requestScope);
        return Promise.reject(new Error('缺少应用标识'));
    }
    private async findByName(name: string, page: number = 1): Promise<NameSearchResult> {
        const result = await fetchAppsPage({ page, pageSize: 40, sort: 'download_count', desc: true,
            searchKey: 'name', searchValue: name, exact: false, force: false }, this.requestScope);
        const response = result.data;
        const matches = response.data?.data ?? [];
        if (!response.success || matches.length === 0) {
            throw new Error('未找到同名应用；如需投稿，请输入包名、App ID 或应用市场链接');
        }
        return { apps: sortSearchResults(matches, name), stale: result.stale,
            totalPages: response.data?.total_pages ?? 1, total: response.data?.total_count ?? matches.length };
    }

    private async changeNamePage(page: number): Promise<void> {
        if (this.loading || page < 1 || page > this.namePages) return;
        const query = this.nameQuery;
        this.requestScope.cancel(); this.requestScope = new RequestScope();
        const token = ++this.searchRequestToken;
        const lifecycle = this.lifecycleToken;
        this.loading = true;
        try {
            const result = await this.findByName(query, page);
            if (!this.isSearchCurrent(token, lifecycle)) return;
            this.setResults(result.apps);
            this.resultApp = result.apps[0];
            this.namePage = page;
            this.namePages = result.totalPages;
            this.nameTotal = result.total;
            this.fromCache = result.stale;
            this.status = `第 ${page} / ${this.namePages} 页，共 ${this.nameTotal} 个结果`;
            this.resultScroller.scrollTo({ xOffset: 0, yOffset: 0 });
        } catch (error) {
            if (this.isSearchCurrent(token, lifecycle)) showToastSafely(this.prompt, (error as Error).message);
        } finally { if (this.isSearchCurrent(token, lifecycle)) this.loading = false; }
    }

    private async remember(raw: string): Promise<void> {
        const next = [raw].concat(this.history.filter((item: string) => item !== raw)).slice(0, 10);
        this.history = next;
        try { await setSearchHistory(next); }
        catch (error) {
            console.warn('[Dashboard][pages/search/SearchPage][WARN]', `保存搜索历史失败: ${JSON.stringify(error)}`);
        }
    }
    private async submitNew(
        target: AppRouteTarget,
        searchToken: number,
        lifecycleToken: number,
    ): Promise<boolean> {
        const body: SubmitAppBody = { comment: { user: this.username } };
        if (target.appId) body.app_id = target.appId;
        else if (target.packageName) body.pkg_name = target.packageName;
        else throw new Error('投稿缺少应用标识');
        const response = await submitApp(body);
        if (!this.isSearchCurrent(searchToken, lifecycleToken)) return false;
        if (!response.success || !response.data?.full_info) throw new Error('投稿接口未返回有效应用数据');
        this.resultApp = response.data.full_info;
        this.setResults([response.data.full_info]);
        this.activeTarget = { appId: response.data.full_info.app_id, packageName: response.data.full_info.pkg_name };
        this.fromCache = false;
        this.status = '新应用已收录并完成加载';
        showToastSafely(this.prompt, `已发现并收录新应用：${response.data.full_info.name}`, 2200, 'V3Search');
        return true;
    }
    private updateExisting(): void {
        const token = this.backgroundUpdateToken;
        const target: AppRouteTarget = { appId: this.activeTarget.appId, packageName: this.activeTarget.packageName };
        this.backgroundRefresh.schedule((): void => {
            if (!this.visible || token !== this.backgroundUpdateToken) return;
            this.detailRequest(target, true).then((fresh) => {
                if (token !== this.backgroundUpdateToken || !fresh.data.success || !fresh.data.data?.full_info) return;
                const app = fresh.data.data.full_info;
                this.resultApp = app;
                this.setResults(this.resultSource.items().map((item: MarketApp) => item.app_id === app.app_id ? app : item));
                this.fromCache = fresh.stale;
            }).catch((error: Error) =>
                console.warn('[Dashboard][pages/search/SearchPage][WARN]', `静默后台更新失败: ${error.message}`));
        }, BACKGROUND_REFRESH_DELAY_MS);
    }
    private isMissingApplication(error: Error): boolean {
        return error.message.includes('404') || error.message.includes('未找到');
    }
    private async searchByName(raw: string, searchToken: number, lifecycleToken: number): Promise<void> {
        const searchResult = await this.findByName(raw);
        if (!this.isSearchCurrent(searchToken, lifecycleToken)) return;
        this.nameQuery = raw;
        this.namePages = searchResult.totalPages;
        this.nameTotal = searchResult.total;
        this.setResults(searchResult.apps);
        this.resultApp = searchResult.apps[0];
        this.activeTarget = { appId: this.resultApp.app_id, packageName: this.resultApp.pkg_name };
        this.fromCache = searchResult.stale;
        this.status = `第 1 / ${this.namePages} 页，共 ${this.nameTotal} 个结果${searchResult.stale ? '（离线缓存）' : ''}`;
    }

    private async searchByTarget(target: AppRouteTarget, searchToken: number, lifecycleToken: number): Promise<void> {
        this.activeTarget = target;
        let detail: ApiDataResult<BaseAPIResponse<AppDetailPayload>>;
        try {
            detail = await this.detailRequest(target, false);
            if (!this.isSearchCurrent(searchToken, lifecycleToken)) return;
        }
        catch (error) {
            if (!this.isSearchCurrent(searchToken, lifecycleToken)) return;
            const requestError = error as Error;
            if (this.isMissingApplication(requestError)) {
                await this.submitNew(target, searchToken, lifecycleToken);
                return;
            }
            throw requestError;
        }
        if (!detail.data.success || !detail.data.data?.full_info) {
            await this.submitNew(target, searchToken, lifecycleToken);
            return;
        }
        this.resultApp = detail.data.data.full_info;
        this.setResults([this.resultApp]);
        this.activeTarget = { appId: this.resultApp.app_id, packageName: this.resultApp.pkg_name };
        this.fromCache = detail.stale;
        this.status = detail.stale ? '已从离线缓存加载结果' : '搜索结果已完整加载';
        if (detail.data.data.new_app) {
            await this.submitNew(this.activeTarget, searchToken, lifecycleToken);
        } else {
            this.updateExisting();
        }
    }

    private async search(recordHistory: boolean = true): Promise<void> {
        const raw = this.input.trim();
        if (!this.visible || !raw || this.loading) {
            if (!raw) showToastSafely(this.prompt, '请输入应用信息', 1500, 'V3Search');
            return;
        }
        this.requestScope.cancel(); this.requestScope = new RequestScope();
        const searchToken = ++this.searchRequestToken;
        const lifecycleToken = this.lifecycleToken;
        this.loading = true;
        this.backgroundUpdateToken++;
        this.backgroundRefresh.cancel();
        this.pendingDetail.cancel();
        this.errorMessage = '';
        this.nameQuery = ''; this.namePages = 0; this.namePage = 1;
        this.setResults([]);
        this.resultApp = undefined;
        this.status = '正在查找应用…';
        if (recordHistory) {
            await this.remember(raw);
            if (!this.isSearchCurrent(searchToken, lifecycleToken)) return;
        }
        try {
            const target = searchTargetFromInput(raw);
            if (target.appId || target.packageName) {
                await this.searchByTarget(target, searchToken, lifecycleToken);
            } else {
                await this.searchByName(raw, searchToken, lifecycleToken);
            }
            if (this.isSearchCurrent(searchToken, lifecycleToken)) this.openDetailIfRequested();
        } catch (error) {
            if (!this.isSearchCurrent(searchToken, lifecycleToken)) return;
            const message = (error as Error).message;
            this.errorMessage = message;
            this.status = '搜索或投稿未完成';
            this.openDetailAfterSearch = false;
            showToastSafely(this.prompt, message, 2600, 'V3Search');
        } finally {
            if (this.isSearchCurrent(searchToken, lifecycleToken)) this.loading = false;
        }
    }
    private openDetail(app?: MarketApp): void {
        const targetApp = app ?? this.resultApp;
        if (!targetApp) return;
        this.vibrate();
        const target: AppRouteTarget = {
            appId: targetApp.app_id,
            packageName: targetApp.pkg_name,
            backgroundRefreshHandled: this.resultApp?.app_id === targetApp.app_id,
            previewApp: targetApp,
        };
        try {
            setDetailTarget(target);
            this.onOpenAppDetail?.(target);
        }
        catch (error) {
            console.error('[Dashboard][pages/search/SearchPage][ERROR]',
                `打开应用详情失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, '暂时无法打开应用详情，请重试', 1800, 'SearchPage');
        }
    }
    private openDetailIfRequested(): void {
        if (!this.openDetailAfterSearch || !this.resultApp) return;
        this.openDetailAfterSearch = false;
        const lifecycleToken = this.lifecycleToken;
        this.pendingDetail.schedule((): void => {
            if (this.isVisible(lifecycleToken)) this.openDetail();
        });
    }
    private applySuggestion(value: string): void { this.input = value; this.search(); }

    private async clearHistory(): Promise<void> {
        this.vibrate();
        this.history = [];
        try { await clearSearchHistory(); }
        catch (error) {
            console.warn('[Dashboard][pages/search/SearchPage][WARN]', `清空搜索历史失败: ${JSON.stringify(error)}`);
        }
    }

    @Builder
    private tagButton(value: string, prefix: string): void {
        Button(value, { stateEffect: false }).height(36).margin({ right: 8, bottom: 8 }).fontSize(13)
            .fontColor($r('app.color.diff_content')).backgroundColor($r('app.color.v3_surface_alt'))
            .scale({ x: this.pressedControl === `tag-${value}` ? 0.97 : 1,
                y: this.pressedControl === `tag-${value}` ? 0.97 : 1 })
            .animation({ duration: 120, curve: Curve.EaseOut })
            .visualEffect(pressVisualEffect(
                this.pressedControl === `tag-${value}`, hdsEffect.PointLightIlluminatedType.BORDER, 5, 84))
            .compositingFilter(pressLightFieldFilter(this.pressedControl === `tag-${value}`))
            .onTouch((event: TouchEvent): void => this.updateControlPress(`tag-${value}`, event))
            .onClick(() => {
                this.vibrate();
                this.applySuggestion(value);
            }).accessibilityText(`${prefix}${value}`)
    }

    build() {
        Column({ space: 12 }) {
            Column({ space: 12 }) {
                Row({ space: 10 }) {
                    Button({ type: ButtonType.Circle, stateEffect: false }) {
                        SymbolGlyph($r('sys.symbol.chevron_left'))
                            .fontSize('24vp')
                            .fontColor([$r('app.color.v3_text_primary')])
                    }
                        .width(44).height(44).backgroundColor(Color.Transparent)
                        .border({ width: 1, color: $r('app.color.border') })
                        .scale({ x: this.pressedControl === 'back' ? 0.94 : 1,
                            y: this.pressedControl === 'back' ? 0.94 : 1 })
                        .animation({ duration: 120, curve: Curve.EaseOut })
                        .visualEffect(pressVisualEffect(this.pressedControl === 'back',
                            hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                        .compositingFilter(pressLightFieldFilter(this.pressedControl === 'back'))
                        .onTouch((event: TouchEvent): void => this.updateControlPress('back', event))
                        .onClick(() => { this.vibrate(); if (this.onClose) this.onClose(); })
                        .accessibilityText('关闭应用搜索并返回应用页面')
                    Search({ value: this.input, placeholder: '应用名称 / 包名 / App ID / 应用市场链接' })
                        .layoutWeight(1).height(48).defaultFocus(false).enableKeyboardOnFocus(false)
                        .searchButton('搜索')
                        .backgroundColor($r('app.color.v3_surface_alt'))
                        .scale({ x: this.pressedControl === 'search' ? 0.985 : 1,
                            y: this.pressedControl === 'search' ? 0.985 : 1 })
                        .animation({ duration: 120, curve: Curve.EaseOut })
                        .visualEffect(pressVisualEffect(this.pressedControl === 'search',
                            hdsEffect.PointLightIlluminatedType.BORDER, 6, 96))
                        .compositingFilter(pressLightFieldFilter(this.pressedControl === 'search'))
                        .onTouch((event: TouchEvent): void => this.updateControlPress('search', event))
                        .geometryTransition(this.geometryId, { follow: true })
                        .transition(TransitionEffect.opacity(0.99))
                        .onChange((value: string) => this.input = value)
                        .onSubmit(() => { this.vibrate(); this.search(); })
                        .accessibilityText('搜索应用名称包名App ID或应用市场链接')
                }.width('100%').padding({ left: 16, right: 20, top: this.statusBarHeight + 8 })
            }
            .width('100%')
            .backgroundColor($r('app.color.background'))
            .zIndex(2)
            .opacity(this.animStep >= 1 ? 1 : 0)
            .translate({ y: this.animStep >= 1 ? 0 : 20 })
            .accessibilityText('搜索栏区域')

            if (this.loading || this.errorMessage.length > 0 || this.resultCount > 0) {
                Row({ space: 8 }) {
                    if (this.loading) {
                        LoadingProgress().width(22).height(22).color($r('app.color.diff_content'))
                            .accessibilityText('搜索处理中')
                    }
                    Text(this.errorMessage || this.status).fontSize(13)
                        .fontColor(this.errorMessage ? $r('app.color.v3_accent_red') : $r('app.color.v3_text_secondary'))
                        .layoutWeight(1)
                    if (this.fromCache) {
                        Text('缓存').fontSize(11).fontColor($r('app.color.v3_accent_orange'))
                    }
                }.width('100%').padding({ left: 24, right: 24 }).accessibilityText(this.errorMessage || this.status)
                    .transition(contentEnterTransition(8))
            }

            if (!this.loading && this.resultCount === 0) {
                Column({ space: 12 }) {
                    if (this.history.length > 0) {
                        Column({ space: 10 }) {
                            Row() {
                                Text('搜索历史').fontSize(18).fontWeight(FontWeight.Bold)
                                    .fontColor($r('app.color.v3_text_primary')).layoutWeight(1)
                                Button('删除全部').height(34).fontSize(12).fontColor($r('app.color.diff_content'))
                                    .backgroundColor(Color.Transparent).onClick(() => { this.clearHistory(); })
                                    .accessibilityText('删除全部搜索历史')
                            }.width('100%')
                            Flex({ wrap: FlexWrap.Wrap }) {
                                ForEach(this.history, (value: string) => this.tagButton(value, '搜索历史'))
                            }.width('100%')
                        }.width('100%')
                    }
                    if (this.recommendedApps.length > 0) {
                        Column({ space: 10 }) {
                            Text('搜索推荐').fontSize(18).fontWeight(FontWeight.Bold)
                                .fontColor($r('app.color.v3_text_primary')).width('100%')
                            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
                                ForEach(this.recommendedApps, (app: MarketApp) => {
                                    SearchRecommendationCard({ app, onOpen: (target: MarketApp): void => this.openDetail(target) })
                                }, (app: MarketApp) => `${app.app_id}-${app.updated_at}`)
                            }.width('100%')
                        }.width('100%')
                    }
                }
                .width('100%')
                .padding({ left: 24, right: 24, bottom: 40 })
                .opacity(this.animStep >= 1 ? 1 : 0)
                .translate({ y: this.animStep >= 1 ? 0 : 20 })
            } else if (this.resultCount > 0) {
                Grid(this.resultScroller) {
                    LazyForEach(this.resultSource, (app: MarketApp) => {
                        GridItem() { SearchResultCard({ app, onOpen: (target: MarketApp): void => this.openDetail(target) }) }
                    }, (app: MarketApp) => `${app.app_id}-${app.updated_at}`)
                }
                .columnsTemplate(`repeat(${this.resultColumns}, 1fr)`).columnsGap(12).rowsGap(12)
                .padding({ left: 24, right: 24, bottom: 48 }).layoutWeight(1).width('100%').scrollBar(BarState.Auto)
                .onAreaChange((_oldValue: Area, newValue: Area): void => {
                    const width = Number(newValue.width);
                    this.resultColumns = width >= 840 ? 3 : width >= 600 ? 2 : 1;
                })
                .accessibilityText(`搜索结果，共${this.resultCount}项`)
                .transition(contentEnterTransition(10))
                if (this.namePages > 1) {
                    Row({ space: 12 }) {
                        Button('上一页').enabled(!this.loading && this.namePage > 1)
                            .onClick((): void => { this.changeNamePage(this.namePage - 1); })
                        Text(`${this.namePage} / ${this.namePages}`).fontColor($r('app.color.v3_text_secondary'))
                        Button('下一页').enabled(!this.loading && this.namePage < this.namePages)
                            .onClick((): void => { this.changeNamePage(this.namePage + 1); })
                    }.width('100%').justifyContent(FlexAlign.Center).padding({ bottom: 24 })
                }
            }
        }
        .width('100%').height('100%').backgroundColor($r('app.color.background'))
        .padding({ bottom: SEARCH_BOTTOM_CLEARANCE_VP })
        .onAxisEvent((event: AxisEvent): void => scrollByAxis(this.resultScroller, event))
        .transition(this.transitionEffect)
        .gesture(
            PanGesture({ fingers: 1, direction: PanDirection.Vertical })
                .onActionEnd((event: GestureEvent): void => {
                    if (Math.abs(event.offsetY) >= SEARCH_DISMISS_SWIPE_DISTANCE_VP) {
                        this.vibrate();
                        if (this.onClose) { this.onClose(); }
                    }
                })
        )
        .onAppear(() => {
            this.visible = true;
            this.requestScope = new RequestScope();
            this.recommendationScope = new RequestScope();
            const lifecycleToken = ++this.lifecycleToken;
            this.updatePageAnimation(true);
            this.clearInitialFocus();
            this.pendingFocus.schedule((): void => {
                if (this.isVisible(lifecycleToken)) this.clearInitialFocus();
            });
            getSearchHistory().then((history: string[]) => {
                if (this.isVisible(lifecycleToken)) this.history = history;
            }).catch(() => {});
            this.loadRecommendations(lifecycleToken);
            this.consumePendingTarget();
        })
        .onDisAppear(() => this.updatePageAnimation(false))
        .accessibilityText('应用搜索界面')
    }
}
