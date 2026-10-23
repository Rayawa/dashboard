import { PerformanceTrace } from '../../common/PerformanceTrace';
import { FrameScheduler } from '../../common/FrameScheduler';
import { common } from '@kit.AbilityKit';
import { hdsEffect } from '@kit.UIDesignKit';
import { vibration } from '../../common/vibration';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import type { ChartViewportState } from '../../common/types';
import { chartAxisScale, chartDateLines, chartDateIndices, chartLegendColumns, chartPercentLabel } from './chartLayout';
import type { ChartAxisScale } from './chartLayout';

export interface LineChartPoint {
    label: string;
    value: number;
    detail: string;
}

export interface LineChartSeries {
    label: string;
    color: Resource;
    points: LineChartPoint[];
}

@Component
export struct InteractiveLineChart {
    @Prop @Watch('onDataChanged') title: string = '';
    @Prop @Watch('onDataChanged') unit: string = '';
    @Prop @Watch('onDataChanged') points: LineChartPoint[] = [];
    @Prop @Watch('onDataChanged') series: LineChartSeries[] = [];
    @Prop @Watch('onDataChanged') lineColor: Resource = $r('app.color.diff_content');
    @Prop showTitle: boolean = true;
    @Prop chartHeight: number = 250;
    @Prop responsiveAxisFont: boolean = false;
    @Prop enablePressEffect: boolean = true;
    @Prop @Watch('onViewportPropChanged') viewport: ChartViewportState = { zoom: 1, panRatio: 0 };
    @Prop @Watch('onVisibilityChanged') active: boolean = true;
    private inViewport: boolean = false;
    private alive: boolean = false;
    private frameScheduler: FrameScheduler = new FrameScheduler();
    private dataMaximum: number = 1;
    private axisScale: ChartAxisScale = chartAxisScale(1, '');
    @State private singleSeries: LineChartSeries[] = [];
    private layoutKey: string = '';
    private plotDimensions: number[] = [60, 10, 250];
    private colors: Map<number, number> = new Map();
    private animationStartedAt: number = 0;
    onViewportChange?: (viewport: ChartViewportState) => void;
    private settings: RenderingContextSettings = new RenderingContextSettings(true);
    private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
    @State private canvasWidth: number = 320;
    @State private selected: number = 0;
    private zoom: number = 1;
    private panOffset: number = 0;
    @State private pressed: boolean = false;
    @State private pressedLegend: string = '';
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    private zoomAtGestureStart: number = 1;
    private panAtGestureStart: number = 0;
    private canvasReady: boolean = false;
    private drawProgress: number = 1;
    private animatedDataSignature: string = '';
    private legendPressToken: number = 0;
    private legendPressTimer: number = -1;

    private beginLegendPress(label: string): void {
        const token = ++this.legendPressToken;
        this.pressedLegend = label;
        if (this.legendPressTimer >= 0) clearTimeout(this.legendPressTimer);
        this.legendPressTimer = setTimeout((): void => {
            this.legendPressTimer = -1;
            if (this.legendPressToken === token && this.pressedLegend === label) {
                this.pressedLegend = '';
            }
        }, 800);
    }

    private endLegendPress(): void {
        this.legendPressToken++;
        if (this.legendPressTimer >= 0) {
            clearTimeout(this.legendPressTimer);
            this.legendPressTimer = -1;
        }
        this.pressedLegend = '';
    }

    private sourceSeries(): LineChartSeries[] {
        if (this.series.length > 0) return this.series;
        return this.singleSeries;
    }

    private pointCount(): number {
        const source = this.sourceSeries();
        return source.length > 0 ? source[0].points.length : 0;
    }

    private labels(): LineChartPoint[] {
        const source = this.sourceSeries();
        return source.length > 0 ? source[0].points : [];
    }

    private dataSignature(): string {
        const parts: string[] = [];
        for (const chartSeries of this.sourceSeries()) {
            parts.push(chartSeries.label);
            for (const point of chartSeries.points) {
                parts.push(point.label, String(point.value));
            }
        }
        return parts.join('\u0001');
    }

    aboutToAppear(): void {
        this.alive = true;
        this.rebuildModel();
    }

