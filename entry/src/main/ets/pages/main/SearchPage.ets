import { curves, PromptAction } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { BACKGROUND_REFRESH_DELAY_MS, SEARCH_SHARED_GEOMETRY_ID } from '../../common/constants';
import { consumeSearchTarget, setDetailTarget } from '../../common/appState';
import { fetchAppById, fetchAppByPackage, fetchAppsPage, submitApp } from '../../common/MarketApi';
import { formatCount, formatDateTime } from '../../common/format';
import { clearSearchHistory, getSearchHistory, setSearchHistory } from '../../common/storage';
import { parseInputSplitLinksPkgsAndAppIds } from '../../common/utils';
import { showToastSafely } from '../../common/safeUi';
import {
    cancelStaggerEnterAnimation,
    contentEnterTransition,
    startStaggerEnterAnimation,
} from '../../common/motion';
import { pressVisualEffect } from '../../common/visualEffects';
import type {
    ApiDataResult, AppDetailPayload, AppRouteTarget, BaseAPIResponse, MarketApp, PageInfo, SearchTarget,
    SubmitAppBody,
} from '../../common/types';
import { vibration } from '../../common/vibration';

const SEARCH_DISMISS_SWIPE_DISTANCE_VP: number = 96;

interface NameSearchResult {
    apps: MarketApp[];
    stale: boolean;
}

class SearchResultDataSource implements IDataSource {
    private listeners: DataChangeListener[] = [];
    private data: MarketApp[] = [];

    totalCount(): number { return this.data.length; }
    getData(index: number): MarketApp { return this.data[index]; }
    registerDataChangeListener(listener: DataChangeListener): void {
        if (this.listeners.indexOf(listener) < 0) this.listeners.push(listener);
    }
    unregisterDataChangeListener(listener: DataChangeListener): void {
        const index = this.listeners.indexOf(listener);
        if (index >= 0) this.listeners.splice(index, 1);
    }
    replace(data: MarketApp[]): void {
        this.data = data.slice();
        for (const listener of this.listeners) listener.onDataReloaded();
    }
    items(): MarketApp[] { return this.data; }
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
    @State private pressedCardId: string = '';
    @State private pressedControl: string = '';
    @State private animStep: number = 0;
    private activeTarget: AppRouteTarget = {};
    private openDetailAfterSearch: boolean = false;
    private backgroundUpdateToken: number = 0;
    private enterTimers: number[] = [];

