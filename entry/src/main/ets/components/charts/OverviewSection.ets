import { RequestScope } from '../../services/cache/CachedRequest';
import { formatSdkLabel } from '../../utils/format/format';
import { compareSdkLabels, sdkDistributionData, sdkHistoryValues } from '../../domain/sdk/SdkData';
import { DistributionPanel } from './DistributionPanel';
import type { DistributionChart } from './DistributionPanel';
import { ApiHistoryChart } from './ApiHistoryChart';
import type { HistoryPoint } from './ApiHistoryChart';
import { OVERVIEW_COLLAPSED_SDK_COUNT, MIN_PRESS_FEEDBACK_MS } from '../../config/constants';
import { hdsEffect } from '@kit.UIDesignKit';
import { getContinuationState, setContinuationOverviewState } from '../../state/appState';
import { fetchApiHistory, fetchRatingDistribution, fetchSdkDistribution } from '../../services/api/MarketApi';
import { pressLightFieldFilter, pressVisualEffect } from '../../ui/theme/visualEffects';
import { vibration } from '../../utils/device/vibration';
import type { BaseAPIResponse, ChartViewportState, RatingDistribution } from '../../models/types';
import { DownloadGrowthSection } from './DownloadGrowthSection';
import { chartLegendColumns } from '../../ui/charts/chartLayout';

@Component
export struct OverviewSection {
    @Prop @Watch('onRefreshVersionChanged') refreshVersion: number = 0;
    @Prop @Watch('onActiveChanged') active: boolean = true;
    private requestScope: RequestScope = new RequestScope();
    private alive: boolean = false;
    private loadToken: number = 0;
    private reloadTimer: number = -1;
    private onActiveChanged(): void {
        if (!this.active) {
            this.requestScope.cancel(); this.loadToken++; this.loading = false; this.pendingLoads = 0;
            this.reloadAfterCurrent = false; this.endControlPress(true);
            if (this.reloadTimer >= 0) clearTimeout(this.reloadTimer);
            return;
        }
        if (this.requestScope.cancelled) this.requestScope = new RequestScope();
        if (this.active && this.alive && !this.loaded) this.load(false);
    }
    @Prop enterStep: number = 0;
    onRefreshCompleted?: () => void;
    @State private loading: boolean = false;
    @State private loaded: boolean = false;
    @State private fromCache: boolean = false;
    @State private ratingChart: DistributionChart = { title: '应用评分分布', labels: [], values: [], total: 1 };
    @State private minSdkChart: DistributionChart = { title: '最低 SDK 分布', labels: [], values: [], total: 1 };
    @State private targetSdkChart: DistributionChart = { title: '目标 SDK 分布', labels: [], values: [], total: 1 };
    @State private history: HistoryPoint[] = [];
    @State private apiKeys: string[] = [];
    @State private contentWidth: number = 0;
    @State private sdkLegendWidth: number = 0;
    @State private sdkExpanded: boolean = false;
    @State private targetSdkExpanded: boolean = false;
    @State private minSdkExpanded: boolean = false;
    @State private selectedSdkLabel: string = '';
    @State private sdkOtherHidden: boolean = false;
    @State private apiHistoryViewport: ChartViewportState = { zoom: 1, panRatio: 0 };
    @State private pressedControl: string = '';
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    private pendingLoads: number = 0;
    private reloadAfterCurrent: boolean = false;
    private restoredContinuationUi: boolean = false;
    private controlPressToken: number = 0;
    private controlPressStartedAt: number = 0;
    private controlPressTimer: number = -1;

    private beginControlPress(key: string): void {
        const token = ++this.controlPressToken;
        this.pressedControl = key;
        this.controlPressStartedAt = Date.now();
        if (this.controlPressTimer >= 0) clearTimeout(this.controlPressTimer);
        this.controlPressTimer = setTimeout((): void => {
            this.controlPressTimer = -1;
            if (this.controlPressToken === token && this.pressedControl === key) {
                this.pressedControl = '';
            }
        }, 800);
    }