    private rebuildModel(): void {
        this.singleSeries = [{ label: this.title, color: this.lineColor, points: this.points }];
        this.dataMaximum = 1;
        for (const series of this.sourceSeries()) {
            for (const point of series.points) {
                const value = point.value;
                if (Number.isFinite(value)) this.dataMaximum = Math.max(this.dataMaximum, value);
            }
        }
        this.axisScale = chartAxisScale(this.dataMaximum, this.unit);
        this.layoutKey = '';
    }

    private onDataChanged(): void {
        this.rebuildModel();
        if (this.pointCount() === 0) { this.canvasReady = false; this.frameScheduler.cancel(); }
        this.selected = Math.min(this.selected, Math.max(0, this.pointCount() - 1));
        this.applyViewportState(false);
        this.startEntranceAnimation();
    }

    private onVisibilityChanged(): void {
        if (this.active && this.inViewport) this.startEntranceAnimation();
        else {
            this.frameScheduler.cancel();
            this.endLegendPress(); this.pressed = false;
            this.animationStartedAt = 0;
            this.drawProgress = 1;
        }
    }

    private requestDraw(): void {
        if (!this.alive || !this.canvasReady || !this.active || !this.inViewport) return;
        this.frameScheduler.request(this.getUIContext(), (): void => {
            if (!this.alive || !this.active || !this.inViewport) return;
            if (this.animationStartedAt > 0) {
                const elapsed = Math.min(1, (Date.now() - this.animationStartedAt) / 280);
                this.drawProgress = 1 - Math.pow(1 - elapsed, 3);
                if (elapsed >= 1) this.animationStartedAt = 0;
            }
            PerformanceTrace.measure('Dashboard.Chart.Draw', (): void => this.draw());
            if (this.animationStartedAt > 0) this.requestDraw();
        });
    }

    private onViewportPropChanged(): void {
        this.applyViewportState();
    }

    private viewportZoom(): number {
        const value = Number(this.viewport.zoom);
        return value >= 1 ? Math.min(4, value) : 1;
    }

    private viewportPanRatio(): number {
        const value = Number(this.viewport.panRatio);
        return value >= 0 ? Math.min(1, value) : 0;
    }

    private applyViewportState(redraw: boolean = true): void {
        this.zoom = this.viewportZoom();
        this.panOffset = this.clampPan(this.maxPan(this.zoom) * this.viewportPanRatio(), this.zoom);
        if (redraw) this.requestDraw();
    }

    private emitViewport(): void {
        if (!this.onViewportChange) return;
        const maximum = this.maxPan();
        this.onViewportChange({
            zoom: this.zoom,
            panRatio: maximum > 0 ? this.panOffset / maximum : 0,
        });
    }

    private startEntranceAnimation(): void {
        if (!this.canvasReady || !this.active || !this.inViewport) return;
        const signature = this.dataSignature();
        if (signature !== this.animatedDataSignature) {
            const firstDraw = this.animatedDataSignature.length === 0;
            this.animatedDataSignature = signature;
            this.selected = Math.max(0, this.pointCount() - 1);
            // Background data replacement stays stable; animate only the first small, visible chart.
            this.animationStartedAt = firstDraw && this.pointCount() <= 180 && this.sourceSeries().length === 1 ? Date.now() : 0;
            this.drawProgress = this.animationStartedAt > 0 ? 0 : 1;
        }
        this.requestDraw();
    }

    private rgba(color: number, alpha: number): string {
        const red = (color >>> 16) & 0xFF;
        const green = (color >>> 8) & 0xFF;
        const blue = color & 0xFF;
        return `rgba(${red},${green},${blue},${alpha})`;
    }

    private pointY(points: LineChartPoint[], index: number, top: number, drawHeight: number, maximum: number): number {
        const baseline = top + drawHeight;
        const value = points[index]?.value ?? 0;
        const target = top + drawHeight * (1 - value / maximum);
        return baseline - (baseline - target) * this.drawProgress;
    }

    private traceSmoothLine(points: LineChartPoint[], top: number, drawHeight: number, maximum: number): void {
        if (points.length === 0) return;
        const width = this.dimensions()[2];
        const step = width * this.zoom / Math.max(1, this.pointCount() - 1);
        const first = Math.max(0, Math.floor(this.panOffset / Math.max(0.001, step)) - 1);
        const last = Math.min(points.length - 1, Math.ceil((this.panOffset + width) / Math.max(0.001, step)) + 1);
        this.context.moveTo(this.pointX(first), this.pointY(points, first, top, drawHeight, maximum));
        for (let index = first + 1; index <= last; index++) {
            const previousX = this.pointX(index - 1);
            const previousY = this.pointY(points, index - 1, top, drawHeight, maximum);
            const x = this.pointX(index);
            const y = this.pointY(points, index, top, drawHeight, maximum);
            const controlOffset = (x - previousX) * 0.34;
            this.context.bezierCurveTo(previousX + controlOffset, previousY, x - controlOffset, y, x, y);
        }
    }

