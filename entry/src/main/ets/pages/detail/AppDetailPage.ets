import { AppIdentity } from '../../components/detail/AppIdentity';
import { AppDescription } from '../../components/detail/AppDescription';
import { PerformanceTrace } from '../../utils/diagnostics/PerformanceTrace';
import { RequestScope } from '../../services/cache/CachedRequest';
import { DeferredDetailSection } from '../../components/detail/DeferredDetailSection';
import { DiscoveryInteraction } from '../../ui/interaction/DiscoveryInteraction';
import { DetailTag } from '../../components/detail/DetailTag';
import type { DetailField } from '../../models/detailTypes';
import { ScreenshotCarousel } from '../../components/detail/ScreenshotCarousel';
import { DiscoveryButtonStyle } from '../../ui/theme/DiscoveryTheme';
import { VersionTimeline } from '../../components/detail/VersionTimeline';
import { sortAppMetrics, versionChanges } from '../../domain/discovery/DiscoveryQuery';
import { getLocalCollection, saveCollectedApp } from '../../services/storage/storage';
import { openAppCollection } from '../../ui/navigation/discoveryNavigation';
import type { VersionChange, SavedApp } from '../../models/types';
import { common, Want } from '@kit.AbilityKit';
import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import { collectionStarIcon } from '../../ui/icons/collectionIcon';
import {
    hdsEffect,
    HdsNavDestination,
    HdsNavDestinationTitleMode,
    ScrollEffectType,
} from '@kit.UIDesignKit';
import {
    BACKGROUND_REFRESH_DELAY_MS,
    CONTENT_MAX_WIDTH,
    CONTINUATION_ROUTE_DETAIL,
    ROUTE_APP_DETAIL,
    HUAWEI_APP_DETAIL_URL_PREFIX,
    RESPONSIVE_BREAKPOINT_LARGE,
    RESPONSIVE_BREAKPOINT_MEDIUM,
    S_SITE_PUBLIC_BASE_URL,
    S_SITE_APP_DETAIL_QUERY,
} from '../../config/constants';
import {
    flushContinuationScroll, getMainTabIndex, setContinuationScrollDistance, consumeDetailTarget,
    getContinuationState,
    peekDetailTarget,
    setContinuationDetailChartsState,
    setContinuationView,
} from '../../state/appState';
import { fetchAppById, fetchAppByPackage, fetchAppMetrics, fetchAppRatingHistory } from '../../services/api/MarketApi';
import { scrollByAxis } from '../../ui/interaction/scroll';
import { showToastSafely } from '../../ui/feedback/safeUi';
import { getPathParamsSafely, popPathSafely } from '../../ui/navigation/safeNavigation';
import {
    cancelStaggerEnterAnimation,
    contentEnterTransition,
    startStaggerEnterAnimation,
} from '../../ui/animation/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../ui/theme/visualEffects';
import { WebShareManager } from '../../services/sharing/shareControl';
import { vibration } from '../../utils/device/vibration';
import {
    HDS_MATERIAL_LEVEL_GENTLE,
    HDS_MATERIAL_TYPE_ADAPTIVE,
    HDS_TITLE_SIZE_SMALL,
    SUPPORTS_HARMONY_API_23,
} from '../../config/platformCompatibility';
import type {
    ApiDataResult,
    AppDetailPayload,
    AppMetric,
    AppRatingHistory,
    AppRouteTarget,
    BaseAPIResponse,
    ChartViewportState,
    MarketApp,
    ScreenshotInfo,
} from '../../models/types';
import { InteractiveLineChart } from '../../components/charts/InteractiveLineChart';
import { RatingBreakdown } from '../../components/detail/RatingBreakdown';
import type { LineChartPoint } from '../../models/chartTypes';
import { detailDownloadPoints, detailRatingPoints } from '../../domain/detail/DetailHistory';
import { detailFields, detailScreenshots } from '../../ui/detail/DetailPresentation';

