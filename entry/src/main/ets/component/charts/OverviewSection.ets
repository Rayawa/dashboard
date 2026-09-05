import { common } from '@kit.AbilityKit';
import { hdsEffect } from '@kit.UIDesignKit';
import { getContinuationState, setContinuationOverviewState } from '../../common/appState';
import { fetchApiHistory, fetchRatingDistribution, fetchSdkDistribution } from '../../common/MarketApi';
import { formatCount } from '../../common/format';
import { vibration } from '../../common/vibration';
import type { BaseAPIResponse, ChartViewportState, RatingDistribution } from '../../common/types';
import { InteractiveLineChart } from './InteractiveLineChart';
import type { LineChartPoint, LineChartSeries } from './InteractiveLineChart';

interface DistributionChart { title: string; labels: string[]; values: number[]; total: number; }
interface HistoryPoint { date: string; values: Record<string, number>; }
const COLLAPSED_SDK_COUNT: number = 7;

@Component
struct DistributionPanel {
    @Prop @Watch('onChartChanged') chart: DistributionChart = { title: '', labels: [], values: [], total: 1 };
    @Prop horizontalLegend: boolean = false;
    @Prop showLegend: boolean = true;
    @Prop collapsible: boolean = false;
    @Prop @Watch('onDisplayChanged') expanded: boolean = false;
    @Prop colorLabels: string[] = [];
    @Prop @Watch('onSelectedLabelChanged') selectedLabel: string = '';
    @Prop embedded: boolean = false;
    @Prop showTitle: boolean = true;
    @Prop showExpandAction: boolean = false;
    @Prop chartCaption: string = '';
    @Prop reserveCaptionSpace: boolean = false;
    onExpand?: () => void;
    onCollapse?: () => void;
    onSelect?: (label: string) => void;
    @State private selected: number = 0;
    @State private canvasSize: number = 220;
    @State private pressed: boolean = false;
    @State private pressedControl: string = '';
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    private settings: RenderingContextSettings = new RenderingContextSettings(true);
    private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
    private canvasReady: boolean = false;
    private drawProgress: number = 1;
    private detailProgress: number = 1;
    private animationToken: number = 0;