    aboutToDisappear(): void {
        this.alive = false;
        this.frameScheduler.cancel();
        this.endLegendPress();
    }

    onWillApplyTheme(_theme: Theme): void { this.colors.clear(); this.requestDraw(); }

    private maximum(): number {
        return this.axisScale.maximum;
    }

    private valueLabel(value: number): string {
        return this.unit === '%' ? chartPercentLabel(value) : String(value);
    }

    private dimensions(): number[] {
        const key = `${this.canvasWidth}:${this.maximum()}:${this.unit}:${this.responsiveAxisFont}`;
        if (key === this.layoutKey) return this.plotDimensions;
        this.layoutKey = key;
        this.context.font = `${this.axisFontSize()}vp sans-serif`;
        let labelWidth = 0;
        for (const label of this.axisScale.labels) labelWidth = Math.max(labelWidth, this.context.measureText(label).width);
        const left = Math.min(this.canvasWidth * 0.32, Math.max(36, Math.ceil(labelWidth) + 12));
        const right = 12;
        this.plotDimensions = [left, right, Math.max(1, this.canvasWidth - left - right)];
        return this.plotDimensions;
    }

    private axisFontSize(): number {
        if (this.canvasWidth < 600) return this.responsiveAxisFont ? 11 : 12;
        if (this.canvasWidth < 840) return 13;
        return 14;
    }

    private dateFontSize(): number {
        return this.canvasWidth < 600 ? 11 : 12;
    }

    private bottomAxisSpace(): number {
        return this.dateFontSize() * 2 + 18;
    }

    private summaryColumns(): number {
        return chartLegendColumns(this.canvasWidth);
    }

    private maxPan(zoom: number = this.zoom): number {
        const drawWidth = this.dimensions()[2];
        return Math.max(0, drawWidth * zoom - drawWidth);
    }

    private clampPan(value: number, zoom: number = this.zoom): number {
        return Math.max(0, Math.min(this.maxPan(zoom), value));
    }

    private pointX(index: number): number {
        const dimensions = this.plotDimensions;
        const virtualWidth = dimensions[2] * this.zoom;
        return dimensions[0] + virtualWidth * index / Math.max(1, this.pointCount() - 1) - this.panOffset;
    }

    private selectAt(x: number): void {
        if (this.pointCount() === 0) return;
        const dimensions = this.dimensions();
        const virtualX = x - dimensions[0] + this.panOffset;
        const ratio = Math.max(0, Math.min(1, virtualX / Math.max(1, dimensions[2] * this.zoom)));
        const index = Math.round(ratio * Math.max(0, this.pointCount() - 1));
        if (index === this.selected) return;
        if (this.vibrationLevel > 0) vibration.dotVibration();
        this.selected = index;
        this.requestDraw();
    }

    private resolveColor(resource: Resource): number {
        const cached = this.colors.get(resource.id);
        if (cached !== undefined) return cached;
        const host = this.getUIContext().getHostContext() as common.UIAbilityContext;
        try {
            const color = host.resourceManager.getColorSync(resource.id);
            this.colors.set(resource.id, color);
            return color;
        } catch (error) {
            console.warn('[Dashboard][component/charts/InteractiveLineChart][WARN]',
                `折线颜色读取失败: ${JSON.stringify(error)}`);
            return 0xFF1E6FCD;
        }
    }

    private selectedDetail(): string {
        const source = this.sourceSeries();
        const labels = this.labels();
        if (source.length === 0 || labels.length === 0) return `暂无${this.title}`;
        if (source.length === 1) return source[0].points[Math.min(this.selected, source[0].points.length - 1)].detail;
        const values: string[] = [];
        for (const chartSeries of source) {
            const point = chartSeries.points[Math.min(this.selected, chartSeries.points.length - 1)];
            values.push(`${chartSeries.label} ${this.valueLabel(point?.value ?? 0)}`);
        }
        return `${labels[Math.min(this.selected, labels.length - 1)].label} · ${values.join(' · ')}`;
    }

