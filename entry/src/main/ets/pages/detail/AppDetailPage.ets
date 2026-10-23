import { PerformanceTrace } from '../../common/PerformanceTrace';
import { RequestScope } from '../../common/CachedRequest';
import { getMainTabIndex, setContinuationScrollDistance } from '../../common/appState';
import { flushContinuationScroll } from '../../common/appState';
import { DeferredDetailSection } from '../../component/detail/DeferredDetailSection';
import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
import { DetailTag } from '../../component/detail/DetailTag';
import type { DetailField } from '../../component/detail/DetailTag';
import { ScreenshotCarousel } from '../../component/detail/ScreenshotCarousel';
import { DiscoveryButtonStyle } from '../../common/DiscoveryTheme';
import { VersionTimeline } from '../../component/detail/VersionTimeline';
import { sortAppMetrics, versionChanges } from '../../common/DiscoveryQuery';
import { getLocalCollection, saveCollectedApp } from '../../common/storage';
import { openAppCollection } from '../../common/discoveryNavigation';
import type { VersionChange, SavedApp } from '../../common/types';
import { common, Want } from '@kit.AbilityKit';
import { LengthMetrics, PromptAction, SymbolGlyphModifier } from '@kit.ArkUI';
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
} from '../../common/constants';
import {
    consumeDetailTarget,
    getContinuationState,
    peekDetailTarget,
    setContinuationDetailChartsState,
    setContinuationView,
} from '../../common/appState';
import { fetchAppById, fetchAppByPackage, fetchAppMetrics, fetchAppRatingHistory } from '../../common/MarketApi';
import { formatSdkVersion, formatBytes, formatCount, formatDateTime, formatDownloadCount } from '../../common/format';
import { scrollByAxis } from '../../common/scroll';
import { showToastSafely } from '../../common/safeUi';
import { getPathParamsSafely, popPathSafely } from '../../common/safeNavigation';
import {
    cancelStaggerEnterAnimation,
    contentEnterTransition,
    startStaggerEnterAnimation,
} from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { WebShareManager } from '../../common/shareControl';
import { vibration } from '../../common/vibration';
import {
    HDS_MATERIAL_LEVEL_GENTLE,
    HDS_MATERIAL_TYPE_ADAPTIVE,
    HDS_TITLE_SIZE_SMALL,
    SUPPORTS_HARMONY_API_23,
} from '../../common/platformCompatibility';
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
} from '../../common/types';
import { InteractiveLineChart } from '../../component/charts/InteractiveLineChart';
import { RatingBreakdown } from '../../component/detail/RatingBreakdown';
import type { LineChartPoint } from '../../component/charts/InteractiveLineChart';
import { downsampleLinePoints, filterDownloadOutliers } from '../../component/charts/chartDataProcessing';

interface TimedRating { rating: AppRatingHistory; time: number; value: number; }

