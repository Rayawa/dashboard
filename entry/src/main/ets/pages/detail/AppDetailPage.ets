import { common, Want } from '@kit.AbilityKit';
import { curves, LengthMetrics, PromptAction } from '@kit.ArkUI';
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
import { formatBytes, formatCount, formatDateTime, formatDownloadCount } from '../../common/format';
import { scrollByAxis } from '../../common/scroll';
import { showToastSafely } from '../../common/safeUi';
import { popPathSafely } from '../../common/safeNavigation';
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
    HDS_MATERIAL_TYPE_IMMERSIVE,
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
import type { LineChartPoint } from '../../component/charts/InteractiveLineChart';

interface DetailField {
    label: string;
    value: string;
}

@Component
struct DetailTag {
    field: DetailField = { label: '', value: '-' };
    @State private pressed: boolean = false;

    build() {
        Row({ space: 7 }) {
            Text(this.field.label)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.diff_content'))
                .flexShrink(0)
                .accessibilityText(this.field.label)
            Scroll() {
                Row() {
                    Text(this.field.value)
                        .fontSize(12)
                        .fontColor($r('app.color.v3_text_primary'))
                        .maxLines(1)
                        .textAlign(TextAlign.Start)
                        .accessibilityText(`${this.field.label}${this.field.value}`)
                }
                .constraintSize({ minWidth: '100%' })
                .justifyContent(FlexAlign.Start)
            }
                .layoutWeight(1)
                .height(20)
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .edgeEffect(EdgeEffect.None)
                .accessibilityText(`${this.field.label}详情，可左右滑动查看`)
        }
        .alignItems(VerticalAlign.Center)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .width('100%')
        .height(36)
        .borderRadius(14)
        .backgroundColor($r('app.color.v3_surface_alt'))
        .border({ width: 1, color: $r('app.color.v3_chart_grid') })
        .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
            this.pressed, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
        .compositingFilter(pressLightFieldFilter(this.pressed))
        .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.pressed = true;
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressed = false;
        })
        .accessibilityGroup(true)
        .accessibilityText(`${this.field.label}，${this.field.value}`)
    }
}

@Component
struct ScreenshotCarousel {
    @Prop @Watch('onScreenshotsChanged') screenshots: ScreenshotInfo[] = [];
    @Prop compact: boolean = false;
    @State private currentIndex: number = 0;
    @State private dragOffset: number = 0;
    @State private frameWidth: number = 0;
    private autoPlayTimer: number = -1;
    private switching: boolean = false;
    private active: boolean = false;
    private settledScreenshotKeys: string[] = [];

    private onScreenshotsChanged(): void {
        if (this.currentIndex >= this.screenshots.length) {
            this.currentIndex = 0;
        }
        this.restartAutoPlay();
    }

    private isLandscape(): boolean {
        if (this.screenshots.length === 0) {
            return false;
        }
        const shot = this.screenshots[0];
        const normalized = shot.resolution.replace('×', '*').replace('x', '*').replace('X', '*');
        const parts = normalized.split('*');
        if (parts.length < 2) {
            return false;
        }
        let width = Number(parts[0]);
        let height = Number(parts[1]);
        if (width <= 0 || height <= 0) {
            return false;
        }
        if (shot.rotated !== 0) {
            const originalWidth = width;
            width = height;
            height = originalWidth;
        }
        return width > height;
    }

    private relativePosition(index: number): number {
        const count = this.screenshots.length;
        if (count <= 1 || index === this.currentIndex) {
            return 0;
        }
        const forward = (index - this.currentIndex + count) % count;
        if (forward === 1) {
            return 1;
        }
        if (forward === count - 1) {
            return -1;
        }
        return 2;
    }

    private cardPosition(index: number, leftCopy: boolean): number {
        if (leftCopy && this.screenshots.length === 2) {
            return index === this.currentIndex ? 2 : -1;
        }
        return this.relativePosition(index);
    }