    private onChartChanged(): void {
        this.selected = 0;
        setTimeout((): void => this.animatePie(), 0);
    }
    private onDisplayChanged(): void {
        this.selected = 0;
        if (this.expanded) {
            setTimeout((): void => this.animateOtherExpansion(), 0);
        } else {
            setTimeout((): void => this.animateOtherCollapse(), 0);
        }
    }
    private onSelectedLabelChanged(): void {
        setTimeout((): void => this.draw(), 0);
    }
    private animatePie(): void {
        if (!this.canvasReady || this.chart.total <= 0) {
            this.draw();
            return;
        }
        const token = ++this.animationToken;
        const startedAt = Date.now();
        this.drawProgress = 0;
        this.detailProgress = this.expanded ? 1 : 0;
        const tick = (): void => {
            if (token !== this.animationToken) return;
            const elapsed = Math.min(1, (Date.now() - startedAt) / 700);
            this.drawProgress = 1 - Math.pow(1 - elapsed, 3);
            this.draw();
            if (elapsed < 1) setTimeout(tick, 16);
        };
        tick();
    }
    private animateOtherExpansion(): void {
        this.drawProgress = 1;
        if (!this.canvasReady || !this.hasOverflow()) {
            this.detailProgress = 1;
            this.draw();
            return;
        }
        const token = ++this.animationToken;
        const startedAt = Date.now();
        this.detailProgress = 0;
        const tick = (): void => {
            if (token !== this.animationToken) return;
            const elapsed = Math.min(1, (Date.now() - startedAt) / 520);
            this.detailProgress = 1 - Math.pow(1 - elapsed, 3);
            this.draw();
            if (elapsed < 1) setTimeout(tick, 16);
        };
        tick();
    }
    private animateOtherCollapse(): void {
        this.drawProgress = 1;
        if (!this.canvasReady || !this.hasOverflow()) {
            this.detailProgress = 0;
            this.draw();
            return;
        }
        const token = ++this.animationToken;
        const startedAt = Date.now();
        this.detailProgress = 1;
        const tick = (): void => {
            if (token !== this.animationToken) return;
            const elapsed = Math.min(1, (Date.now() - startedAt) / 420);
            this.detailProgress = Math.pow(1 - elapsed, 3);
            this.draw();
            if (elapsed < 1) setTimeout(tick, 16);
        };
        tick();
    }
    private colors(): Resource[] {
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
    private hasOverflow(): boolean {
        const labelCount = this.onSelect && this.colorLabels.length > 0 ?
            this.colorLabels.length : this.chart.labels.length;
        return this.collapsible && labelCount > COLLAPSED_SDK_COUNT;
    }
    private toggleExpansion(): void {
        if (this.expanded) {
            if (this.onCollapse) this.onCollapse();
        } else if (this.onExpand) {
            this.onExpand();
        }
    }
    private usesSharedLabels(): boolean {
        return this.onSelect !== undefined && this.colorLabels.length > 0;
    }
    private sourceLabels(): string[] {
        return this.usesSharedLabels() ? this.colorLabels : this.chart.labels;
    }
    private displayLabels(): string[] {
        const labels = this.sourceLabels();
        if (!this.hasOverflow() || this.expanded) return labels;
        return labels.slice(0, COLLAPSED_SDK_COUNT).concat(['其他']);
    }
    private displayValues(): number[] {
        const collapsedLabels = this.sourceLabels().slice(0, COLLAPSED_SDK_COUNT);
        return this.displayLabels().map((label: string): number => {
            if (label !== '其他') {
                const index = this.chart.labels.indexOf(label);
                return index >= 0 ? (this.chart.values[index] ?? 0) : 0;
            }
            let total = 0;
            for (let index = 0; index < this.chart.labels.length; index++) {
                if (collapsedLabels.indexOf(this.chart.labels[index]) < 0) total += this.chart.values[index] ?? 0;
            }
            return total;
        });
    }
    private expandedValues(): number[] {
        return this.sourceLabels().map((label: string): number => {
            const index = this.chart.labels.indexOf(label);
            return index >= 0 ? (this.chart.values[index] ?? 0) : 0;
        });
    }
    private visibleValues(): number[] {
        return this.displayValues();
    }
    private visibleTotal(): number {
        return this.visibleValues().reduce((sum: number, value: number) => sum + value, 0);
    }
    private expandFromOther(): void {
        if (this.expanded || !this.onExpand) return;
        this.selected = 0;
        this.onExpand();
    }
    private colorAt(index: number): Resource {
        const colors = this.colors();
        const label = this.displayLabels()[index] ?? '';
        if (label === '其他') return $r('app.color.nd_text_sub');
        const sharedIndex = this.colorLabels.indexOf(label);
        return colors[(sharedIndex >= 0 ? sharedIndex : index) % colors.length];
    }
    private expandedColorAt(index: number): Resource {
        const colors = this.colors();
        const label = this.sourceLabels()[index] ?? '';
        const sharedIndex = this.colorLabels.indexOf(label);
        return colors[(sharedIndex >= 0 ? sharedIndex : index) % colors.length];
    }
    private selectedIndex(): number {
        if (this.onSelect && this.selectedLabel.length > 0) {
            return this.displayLabels().indexOf(this.selectedLabel);
        }
        return Math.min(this.selected, this.displayLabels().length - 1);
    }
    private selectedText(): string {
        const labels = this.displayLabels();
        const values = this.displayValues();
        if (labels.length === 0) return '暂无数据';
        const index = this.selectedIndex();
        if (index < 0) return '未选择当前图表中的版本';
        const value = values[index] ?? 0;
        const percent = this.chart.total > 0 ? value / this.chart.total * 100 : 0;
        return `${labels[index]}：${formatCount(value)}，${percent.toFixed(1)}%`;
    }

    private legendText(index: number): string {
        const value = this.displayValues()[index] ?? 0;
        const percent = this.chart.total > 0 ? value / this.chart.total * 100 : 0;
        return `${formatCount(value)} · ${percent.toFixed(1)}%`;
    }

    private resolvedColor(resource: Resource): number {
        const host = this.getUIContext().getHostContext() as common.UIAbilityContext;
        try {
            return host.resourceManager.getColorSync(resource.id);
        } catch (error) {
            console.warn('[Dashboard][component/charts/OverviewSection][WARN]',
                `饼图颜色读取失败: ${JSON.stringify(error)}`);
            return 0xFF1E6FCD;
        }
    }

    private drawSector(center: number, radius: number, startAngle: number, endAngle: number,
        color: Resource, surfaceColor: number, highlighted: boolean): void {
        if (endAngle <= startAngle) return;
        this.context.beginPath();
        this.context.moveTo(center, center);
        this.context.arc(center, center, radius, startAngle, endAngle);
        this.context.closePath();
        this.context.fillStyle = this.resolvedColor(color);
        this.context.fill();
        this.context.strokeStyle = surfaceColor;
        this.context.lineWidth = 2;
        this.context.stroke();
        if (highlighted) {
            this.context.beginPath();
            this.context.arc(center, center, radius + 4, startAngle, endAngle);
            this.context.strokeStyle = this.resolvedColor(color);
            this.context.lineWidth = 4;
            this.context.stroke();
        }
    }

    private draw(): void {
        const size = this.canvasSize;
        this.context.clearRect(0, 0, size, size);
        const values = this.visibleValues();
        const visibleTotal = this.visibleTotal();
        if (visibleTotal <= 0 || values.length === 0) return;
        const center = size / 2;
        const radius = Math.max(20, center - 12);
        let startAngle = -Math.PI / 2;
        const surfaceColor = this.resolvedColor($r('app.color.v3_surface'));
        const animatingDetail = this.hasOverflow() &&
            ((this.expanded && this.detailProgress < 1) || (!this.expanded && this.detailProgress > 0));
        if (animatingDetail) {
            const detailValues = this.expandedValues();
            const detailTotal = detailValues.reduce((sum: number, value: number) => sum + value, 0);
            if (detailTotal <= 0) return;
            for (let index = 0; index < Math.min(COLLAPSED_SDK_COUNT, detailValues.length); index++) {
                if (detailValues[index] <= 0) continue;
                const endAngle = startAngle + Math.PI * 2 * detailValues[index] / detailTotal;
                this.drawSector(center, radius, startAngle, endAngle, this.expandedColorAt(index), surfaceColor,
                    index === this.selectedIndex());
                startAngle = endAngle;
            }
            let tailTotal = 0;
            for (let index = COLLAPSED_SDK_COUNT; index < detailValues.length; index++) {
                tailTotal += Math.max(0, detailValues[index]);
            }
            const tailStartAngle = startAngle;
            const tailEndAngle = tailStartAngle + Math.PI * 2 * tailTotal / detailTotal;
            this.drawSector(center, radius, tailStartAngle, tailEndAngle, $r('app.color.nd_text_sub'),
                surfaceColor, false);
            const revealEndAngle = tailStartAngle + (tailEndAngle - tailStartAngle) * this.detailProgress;
            for (let index = COLLAPSED_SDK_COUNT; index < detailValues.length; index++) {
                if (detailValues[index] <= 0) continue;
                const finalEndAngle = startAngle + Math.PI * 2 * detailValues[index] / detailTotal;
                this.drawSector(center, radius, startAngle, Math.min(finalEndAngle, revealEndAngle),
                    this.expandedColorAt(index), surfaceColor, index === this.selectedIndex());
                startAngle = finalEndAngle;
            }
            return;
        }
        for (let index = 0; index < values.length; index++) {
            if (values[index] <= 0) continue;
            const sweep = Math.PI * 2 * values[index] / visibleTotal * this.drawProgress;
            const endAngle = startAngle + sweep;
            this.drawSector(center, radius, startAngle, endAngle, this.colorAt(index), surfaceColor,
                index === this.selectedIndex() && this.drawProgress >= 1);
            startAngle = endAngle;
        }
    }

    private selectAt(x: number, y: number): void {
        if (this.chart.total <= 0) return;
        const labels = this.displayLabels();
        const values = this.visibleValues();
        const visibleTotal = this.visibleTotal();
        if (visibleTotal <= 0) return;
        const center = this.canvasSize / 2;
        const dx = x - center;
        const dy = y - center;
        if (Math.sqrt(dx * dx + dy * dy) > center) return;
        let angle = Math.atan2(dy, dx) + Math.PI / 2;
        if (angle < 0) angle += Math.PI * 2;
        let accumulated = 0;
        for (let index = 0; index < values.length; index++) {
            if (values[index] <= 0) continue;
            accumulated += Math.PI * 2 * values[index] / visibleTotal;
            if (angle <= accumulated) {
                if (labels[index] === '其他') {
                    this.expandFromOther();
                    return;
                }
                if (!this.onSelect && index !== this.selectedIndex() && this.vibrationLevel > 0) vibration.dotVibration();
                this.selected = index;
                if (this.onSelect) this.onSelect(labels[index]);
                this.draw();
                return;
            }
        }
    }

    aboutToDisappear(): void {
        this.animationToken++;
    }

    @Builder
    private pieCanvas(): void {
        Canvas(this.context)
            .width(this.canvasSize).height(this.canvasSize).align(Alignment.Center)
            .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
            .animation({ duration: 120, curve: Curve.EaseOut })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                    sourceType: hdsEffect.PointLightSourceType.BRIGHT,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER,
                    options: { color: $r('app.color.diff_content'), intensity: 4, height: 100 },
                })
                .buildEffect())
            .onReady((): void => {
                this.canvasReady = true;
                this.animatePie();
            })
            .onTouch((event: TouchEvent): void => {
                if (event.type === TouchType.Down) {
                    this.pressed = true;
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.pressed = false;
                }
                if (event.type === TouchType.Down && event.touches.length > 0) {
                    this.selectAt(event.touches[0].x, event.touches[0].y);
                }
            })
            .accessibilityText(`${this.chart.title}饼图，点一下扇区可以查看具体数据`)
    }

    @Builder
    private legendGrid(columns: number): void {
        GridRow({ columns, gutter: { x: 5, y: 4 } }) {
            ForEach(this.displayLabels(), (label: string, index: number) => {
                GridCol({ span: 1 }) {
                    Row({ space: 5 }) {
                        Row().width(8).height(8).borderRadius(4)
                            .backgroundColor(this.colorAt(index))
                        Column({ space: 1 }) {
                            if (label === '其他') {
                                Text('其他（点击展开）').fontSize(13).fontWeight(FontWeight.Medium)
                                    .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                            } else {
                                Text(label).fontSize(13).fontWeight(FontWeight.Medium)
                                    .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                            }
                            Text(this.legendText(index)).fontSize(11)
                                .fontColor($r('app.color.v3_text_secondary')).maxLines(1)
                        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                    }
                    .width('100%').padding({ left: 6, right: 6, top: 5, bottom: 5 }).borderRadius(8)
                    .backgroundColor(index === this.selectedIndex() ?
                        $r('app.color.v3_surface_alt') : Color.Transparent)
                    .scale({ x: this.pressedControl === label ? 0.97 : 1,
                        y: this.pressedControl === label ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(new hdsEffect.HdsEffectBuilder()
                        .pointLight({
                            sourceType: hdsEffect.PointLightSourceType.BRIGHT,
                            illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER,
                            options: { color: $r('app.color.diff_content'), intensity: 5, height: 84 },
                        })
                        .buildEffect())
                    .onTouch((event: TouchEvent): void => {
                        if (event.type === TouchType.Down) this.pressedControl = label;
                        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                            this.pressedControl = '';
                        }
                    })
                    .onClick(() => {
                        if (label === '其他') {
                            this.expandFromOther();
                            return;
                        }
                        if (!this.onSelect && this.vibrationLevel > 0) vibration.dotVibration();
                        this.selected = index;
                        if (this.onSelect) this.onSelect(label);
                        this.draw();
                    })
                    .transition(TransitionEffect.OPACITY.combine(
                        TransitionEffect.scale({ x: 0.94, y: 0.94 })))
                    .accessibilityText(label === '其他' ?
                        `其他，${this.legendText(index)}，点击展开全部` :
                        `${label}，${this.legendText(index)}`)
                }
            }, (label: string) => `${this.chart.title}-${label}`)
        }
        .width('100%')
        .accessibilityText(`${this.chart.title}图例`)
    }

    build() {
        Column({ space: (this.chartCaption.length > 0 || this.reserveCaptionSpace) ? 2 : 8 }) {
            if (this.showTitle) {
                Row() {
                    Text(this.chart.title).fontSize(18).fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.v3_text_primary')).layoutWeight(1)
                        .accessibilityText(this.chart.title)
                    if (this.showExpandAction && this.hasOverflow()) {
                        Text(this.expanded ? '收起' : '展开全部')
                            .fontSize(13)
                            .fontColor($r('app.color.diff_content'))
                            .padding({ left: 6, right: 6, top: 4, bottom: 4 })
                            .borderRadius(8)
                            .scale({ x: this.pressedControl === 'expand' ? 0.94 : 1,
                                y: this.pressedControl === 'expand' ? 0.94 : 1 })
                            .animation({ duration: 120, curve: Curve.EaseOut })
                            .visualEffect(new hdsEffect.HdsEffectBuilder()
                                .pointLight({
                                    sourceType: hdsEffect.PointLightSourceType.BRIGHT,
                                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER,
                                    options: { color: $r('app.color.diff_content'), intensity: 5, height: 84 },
                                })
                                .buildEffect())
                            .onTouch((event: TouchEvent): void => {
                                if (event.type === TouchType.Down) this.pressedControl = 'expand';
                                else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                                    this.pressedControl = '';
                                }
                            })
                            .onClick(() => this.toggleExpansion())
                            .accessibilityText(this.expanded ? `收起${this.chart.title}` : `展开${this.chart.title}全部SDK`)
                    }
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
            }
            if (this.chartCaption.length > 0 || this.reserveCaptionSpace) {
                Text(this.chartCaption)
                    .height(20)
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.chartCaption.length > 0 ?
                        $r('app.color.v3_text_secondary') : Color.Transparent)
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .accessibilityText(this.chartCaption)
            }
            if (this.chart.values.length > 0) {
                if (this.horizontalLegend) {
                    Row({ space: 10 }) {
                        this.pieCanvas()
                        if (this.showLegend) {
                            Column() {
                                this.legendGrid(2)
                            }
                            .layoutWeight(1)
                            .alignItems(HorizontalAlign.Start)
                        }
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center)
                } else {
                    this.pieCanvas()
                    if (this.showLegend) this.legendGrid(2)
                }
            } else {
                Text('暂无数据').fontColor($r('app.color.v3_text_secondary')).padding(30)
                    .accessibilityText(`${this.chart.title}暂无数据`)
            }
        }
        .width('100%').padding(this.embedded ? 0 : 14).borderRadius(this.embedded ? 0 : 18)
        .backgroundColor(this.embedded ? Color.Transparent : $r('app.color.v3_surface'))
        .border({ width: this.embedded ? 0 : 1, color: $r('app.color.nd_card_border') })
        .onAreaChange((_oldArea: Area, area: Area): void => {
            const width = Number(area.width);
            if (width > 0) {
                this.canvasSize = this.horizontalLegend ?
                    Math.max(154, Math.min(196, width * 0.36)) :
                    Math.max(164, Math.min(220, width - (this.embedded ? 24 : 44)));
                setTimeout((): void => this.draw(), 0);
            }
        })
        .onAppear(() => this.animatePie())
        .accessibilityGroup(true).accessibilityText(`${this.chart.title}，${this.selectedText()}`)
    }
}