    private selectedDate(): string {
        const labels = this.labels();
        return labels.length > 0 ? labels[Math.min(this.selected, labels.length - 1)].label : '';
    }

    private selectedSeriesValue(label: string): string {
        // Read the reactive source inside the Text binding, rather than capturing a stale keyed row object.
        const series = this.sourceSeries().find((item: LineChartSeries): boolean => item.label === label);
        const point = series?.points[Math.min(this.selected, series.points.length - 1)];
        return this.valueLabel(point?.value ?? 0);
    }

    private selectedSeriesColor(label: string): Resource {
        return this.sourceSeries().find((item: LineChartSeries): boolean => item.label === label)?.color ?? this.lineColor;
    }

    private draw(): void {
        if (!this.canvasReady || !this.active || !this.inViewport) return;
        const width = this.canvasWidth;
        const height = this.chartHeight;
        this.context.clearRect(0, 0, width, height);
        const source = this.sourceSeries();
        const labels = this.labels();
        if (source.length === 0 || labels.length === 0) return;
        let gridColor = 0x33334455;
        let textColor = 0xFF666666;
        try {
            gridColor = this.resolveColor($r('app.color.v3_chart_grid'));
            textColor = this.resolveColor($r('app.color.v3_text_secondary'));
        } catch (error) {
            console.warn('[Dashboard][component/charts/InteractiveLineChart][WARN]',
                `图表颜色读取失败: ${JSON.stringify(error)}`);
        }
        const dimensions = this.dimensions();
        const left = dimensions[0];
        const drawWidth = dimensions[2];
        const top = 18;
        const bottom = this.bottomAxisSpace();
        const drawHeight = Math.max(1, height - top - bottom);
        const baseline = top + drawHeight;
        const maximum = this.maximum();
        this.context.strokeStyle = gridColor;
        this.context.fillStyle = textColor;
        this.context.lineWidth = 1;
        this.context.font = `${this.axisFontSize()}vp sans-serif`;
        this.context.setLineDash([5, 6]);
        this.context.textBaseline = 'middle';
        for (let row = 0; row <= this.axisScale.intervals; row++) {
            const y = top + drawHeight * row / this.axisScale.intervals;
            this.context.beginPath();
            this.context.moveTo(left, y);
            this.context.lineTo(left + drawWidth, y);
            this.context.stroke();
            this.context.textAlign = 'right';
            this.context.fillText(this.axisScale.labels[row], left - 8, y, Math.max(1, left - 12));
        }
        this.context.setLineDash([]);
        this.context.save();
        this.context.beginPath();
        this.context.rect(left, top, drawWidth, drawHeight);
        this.context.clip();

        for (const chartSeries of source) {
            if (chartSeries.points.length === 0) continue;
            const color = this.resolveColor(chartSeries.color);
            const firstX = this.pointX(0);
            const lastX = this.pointX(chartSeries.points.length - 1);
            const pointSpacing = Math.abs(this.pointX(Math.min(1, chartSeries.points.length - 1)) - firstX);
            const drawPointMarkers = pointSpacing >= 6;
            const gradient = this.context.createLinearGradient(0, top, 0, baseline);
            gradient.addColorStop(0, this.rgba(color, source.length > 1 ? 0.16 : 0.34));
            gradient.addColorStop(1, this.rgba(color, 0));
            this.context.fillStyle = gradient;
            this.context.beginPath();
            this.traceSmoothLine(chartSeries.points, top, drawHeight, maximum);
            this.context.lineTo(lastX, baseline);
            this.context.lineTo(firstX, baseline);
            this.context.closePath();
            this.context.fill();
            this.context.strokeStyle = color;
            this.context.lineWidth = 2.4;
            this.context.lineJoin = 'round';
            this.context.lineCap = 'round';
            this.context.beginPath();
            this.traceSmoothLine(chartSeries.points, top, drawHeight, maximum);
            this.context.stroke();
            for (let index = 0; index < chartSeries.points.length; index++) {
                if (!drawPointMarkers && index !== this.selected) continue;
                const x = this.pointX(index);
                if (x < left - 6 || x > left + drawWidth + 6) continue;
                const y = this.pointY(chartSeries.points, index, top, drawHeight, maximum);
                this.context.fillStyle = color;
                this.context.beginPath();
                this.context.arc(x, y, index === this.selected ? 4.5 : 2.5, 0, Math.PI * 2);
                this.context.fill();
                if (index === this.selected) {
                    this.context.strokeStyle = this.rgba(color, 0.24);
                    this.context.lineWidth = 5;
                    this.context.beginPath();
                    this.context.arc(x, y, 6.5, 0, Math.PI * 2);
                    this.context.stroke();
                }
            }
        }

        if (this.selected >= 0 && this.selected < labels.length) {
            const selectedX = this.pointX(this.selected);
            if (selectedX >= left && selectedX <= left + drawWidth) {
                this.context.strokeStyle = textColor;
                this.context.lineWidth = 1;
                this.context.setLineDash([4, 4]);
                this.context.beginPath();
                this.context.moveTo(selectedX, top);
                this.context.lineTo(selectedX, baseline);
                this.context.stroke();
                this.context.setLineDash([]);
            }
        }
        this.context.restore();
        // Dates are outside the curve clip. Horizontal month/day + year has a bounded footprint.
        this.context.font = `${this.dateFontSize()}vp sans-serif`;
        this.context.textAlign = 'center';
        this.context.textBaseline = 'top';
        this.context.fillStyle = textColor;
        const indices = chartDateIndices(labels.length, drawWidth, this.zoom, this.panOffset);
        const lineHeight = this.dateFontSize() + 2;
        let previousRight = -1;
        for (const index of indices) {
            const lines = chartDateLines(labels[index].label);
            let labelWidth = 0;
            for (const line of lines) labelWidth = Math.max(labelWidth, this.context.measureText(line).width);
            labelWidth = Math.min(72, labelWidth);
            const x = Math.max(8 + labelWidth / 2, Math.min(width - 8 - labelWidth / 2, this.pointX(index)));
            if (x - labelWidth / 2 < previousRight + 8) continue;
            for (let line = 0; line < lines.length; line++) {
                this.context.fillText(lines[line], x, baseline + 8 + line * lineHeight, 72);
            }
            previousRight = x + labelWidth / 2;
        }
    }