const DETAIL_CHART_MAX_POINTS: number = 360;

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
            this.ratingChartPoints = this.prepareRatingPoints(result.data.data || []);
            result.revalidated?.then((fresh) => {
                if (this.active && version === this.requestVersion && !fresh.stale) {
                    this.ratingChartPoints = this.prepareRatingPoints(fresh.data.data || []);
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
            this.downloadChartPoints = this.prepareDownloadPoints(metrics);
            this.versions = versionChanges(metrics, true);
            this.metricsStale = result.stale;
            result.revalidated?.then((fresh) => {
                if (!this.active || version !== this.requestVersion || token !== this.metricsToken || fresh.stale) return;
                const metrics = sortAppMetrics(fresh.data.data || []);
                this.downloadChartPoints = this.prepareDownloadPoints(metrics);
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
            if (this.active) this.saved = next;
        } catch (_) {
            showToastSafely(this.prompt, '保存收藏失败，请重试');
        } finally { if (this.active) this.saving = false; }
    }

    private openDeveloper(): void {
        if (!this.app) return;
        openAppCollection(this.pageStack, { title: this.app.developer_name || '开发者应用',
            developerId: this.app.dev_id, developerName: this.app.developer_name });
    }

    private createFields(): DetailField[] {
        if (!this.app) {
            return [];
        }
        return [
            { label: '应用 ID', value: this.app.app_id || '-' },
            { label: '包名', value: this.app.pkg_name || '-' },
            { label: '开发者', value: this.app.developer_name || '-' },
            { label: '分类', value: `${this.app.kind_type_name || '-'} · ${this.app.kind_name || '-'}` },
            { label: '版本', value: `${this.app.version || '-'} (${this.app.version_code || 0})` },
            { label: '应用大小', value: formatBytes(this.app.size_bytes) },
            { label: '最低 SDK', value: formatSdkVersion(this.app.minsdk) },
            { label: '目标 SDK', value: formatSdkVersion(this.app.target_sdk) },
            { label: '编译 SDK', value: formatSdkVersion(this.app.compile_sdk_version) },
            { label: '最低 API 版本', value: String(this.app.min_hmos_api_level ?? '-') },
            { label: '下载量', value: formatDownloadCount(this.app.download_count) },
            { label: '评分', value: this.app.average_rating ? `${this.app.average_rating} / 5` : '-' },
            { label: '评分数量', value: formatCount(this.app.total_star_rating_count) },
            { label: '供应商', value: this.app.supplier || '-' },
            { label: '标签', value: this.app.tag_name || '-' },
            { label: '支持设备', value: this.app.main_device_codes?.join('、') || '-' },
            { label: '应用内购买', value: this.app.iap ? '支持' : '不支持' },
            { label: '付费状态', value: this.app.is_pay ? '付费应用' : '免费应用' },
            { label: '价格', value: String(this.app.price ?? '免费') },
            { label: '发行国家/地区', value: this.app.release_countries?.join('、') || '-' },
            { label: '备案主体', value: this.app.recordal_entity_name || this.app.recordal_entity_title || '-' },
            { label: '备案信息', value: this.app.app_recordal_info || '-' },
            { label: '上架时间', value: formatDateTime(this.app.listed_at) },
            { label: '数据更新', value: formatDateTime(this.app.updated_at) },
        ];
    }

    private createScreenshots(): ScreenshotInfo[] {
        if (!this.app) {
            return [];
        }
        if (this.app.new_screen_shots && this.app.new_screen_shots.length > 0) {
            return this.app.new_screen_shots;
        }
        return (this.app.screen_shots ?? []).map((url: string) => ({
            url,
            resolution: '',
            rotated: 0,
        } as ScreenshotInfo));
    }

    private preparePresentation(): void {
        this.fieldsCache = this.createFields();
        this.screenshotCache = this.createScreenshots();
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

    private prepareDownloadPoints(metrics: AppMetric[]): LineChartPoint[] {
        const points = metrics.filter((metric: AppMetric): boolean =>
            Number.isFinite(Number(metric.download_count)) && Number(metric.download_count) >= 0)
            .map((metric: AppMetric): LineChartPoint => ({
                label: metric.created_at, value: Number(metric.download_count), detail: metric.version || '-',
            }));
        return downsampleLinePoints(filterDownloadOutliers(points), DETAIL_CHART_MAX_POINTS)
            .map((point: LineChartPoint): LineChartPoint => ({
                label: formatDateTime(point.label).split(' ')[0], value: point.value,
                detail: `${formatDateTime(point.label)} · 下载量 ${formatDownloadCount(point.value)} · 版本 ${point.detail}`,
            }));
    }

    private prepareRatingPoints(ratingHistory: AppRatingHistory[]): LineChartPoint[] {
        const timed = ratingHistory.map((rating: AppRatingHistory): TimedRating => ({ rating,
            time: new Date(rating.report_date).getTime(),
            value: Number(rating.cumulative_avg_rating_high_prec ?? rating.cumulative_avg_rating_origin ?? 0),
        })).filter((item: TimedRating): boolean => Number.isFinite(item.time) &&
            Number.isFinite(item.value) && item.value >= 0 && item.value <= 5)
            .sort((left: TimedRating, right: TimedRating): number => left.time - right.time);
        const points = timed.map((item: TimedRating): LineChartPoint => ({ label: item.rating.report_date,
            value: item.value, detail: String(item.rating.cumulative_total_count ?? 0) }));
        return downsampleLinePoints(points, DETAIL_CHART_MAX_POINTS).map((point: LineChartPoint): LineChartPoint => ({
            label: point.label, value: point.value,
            detail: `${point.label} · 平均评分 ${point.value} · 累计 ${point.detail} 条评分`,
        }));
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
        Column({ space: 8 }) {
            Image(this.app?.icon_url || $r('app.media.startIcon'))
                .width(100)
                .height(100)
                .borderRadius(22)
                .objectFit(ImageFit.Cover)
                .alt($r('app.media.startIcon'))
                .accessibilityText(`${this.app?.name || '未知应用'}应用图标`)
                .margin({ bottom: 10 })
            Text(this.app?.name || '未知应用')
                .fontSize(30)
                .fontWeight(800)
                .fontColor($r('app.color.diff_content'))
                .textAlign(TextAlign.Center)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .accessibilityText(this.app?.name || '未知应用')
            Text(this.app?.developer_name || '未知开发者')
                .fontSize(20)
                .fontWeight(600)
                .fontColor($r('app.color.v3_text_secondary'))
                .textAlign(TextAlign.Center)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .scale({ x: this.interaction.pressedKey === 'developer-link' ? 0.97 : 1,
                    y: this.interaction.pressedKey === 'developer-link' ? 0.97 : 1 })
                .animation({ duration: 120, curve: Curve.EaseOut })
                .visualEffect(pressVisualEffect(this.interaction.pressedKey === 'developer-link',
                    hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'developer-link'))
                .onTouch((event: TouchEvent): void => this.interaction.touch('developer-link', event))
                .onClick((): void => { this.interaction.activate('developer-link'); this.openDeveloper(); })
                .accessibilityText(`开发公司${this.app?.developer_name || '未知'}，点击查看全部应用`)
        }
        .width('100%')
        .padding({ top: 18, bottom: 18, left: 12, right: 12 })
        .opacity(this.animStep >= this.requiredStep('identity') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('identity') ? 0 : 20 })
        .accessibilityGroup(false).accessibilityLevel('no')
        .accessibilityText(`${this.app?.name || '未知应用'}的图标、名称和开发公司`)
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
        Column({ space: 10 }) {
            Text('应用介绍')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary'))
                .width('100%')
                .accessibilityText('应用介绍')
            Text(this.app?.description || '暂无介绍')
                .maxLines(this.descriptionExpanded ? 10000 : 8)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontSize(14)
                .lineHeight(22)
                .fontColor($r('app.color.v3_text_primary'))
                .width('100%')
                .accessibilityText(this.app?.description || '暂无应用介绍')
            if ((this.app?.description?.length || 0) > 240) {
                Button(this.descriptionExpanded ? '收起介绍' : '展开完整介绍')
                    .onClick((): void => { this.descriptionExpanded = !this.descriptionExpanded; })
            }
            if (this.app?.new_features) {
                Divider().color($r('app.color.v3_chart_grid')).accessibilityText('内容分隔线')
                Text('新版特性')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary'))
                    .width('100%')
                    .accessibilityText('新版特性')
                Text(this.app.new_features)
                    .maxLines(this.featuresExpanded ? 10000 : 6)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontSize(14)
                    .lineHeight(22)
                    .fontColor($r('app.color.v3_text_primary'))
                    .width('100%')
                    .accessibilityText(this.app.new_features)
                if (this.app.new_features.length > 180) {
                    Button(this.featuresExpanded ? '收起新版特性' : '展开新版特性')
                        .onClick((): void => { this.featuresExpanded = !this.featuresExpanded; })
                }
            }
        }
        .width('100%')
        .padding(18)
        .borderRadius(18)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .opacity(this.animStep >= this.requiredStep('description') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('description') ? 0 : 20 })
        .accessibilityGroup(false).accessibilityLevel('no')
        .accessibilityText('应用介绍和新版特性')
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
                                icon: new SymbolGlyphModifier(this.saved ? $r('sys.symbol.star_fill') : $r('sys.symbol.star'))
                                    .fontColor([this.saved ? $r('app.color.diff_content') : $r('sys.color.icon_primary')]),
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