    private revealProgress(): number {
        return Math.min(1, Math.abs(this.dragOffset) / Math.max(1, this.frameWidth));
    }

    private screenshotKey(shot: ScreenshotInfo, index: number): string {
        return `${shot.url}-${index}`;
    }

    private markScreenshotSettled(shot: ScreenshotInfo, index: number): void {
        const key = this.screenshotKey(shot, index);
        if (!this.settledScreenshotKeys.includes(key)) {
            this.settledScreenshotKeys.push(key);
        }
        if (this.allScreenshotsSettled()) {
            this.restartAutoPlay();
        }
    }

    private allScreenshotsSettled(): boolean {
        for (let index = 0; index < this.screenshots.length; index++) {
            if (!this.settledScreenshotKeys.includes(this.screenshotKey(this.screenshots[index], index))) {
                return false;
            }
        }
        return true;
    }

    private cardScale(position: number): number {
        if (position === 0) {
            return 1;
        }
        if (Math.abs(position) > 1) {
            return 0.9;
        }
        const revealing = (this.dragOffset < 0 && position === 1) || (this.dragOffset > 0 && position === -1);
        return revealing ? 0.9 + this.revealProgress() * 0.1 : 0.9;
    }

    private cardTranslateX(position: number): number {
        if (position === 0) {
            return this.dragOffset;
        }
        if (Math.abs(position) > 1) {
            return this.frameWidth * 2;
        }
        const sideOffset = this.frameWidth * (this.isLandscape() ? 0.12 : 0.32);
        if ((this.dragOffset < 0 && position === 1) || (this.dragOffset > 0 && position === -1)) {
            return position * sideOffset * (1 - this.revealProgress());
        }
        return position * sideOffset;
    }

    private cardOpacity(position: number): number {
        if (position === 0) {
            return 1;
        }
        if (Math.abs(position) > 1) {
            return 0;
        }
        const revealing = (this.dragOffset < 0 && position === 1) || (this.dragOffset > 0 && position === -1);
        return revealing ? 0.68 + this.revealProgress() * 0.32 : 0.68;
    }

    private cardZIndex(position: number): number {
        if (position === 0) {
            return 3;
        }
        if (Math.abs(position) > 1) {
            return 0;
        }
        const revealing = (this.dragOffset < 0 && position === 1) || (this.dragOffset > 0 && position === -1);
        return revealing ? 2 : 1;
    }

    private stopAutoPlay(): void {
        if (this.autoPlayTimer >= 0) {
            clearInterval(this.autoPlayTimer);
            this.autoPlayTimer = -1;
        }
    }

    private restartAutoPlay(): void {
        this.stopAutoPlay();
        if (!this.active || this.screenshots.length <= 1 || !this.allScreenshotsSettled()) {
            return;
        }
        this.autoPlayTimer = setInterval((): void => this.completeSwitch(1), 2500);
    }

    private completeSwitch(direction: number, restartTimer: boolean = true): void {
        if (this.switching || this.screenshots.length <= 1) {
            return;
        }
        this.stopAutoPlay();
        this.switching = true;
        const count = this.screenshots.length;
        const targetOffset = direction > 0 ? -Math.max(280, this.frameWidth) : Math.max(280, this.frameWidth);
        this.getUIContext().animateTo({
            duration: 280,
            curve: curves.springMotion(0.42, 0.88),
            onFinish: (): void => {
                this.currentIndex = (this.currentIndex + direction + count) % count;
                this.dragOffset = 0;
                this.switching = false;
                if (restartTimer) {
                    this.restartAutoPlay();
                }
            },
        }, (): void => {
            this.dragOffset = targetOffset;
        });
    }

    private restoreCurrentCard(): void {
        this.getUIContext().animateTo({
            duration: 220,
            curve: curves.springMotion(0.42, 0.88),
            onFinish: (): void => this.restartAutoPlay(),
        }, (): void => {
            this.dragOffset = 0;
        });
    }