@Component
struct ApiHistoryChart {
    @Prop history: HistoryPoint[] = [];
    @Prop apiKeys: string[] = [];
    @Prop viewport: ChartViewportState = { zoom: 1, panRatio: 0 };
    onViewportChange?: (viewport: ChartViewportState) => void;

    private palette(): Resource[] {
        return [
            $r('app.color.diff_content'),
            $r('app.color.v3_accent_cyan'),
            $r('app.color.v3_accent_green'),
            $r('app.color.v3_accent_orange'),
            $r('app.color.v3_accent_red'),
            $r('app.color.v3_accent_purple'),
            $r('app.color.v3_chart_series_7'),
            $r('app.color.v3_chart_series_8'),
            $r('app.color.v3_chart_series_9'),
            $r('app.color.v3_chart_series_10'),
            $r('app.color.v3_chart_series_11'),
            $r('app.color.v3_chart_series_12'),
            $r('app.color.v3_chart_series_13'),
            $r('app.color.v3_chart_series_14'),
            $r('app.color.v3_chart_series_15'),
            $r('app.color.v3_chart_series_16'),
        ];
    }

    private chartSeries(): LineChartSeries[] {
        const colors = this.palette();
        return this.apiKeys.map((key: string, index: number): LineChartSeries => ({
            label: `API ${key}`,
            color: colors[index % colors.length],
            points: this.history.map((point: HistoryPoint): LineChartPoint => {
                const value = Number(point.values[key] ?? 0);
                return {
                    label: point.date,
                    value,
                    detail: `${point.date} · API ${key} 占比 ${value.toFixed(2)}%`,
                } as LineChartPoint;
            }),
        } as LineChartSeries));
    }