    private endControlPress(immediate: boolean = false): void {
        if (this.controlPressTimer >= 0) {
            clearTimeout(this.controlPressTimer);
            this.controlPressTimer = -1;
        }
        const key = this.pressedControl;
        const token = this.controlPressToken;
        const remaining = immediate ? 0 :
            Math.max(0, MIN_PRESS_FEEDBACK_MS - (Date.now() - this.controlPressStartedAt));
        if (key.length === 0 || remaining <= 0) {
            this.controlPressToken++;
            this.pressedControl = '';
            return;
        }
        this.controlPressTimer = setTimeout((): void => {
            this.controlPressTimer = -1;
            if (this.controlPressToken === token && this.pressedControl === key) {
                this.controlPressToken++;
                this.pressedControl = '';
            }
        }, remaining);
    }

    aboutToDisappear(): void {
        this.requestScope.cancel();
        this.alive = false; this.loadToken++;
        if (this.reloadTimer >= 0) clearTimeout(this.reloadTimer);
        this.loading = false; this.reloadAfterCurrent = false;
        this.endControlPress(true);
    }

    aboutToAppear(): void {
        this.alive = true;
        if (this.requestScope.cancelled) this.requestScope = new RequestScope();
        if (this.restoredContinuationUi) return;
        this.restoredContinuationUi = true;
        const state = getContinuationState().overviewState;
        this.sdkExpanded = state.sdkExpanded === true;
        this.targetSdkExpanded = state.targetSdkExpanded === true;
        this.minSdkExpanded = state.minSdkExpanded === true;
        this.sdkOtherHidden = state.sdkOtherHidden === true;
        this.apiHistoryViewport = state.apiHistoryViewport ?? { zoom: 1, panRatio: 0 };
    }

    private syncContinuationUi(): void {
        setContinuationOverviewState({
            sdkExpanded: this.sdkExpanded,
            targetSdkExpanded: this.targetSdkExpanded,
            minSdkExpanded: this.minSdkExpanded,
            sdkOtherHidden: this.sdkOtherHidden,
            apiHistoryViewport: this.apiHistoryViewport,
        });
    }

    private updateApiHistoryViewport(viewport: ChartViewportState): void {
        this.apiHistoryViewport = viewport;
        this.syncContinuationUi();
    }