    private selectPage(index: number): void {
        if (index === this.currentIndex || this.switching) {
            return;
        }
        this.stopAutoPlay();
        this.getUIContext().animateTo({
            duration: 260,
            curve: curves.springMotion(0.42, 0.88),
            onFinish: (): void => this.restartAutoPlay(),
        }, (): void => {
            this.currentIndex = index;
            this.dragOffset = 0;
        });
    }

    aboutToAppear(): void {
        this.active = true;
    }

    aboutToDisappear(): void {
        this.active = false;
        this.stopAutoPlay();
    }

    @Builder
    private screenshotCard(shot: ScreenshotInfo, index: number, leftCopy: boolean = false): void {
        Image(shot.url)
            .width(this.isLandscape() ? '88%' : (this.compact ? '91%' : '52%'))
            .aspectRatio(this.isLandscape() ? 16 / 9 : 9 / 16)
            .objectFit(ImageFit.Contain)
            .borderRadius(16)
            .clip(true)
            .backgroundColor($r('app.color.v3_surface_alt'))
            .border({ width: 1, color: $r('app.color.nd_card_border') })
            .alt($r('app.media.startIcon'))
            .onComplete((): void => this.markScreenshotSettled(shot, index))
            .onError((): void => this.markScreenshotSettled(shot, index))
            .translate({ x: this.cardTranslateX(this.cardPosition(index, leftCopy)) })
            .scale({
                x: this.cardScale(this.cardPosition(index, leftCopy)),
                y: this.cardScale(this.cardPosition(index, leftCopy)),
            })
            .opacity(this.cardOpacity(this.cardPosition(index, leftCopy)))
            .zIndex(this.cardZIndex(this.cardPosition(index, leftCopy)))
            .accessibilityText(`第${index + 1}张应用截图`)
    }