    build() {
        Column({ space: 12 }) {
            Row() {
                Text('Harmony API 版本占比历史').fontSize(18).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).layoutWeight(1)
            }.width('100%')
            InteractiveLineChart({
                title: 'Harmony API版本占比历史',
                unit: '%',
                series: this.chartSeries(),
                showTitle: false,
                chartHeight: 280,
                responsiveAxisFont: true,
                viewport: this.viewport,
                onViewportChange: (viewport: ChartViewportState): void => {
                    if (this.onViewportChange) this.onViewportChange(viewport);
                },
            })
        }
        .width('100%').accessibilityText('Harmony API版本占比历史')
    }
}

@Component
export struct OverviewSection {
    @Prop @Watch('onRefreshVersionChanged') refreshVersion: number = 0;
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

    aboutToAppear(): void {
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
        const sorted = source.slice().sort((a: number[], b: number[]) => Number(b[0]) - Number(a[0]));
        const values = sorted.map((item: number[]) => Number(item[1]));
        return {
            title, labels: sorted.map((item: number[]) => `API ${item[0]}`), values,
            total: values.reduce((sum: number, value: number) => sum + value, 0),
        };
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
        return Object.keys(labels).sort((a: string, b: string) =>
            Number(b.replace('API ', '')) - Number(a.replace('API ', '')));
    }
    private visibleSdkLabels(): string[] {
        const labels = this.sdkLabels();
        if (this.sdkExpanded || labels.length <= COLLAPSED_SDK_COUNT) return labels;
        return labels.slice(0, COLLAPSED_SDK_COUNT).concat(['其他']);
    }
    private sdkValue(chart: DistributionChart, label: string): number {
        if (label !== '其他') {
            const index = chart.labels.indexOf(label);
            return index >= 0 ? chart.values[index] : 0;
        }
        const visible = this.sdkLabels().slice(0, COLLAPSED_SDK_COUNT);
        let total = 0;
        for (let index = 0; index < chart.labels.length; index++) {
            if (visible.indexOf(chart.labels[index]) < 0) total += chart.values[index] ?? 0;
        }
        return total;
    }
    private sdkPercent(chart: DistributionChart, label: string): string {
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
            const collapsedLabels = this.sdkLabels().slice(0, COLLAPSED_SDK_COUNT);
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
                GridRow({ columns: this.contentWidth >= 840 ? 4 : (this.contentWidth >= 600 ? 3 : 2),
                    gutter: { x: 5, y: 5 } }) {
                    ForEach(this.visibleSdkLabels(), (label: string, index: number) => {
                        GridCol({ span: 1 }) {
                            Row({ space: 5 }) {
                                Row().width(8).height(8).borderRadius(4)
                                    .backgroundColor(label === '其他' ? $r('app.color.nd_text_sub') :
                                        this.sdkColors()[this.sdkLabels().indexOf(label) % this.sdkColors().length])
                                Column({ space: 1 }) {
                                    if (label === '其他') {
                                        Text('其他（点击展开）').fontSize(13).fontWeight(FontWeight.Medium)
                                            .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                                    } else {
                                        Text(label).fontSize(13).fontWeight(FontWeight.Medium)
                                            .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                                    }
                                    Text(`目标 ${this.sdkPercent(this.targetSdkChart, label)} · 最低 ${this.sdkPercent(this.minSdkChart, label)}`)
                                        .fontSize(10).fontColor($r('app.color.v3_text_secondary')).maxLines(1)
                                }
                                .layoutWeight(1)
                                .alignItems(HorizontalAlign.Start)
                            }
                            .width('100%')
                            .padding({ left: 6, right: 6, top: 5, bottom: 5 })
                            .borderRadius(8)
                            .backgroundColor(label === this.activeSdkLabel() ?
                                $r('app.color.v3_surface_alt') : Color.Transparent)
                            .scale({ x: this.pressedControl === label ? 0.97 : 1,
                                y: this.pressedControl === label ? 0.97 : 1 })
                            .animation({ duration: 120, curve: Curve.EaseOut })
                            .visualEffect(new hdsEffect.HdsEffectBuilder()
                                .pointLight({
                                    sourceType: hdsEffect.PointLightSourceType.BRIGHT,
                                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER,
                                    options: { color: $r('app.color.diff_content'), intensity: 5, height: 84 },
                                })
                                .buildEffect())
                            .onTouch((event: TouchEvent): void => {
                                if (event.type === TouchType.Down) this.pressedControl = label;
                                else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                                    this.pressedControl = '';
                                }
                            })
                            .onClick(() => {
                                this.selectSdk(label);
                            })
                            .transition(TransitionEffect.OPACITY.combine(
                                TransitionEffect.scale({ x: 0.94, y: 0.94 })))
                            .accessibilityText(label === '其他' ?
                                '其他SDK，点击展开全部SDK版本' :
                                `${label}，目标占比${this.sdkPercent(this.targetSdkChart, label)}，最低占比${this.sdkPercent(this.minSdkChart, label)}`)
                        }
                    }, (label: string) => `sdk-shared-${label}`)
                }
                .width('100%')
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
                if (this.sdkLabels().length > COLLAPSED_SDK_COUNT) {
                    Text(this.sdkExpanded ? '收起' : '展开全部')
                        .fontSize(13)
                        .fontColor($r('app.color.diff_content'))
                        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
                        .borderRadius(8)
                        .scale({ x: this.pressedControl === 'sdk-expand' ? 0.94 : 1,
                            y: this.pressedControl === 'sdk-expand' ? 0.94 : 1 })
                        .animation({ duration: 120, curve: Curve.EaseOut })
                        .visualEffect(new hdsEffect.HdsEffectBuilder()
                            .pointLight({
                                sourceType: hdsEffect.PointLightSourceType.BRIGHT,
                                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER,
                                options: { color: $r('app.color.diff_content'), intensity: 5, height: 84 },
                            })
                            .buildEffect())
                        .onTouch((event: TouchEvent): void => {
                            if (event.type === TouchType.Down) this.pressedControl = 'sdk-expand';
                            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                                this.pressedControl = '';
                            }
                        })
                        .onClick(() => {
                            if (this.sdkExpanded) this.collapseSdk(); else this.expandSdk();
                        })
                        .accessibilityText(this.sdkExpanded ? '收起全部SDK版本' : '展开全部SDK版本')
                }
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            Row({ space: 12 }) {
                Column() {
                    DistributionPanel({ chart: this.targetSdkChart, showLegend: false, collapsible: true,
                        expanded: this.sdkExpanded, colorLabels: this.sdkLabels(), embedded: true,
                        showTitle: false, chartCaption: '目标 SDK',
                        selectedLabel: this.activeSdkLabel(),
                        onSelect: (label: string): void => this.selectSdk(label),
                        onExpand: (): void => this.expandSdk() })
                }
                .layoutWeight(1)
                Column() {
                    DistributionPanel({ chart: this.minSdkChart, showLegend: false, collapsible: true,
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

    private finish(): void {
        this.pendingLoads--;
        if (this.pendingLoads <= 0) {
            this.loading = false;
            this.loaded = true;
            if (this.reloadAfterCurrent) {
                this.reloadAfterCurrent = false;
                setTimeout((): void => this.load(true), 0);
            } else if (this.onRefreshCompleted) {
                this.onRefreshCompleted();
            }
        }
    }
    private failed(name: string, error: Error): void {
        console.error('[Dashboard][component/charts/OverviewSection][ERROR]', `${name}加载失败: ${error.message}`);
    }
    private load(force: boolean): void {
        if (this.loading) {
            this.reloadAfterCurrent = this.reloadAfterCurrent || force;
            return;
        }
        this.loading = true;
        this.fromCache = false;
        this.pendingLoads = 4;
        fetchRatingDistribution(force).then((result) => {
            const response = result.data as BaseAPIResponse<RatingDistribution>;
            if (!response.success || !response.data) throw new Error('评分接口未返回有效数据');
            const rating = response.data;
            const values = [rating.star_5, rating.star_4, rating.star_3, rating.star_2, rating.star_1];
            this.ratingChart = { title: '应用评分分布', labels: ['5 星', '4 星', '3 星', '2 星', '1 星与无评分'],
                values, total: values.reduce((sum: number, value: number) => sum + value, 0) };
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => this.failed('评分分布', error)).finally(() => this.finish());
        fetchSdkDistribution('min_sdk', force).then((result) => {
            if (!result.data.success || !result.data.data) throw new Error('最低 SDK 接口未返回有效数据');
            this.minSdkChart = this.distribution('最低 SDK 分布', result.data.data as number[][]);
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => this.failed('最低 SDK 分布', error)).finally(() => this.finish());
        fetchSdkDistribution('target_sdk', force).then((result) => {
            if (!result.data.success || !result.data.data) throw new Error('目标 SDK 接口未返回有效数据');
            this.targetSdkChart = this.distribution('目标 SDK 分布', result.data.data as number[][]);
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => this.failed('目标 SDK 分布', error)).finally(() => this.finish());
        fetchApiHistory(force).then((result) => {
            if (!result.data.success || !result.data.data) throw new Error('API 历史接口未返回有效数据');
            const next: HistoryPoint[] = [];
            for (const raw of result.data.data as object[]) {
                const tuple = raw as object[];
                if (tuple.length >= 2) next.push({ date: String(tuple[0]), values: tuple[1] as Record<string, number> });
            }
            this.history = next;
            const discovered: Record<string, boolean> = {};
            for (const historyPoint of next) {
                for (const key of Object.keys(historyPoint.values)) discovered[key] = true;
            }
            this.apiKeys = Object.keys(discovered).sort((a: string, b: string) => Number(b) - Number(a));
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => this.failed('Harmony API 历史', error)).finally(() => this.finish());
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
                    .accessibilityText('应用概况图表加载中')
            }
            if (this.contentWidth >= 840) {
                Row({ space: 12 }) {
                    Column() {
                        this.combinedSdkPanel()
                    }.layoutWeight(2)
                    Column() {
                        DistributionPanel({ chart: this.ratingChart, reserveCaptionSpace: true })
                    }.layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
                .accessibilityText('共用图例的SDK组合图表与评分分布图表')
            } else if (this.contentWidth >= 600) {
                Column({ space: 12 }) {
                    this.combinedSdkPanel()
                    DistributionPanel({ chart: this.ratingChart, horizontalLegend: true })
                }
                .width('100%')
                .accessibilityText('共用图例的双列SDK分布和横向评分分布')
            } else {
                Column({ space: 12 }) {
                    DistributionPanel({ chart: this.targetSdkChart, collapsible: true,
                        expanded: this.targetSdkExpanded, colorLabels: this.sdkLabels(), showExpandAction: true,
                        onExpand: (): void => this.expandTargetSdk(),
                        onCollapse: (): void => this.collapseTargetSdk() })
                    DistributionPanel({ chart: this.minSdkChart, collapsible: true,
                        expanded: this.minSdkExpanded, colorLabels: this.sdkLabels(), showExpandAction: true,
                        onExpand: (): void => this.expandMinSdk(),
                        onCollapse: (): void => this.collapseMinSdk() })
                    DistributionPanel({ chart: this.ratingChart })
                }
                .width('100%')
                .accessibilityText('各自使用独立图例的目标SDK、最低SDK与评分分布图表')
            }
            ApiHistoryChart({
                history: this.history,
                apiKeys: this.apiKeys,
                viewport: this.apiHistoryViewport,
                onViewportChange: (viewport: ChartViewportState): void => this.updateApiHistoryViewport(viewport),
            })
        }
        .width('100%')
        .onAreaChange((_oldArea: Area, area: Area): void => {
            this.contentWidth = Number(area.width);
        })
        .onAppear(() => { if (!this.loaded) this.load(false); })
        .accessibilityText('应用概况页面')
    }
}