    private onRefreshVersionChanged(): void { if (this.refreshVersion > 0) this.load(true); }
    private distribution(title: string, source: number[][]): DistributionChart {
        const data = sdkDistributionData(source);
        return { title, labels: data.labels, values: data.values, total: data.total };
    }
    private sdkColors(): Resource[] {
        return [
            $r('app.color.diff_content'), $r('app.color.v3_accent_cyan'), $r('app.color.v3_accent_green'),
            $r('app.color.v3_accent_orange'), $r('app.color.v3_accent_red'), $r('app.color.v3_accent_purple'),
            $r('app.color.v3_chart_series_7'), $r('app.color.v3_chart_series_8'),
            $r('app.color.v3_chart_series_9'), $r('app.color.v3_chart_series_10'),
            $r('app.color.v3_chart_series_11'), $r('app.color.v3_chart_series_12'),
            $r('app.color.v3_chart_series_13'), $r('app.color.v3_chart_series_14'),
            $r('app.color.v3_chart_series_15'), $r('app.color.v3_chart_series_16'),
        ];
    }
    private sdkLabels(): string[] {
        const labels: Record<string, boolean> = {};
        for (const label of this.targetSdkChart.labels) labels[label] = true;
        for (const label of this.minSdkChart.labels) labels[label] = true;
        return Object.keys(labels).sort(compareSdkLabels);
    }
    private visibleSdkLabels(): string[] {
        const labels = this.sdkLabels();
        if (this.sdkExpanded || labels.length <= OVERVIEW_COLLAPSED_SDK_COUNT) return labels;
        return labels.slice(0, OVERVIEW_COLLAPSED_SDK_COUNT).concat(['其他']);
    }
    private sdkValue(chart: DistributionChart, label: string): number {
        if (label !== '其他') {
            const index = chart.labels.indexOf(label);
            return index >= 0 ? chart.values[index] : 0;
        }
        const visible = this.sdkLabels().slice(0, OVERVIEW_COLLAPSED_SDK_COUNT);
        let total = 0;
        for (let index = 0; index < chart.labels.length; index++) {
            if (visible.indexOf(chart.labels[index]) < 0) total += chart.values[index] ?? 0;
        }
        return total;
    }
    private sdkPercent(chart: DistributionChart, label: string): string {
        if (label !== '其他' && chart.labels.indexOf(label) < 0) return '—';
        const percent = chart.total > 0 ? this.sdkValue(chart, label) / chart.total * 100 : 0;
        return `${percent.toFixed(1)}%`;
    }
    private activeSdkLabel(): string {
        const labels = this.visibleSdkLabels();
        return labels.indexOf(this.selectedSdkLabel) >= 0 ? this.selectedSdkLabel : (labels[0] ?? '');
    }
    private selectSdk(label: string): void {
        if (label === '其他') {
            this.expandSdk();
            return;
        }
        if (label !== this.activeSdkLabel() && this.vibrationLevel > 0) vibration.dotVibration();
        this.selectedSdkLabel = label;
    }
    private expandSdk(): void {
        if (this.sdkExpanded) return;
        if (this.vibrationLevel > 0) vibration.dotVibration();
        this.getUIContext().animateTo({ duration: 360, curve: Curve.Friction }, (): void => {
            this.sdkExpanded = true;
            this.targetSdkExpanded = true;
            this.minSdkExpanded = true;
            this.selectedSdkLabel = this.sdkLabels()[0] ?? '';
            this.syncContinuationUi();
        });
    }
    private collapseSdk(): void {
        if (!this.sdkExpanded) return;
        if (this.vibrationLevel > 0) vibration.dotVibration();
        this.getUIContext().animateTo({ duration: 300, curve: Curve.Friction }, (): void => {
            const collapsedLabels = this.sdkLabels().slice(0, OVERVIEW_COLLAPSED_SDK_COUNT);
            if (collapsedLabels.indexOf(this.selectedSdkLabel) < 0) {
                this.selectedSdkLabel = collapsedLabels[0] ?? '';
            }
            this.sdkExpanded = false;
            this.targetSdkExpanded = false;
            this.minSdkExpanded = false;
            this.syncContinuationUi();
        });
    }
    private expandTargetSdk(): void {
        if (this.targetSdkExpanded) return;
        if (this.vibrationLevel > 0) vibration.dotVibration();
        this.getUIContext().animateTo({ duration: 360, curve: Curve.Friction }, (): void => {
            this.targetSdkExpanded = true;
            this.sdkExpanded = true;
            this.syncContinuationUi();
        });
    }
    private collapseTargetSdk(): void {
        if (!this.targetSdkExpanded) return;
        if (this.vibrationLevel > 0) vibration.dotVibration();
        this.getUIContext().animateTo({ duration: 300, curve: Curve.Friction }, (): void => {
            this.targetSdkExpanded = false;
            this.sdkExpanded = this.minSdkExpanded;
            this.syncContinuationUi();
        });
    }
    private expandMinSdk(): void {
        if (this.minSdkExpanded) return;
        if (this.vibrationLevel > 0) vibration.dotVibration();
        this.getUIContext().animateTo({ duration: 360, curve: Curve.Friction }, (): void => {
            this.minSdkExpanded = true;
            this.sdkExpanded = true;
            this.syncContinuationUi();
        });
    }
    private collapseMinSdk(): void {
        if (!this.minSdkExpanded) return;
        if (this.vibrationLevel > 0) vibration.dotVibration();
        this.getUIContext().animateTo({ duration: 300, curve: Curve.Friction }, (): void => {
            this.minSdkExpanded = false;
            this.sdkExpanded = this.targetSdkExpanded;
            this.syncContinuationUi();
        });
    }