    @Builder
    private seriesSummary(): void {
        Column({ space: 8 }) {
          Text(this.selectedDate()).fontSize(this.responsiveAxisFont && this.canvasWidth < 600 ? 13 : 15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.v3_text_primary')).width('100%')
          GridRow({ columns: this.summaryColumns(), gutter: { x: 6, y: 6 } }) {
            ForEach(this.sourceSeries(), (chartSeries: LineChartSeries) => {
              GridCol({ span: 1 }) {
                Row({ space: 7 }) {
                  Row().width(10).height(10).flexShrink(0).borderRadius(5).backgroundColor(this.selectedSeriesColor(chartSeries.label))
                  Column({ space: 3 }) {
                    Text(chartSeries.label).fontSize(13).fontColor($r('app.color.v3_text_secondary'))
                      .width('100%').wordBreak(WordBreak.BREAK_ALL)
                    Text(this.selectedSeriesValue(chartSeries.label)).fontSize(13).fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.v3_text_primary')).width('100%').wordBreak(WordBreak.BREAK_ALL)
                  }.layoutWeight(1).constraintSize({ minWidth: 0 }).alignItems(HorizontalAlign.Start)
                }
                .width('100%').padding({ left: 8, right: 8, top: 7, bottom: 7 })
                .borderRadius(10).backgroundColor($r('app.color.v3_surface_alt'))
                .border({ width: 1, color: $r('app.color.nd_card_border') })
                .scale({ x: this.pressedLegend === chartSeries.label ? 0.98 : 1,
                    y: this.pressedLegend === chartSeries.label ? 0.98 : 1 })
                .animation({ duration: 120, curve: Curve.EaseOut })
                .visualEffect(pressVisualEffect(this.pressedLegend === chartSeries.label,
                    hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                .compositingFilter(pressLightFieldFilter(this.pressedLegend === chartSeries.label))
                .onTouch((event: TouchEvent): void => {
                    if (event.type === TouchType.Down) this.beginLegendPress(chartSeries.label);
                    else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                        this.endLegendPress();
                    }
                })
                .onClick((): void => this.endLegendPress())
                .accessibilityText(`${chartSeries.label}，${this.selectedSeriesValue(chartSeries.label)}`)
              }
            }, (chartSeries: LineChartSeries) => chartSeries.label)
          }
          .width('100%')
          .accessibilityText('平铺显示各API版本当前占比')
        }.width('100%')
    }

    build() {
        Column({ space: 10 }) {
            if (this.showTitle) {
                Text(this.title).fontSize(18).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).width('100%').accessibilityText(this.title)
            }
            if (this.pointCount() > 0) {
                Canvas(this.context)
                    .width('100%').height(this.chartHeight)
                    .scale({ x: this.enablePressEffect && this.pressed ? 0.995 : 1,
                        y: this.enablePressEffect && this.pressed ? 0.995 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.enablePressEffect && this.pressed,
                        this.enablePressEffect ? hdsEffect.PointLightIlluminatedType.BORDER :
                            hdsEffect.PointLightIlluminatedType.NONE, 4, 100))
                    .compositingFilter(pressLightFieldFilter(this.enablePressEffect && this.pressed))
                    .onReady(() => {
                        this.canvasReady = true;
                        this.applyViewportState(false);
                        this.startEntranceAnimation();
                    })
                    .onAreaChange((_oldArea: Area, newArea: Area): void => {
                        const width = Number(newArea.width);
                        if (width > 0 && width !== this.canvasWidth) {
                            this.canvasWidth = width;
                            this.applyViewportState(false);
                            this.requestDraw();
                        }
                    })
                    .onTouch((event: TouchEvent): void => {
                        if (this.enablePressEffect && event.type === TouchType.Down) {
                            this.pressed = true;
                        } else if (this.enablePressEffect &&
                            (event.type === TouchType.Up || event.type === TouchType.Cancel)) {
                            this.pressed = false;
                        }
                        if (event.touches.length > 0 && (event.type === TouchType.Down || event.type === TouchType.Move)) {
                            this.selectAt(event.touches[0].x);
                        }
                    })
                    .gesture(GestureGroup(GestureMode.Parallel,
                        PanGesture({ fingers: 1, direction: PanDirection.Horizontal })
                            .onActionStart((): void => {
                                this.panAtGestureStart = this.panOffset;
                                if (this.vibrationLevel > 0) vibration.dotVibration();
                            })
                            .onActionUpdate((event: GestureEvent): void => {
                                this.panOffset = this.clampPan(this.panAtGestureStart - event.offsetX);
                                this.requestDraw();
                            })
                            .onActionEnd((): void => this.emitViewport()),
                        PinchGesture({ fingers: 2, distance: 4 })
                            .onActionStart((): void => {
                                this.zoomAtGestureStart = this.zoom;
                                if (this.vibrationLevel > 0) vibration.dotVibration();
                            })
                            .onActionUpdate((event: GestureEvent): void => {
                                const nextZoom = Math.max(1, Math.min(4, this.zoomAtGestureStart * event.scale));
                                const oldMax = this.maxPan(this.zoom);
                                const ratio = oldMax > 0 ? this.panOffset / oldMax : 0.5;
                                this.zoom = nextZoom;
                                this.panOffset = this.clampPan(this.maxPan(nextZoom) * ratio, nextZoom);
                                this.requestDraw();
                            })
                            .onActionEnd((): void => this.emitViewport())
                    ))
                    .accessibilityText(`${this.title}折线图，点一下可查看对应日期，需要时可放大或左右拖动`)
                if (this.sourceSeries().length > 1) {
                    this.seriesSummary()
                } else {
                    Text(this.selectedDetail()).fontSize(15).lineHeight(22)
                        .fontColor($r('app.color.v3_text_secondary')).width('100%')
                        .accessibilityText(this.selectedDetail())
                }
            } else {
                Text(`暂无${this.title}`).fontColor($r('app.color.v3_text_secondary')).padding(24)
                    .accessibilityText(`暂无${this.title}`)
            }
        }
        .width('100%').padding(14).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .onVisibleAreaChange([0, 0.01], (visible: boolean, ratio: number): void => {
            this.inViewport = visible && ratio > 0;
            this.onVisibilityChanged();
        })
        .accessibilityGroup(true)
        .accessibilityText(this.pointCount() > 0 ? `${this.title}，${this.selectedDetail()}` : `${this.title}暂无数据`)
    }
}