@Component
export struct AppDetailPage {
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction(this.getUIContext());
    @Consume('pageStack') private pageStack: NavPathStack;
    routeTarget: AppRouteTarget = {};
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private scroller: Scroller = new Scroller();
    private leftScroller: Scroller = new Scroller();
    private rightScroller: Scroller = new Scroller();
    private shareManager?: WebShareManager;
    private readonly shareOwnerId: number = WebShareManager.createOwnerId();
    private requestScope: RequestScope = new RequestScope();
    private target: AppRouteTarget = {};
    @State @Watch('preparePresentation') private app: MarketApp | undefined = undefined;
    @State private fieldsCache: DetailField[] = [];
    @State private screenshotCache: ScreenshotInfo[] = [];
    @State private screenshotsVisible: boolean = false;
    @State private downloadsVisible: boolean = false;
    @State private ratingsVisible: boolean = false;
    @State private pageVisible: boolean = true;
    @State private featuresExpanded: boolean = false;
    @State private descriptionExpanded: boolean = false;
    private historyRequested: boolean = false;
    private historyRequestVersion: number = -1;
    private historyPackage: string = '';
    private historyActivated: boolean = false;
    @State private versions: VersionChange[] = [];
    @State private metricsLoading: boolean = false;
    @State private metricsError: string = '';
    @State private metricsStale: boolean = false;
    @State private saved: boolean = false;
    @State private saving: boolean = false;
    private savedToken: number = 0;
    private metricsToken: number = 0;
    @State private downloadChartPoints: LineChartPoint[] = [];
    @State private ratingChartPoints: LineChartPoint[] = [];
    @State private loading: boolean = true;
    @State private refreshing: boolean = false;
    @State private fromCache: boolean = false;
    @State private errorMessage: string = '';
    @State private started: boolean = false;
    @State private contentWidth: number = 0;
    @State private animStep: number = 0;
    @State private downloadChartViewport: ChartViewportState = { zoom: 1, panRatio: 0 };
    @State private ratingChartViewport: ChartViewportState = { zoom: 1, panRatio: 0 };
    @State private pressedAction: string = '';
    @StorageLink('applicationActive') @Watch('onApplicationActiveChanged') private applicationActive: boolean = true;
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    @StorageLink('immersiveMaterialLevel') private immersiveMaterialLevel: number = HDS_MATERIAL_LEVEL_GENTLE;
    private active: boolean = false;
    private requestVersion: number = 0;
    private initialLoadTimer: number = -1;
    private restoreScrollTimer: number = -1;
    private pendingRestoreDistance: number = -1;
    private backgroundRefreshTimer: number = -1;
    private enterAnimationPending: boolean = true;
    private enterAnimationTimers: number[] = [];

    private vibrate(): void {
        if (this.vibrationLevel > 0) {
            vibration.dotVibration();
        }
    }