    @Builder
    private sdkLegend(): void {
        if (this.sdkLabels().length > 0) {
            Column() {
                GridRow({ columns: chartLegendColumns(this.sdkLegendWidth, 150, 4),
                    gutter: { x: 5, y: 5 } }) {
                    ForEach(this.visibleSdkLabels(), (label: string, index: number) => {
                        GridCol({ span: 1 }) {
                            Row({ space: 5 }) {
                                Row().width(8).height(8).borderRadius(4)
                                    .flexShrink(0)
                                    .backgroundColor(label === '其他' ? $r('app.color.nd_text_sub') :
                                        this.sdkColors()[this.sdkLabels().indexOf(label) % this.sdkColors().length])
                                Column({ space: 1 }) {
                                    if (label === '其他') {
                                        Text('其他（点击展开）').fontSize(13).fontWeight(FontWeight.Medium)
                                            .fontColor($r('app.color.v3_text_primary')).width('100%')
                                            .wordBreak(WordBreak.BREAK_ALL)
                                    } else {
                                        Text(formatSdkLabel(label)).fontSize(13).fontWeight(FontWeight.Medium)
                                            .fontColor($r('app.color.v3_text_primary')).width('100%')
                                            .wordBreak(WordBreak.BREAK_ALL)
                                    }
                                    Text(`目标 ${this.sdkPercent(this.targetSdkChart, label)} · 最低 ${this.sdkPercent(this.minSdkChart, label)}`)
                                        .fontSize(10).fontColor($r('app.color.v3_text_secondary')).width('100%')
                                        .wordBreak(WordBreak.BREAK_ALL)
                                }
                                .layoutWeight(1).constraintSize({ minWidth: 0 })
                                .alignItems(HorizontalAlign.Start)
                            }
                            .width('100%')
                            .padding({ left: 6, right: 6, top: 5, bottom: 5 })
                            .borderRadius(8)
                            .border({ width: 1, color: $r('app.color.nd_card_border') })
                            .scale({ x: this.pressedControl === label ? 0.97 : 1,
                                y: this.pressedControl === label ? 0.97 : 1 })
                            .animation({ duration: 120, curve: Curve.EaseOut })
                            .backgroundColor(label === this.activeSdkLabel() ?
                                $r('app.color.v3_surface_alt') : Color.Transparent)
                            .visualEffect(pressVisualEffect(
                                this.pressedControl === label,
                                hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                            .compositingFilter(pressLightFieldFilter(this.pressedControl === label))
                            .onTouch((event: TouchEvent): void => {
                                if (event.type === TouchType.Down) this.beginControlPress(label);
                                else if (event.type === TouchType.Up) {
                                    this.endControlPress();
                                } else if (event.type === TouchType.Cancel) {
                                    this.endControlPress(true);
                                }
                            })
                            .onClick(() => {
                                this.endControlPress();
                                this.selectSdk(label);
                            })
                            .transition(TransitionEffect.OPACITY.combine(
                                TransitionEffect.scale({ x: 0.94, y: 0.94 })))
                            .accessibilityText(label === '其他' ?
                                '其他SDK，点击展开全部SDK版本' :
                                `${formatSdkLabel(label)}，目标占比${this.sdkPercent(this.targetSdkChart, label)}，最低占比${this.sdkPercent(this.minSdkChart, label)}`)
                        }
                    }, (label: string) => `sdk-shared-${label}`)
                }
                .width('100%')
                .onAreaChange((_oldArea: Area, area: Area): void => { this.sdkLegendWidth = Number(area.width); })
                .animation({ duration: 360, curve: Curve.Friction })
            }
            .width('100%')
            .accessibilityText('目标SDK与最低SDK共享图例')
        }
    }

    @Builder
    private combinedSdkPanel(): void {
        Column({ space: 8 }) {
            Row() {
                Text('应用SDK分布')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary'))
                    .layoutWeight(1)
                    .accessibilityText('应用SDK分布')
                if (this.sdkLabels().length > OVERVIEW_COLLAPSED_SDK_COUNT) {
                    Text(this.sdkExpanded ? '收起' : '展开全部')
                        .fontSize(13)
                        .fontColor($r('app.color.diff_content'))
                        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
                        .borderRadius(8)
                        .scale({ x: this.pressedControl === 'sdk-expand' ? 0.94 : 1,
                            y: this.pressedControl === 'sdk-expand' ? 0.94 : 1 })
                        .animation({ duration: 120, curve: Curve.EaseOut })
                        .visualEffect(pressVisualEffect(this.pressedControl === 'sdk-expand',
                            hdsEffect.PointLightIlluminatedType.BORDER, 5, 84))
                        .compositingFilter(pressLightFieldFilter(this.pressedControl === 'sdk-expand'))
                        .onTouch((event: TouchEvent): void => {
                            if (event.type === TouchType.Down) this.beginControlPress('sdk-expand');
                            else if (event.type === TouchType.Up) {
                                this.endControlPress();
                            } else if (event.type === TouchType.Cancel) {
                                this.endControlPress(true);
                            }
                        })
                        .onClick(() => {
                            this.endControlPress();
                            if (this.sdkExpanded) this.collapseSdk(); else this.expandSdk();
                        })
                        .accessibilityText(this.sdkExpanded ? '收起全部SDK版本' : '展开全部SDK版本')
                }
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            Row({ space: 12 }) {
                Column() {
                    DistributionPanel({ active: this.active, chart: this.targetSdkChart, showLegend: false, collapsible: true,
                        expanded: this.sdkExpanded, colorLabels: this.sdkLabels(), embedded: true,
                        showTitle: false, chartCaption: '目标 SDK',
                        selectedLabel: this.activeSdkLabel(),
                        onSelect: (label: string): void => this.selectSdk(label),
                        onExpand: (): void => this.expandSdk() })
                }
                .layoutWeight(1)
                Column() {
                    DistributionPanel({ active: this.active, chart: this.minSdkChart, showLegend: false, collapsible: true,
                        expanded: this.sdkExpanded, colorLabels: this.sdkLabels(), embedded: true,
                        showTitle: false, chartCaption: '最低 SDK',
                        selectedLabel: this.activeSdkLabel(),
                        onSelect: (label: string): void => this.selectSdk(label),
                        onExpand: (): void => this.expandSdk() })
                }
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            this.sdkLegend()
        }
        .width('100%')
        .padding(14)
        .borderRadius(18)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .accessibilityText('目标SDK与最低SDK共用图例组合图表')
    }

    private finish(token: number): void {
        if (!this.alive || token !== this.loadToken) return;
        this.pendingLoads--;
        if (this.pendingLoads <= 0) {
            this.loading = false;
            this.loaded = true;
            if (this.reloadAfterCurrent) {
                this.reloadAfterCurrent = false;
                this.reloadTimer = setTimeout((): void => { this.reloadTimer = -1; if (this.alive) this.load(true); }, 0);
            } else if (this.onRefreshCompleted) {
                this.onRefreshCompleted();
            }
        }
    }
    private failed(name: string, error: Error): void {
        console.error('[Dashboard][component/charts/OverviewSection][ERROR]', `${name}加载失败: ${error.message}`);
    }
    private load(force: boolean): void {
        if (!this.alive || !this.active) return;
        if (this.loading) {
            this.reloadAfterCurrent = this.reloadAfterCurrent || force;
            return;
        }
        this.loading = true;
        this.fromCache = false;
        const token = ++this.loadToken;
        this.pendingLoads = 4;
        fetchRatingDistribution(force, this.requestScope).then((result) => {
            if (!this.alive || token !== this.loadToken) return;
            const response = result.data as BaseAPIResponse<RatingDistribution>;
            if (!response.success || !response.data) throw new Error('评分接口未返回有效数据');
            const rating = response.data;
            const values = [rating.star_5, rating.star_4, rating.star_3, rating.star_2, rating.star_1];
            this.ratingChart = { title: '应用评分分布', labels: ['5 星', '4 星', '3 星', '2 星', '1 星与无评分'],
                values, total: values.reduce((sum: number, value: number) => sum + value, 0) };
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => this.failed('评分分布', error)).finally(() => this.finish(token));
        fetchSdkDistribution('min_sdk', force, this.requestScope).then((result) => {
            if (!this.alive || token !== this.loadToken) return;
            if (!result.data.success || !result.data.data) throw new Error('最低 SDK 接口未返回有效数据');
            this.minSdkChart = this.distribution('最低 SDK 分布', result.data.data as number[][]);
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => this.failed('最低 SDK 分布', error)).finally(() => this.finish(token));
        fetchSdkDistribution('target_sdk', force, this.requestScope).then((result) => {
            if (!this.alive || token !== this.loadToken) return;
            if (!result.data.success || !result.data.data) throw new Error('目标 SDK 接口未返回有效数据');
            this.targetSdkChart = this.distribution('目标 SDK 分布', result.data.data as number[][]);
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => this.failed('目标 SDK 分布', error)).finally(() => this.finish(token));
        fetchApiHistory(force, this.requestScope).then((result) => {
            if (!this.alive || token !== this.loadToken) return;
            if (!result.data.success || !result.data.data) throw new Error('API 历史接口未返回有效数据');
            const next: HistoryPoint[] = [];
            for (const raw of result.data.data as object[]) {
                const tuple = raw as object[];
                if (tuple.length >= 2) next.push({ date: String(tuple[0]),
                    values: sdkHistoryValues(tuple[1] as Record<string, number>) });
            }
            this.history = next;
            const discovered: Record<string, boolean> = {};
            for (const historyPoint of next) {
                for (const key of Object.keys(historyPoint.values)) discovered[key] = true;
            }
            this.apiKeys = Object.keys(discovered).sort(compareSdkLabels);
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => this.failed('API 版本历史', error)).finally(() => this.finish(token));
    }

    build() {
        Column({ space: 14 }) {
            if (this.fromCache) {
                Text('网络不可用，当前图表来自本地离线缓存').fontSize(13)
                    .fontColor($r('app.color.v3_text_primary')).padding(12).width('100%')
                    .borderRadius(12).backgroundColor($r('app.color.v3_warning_bg'))
            }
            if (this.loading && !this.loaded) {
                LoadingProgress().width(34).height(34).color($r('app.color.diff_content')).margin(50)
                    .accessibilityText('概况图表加载中')
            }
            DownloadGrowthSection()
            if (this.contentWidth >= 840) {
                Row({ space: 12 }) {
                    Column() {
                        this.combinedSdkPanel()
                    }.layoutWeight(2)
                    Column() {
                        DistributionPanel({ active: this.active, chart: this.ratingChart, reserveCaptionSpace: true })
                    }.layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
                .opacity(this.enterStep >= 2 ? 1 : 0)
                .translate({ y: this.enterStep >= 2 ? 0 : 20 })
                .accessibilityText('共用图例的SDK组合图表与评分分布图表')
            } else if (this.contentWidth >= 600) {
                Column({ space: 12 }) {
                    Column() {
                        this.combinedSdkPanel()
                    }
                    .width('100%')
                    .opacity(this.enterStep >= 2 ? 1 : 0)
                    .translate({ y: this.enterStep >= 2 ? 0 : 20 })
                    Column() {
                        DistributionPanel({ active: this.active, chart: this.ratingChart, horizontalLegend: true })
                    }
                    .width('100%')
                    .opacity(this.enterStep >= 3 ? 1 : 0)
                    .translate({ y: this.enterStep >= 3 ? 0 : 20 })
                }
                .width('100%')
                .accessibilityText('共用图例的双列SDK分布和横向评分分布')
            } else {
                Column({ space: 12 }) {
                    Column() {
                        DistributionPanel({ active: this.active, chart: this.targetSdkChart, collapsible: true,
                            expanded: this.targetSdkExpanded, colorLabels: this.sdkLabels(), showExpandAction: true,
                            onExpand: (): void => this.expandTargetSdk(),
                            onCollapse: (): void => this.collapseTargetSdk() })
                    }
                    .width('100%')
                    .opacity(this.enterStep >= 2 ? 1 : 0)
                    .translate({ y: this.enterStep >= 2 ? 0 : 20 })
                    Column() {
                        DistributionPanel({ active: this.active, chart: this.minSdkChart, collapsible: true,
                            expanded: this.minSdkExpanded, colorLabels: this.sdkLabels(), showExpandAction: true,
                            onExpand: (): void => this.expandMinSdk(),
                            onCollapse: (): void => this.collapseMinSdk() })
                    }
                    .width('100%')
                    .opacity(this.enterStep >= 3 ? 1 : 0)
                    .translate({ y: this.enterStep >= 3 ? 0 : 20 })
                    Column() {
                        DistributionPanel({ active: this.active, chart: this.ratingChart })
                    }
                    .width('100%')
                    .opacity(this.enterStep >= 4 ? 1 : 0)
                    .translate({ y: this.enterStep >= 4 ? 0 : 20 })
                }
                .width('100%')
                .accessibilityText('各自使用独立图例的目标SDK、最低SDK与评分分布图表')
            }
            Column() {
                ApiHistoryChart({
                    active: this.active,                    history: this.history,
                    apiKeys: this.apiKeys,
                    viewport: this.apiHistoryViewport,
                    onViewportChange: (viewport: ChartViewportState): void => this.updateApiHistoryViewport(viewport),
                })
            }
            .width('100%')
            .opacity(this.enterStep >= (this.contentWidth >= 840 ? 3 : this.contentWidth >= 600 ? 4 : 5) ? 1 : 0)
            .translate({
                y: this.enterStep >= (this.contentWidth >= 840 ? 3 : this.contentWidth >= 600 ? 4 : 5) ? 0 : 20,
            })
        }
        .width('100%')
        .onAreaChange((_oldArea: Area, area: Area): void => {
            this.contentWidth = Number(area.width);
        })
        .onAppear(() => { if (this.active && !this.loaded) this.load(false); })
        .accessibilityText('概况页面')
    }
}