    aboutToDisappear(): void {
        this.backgroundUpdateToken++;
        cancelStaggerEnterAnimation(this.enterTimers);
        this.enterTimers = [];
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
            console.warn('[Dashboard][pages/main/SearchPage][WARN]',
                `清除搜索框初始焦点失败: ${JSON.stringify(error)}`);
        }
    }

    private async loadRecommendations(): Promise<void> {
        try {
            const result = await fetchAppsPage(1, 8, 'download_count', true);
            const response = result.data as BaseAPIResponse<PageInfo<MarketApp>>;
            if (response.success && response.data) {
                this.recommendedApps = response.data.data ?? [];
            }
        } catch (error) {
            console.warn('[Dashboard][pages/main/SearchPage][WARN]',
                `搜索推荐应用加载失败: ${(error as Error).message}`);
        }
    }

    private vibrate(): void { if (this.vibrationLevel > 0) vibration.dotVibration(); }
    private setResults(results: MarketApp[]): void {
        this.resultSource.replace(results);
        this.resultCount = results.length;
    }
    private decodeInputValue(value: string): string {
        try { return decodeURIComponent(value); }
        catch (error) {
            console.warn('[Dashboard][pages/main/SearchPage][WARN]',
                `输入链接参数解码失败，保留原值: ${JSON.stringify(error)}`);
            return value;
        }
    }
    private onRequestVersionChanged(): void { this.consumePendingTarget(); }
    private consumePendingTarget(): void {
        const target: SearchTarget = consumeSearchTarget();
        const raw = target.rawText || target.packageName || target.appId || '';
        if (!raw) return;
        this.input = raw;
        this.openDetailAfterSearch = target.openDetailOnSuccess === true;
        if (target.autoRun !== false) {
            setTimeout((): void => { this.search(target.recordHistory === true); }, 0);
        }
    }
    private targetFromInput(): AppRouteTarget {
        const dashboardAppId = this.input.match(/[?&#]app_id=([^&#]+)/);
        if (dashboardAppId && dashboardAppId[1]) return { appId: this.decodeInputValue(dashboardAppId[1]) };
        const dashboardPackage = this.input.match(/[?&#]pkg=([^&#]+)/);
        if (dashboardPackage && dashboardPackage[1]) return { packageName: this.decodeInputValue(dashboardPackage[1]) };
        const parsed = parseInputSplitLinksPkgsAndAppIds(this.input);
        if (parsed.app_ids.length > 0) {
            const appId = parsed.app_ids[parsed.app_ids.length - 1];
            return { appId: appId.startsWith('C') ? appId : `C${appId}` };
        }
        if (parsed.pkgs.length > 0) return { packageName: parsed.pkgs[parsed.pkgs.length - 1] };
        const idMatch = this.input.match(/[?&]id=([^&#]+)/);
        return idMatch && idMatch[1] ? { packageName: this.decodeInputValue(idMatch[1]) } : {};
    }
    private detailRequest(target: AppRouteTarget, force: boolean): Promise<ApiDataResult<BaseAPIResponse<AppDetailPayload>>> {
        if (target.appId) return fetchAppById(target.appId, force);
        if (target.packageName) return fetchAppByPackage(target.packageName, force);
        return Promise.reject(new Error('缺少应用标识'));
    }
    private relevance(app: MarketApp, query: string): number {
        const normalized = query.trim().toLowerCase();
        const name = (app.name || '').toLowerCase();
        const packageName = (app.pkg_name || '').toLowerCase();
        if (name === normalized || packageName === normalized) return 0;
        if (name.startsWith(normalized)) return 1;
        if (packageName.startsWith(normalized)) return 2;
        if (name.includes(normalized)) return 3;
        if (packageName.includes(normalized)) return 4;
        return 5;
    }
    private async findByName(name: string): Promise<NameSearchResult> {
        const firstResult = await fetchAppsPage(1, 100, 'download_count', true, 'name', name, false, true);
        const response = firstResult.data as BaseAPIResponse<PageInfo<MarketApp>>;
        let matches: MarketApp[] = response.data?.data ?? [];
        if (!response.success || matches.length === 0) {
            throw new Error('未找到同名应用；如需投稿，请输入包名、App ID 或应用市场链接');
        }
        const totalPages = response.data?.total_pages ?? 1;
        let stale = firstResult.stale;
        for (let page = 2; page <= totalPages; page++) {
            const nextResult = await fetchAppsPage(page, 100, 'download_count', true, 'name', name, false, true);
            const nextResponse = nextResult.data as BaseAPIResponse<PageInfo<MarketApp>>;
            if (nextResponse.success && nextResponse.data) matches = matches.concat(nextResponse.data.data ?? []);
            stale = stale || nextResult.stale;
        }
        return {
            apps: matches.sort((left: MarketApp, right: MarketApp) =>
                this.relevance(left, name) - this.relevance(right, name)),
            stale,
        };
    }
    private async remember(raw: string): Promise<void> {
        const next = [raw].concat(this.history.filter((item: string) => item !== raw)).slice(0, 10);
        this.history = next;
        try { await setSearchHistory(next); }
        catch (error) {
            console.warn('[Dashboard][pages/main/SearchPage][WARN]', `保存搜索历史失败: ${JSON.stringify(error)}`);
        }
    }
    private async submitNew(target: AppRouteTarget): Promise<void> {
        const body: SubmitAppBody = { comment: { user: this.username } };
        if (target.appId) body.app_id = target.appId;
        else if (target.packageName) body.pkg_name = target.packageName;
        else throw new Error('投稿缺少应用标识');
        const response = await submitApp(body);
        if (!response.success || !response.data?.full_info) throw new Error('投稿接口未返回有效应用数据');
        this.resultApp = response.data.full_info;
        this.setResults([response.data.full_info]);
        this.activeTarget = { appId: response.data.full_info.app_id, packageName: response.data.full_info.pkg_name };
        this.fromCache = false;
        this.status = '新应用已收录并完成加载';
        showToastSafely(this.prompt, `已发现并收录新应用：${response.data.full_info.name}`, 2200, 'V3Search');
    }
    private updateExisting(): void {
        const token = this.backgroundUpdateToken;
        const target: AppRouteTarget = { appId: this.activeTarget.appId, packageName: this.activeTarget.packageName };
        setTimeout((): void => {
            if (token !== this.backgroundUpdateToken) return;
            this.detailRequest(target, true).then((fresh) => {
                if (token !== this.backgroundUpdateToken || !fresh.data.success || !fresh.data.data?.full_info) return;
                const app = fresh.data.data.full_info;
                this.resultApp = app;
                this.setResults(this.resultSource.items().map((item: MarketApp) => item.app_id === app.app_id ? app : item));
                this.fromCache = fresh.stale;
            }).catch((error: Error) =>
                console.warn('[Dashboard][pages/main/SearchPage][WARN]', `静默后台更新失败: ${error.message}`));
        }, BACKGROUND_REFRESH_DELAY_MS);
    }
    private isMissingApplication(error: Error): boolean {
        return error.message.includes('404') || error.message.includes('未找到');
    }
    private async search(recordHistory: boolean = true): Promise<void> {
        const raw = this.input.trim();
        if (!raw || this.loading) {
            if (!raw) showToastSafely(this.prompt, '请输入应用信息', 1500, 'V3Search');
            return;
        }
        this.loading = true;
        this.backgroundUpdateToken++;
        this.errorMessage = '';
        this.setResults([]);
        this.resultApp = undefined;
        this.status = '正在查找应用…';
        if (recordHistory) {
            await this.remember(raw);
        }
        try {
            const target = this.targetFromInput();
            if (!target.appId && !target.packageName) {
                const searchResult = await this.findByName(raw);
                this.setResults(searchResult.apps);
                this.resultApp = searchResult.apps[0];
                this.activeTarget = { appId: this.resultApp.app_id, packageName: this.resultApp.pkg_name };
                this.fromCache = searchResult.stale;
                this.status = searchResult.stale ? `已从缓存加载 ${this.resultCount} 个结果` :
                    `已加载全部 ${this.resultCount} 个结果`;
                this.updateExisting();
                this.openDetailIfRequested();
                return;
            }
            this.activeTarget = target;
            let detail: ApiDataResult<BaseAPIResponse<AppDetailPayload>>;
            try { detail = await this.detailRequest(target, false); }
            catch (error) {
                const requestError = error as Error;
                if (this.isMissingApplication(requestError)) {
                    await this.submitNew(target);
                    this.openDetailIfRequested();
                    return;
                }
                throw requestError;
            }
            if (!detail.data.success || !detail.data.data?.full_info) {
                await this.submitNew(target);
                this.openDetailIfRequested();
                return;
            }
            this.resultApp = detail.data.data.full_info;
            this.setResults([this.resultApp]);
            this.activeTarget = { appId: this.resultApp.app_id, packageName: this.resultApp.pkg_name };
            this.fromCache = detail.stale;
            this.status = detail.stale ? '已从离线缓存加载结果' : '搜索结果已完整加载';
            if (detail.data.data.new_app) await this.submitNew(this.activeTarget);
            else this.updateExisting();
            this.openDetailIfRequested();
        } catch (error) {
            const message = (error as Error).message;
            this.errorMessage = message;
            this.status = '搜索或投稿未完成';
            showToastSafely(this.prompt, message, 2600, 'V3Search');
        } finally { this.loading = false; }
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
            console.error('[Dashboard][pages/main/SearchPage][ERROR]',
                `打开应用详情失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, '暂时无法打开应用详情，请重试', 1800, 'SearchPage');
        }
    }
    private openDetailIfRequested(): void {
        if (!this.openDetailAfterSearch || !this.resultApp) return;
        this.openDetailAfterSearch = false;
        setTimeout((): void => this.openDetail(), 0);
    }
    private applySuggestion(value: string): void { this.input = value; this.search(); }

    private cardId(app: MarketApp): string {
        return app.app_id || app.pkg_name || app.name || 'unknown';
    }

    private updateCardPress(app: MarketApp, pressed: boolean): void {
        this.pressedCardId = pressed ? this.cardId(app) : '';
    }
    private async clearHistory(): Promise<void> {
        this.vibrate();
        this.history = [];
        try { await clearSearchHistory(); }
        catch (error) {
            console.warn('[Dashboard][pages/main/SearchPage][WARN]', `清空搜索历史失败: ${JSON.stringify(error)}`);
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
            .onTouch((event: TouchEvent): void => {
                if (event.type === TouchType.Down) this.pressedControl = `tag-${value}`;
                else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedControl = '';
            })
            .onClick(() => {
                this.vibrate();
                this.applySuggestion(value);
            }).accessibilityText(`${prefix}${value}`)
    }

    @Builder
    private recommendCard(app: MarketApp): void {
        Column({ space: 5 }) {
            Stack() {
                Image(app.icon_url || $r('app.media.startIcon'))
                    .width('100%').height('100%').objectFit(ImageFit.Cover)
                    .borderRadius(10).clip(true)
                    .alt($r('app.media.startIcon'))
                    .accessibilityText(`${app.name || '未知应用'}图标`)
            }
                .width(42).height(42).borderRadius(10).clip(true)
            Text(app.name || '未知应用').fontSize(13).fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(app.developer_name || '未知开发者').fontSize(11)
                .fontColor($r('app.color.v3_text_secondary')).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('48%').height(104).padding({ top: 12, bottom: 10 }).borderRadius(14)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .margin({ bottom: 10 })
        .scale({ x: this.pressedCardId === this.cardId(app) ? 0.97 : 1,
            y: this.pressedCardId === this.cardId(app) ? 0.97 : 1 })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(this.pressedCardId === this.cardId(app),
            hdsEffect.PointLightIlluminatedType.BORDER))
        .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.updateCardPress(app, true);
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.updateCardPress(app, false);
        })
        .onClick(() => this.openDetail(app))
        .accessibilityGroup(true)
        .accessibilityText(`推荐应用${app.name || '未知应用'}，开发者${app.developer_name || '未知'}`)
    }

    @Builder
    private resultCard(app: MarketApp): void {
        Row({ space: 12 }) {
            Stack() {
                Image(app.icon_url || $r('app.media.startIcon'))
                    .width('100%').height('100%').objectFit(ImageFit.Cover)
                    .borderRadius(14).clip(true)
                    .alt($r('app.media.startIcon'))
                    .accessibilityText(`${app.name || '未知应用'}应用图标`)
            }
                .width(58).height(58).borderRadius(14).clip(true)
            Column({ space: 4 }) {
                Text(app.name || '未知应用').fontSize(17).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(app.developer_name || '未知开发者').fontSize(12).fontColor($r('app.color.diff_content'))
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${app.pkg_name} · ${formatCount(app.download_count)} 下载`).fontSize(11)
                    .fontColor($r('app.color.v3_text_secondary')).maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`更新：${formatDateTime(app.updated_at)}`).fontSize(11)
                    .fontColor($r('app.color.v3_text_secondary'))
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text('›').fontSize(26).fontColor($r('app.color.v3_text_secondary')).accessibilityText('进入详情')
        }
        .width('100%').height(96).padding(14).borderRadius(16)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .scale({ x: this.pressedCardId === this.cardId(app) ? 0.975 : 1,
            y: this.pressedCardId === this.cardId(app) ? 0.975 : 1 })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(this.pressedCardId === this.cardId(app),
            hdsEffect.PointLightIlluminatedType.BORDER_CONTENT))
        .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.updateCardPress(app, true);
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.updateCardPress(app, false);
        })
        .onClick(() => this.openDetail(app))
        .accessibilityGroup(true).accessibilityText(`打开${app.name || '未知应用'}详情`)
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
                        .onTouch((event: TouchEvent): void => {
                            if (event.type === TouchType.Down) this.pressedControl = 'back';
                            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                                this.pressedControl = '';
                            }
                        })
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
                        .onTouch((event: TouchEvent): void => {
                            if (event.type === TouchType.Down) this.pressedControl = 'search';
                            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                                this.pressedControl = '';
                            }
                        })
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
                                    this.recommendCard(app)
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
                Grid() {
                    LazyForEach(this.resultSource, (app: MarketApp) => {
                        GridItem() { this.resultCard(app) }
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
            }
        }
        .width('100%').height('100%').backgroundColor($r('app.color.background'))
        .transition(this.transitionEffect)
        .gesture(
            PanGesture({ fingers: 1, direction: PanDirection.Vertical })
                .onActionEnd((event: GestureEvent): void => {
                    if (event.offsetY <= -SEARCH_DISMISS_SWIPE_DISTANCE_VP) {
                        this.vibrate();
                        if (this.onClose) { this.onClose(); }
                    }
                })
        )
        .onAppear(() => {
            this.updatePageAnimation(true);
            this.clearInitialFocus();
            setTimeout((): void => this.clearInitialFocus(), 0);
            getSearchHistory().then((history: string[]) => { this.history = history; }).catch(() => {});
            this.loadRecommendations();
            this.consumePendingTarget();
        })
        .onDisAppear(() => this.updatePageAnimation(false))
        .accessibilityText('应用搜索界面')
    }
}