    private startPageAnimationForEntry(): void {
        if (!this.enterAnimationPending || !this.app || this.contentWidth <= 0) {
            return;
        }
        this.enterAnimationPending = false;
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.animStep = 0;
        this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 2, (step: number): void => {
            this.animStep = step;
        });
    }

    private requiredStep(group: string): number {
        return group === 'identity' || group === 'information' ? 1 : 2;
    }

    aboutToAppear(): void {
        this.requestScope = new RequestScope();
        this.active = true;
        this.enterAnimationPending = true;
        this.animStep = 0;
        const fallbackTarget = peekDetailTarget();
        this.target = (this.routeTarget.appId || this.routeTarget.packageName) ? this.routeTarget : fallbackTarget;
        this.app = this.target.previewApp;
        this.preparePresentation();
        const chartState = getContinuationState().detailChartsState;
        if (chartState.targetKey === this.detailTargetKey()) {
            this.downloadChartViewport = chartState.downloadViewport ?? { zoom: 1, panRatio: 0 };
            this.ratingChartViewport = chartState.ratingViewport ?? { zoom: 1, panRatio: 0 };
        } else {
            this.downloadChartViewport = { zoom: 1, panRatio: 0 };
            this.ratingChartViewport = { zoom: 1, panRatio: 0 };
            this.syncDetailChartState();
        }
        this.startPageAnimationForEntry();
    }

    private detailTargetKey(): string {
        return this.target.appId || this.target.packageName || '';
    }

    private syncDetailChartState(): void {
        setContinuationDetailChartsState({
            targetKey: this.detailTargetKey(),
            downloadViewport: this.downloadChartViewport,
            ratingViewport: this.ratingChartViewport,
        });
    }

    private updateDownloadChartViewport(viewport: ChartViewportState): void {
        this.downloadChartViewport = viewport;
        this.syncDetailChartState();
    }

    private updateRatingChartViewport(viewport: ChartViewportState): void {
        this.ratingChartViewport = viewport;
        this.syncDetailChartState();
    }

    private shareUrl(): string {
        if (!this.app) {
            return S_SITE_PUBLIC_BASE_URL;
        }
        return `${S_SITE_PUBLIC_BASE_URL}${S_SITE_APP_DETAIL_QUERY}${encodeURIComponent(this.app.app_id)}`;
    }

    private syncShareData(): void {
        if (!this.app) {
            return;
        }
        try {
            const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            this.shareManager = WebShareManager.getInstance(context);
            this.shareManager.updateShareData(
                this.shareUrl(),
                `${this.app.name}｜Dashboard应用看板`,
                `${this.app.developer_name || '未知开发者'} · ${this.app.pkg_name}`,
                undefined,
                this.shareOwnerId,
            );
            this.shareManager.enablePassiveShare(this.shareOwnerId);
        } catch (error) {
            console.warn('[Dashboard][AppDetailPage][WARN]', `分享能力暂不可用: ${JSON.stringify(error)}`);
        }
    }

    private suspendShare(): void {
        this.shareManager?.clearShareDataProvider(this.shareOwnerId);
        this.shareManager?.disablePassiveShare(this.shareOwnerId);
    }

    private onApplicationActiveChanged(): void {
        if (!this.applicationActive) this.suspendShare();
        else if (this.active && this.pageVisible) this.syncShareData();
    }

    private showShare(): void {
        this.vibrate();
        if (!this.app) {
            showToastSafely(this.prompt, '详情加载完成后才能分享', 1500, 'V3AppDetail');
            return;
        }
        this.syncShareData();
        this.shareManager?.showSystemShare(this.shareUrl());
    }

    private closePage(): void {
        const continuation = getContinuationState();
        setContinuationView(continuation.mainTab, 0);
        if (!popPathSafely(this.pageStack, 'pages/detail/AppDetailPage')) {
            showToastSafely(this.prompt, '暂时无法返回，请重试', 1600, 'AppDetailPage');
        }
    }

    private saveScrollPosition(scroller: Scroller): void {
        if (!this.pageVisible || !this.applicationActive) return;
        try {
            setContinuationScrollDistance(scroller.currentOffset().yOffset);
        } catch (error) {
            console.warn('[Dashboard][pages/detail/AppDetailPage][WARN]',
                `保存详情页滚动位置失败: ${JSON.stringify(error)}`);
        }
    }

    private initializePage(): void {
        if (this.started) {
            return;
        }
        this.started = true;
        const pendingTarget = consumeDetailTarget();
        if (!this.target.appId && !this.target.packageName) {
            const routeParams = getPathParamsSafely<AppRouteTarget>(this.pageStack, ROUTE_APP_DETAIL);
            const routed = routeParams.length > 0 ? routeParams[routeParams.length - 1] : this.routeTarget;
            this.target = routed?.appId || routed?.packageName ? routed : pendingTarget;
            this.app = this.target.previewApp;
        }
        const continuation = getContinuationState();
        setContinuationView(
            continuation.mainTab,
            0,
            CONTINUATION_ROUTE_DETAIL,
            this.target,
            this.shareUrl(),
        );
        this.initialLoadTimer = setTimeout((): void => {
            this.initialLoadTimer = -1;
            if (!this.active) return;
            this.load(false);
        }, 0);
        const sameTarget = (!!this.target.appId && this.target.appId === continuation.detailAppId) ||
            (!!this.target.packageName && this.target.packageName === continuation.detailPackageName);
        if (sameTarget && continuation.routeName === CONTINUATION_ROUTE_DETAIL && continuation.scrollDistance > 0) {
            this.pendingRestoreDistance = continuation.scrollDistance;
            this.restorePendingScroll();
        }
    }

    private restorePendingScroll(): void {
        if (this.pendingRestoreDistance < 0 || !this.app || !this.pageVisible) return;
        if (this.restoreScrollTimer >= 0) clearTimeout(this.restoreScrollTimer);
        this.restoreScrollTimer = setTimeout((): void => {
            this.restoreScrollTimer = -1;
            if (!this.active || !this.pageVisible || this.pendingRestoreDistance < 0) return;
            try {
                const scroller = this.contentWidth >= 840 ? this.rightScroller : this.scroller;
                scroller.scrollTo({ xOffset: 0, yOffset: this.pendingRestoreDistance, animation: { duration: 0 } });
                this.pendingRestoreDistance = -1;
            } catch (_) { /* Retry when the page is shown or data becomes available. */ }
        }, 80);
    }

    private request(force: boolean): Promise<ApiDataResult<BaseAPIResponse<AppDetailPayload>>> {
        if (this.target.appId) {
            return fetchAppById(this.target.appId, force, this.requestScope);
        }
        if (this.target.packageName) {
            return fetchAppByPackage(this.target.packageName, force, this.requestScope);
        }
        return Promise.reject(new Error('缺少应用标识'));
    }

    private load(force: boolean, background: boolean = false, showRefreshing: boolean = false): void {
        this.requestScope.cancel(); this.requestScope = new RequestScope();
        const trace = PerformanceTrace.begin('Dashboard.Detail.Data');
        const version = ++this.requestVersion;
        if (showRefreshing) this.refreshing = true;
        if (!background) { this.loading = true; this.errorMessage = ''; }
        this.request(force).then((result) => {
            this.applyDetailResult(result, version, force && (!background || showRefreshing));
        }).catch((error: Error) => {
            if (this.active && version === this.requestVersion && !background) this.errorMessage = `详情加载失败：${error.message}`;
        }).finally((): void => {
            PerformanceTrace.finish('Dashboard.Detail.Data', trace);
            if (!this.active || version !== this.requestVersion) return;
            this.loading = false;
            this.refreshing = false;
        });
    }

    private applyDetailResult(result: ApiDataResult<BaseAPIResponse<AppDetailPayload>>, version: number,
        refreshHistory: boolean): void {
        if (!this.active || version !== this.requestVersion) return;
        if (!result.data.success || !result.data.data?.full_info) throw new Error('未找到该应用');
        this.app = result.data.data.full_info;
        this.restorePendingScroll();
        this.fromCache = result.stale;
        this.startPageAnimationForEntry();
        this.syncShareData();
        this.refreshSaved();
        if (this.historyActivated && this.app.pkg_name) {
            this.requestHistory(refreshHistory, version);
        }
        result.revalidated?.then((fresh) => {
            if (!fresh.stale) this.applyDetailResult(fresh, version, false);
        }).catch((): void => {});
    }

    private loadRatings(packageName: string, force: boolean, version: number): void {
        fetchAppRatingHistory(packageName, force, this.requestScope).then((result) => {
            if (!this.active || version !== this.requestVersion || !result.data.success) return;
            this.ratingChartPoints = detailRatingPoints(result.data.data || []);
            result.revalidated?.then((fresh) => {
                if (this.active && version === this.requestVersion && !fresh.stale) {
                    this.ratingChartPoints = detailRatingPoints(fresh.data.data || []);
                }
            }).catch((): void => {});
        }).catch((error: Error): void => {
            console.warn('[Dashboard][AppDetailPage][WARN]', `评分趋势加载失败: ${error.message}`);
        });
    }

    private async loadMetrics(packageName: string, force: boolean, version: number): Promise<void> {
        const token = ++this.metricsToken;
        this.metricsLoading = true;
        this.metricsError = '';
        try {
            const result = await fetchAppMetrics(packageName, force, this.requestScope);
            if (!this.active || version !== this.requestVersion || token !== this.metricsToken) return;
            if (!result.data.success) throw new Error('历史指标暂不可用');
            const metrics = PerformanceTrace.measure('Dashboard.Detail.SortHistory', (): AppMetric[] => sortAppMetrics(result.data.data || []));
            this.downloadChartPoints = detailDownloadPoints(metrics);
            this.versions = versionChanges(metrics, true);
            this.metricsStale = result.stale;
            result.revalidated?.then((fresh) => {
                if (!this.active || version !== this.requestVersion || token !== this.metricsToken || fresh.stale) return;
                const metrics = sortAppMetrics(fresh.data.data || []);
                this.downloadChartPoints = detailDownloadPoints(metrics);
                this.versions = versionChanges(metrics, true);
                this.metricsStale = false;
            }).catch((): void => {});
        } catch (error) {
            if (this.active && version === this.requestVersion && token === this.metricsToken) this.metricsError = (error as Error).message;
        } finally {
            if (this.active && version === this.requestVersion && token === this.metricsToken) this.metricsLoading = false;
        }
    }

    private async refreshSaved(): Promise<void> {
        if (this.saving) return;
        const token = ++this.savedToken;
        try {
            const collection = await getLocalCollection();
            if (this.active && token === this.savedToken) {
                this.saved = collection.apps.some((item: SavedApp) => item.appId === this.app?.app_id);
            }
        } catch (_) {
            console.warn('[Dashboard][AppDetailPage][WARN]', '读取收藏失败');
        }
    }

    private async toggleSaved(): Promise<void> {
        if (!this.app || this.saving) return;
        this.saving = true;
        this.savedToken++;
        const next = !this.saved;
        try {
            await saveCollectedApp({ appId: this.app.app_id, packageName: this.app.pkg_name,
                name: this.app.name, iconUrl: this.app.icon_url }, next);
            if (this.active) {
                this.saved = next;
                showToastSafely(this.prompt, next ? '收藏成功' : '取消收藏');
            }
        } catch (_) {
            showToastSafely(this.prompt, '保存收藏失败，请重试');
        } finally { if (this.active) this.saving = false; }
    }

    private openDeveloper(): void {
        if (!this.app) return;
        openAppCollection(this.pageStack, { title: this.app.developer_name || '开发者应用',
            developerId: this.app.dev_id, developerName: this.app.developer_name });
    }

    private preparePresentation(): void {
        this.fieldsCache = detailFields(this.app);
        this.screenshotCache = detailScreenshots(this.app);
    }

    private fields(): DetailField[] { return this.fieldsCache; }
    private screenshots(): ScreenshotInfo[] { return this.screenshotCache; }

    private activateHistory(visible: boolean): void {
        if (!visible) return;
        this.historyActivated = true;
        this.requestHistory(false, this.requestVersion);
    }

    private requestHistory(force: boolean, version: number): void {
        if (!this.active || !this.app?.pkg_name) return;
        if (!force && this.historyRequested && this.historyRequestVersion === version &&
            this.historyPackage === this.app.pkg_name) return;
        this.historyRequested = true;
        this.historyRequestVersion = version;
        this.historyPackage = this.app.pkg_name;
        this.loadMetrics(this.app.pkg_name, force, version);
        this.loadRatings(this.app.pkg_name, force, version);
    }

    private async openExternal(uri: string, failureMessage: string): Promise<void> {
        try {
            const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            await context.startAbility({
                action: 'ohos.want.action.viewData',
                entities: ['entity.system.browsable'],
                uri,
            } as Want);
        } catch (error) {
            console.error('[Dashboard][pages/detail/AppDetailPage][ERROR]', `${failureMessage}: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, failureMessage, 1800, 'V3AppDetail');
        }
    }

    private async openMarket(): Promise<void> {
        if (!this.app) {
            return;
        }
        const id = this.app.app_id || this.app.alliance_app_id || '';
        await this.openExternal(`${HUAWEI_APP_DETAIL_URL_PREFIX}${id}`, '无法打开应用市场详情');
    }

    @Builder
    private appIdentity(): void {
        AppIdentity({ app: this.app, onOpenDeveloper: (): void => this.openDeveloper() })
            .opacity(this.animStep >= this.requiredStep('identity') ? 1 : 0)
            .translate({ y: this.animStep >= this.requiredStep('identity') ? 0 : 20 })
    }

    @Builder
    private appActions(): void {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
            Button('在华为应用市场打开', { stateEffect: false })
                .margin(4)
                .backgroundColor($r('app.color.diff_content'))
                .scale({
                    x: this.pressedAction === 'market' ? 0.97 : 1,
                    y: this.pressedAction === 'market' ? 0.97 : 1,
                })
                .animation({ duration: 120, curve: Curve.EaseOut })
                .visualEffect(pressVisualEffect(this.pressedAction === 'market',
                    hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                .compositingFilter(pressLightFieldFilter(this.pressedAction === 'market'))
                .onTouch((event: TouchEvent): void => {
                    if (event.type === TouchType.Down) this.pressedAction = 'market';
                    else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                        this.pressedAction = '';
                    }
                })
                .onClick(() => {
                    this.vibrate();
                    this.openMarket();
                })
                .accessibilityText('在华为应用市场打开此应用')
            if (this.app?.privacy_url) {
                Button('隐私政策', { stateEffect: false })
                    .margin(4)
                    .fontColor($r('app.color.v3_text_primary'))
                    .backgroundColor($r('app.color.v3_surface_alt'))
                    .scale({
                        x: this.pressedAction === 'privacy' ? 0.97 : 1,
                        y: this.pressedAction === 'privacy' ? 0.97 : 1,
                    })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedAction === 'privacy',
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedAction === 'privacy'))
                    .onTouch((event: TouchEvent): void => {
                        if (event.type === TouchType.Down) this.pressedAction = 'privacy';
                        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                            this.pressedAction = '';
                        }
                    })
                    .onClick(() => {
                        this.vibrate();
                        this.openExternal(this.app!.privacy_url!, '无法打开应用隐私政策');
                    })
                    .accessibilityText(`打开${this.app?.name || '此应用'}隐私政策`)
            }
        }
        .width('100%')
        .accessibilityText('应用详情操作')
    }

    @Builder
    private appInformation(): void {
        Column({ space: 12 }) {
            if (this.contentWidth < 840) {
                this.appActions()
            }
            GridRow({
                columns: { xs: 1, sm: 2, md: 2 },
                gutter: { x: 8, y: 8 },
                breakpoints: {
                    value: [RESPONSIVE_BREAKPOINT_MEDIUM, RESPONSIVE_BREAKPOINT_LARGE],
                    reference: BreakpointsReference.WindowSize,
                },
            }) {
                ForEach(this.fields(), (field: DetailField) => {
                    GridCol({ span: 1 }) { DetailTag({ field }) }
                }, (field: DetailField) => field.label)
            }
            .width('100%')
            .padding(12)
            .borderRadius(16)
            .backgroundColor($r('app.color.v3_surface'))
            .border({ width: 1, color: $r('app.color.nd_card_border') })
            .accessibilityText('以标签形式展示的应用详细字段')

            Button('查看开发者的全部应用', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-0'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-0', event)).onClick((): void => { this.interaction.activate('discovery-0'); this.openDeveloper(); })
            RatingBreakdown({ app: this.app! })

            if (this.contentWidth >= 840) {
                this.appActions()
            }
        }
        .width('100%')
        .opacity(this.animStep >= this.requiredStep('information') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('information') ? 0 : 20 })
        .accessibilityGroup(false).accessibilityLevel('no')
        .accessibilityText('应用详细信息和操作')
    }

    @Builder
    private appDescription(): void {
        AppDescription({ description: this.app?.description || '', newFeatures: this.app?.new_features || '',
            descriptionExpanded: $descriptionExpanded, featuresExpanded: $featuresExpanded })
            .opacity(this.animStep >= this.requiredStep('description') ? 1 : 0)
            .translate({ y: this.animStep >= this.requiredStep('description') ? 0 : 20 })
    }

    @Builder
    private appScreenshots(): void {
        Column({ space: 10 }) {
            Text('应用截图')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary'))
                .width('100%')
                .accessibilityText('应用截图')
            ScreenshotCarousel({ active: this.applicationActive && this.pageVisible && this.screenshotsVisible, screenshots: this.screenshots(), compact: this.contentWidth < 840 })
        }
        .width('100%')
        .padding(18)
        .borderRadius(18)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .opacity(this.animStep >= this.requiredStep('screenshots') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('screenshots') ? 0 : 20 })
        .accessibilityGroup(false).accessibilityLevel('no')
        .accessibilityText('应用截图区域')
    }

    @Builder
    private downloadChart(): void {
        InteractiveLineChart({
            active: this.applicationActive && this.pageVisible && this.downloadsVisible,
            title: '下载量趋势',
            unit: '次',
            points: this.downloadChartPoints,
            lineColor: $r('app.color.diff_content'),
            enablePressEffect: false,
            viewport: this.downloadChartViewport,
            onViewportChange: (viewport: ChartViewportState): void => this.updateDownloadChartViewport(viewport),
        })
        .opacity(this.animStep >= this.requiredStep('downloadChart') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('downloadChart') ? 0 : 20 })
    }

    @Builder
    private ratingChart(): void {
        InteractiveLineChart({
            active: this.applicationActive && this.pageVisible && this.ratingsVisible,
            title: '评分趋势',
            unit: '分',
            points: this.ratingChartPoints,
            lineColor: $r('app.color.v3_accent_orange'),
            enablePressEffect: false,
            viewport: this.ratingChartViewport,
            onViewportChange: (viewport: ChartViewportState): void => this.updateRatingChartViewport(viewport),
        })
        .opacity(this.animStep >= this.requiredStep('ratingChart') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('ratingChart') ? 0 : 20 })
    }

    @Builder
    private identityAndInformation(): void {
        Column({ space: 14 }) {
            this.appIdentity()
            Divider()
                .color($r('app.color.border'))
                .opacity(this.animStep >= this.requiredStep('information') ? 1 : 0)
                .accessibilityText('应用身份与详细信息分隔线')
            this.appInformation()
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
    }

    @Builder
    private versionTimeline(): void {
        VersionTimeline({ changes: this.versions, loading: this.metricsLoading, error: this.metricsError,
            stale: this.metricsStale, onRetry: (): void => {
                if (this.app?.pkg_name) this.loadMetrics(this.app.pkg_name, true, this.requestVersion);
            } })
    }

    @Builder
    private descriptionScreenshotsAndCharts(): void {
        Column({ space: 14 }) {
            DeferredDetailSection({ active: this.applicationActive && this.pageVisible, placeholderHeight: 240,
                content: (): void => { this.appDescription(); } })
            if (this.screenshots().length > 0) {
                DeferredDetailSection({ active: this.applicationActive && this.pageVisible, placeholderHeight: 460,
                    onVisibilityChanged: (visible: boolean): void => { this.screenshotsVisible = visible; },
                    content: (): void => { this.appScreenshots(); } })
            }
            DeferredDetailSection({ active: this.applicationActive && this.pageVisible,
                onVisibilityChanged: (visible: boolean): void => {
                    this.downloadsVisible = visible; this.activateHistory(visible);
                }, content: (): void => { this.downloadChart(); } })
            DeferredDetailSection({ active: this.applicationActive && this.pageVisible,
                onVisibilityChanged: (visible: boolean): void => {
                    this.ratingsVisible = visible; this.activateHistory(visible);
                }, content: (): void => { this.ratingChart(); } })
            DeferredDetailSection({ active: this.applicationActive && this.pageVisible,
                onVisibilityChanged: (visible: boolean): void => this.activateHistory(visible),
                content: (): void => { this.versionTimeline(); } })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
    }

    @Builder
    private detailContent(): void {
        Column({ space: 14 }) {
            this.identityAndInformation()
            this.descriptionScreenshotsAndCharts()
        }
        .width('100%')
        .accessibilityGroup(false).accessibilityLevel('no')
        .accessibilityText('纵向排列的应用信息、介绍、截图和趋势图表')
    }

    @Builder
    private wideDetailContent(): void {
        Column() {
            Row({ space: 16 }) {
                Refresh({ refreshing: $$this.refreshing }) {
                    Scroll(this.leftScroller) {
                        Column({ space: 14 }) {
                            Blank().height(100).width('100%')
                            if (this.fromCache) {
                                Text('网络不佳，当前显示已缓存的应用详情')
                                    .fontSize(13)
                                    .fontColor($r('app.color.v3_text_primary'))
                                    .padding(12)
                                    .width('100%')
                                    .borderRadius(12)
                                    .backgroundColor($r('app.color.v3_warning_bg'))
                                    .accessibilityText('网络不佳，当前显示已缓存的应用详情')
                                    .transition(contentEnterTransition(8))
                            }
                            this.identityAndInformation()
                            Blank().height(36).width('100%')
                        }
                        .width('100%')
                        .padding({ left: 14, right: 7, top: 12 })
                    }
                    .width('100%')
                    .height('100%')
                    .scrollBar(BarState.Off)
                    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true, effectEdge: EffectEdge.END })
                    .onAxisEvent((event: AxisEvent): void => scrollByAxis(this.leftScroller, event))
                    .accessibilityText('可独立滚动的应用信息栏')
                }
                .layoutWeight(4)
                .height('100%')
                .onRefreshing((): void => {
                    this.vibrate();
                    this.load(true, true, true);
                })

                Divider()
                    .vertical(true)
                    .height('100%')
                    .color($r('app.color.border'))
                    .accessibilityText('应用信息与内容分隔线')

                Refresh({ refreshing: $$this.refreshing }) {
                    Scroll(this.rightScroller) {
                        Column({ space: 14 }) {
                            Blank().height(100).width('100%')
                            this.descriptionScreenshotsAndCharts()
                            Blank().height(36).width('100%')
                        }
                        .width('100%')
                        .padding({ left: 7, right: 14, top: 12 })
                    }
                    .width('100%')
                    .height('100%')
                    .scrollBar(BarState.Off)
                    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true, effectEdge: EffectEdge.END })
                    .onDidScroll((): void => this.saveScrollPosition(this.rightScroller))
                    .onScrollStop((): void => flushContinuationScroll())
                    .onAxisEvent((event: AxisEvent): void => scrollByAxis(this.rightScroller, event))
                    .accessibilityText('可独立滚动的应用介绍、截图和趋势图表栏')
                }
                .layoutWeight(6)
                .height('100%')
                .onRefreshing((): void => {
                    this.vibrate();
                    this.load(true, true, true);
                })
            }
            .width('100%')
            .height('100%')
            .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
            .padding({ left: 14, right: 14 })
            .alignItems(VerticalAlign.Top)
            .accessibilityGroup(false).accessibilityLevel('no')
            .accessibilityText('左右两栏可分别滚动的应用详情')
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
    }

    aboutToDisappear(): void {
        flushContinuationScroll(); this.interaction.dispose();
        this.requestScope.cancel();
        this.active = false;
        this.requestVersion++;
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.enterAnimationTimers = [];
        if (this.initialLoadTimer >= 0) clearTimeout(this.initialLoadTimer);
        if (this.restoreScrollTimer >= 0) clearTimeout(this.restoreScrollTimer);
        if (this.backgroundRefreshTimer >= 0) clearTimeout(this.backgroundRefreshTimer);
        this.initialLoadTimer = -1;
        this.restoreScrollTimer = -1;
        this.backgroundRefreshTimer = -1;
        this.shareManager?.clearShareDataProvider(this.shareOwnerId);
        this.shareManager?.disablePassiveShare(this.shareOwnerId);
    }

    build() {
        HdsNavDestination() {
          Stack() {
            if (this.contentWidth >= 840 && this.app && this.errorMessage === '') {
              this.wideDetailContent()
            } else {
              Refresh({ refreshing: $$this.refreshing }) {
              Scroll(this.scroller) {
                Column({ space: 14 }) {
                    Blank().height(100).width('100%')
                    if (this.loading && !this.app) {
                        Column({ space: 12 }) {
                            LoadingProgress()
                                .width(42)
                                .height(42)
                                .color($r('app.color.diff_content'))
                                .accessibilityText('应用详情加载中')
                            Text('正在查找应用并从 API 获取详情…')
                                .fontColor($r('app.color.v3_text_secondary'))
                                .accessibilityText('正在查找应用并从API获取详情')
                        }
                        .height(360)
                        .justifyContent(FlexAlign.Center)
                        .accessibilityGroup(true)
                        .accessibilityText('应用详情正在加载')
                        .transition(contentEnterTransition())
                    } else if (this.errorMessage !== '') {
                        Column({ space: 12 }) {
                            Image($r('app.media.attention'))
                                .width(42)
                                .height(42)
                                .objectFit(ImageFit.Contain)
                                .accessibilityText('加载错误图标')
                            Text(this.errorMessage)
                                .fontColor($r('app.color.v3_accent_red'))
                                .textAlign(TextAlign.Center)
                                .accessibilityText(this.errorMessage)
                            Button('重新加载')
                                .backgroundColor($r('app.color.diff_content'))
                                .onClick(() => {
                                    this.vibrate();
                                    this.load(true);
                                })
                                .accessibilityText('重新加载应用详情')
                        }
                        .height(360)
                        .justifyContent(FlexAlign.Center)
                        .accessibilityGroup(false).accessibilityLevel('no')
                        .accessibilityText(this.errorMessage)
                        .transition(contentEnterTransition())
                    } else if (this.app) {
                        if (this.fromCache) {
                            Text('网络不佳，当前显示已缓存的应用详情')
                                .fontSize(13)
                                .fontColor($r('app.color.v3_text_primary'))
                                .padding(12)
                                .width('100%')
                                .borderRadius(12)
                                .backgroundColor($r('app.color.v3_warning_bg'))
                                .accessibilityText('网络不佳，当前显示已缓存的应用详情')
                                .transition(contentEnterTransition(8))
                        }

                        this.detailContent()
                    }
                    Blank().height(36)
                }
                .width('100%')
                .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
                .padding({ left: 14, right: 14, top: 12 })
              }
              .width('100%')
              .height('100%')
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true, effectEdge: EffectEdge.END })
              .onDidScroll((): void => this.saveScrollPosition(this.scroller))
              .onScrollStop((): void => flushContinuationScroll())
              .backgroundColor($r('app.color.background'))
              .onAxisEvent((event: AxisEvent): void => scrollByAxis(this.scroller, event))
              .accessibilityText('可下拉刷新的公用应用详情页')
              }
              .width('100%').height('100%')
              .onRefreshing((): void => {
                this.vibrate();
                this.load(true, true, true);
              })
            }
          }
          .width('100%')
          .height('100%')
          .clip(true)
          .backgroundColor($r('app.color.background'))
          .onAreaChange((_oldValue: Area, newValue: Area): void => {
              this.contentWidth = Number(newValue.width);
              this.startPageAnimationForEntry();
          })
          .onAppear((): void => this.initializePage())
        }
        .titleBar({
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: false,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                    blurEffectiveStartOffset: LengthMetrics.vp(0),
                    blurEffectiveEndOffset: LengthMetrics.vp(20),
                },
                originalStyle: {
                    backgroundStyle: {
                        backgroundColor: Color.Transparent,
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary'),
                        },
                    },
                },
                scrollEffectStyle: {
                    backgroundStyle: {
                        backgroundColor: Color.Transparent,
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary'),
                        },
                    },
                },
                systemMaterialEffect: SUPPORTS_HARMONY_API_23 ? {
                    materialType: HDS_MATERIAL_TYPE_ADAPTIVE,
                    materialLevel: this.immersiveMaterialLevel,
                } : undefined,
            },
            content: {
                title: {
                    mainTitle: this.app?.name || '应用详情',
                    mainTitleSize: SUPPORTS_HARMONY_API_23 ? HDS_TITLE_SIZE_SMALL : undefined,
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: this.saved ? '取消收藏' : '收藏应用',
                                icon: collectionStarIcon(this.saved),
                                isEnabled: this.app !== undefined && !this.saving,
                                action: (): void => { this.vibrate(); this.toggleSaved(); },
                            },
                        },
                        {
                            content: {
                                label: '分享应用详情',
                                icon: $r('sys.symbol.share'),
                                isEnabled: this.app !== undefined,
                                action: () => this.showShare(),
                            },
                        },
                    ],
                },
                backIcon: {
                    action: () => this.closePage(),
                },
            },
        })
        .onHidden((): void => {
            this.pageVisible = false; flushContinuationScroll();
            this.suspendShare();
            this.requestScope.cancel(); this.requestVersion++; this.historyRequested = false;
            this.loading = false; this.refreshing = false; this.metricsLoading = false;
        })
        .onShown((): void => {
            this.pageVisible = true;
            setContinuationView(getMainTabIndex(), getContinuationState().scrollDistance,
                CONTINUATION_ROUTE_DETAIL, this.target, this.shareUrl());
            this.restorePendingScroll();
            if (this.requestScope.cancelled) {
                this.requestScope = new RequestScope();
                if (!this.app) this.load(false);
                else if (this.historyActivated) this.activateHistory(true);
            }
            this.refreshSaved();
            this.syncShareData();
            this.saveScrollPosition(this.contentWidth >= 840 ? this.rightScroller : this.scroller);
        })
        .titleMode(HdsNavDestinationTitleMode.MINI)
        .width('100%')
        .height('100%')
        .clip(true)
        .backgroundColor($r('app.color.background'))
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
        .onBackPressed((): boolean => {
            this.closePage();
            return true;
        })
        .accessibilityText('应用详情导航页')
    }
}