    build() {
        Column({ space: 12 }) {
            Stack({ alignContent: Alignment.Center }) {
                ForEach(this.screenshots, (shot: ScreenshotInfo, index: number) => {
                    this.screenshotCard(shot, index)
                }, (shot: ScreenshotInfo, index: number) => this.screenshotKey(shot, index))
                if (this.screenshots.length === 2) {
                    ForEach(this.screenshots, (shot: ScreenshotInfo, index: number) => {
                        this.screenshotCard(shot, index, true)
                    }, (shot: ScreenshotInfo, index: number) => `${this.screenshotKey(shot, index)}-left-copy`)
                }
            }
            .width('100%')
            .constraintSize({ maxWidth: 760 })
            .aspectRatio(this.isLandscape() ? 2 : (this.compact ? 0.62 : 1.1))
            .clip(true)
            .onAreaChange((_oldValue: Area, newValue: Area): void => {
                this.frameWidth = Number(newValue.width);
            })
            .onAppear((): void => this.restartAutoPlay())
            .gesture(
                PanGesture({ fingers: 1, direction: PanDirection.Horizontal })
                    .onActionStart((): void => {
                        if (!this.switching) {
                            this.stopAutoPlay();
                        }
                    })
                    .onActionUpdate((event: GestureEvent): void => {
                        if (!this.switching) {
                            const limit = Math.max(280, this.frameWidth);
                            this.dragOffset = Math.max(-limit, Math.min(limit, event.offsetX));
                        }
                    })
                    .onActionEnd((event: GestureEvent): void => {
                        if (this.switching) {
                            return;
                        }
                        const threshold = Math.max(52, this.frameWidth * 0.18);
                        if (this.dragOffset < -threshold || event.velocityX < -900) {
                            this.completeSwitch(1);
                        } else if (this.dragOffset > threshold || event.velocityX > 900) {
                            this.completeSwitch(-1);
                        } else {
                            this.restoreCurrentCard();
                        }
                    })
                    .onActionCancel((): void => this.restoreCurrentCard())
            )

            if (this.screenshots.length > 1) {
                Row({ space: 7 }) {
                    ForEach(this.screenshots, (_shot: ScreenshotInfo, index: number) => {
                        Row()
                            .width(index === this.currentIndex ? 22 : 7)
                            .height(7)
                            .borderRadius(4)
                            .backgroundColor(index === this.currentIndex ?
                                $r('app.color.diff_content') : $r('app.color.v3_chart_grid'))
                            .animation({ duration: 180, curve: Curve.EaseOut })
                            .onClick((): void => this.selectPage(index))
                            .accessibilityText(`切换到第${index + 1}张应用截图`)
                    }, (_shot: ScreenshotInfo, index: number) => `indicator-${index}`)
                }
                .justifyContent(FlexAlign.Center)
                .width('100%')
                .accessibilityText(`当前为第${this.currentIndex + 1}张，共${this.screenshots.length}张应用截图`)
            }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .accessibilityGroup(true)
        .accessibilityText('可自动播放和左右滑动的叠加应用截图')
    }
}


@Component
export struct AppDetailPage {
    @Consume('pageStack') private pageStack: NavPathStack;
    routeTarget: AppRouteTarget = {};
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private scroller: Scroller = new Scroller();
    private leftScroller: Scroller = new Scroller();
    private rightScroller: Scroller = new Scroller();
    private shareManager?: WebShareManager;
    private readonly shareOwnerId: number = WebShareManager.createOwnerId();
    private target: AppRouteTarget = {};
    @State private app: MarketApp | undefined = undefined;
    @State private metrics: AppMetric[] = [];
    @State private ratingHistory: AppRatingHistory[] = [];
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
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    @StorageLink('immersiveMaterialLevel') private immersiveMaterialLevel: number = HDS_MATERIAL_LEVEL_GENTLE;
    private active: boolean = false;
    private requestVersion: number = 0;
    private initialLoadTimer: number = -1;
    private restoreScrollTimer: number = -1;
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
        this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 6, (step: number): void => {
            this.animStep = step;
        });
    }

    private requiredStep(group: string): number {
        if (this.contentWidth >= 840) {
            if (group === 'identity' || group === 'description') return 1;
            if (group === 'information' || group === 'screenshots') return 2;
            if (group === 'downloadChart') return 3;
            return 4;
        }
        if (group === 'identity') return 1;
        if (group === 'information') return 2;
        if (group === 'description') return 3;
        if (group === 'screenshots') return 4;
        if (group === 'downloadChart') return 5;
        return 6;
    }

    aboutToAppear(): void {
        this.active = true;
        this.enterAnimationPending = true;
        this.animStep = 0;
        const fallbackTarget = peekDetailTarget();
        this.target = (this.routeTarget.appId || this.routeTarget.packageName) ? this.routeTarget : fallbackTarget;
        this.app = this.target.previewApp;
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
        try {
            const continuation = getContinuationState();
            setContinuationView(
                continuation.mainTab,
                scroller.currentOffset().yOffset,
                CONTINUATION_ROUTE_DETAIL,
                this.target,
                this.shareUrl(),
            );
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
            this.target = pendingTarget;
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
        if (continuation.routeName === CONTINUATION_ROUTE_DETAIL && continuation.scrollDistance > 0) {
            this.restoreScrollTimer = setTimeout((): void => {
                this.restoreScrollTimer = -1;
                if (!this.active) return;
                try {
                    const targetScroller = this.contentWidth >= 840 ? this.rightScroller : this.scroller;
                    targetScroller.scrollTo({
                        xOffset: 0,
                        yOffset: continuation.scrollDistance,
                        animation: { duration: 0 },
                    });
                } catch (error) {
                    console.warn('[Dashboard][pages/detail/AppDetailPage][WARN]',
                        `恢复滚动位置失败: ${JSON.stringify(error)}`);
                }
            }, 80);
        }
    }

    private request(force: boolean): Promise<ApiDataResult<BaseAPIResponse<AppDetailPayload>>> {
        if (this.target.appId) {
            return fetchAppById(this.target.appId, force);
        }
        if (this.target.packageName) {
            return fetchAppByPackage(this.target.packageName, force);
        }
        return Promise.reject(new Error('缺少应用标识'));
    }

    private load(force: boolean, background: boolean = false, showRefreshing: boolean = false): void {
        const version = ++this.requestVersion;
        if (showRefreshing) {
            this.refreshing = true;
        }
        if (!background) {
            this.loading = true;
            this.errorMessage = '';
        }
        this.request(force).then((result) => {
            if (!this.active || version !== this.requestVersion) return;
            if (!result.data.success || !result.data.data?.full_info) {
                throw new Error('未找到该应用');
            }
            this.app = result.data.data.full_info;
            this.fromCache = result.stale;
            this.startPageAnimationForEntry();
            this.syncShareData();
            if (this.app.pkg_name) {
                fetchAppMetrics(this.app.pkg_name, force).then((metricResult) => {
                    if (this.active && version === this.requestVersion && metricResult.data.success) {
                        this.metrics = metricResult.data.data ?? [];
                    }
                }).catch((error: Error) => console.warn('[Dashboard][pages/detail/AppDetailPage][WARN]', `指标加载失败: ${error.message}`));
                fetchAppRatingHistory(this.app.pkg_name, force).then((ratingResult) => {
                    if (this.active && version === this.requestVersion && ratingResult.data.success) {
                        this.ratingHistory = ratingResult.data.data ?? [];
                    }
                }).catch((error: Error) => console.warn('[Dashboard][pages/detail/AppDetailPage][WARN]', `评分趋势加载失败: ${error.message}`));
            }
            if (!force && !this.target.backgroundRefreshHandled) {
                if (this.backgroundRefreshTimer >= 0) clearTimeout(this.backgroundRefreshTimer);
                this.backgroundRefreshTimer = setTimeout((): void => {
                    this.backgroundRefreshTimer = -1;
                    if (!this.active || version !== this.requestVersion) return;
                    this.load(true, true);
                }, BACKGROUND_REFRESH_DELAY_MS);
            }
        }).catch((error: Error) => {
            if (this.active && version === this.requestVersion && !background) {
                this.errorMessage = `详情加载失败：${error.message}`;
            }
        }).finally(() => {
            if (!this.active || version !== this.requestVersion) return;
            this.loading = false;
            this.refreshing = false;
        });
    }

    private fields(): DetailField[] {
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
            { label: '最低 SDK', value: String(this.app.minsdk ?? '-') },
            { label: '目标 SDK', value: String(this.app.target_sdk ?? '-') },
            { label: '编译 SDK', value: String(this.app.compile_sdk_version ?? '-') },
            { label: '最低 Harmony API', value: String(this.app.min_hmos_api_level ?? '-') },
            { label: '下载量', value: formatDownloadCount(this.app.download_count) },
            { label: '评分', value: this.app.average_rating ? `${this.app.average_rating} / 5` : '-' },
            { label: '评分数量', value: formatCount(this.app.total_star_rating_count) },
            { label: '供应商', value: this.app.supplier || '-' },
            { label: '标签', value: this.app.tag_name || '-' },
            { label: '价格', value: String(this.app.price ?? '免费') },
            { label: '发行国家/地区', value: this.app.release_countries?.join('、') || '-' },
            { label: '备案主体', value: this.app.recordal_entity_name || this.app.recordal_entity_title || '-' },
            { label: '备案信息', value: this.app.app_recordal_info || '-' },
            { label: '上架时间', value: formatDateTime(this.app.listed_at) },
            { label: '数据更新', value: formatDateTime(this.app.updated_at) },
        ];
    }

    private screenshots(): ScreenshotInfo[] {
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

    private downloadPoints(): LineChartPoint[] {
        return this.metrics.slice().sort((left: AppMetric, right: AppMetric) =>
            new Date(left.created_at).getTime() - new Date(right.created_at).getTime()).map((metric: AppMetric) => ({
                label: formatDateTime(metric.created_at).split(' ')[0],
                value: Number(metric.download_count ?? 0),
                detail: `${formatDateTime(metric.created_at)} · 下载量 ${formatDownloadCount(metric.download_count)} · 版本 ${metric.version || '-'}`,
            } as LineChartPoint));
    }

    private ratingPoints(): LineChartPoint[] {
        return this.ratingHistory.slice().sort((left: AppRatingHistory, right: AppRatingHistory) =>
            new Date(left.report_date).getTime() - new Date(right.report_date).getTime()).map((rating: AppRatingHistory) => {
                const value = Number(rating.cumulative_avg_rating_high_prec ?? rating.cumulative_avg_rating_origin ?? 0);
                return {
                    label: rating.report_date,
                    value,
                    detail: `${rating.report_date} · 平均评分 ${value.toFixed(2)} · 累计 ${formatCount(rating.cumulative_total_count)} 条评分`,
                } as LineChartPoint;
            });
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
                .accessibilityText(`开发公司${this.app?.developer_name || '未知'}`)
        }
        .width('100%')
        .padding({ top: 18, bottom: 18, left: 12, right: 12 })
        .opacity(this.animStep >= this.requiredStep('identity') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('identity') ? 0 : 20 })
        .accessibilityGroup(true)
        .accessibilityText(`${this.app?.name || '未知应用'}的图标、名称和开发公司`)
    }

    @Builder
    private appActions(): void {
        Flex({ wrap: FlexWrap.Wrap }) {
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

            this.appActions()
        }
        .width('100%')
        .opacity(this.animStep >= this.requiredStep('information') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('information') ? 0 : 20 })
        .accessibilityGroup(true)
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
                .fontSize(14)
                .lineHeight(22)
                .fontColor($r('app.color.v3_text_primary'))
                .width('100%')
                .accessibilityText(this.app?.description || '暂无应用介绍')
            if (this.app?.new_features) {
                Divider().color($r('app.color.v3_chart_grid')).accessibilityText('内容分隔线')
                Text('新版特性')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary'))
                    .width('100%')
                    .accessibilityText('新版特性')
                Text(this.app.new_features)
                    .fontSize(14)
                    .lineHeight(22)
                    .fontColor($r('app.color.v3_text_primary'))
                    .width('100%')
                    .accessibilityText(this.app.new_features)
            }
        }
        .width('100%')
        .padding(18)
        .borderRadius(18)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .opacity(this.animStep >= this.requiredStep('description') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('description') ? 0 : 20 })
        .accessibilityGroup(true)
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
            ScreenshotCarousel({ screenshots: this.screenshots(), compact: this.contentWidth < 840 })
        }
        .width('100%')
        .padding(18)
        .borderRadius(18)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .opacity(this.animStep >= this.requiredStep('screenshots') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('screenshots') ? 0 : 20 })
        .accessibilityGroup(true)
        .accessibilityText('应用截图区域')
    }

    @Builder
    private downloadChart(): void {
        InteractiveLineChart({
            title: '下载量趋势',
            unit: '次',
            points: this.downloadPoints(),
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
            title: '评分趋势',
            unit: '分',
            points: this.ratingPoints(),
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
    private descriptionScreenshotsAndCharts(): void {
        Column({ space: 14 }) {
            this.appDescription()
            if (this.screenshots().length > 0) {
                this.appScreenshots()
            }
            this.downloadChart()
            this.ratingChart()
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
        .accessibilityGroup(true)
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
            .accessibilityGroup(true)
            .accessibilityText('左右两栏可分别滚动的应用详情')
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
    }

    aboutToDisappear(): void {
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
                        .accessibilityGroup(true)
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
                    materialType: HDS_MATERIAL_TYPE_IMMERSIVE,
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
