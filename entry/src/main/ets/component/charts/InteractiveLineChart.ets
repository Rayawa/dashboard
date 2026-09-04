import { common } from '@kit.AbilityKit';
import { vibration } from '../../common/vibration';

export interface LineChartPoint {
    label: string;
    value: number;
    detail: string;
}

@Component
export struct InteractiveLineChart {
    @Prop title: string = '';
    @Prop unit: string = '';
    @Prop @Watch('onPointsChanged') points: LineChartPoint[] = [];
    @Prop lineColor: Resource = $r('app.color.diff_content');
    @Prop showTitle: boolean = true;
    @Prop chartHeight: number = 250;
    private settings: RenderingContextSettings = new RenderingContextSettings(true);
    private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
    @State private canvasWidth: number = 320;
    @State private selected: number = 0;
    @State private zoom: number = 1;
    @State private panOffset: number = 0;
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;
    private zoomAtGestureStart: number = 1;
    private panAtGestureStart: number = 0;
    private canvasReady: boolean = false;
    private drawProgress: number = 1;
    private animationToken: number = 0;

    private onPointsChanged(): void {
        this.selected = Math.max(0, this.points.length - 1);
        this.zoom = 1;
        this.panOffset = 0;
        setTimeout((): void => this.startEntranceAnimation(), 0);
    }

    private startEntranceAnimation(): void {
        if (!this.canvasReady || this.points.length === 0) {
            this.draw();
            return;
        }
        const token = ++this.animationToken;
        const startedAt = Date.now();
        this.drawProgress = 0;
        const tick = (): void => {
            if (token !== this.animationToken) return;
            const elapsed = Math.min(1, (Date.now() - startedAt) / 800);
            this.drawProgress = 1 - Math.pow(1 - elapsed, 3);
            this.draw();
            if (elapsed < 1) setTimeout(tick, 16);
        };
        tick();
    }

    private rgba(color: number, alpha: number): string {
        const red = (color >>> 16) & 0xFF;
        const green = (color >>> 8) & 0xFF;
        const blue = color & 0xFF;
        return `rgba(${red},${green},${blue},${alpha})`;
    }

    private pointY(index: number, top: number, drawHeight: number, maximum: number): number {
        const baseline = top + drawHeight;
        const target = top + drawHeight * (1 - this.points[index].value / maximum);
        return baseline - (baseline - target) * this.drawProgress;
    }

    private traceSmoothLine(top: number, drawHeight: number, maximum: number): void {
        if (this.points.length === 0) return;
        const firstX = this.pointX(0);
        const firstY = this.pointY(0, top, drawHeight, maximum);
        this.context.moveTo(firstX, firstY);
        for (let index = 1; index < this.points.length; index++) {
            const previousX = this.pointX(index - 1);
            const previousY = this.pointY(index - 1, top, drawHeight, maximum);
            const x = this.pointX(index);
            const y = this.pointY(index, top, drawHeight, maximum);
            const controlOffset = (x - previousX) * 0.34;
            this.context.bezierCurveTo(
                previousX + controlOffset, previousY,
                x - controlOffset, y,
                x, y,
            );
        }
    }

    aboutToDisappear(): void {
        this.animationToken++;
    }

    private maximum(): number {
        let maximum = this.unit === '分' ? 5 : 1;
        for (const point of this.points) maximum = Math.max(maximum, point.value);
        return maximum;
    }

    private valueLabel(value: number): string {
        if (this.unit === '%') return `${value.toFixed(1)}%`;
        if (this.unit === '分') return value.toFixed(1);
        if (value >= 100000000) return `${(value / 100000000).toFixed(1)}亿`;
        if (value >= 100000) return `${Math.round(value / 10000)}万`;
        if (value >= 10000) return `${(value / 10000).toFixed(1)}万`;
        return String(Math.round(value));
    }

    private dimensions(): number[] {
        const left = 52;
        const right = 6;
        return [left, right, Math.max(1, this.canvasWidth - left - right)];
    }

    private maxPan(zoom: number = this.zoom): number {
        const drawWidth = this.dimensions()[2];
        return Math.max(0, drawWidth * zoom - drawWidth);
    }

    private clampPan(value: number, zoom: number = this.zoom): number {
        return Math.max(0, Math.min(this.maxPan(zoom), value));
    }

    private pointX(index: number): number {
        const dimensions = this.dimensions();
        const left = dimensions[0];
        const virtualWidth = dimensions[2] * this.zoom;
        return left + virtualWidth * index / Math.max(1, this.points.length - 1) - this.panOffset;
    }

    private selectAt(x: number): void {
        if (this.points.length === 0) return;
        const dimensions = this.dimensions();
        const virtualX = x - dimensions[0] + this.panOffset;
        const ratio = Math.max(0, Math.min(1, virtualX / Math.max(1, dimensions[2] * this.zoom)));
        const index = Math.round(ratio * Math.max(0, this.points.length - 1));
        if (index !== this.selected && this.vibrationEnabled) vibration.dotVibration();
        this.selected = index;
        this.draw();
    }

    private draw(): void {
        const width = this.canvasWidth;
        const height = this.chartHeight;
        this.context.clearRect(0, 0, width, height);
        if (this.points.length === 0) return;
        const host = this.getUIContext().getHostContext() as common.UIAbilityContext;
        let resolvedLineColor = 0xFF1E6FCD;
        let gridColor = 0x33334455;
        let textColor = 0xFF666666;
        try {
            resolvedLineColor = host.resourceManager.getColorSync(this.lineColor.id);
            gridColor = host.resourceManager.getColorSync($r('app.color.v3_chart_grid').id);
            textColor = host.resourceManager.getColorSync($r('app.color.v3_text_secondary').id);
        } catch (error) {
            console.warn('[Dashboard][component/charts/InteractiveLineChart][WARN]',
                `图表颜色读取失败: ${JSON.stringify(error)}`);
        }
        const dimensions = this.dimensions();
        const left = dimensions[0];
        const drawWidth = dimensions[2];
        const top = 18;
        const bottom = 48;
        const drawHeight = Math.max(1, height - top - bottom);
        const maximum = this.maximum();
        this.context.strokeStyle = gridColor;
        this.context.fillStyle = textColor;
        this.context.lineWidth = 1;
        this.context.font = '13px sans-serif';
        this.context.setLineDash([5, 6]);
        for (let row = 0; row <= 4; row++) {
            const y = top + drawHeight * row / 4;
            this.context.beginPath();
            this.context.moveTo(left, y);
            this.context.lineTo(left + drawWidth, y);
            this.context.stroke();
            this.context.textAlign = 'right';
            this.context.fillText(this.valueLabel(maximum * (4 - row) / 4), left - 8, y + 4);
        }
        this.context.setLineDash([]);

        this.context.save();
        this.context.beginPath();
        this.context.rect(left, 0, drawWidth, height);
        this.context.clip();
        const baseline = top + drawHeight;
        const firstX = this.pointX(0);
        const lastX = this.pointX(this.points.length - 1);
        const gradient = this.context.createLinearGradient(0, top, 0, baseline);
        gradient.addColorStop(0, this.rgba(resolvedLineColor, 0.34));
        gradient.addColorStop(1, this.rgba(resolvedLineColor, 0));
        this.context.fillStyle = gradient;
        this.context.beginPath();
        this.traceSmoothLine(top, drawHeight, maximum);
        this.context.lineTo(lastX, baseline);
        this.context.lineTo(firstX, baseline);
        this.context.closePath();
        this.context.fill();

        this.context.strokeStyle = resolvedLineColor;
        this.context.lineWidth = 2.5;
        this.context.lineJoin = 'round';
        this.context.lineCap = 'round';
        this.context.beginPath();
        this.traceSmoothLine(top, drawHeight, maximum);
        this.context.stroke();
        const labelStep = Math.max(1, Math.ceil(this.points.length / Math.max(2, Math.floor(drawWidth / 82))));
        for (let index = 0; index < this.points.length; index++) {
            const x = this.pointX(index);
            if (x < left - 6 || x > left + drawWidth + 6) continue;
            const y = this.pointY(index, top, drawHeight, maximum);
            this.context.fillStyle = resolvedLineColor;
            this.context.beginPath();
            this.context.arc(x, y, index === this.selected ? 5 : 2.8, 0, Math.PI * 2);
            this.context.fill();
            if (index === this.selected) {
                this.context.strokeStyle = this.rgba(resolvedLineColor, 0.28);
                this.context.lineWidth = 6;
                this.context.beginPath();
                this.context.arc(x, y, 7, 0, Math.PI * 2);
                this.context.stroke();
            }
            if (index % labelStep === 0 || index === this.points.length - 1) {
                this.context.fillStyle = textColor;
                this.context.textAlign = 'center';
                this.context.save();
                this.context.translate(x, height - 12);
                this.context.rotate(-Math.PI / 5);
                this.context.fillText(this.points[index].label, 0, 0);
                this.context.restore();
            }
        }
        if (this.selected >= 0 && this.selected < this.points.length) {
            const selectedX = this.pointX(this.selected);
            if (selectedX >= left && selectedX <= left + drawWidth) {
                this.context.strokeStyle = resolvedLineColor;
                this.context.lineWidth = 1;
                this.context.setLineDash([4, 4]);
                this.context.beginPath();
                this.context.moveTo(selectedX, top);
                this.context.lineTo(selectedX, top + drawHeight);
                this.context.stroke();
                this.context.setLineDash([]);
            }
        }
        this.context.restore();
    }

    build() {
        Column({ space: 10 }) {
            if (this.showTitle) {
                Text(this.title).fontSize(18).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).width('100%').accessibilityText(this.title)
            }
            if (this.points.length > 0) {
                Canvas(this.context)
                    .width('100%').height(this.chartHeight)
                    .onReady(() => {
                        this.canvasReady = true;
                        this.startEntranceAnimation();
                    })
                    .onAreaChange((_oldArea: Area, newArea: Area): void => {
                        const width = Number(newArea.width);
                        if (width > 0) {
                            this.canvasWidth = width;
                            this.panOffset = this.clampPan(this.panOffset);
                            setTimeout((): void => this.draw(), 0);
                        }
                    })
                    .onTouch((event: TouchEvent): void => {
                        if (event.touches.length > 0 && (event.type === TouchType.Down || event.type === TouchType.Move)) {
                            this.selectAt(event.touches[0].x);
                        }
                    })
                    .gesture(GestureGroup(GestureMode.Parallel,
                        PanGesture({ fingers: 1, direction: PanDirection.Horizontal })
                            .onActionStart((): void => { this.panAtGestureStart = this.panOffset; })
                            .onActionUpdate((event: GestureEvent): void => {
                                this.panOffset = this.clampPan(this.panAtGestureStart - event.offsetX);
                                this.draw();
                            }),
                        PinchGesture({ fingers: 2, distance: 4 })
                            .onActionStart((): void => { this.zoomAtGestureStart = this.zoom; })
                            .onActionUpdate((event: GestureEvent): void => {
                                const nextZoom = Math.max(1, Math.min(4, this.zoomAtGestureStart * event.scale));
                                const oldMax = this.maxPan(this.zoom);
                                const ratio = oldMax > 0 ? this.panOffset / oldMax : 0.5;
                                this.zoom = nextZoom;
                                this.panOffset = this.clampPan(this.maxPan(nextZoom) * ratio, nextZoom);
                                this.draw();
                            })
                    ))
                    .accessibilityText(`${this.title}折线图，默认显示全部横坐标，触摸查看数据，双指缩放，单指左右移动`)
                Text(this.points[Math.min(this.selected, this.points.length - 1)].detail).fontSize(14)
                    .fontColor($r('app.color.v3_text_secondary')).width('100%')
                    .accessibilityText(this.points[Math.min(this.selected, this.points.length - 1)].detail)
                Text('触摸查看数据 · 双指缩放 · 单指左右移动').fontSize(12)
                    .fontColor($r('app.color.v3_text_secondary')).width('100%')
                    .accessibilityText('图表操作说明，触摸查看数据，双指缩放，单指左右移动')
            } else {
                Text(`暂无${this.title}`).fontColor($r('app.color.v3_text_secondary')).padding(24)
                    .accessibilityText(`暂无${this.title}`)
            }
        }
        .width('100%').padding(14).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .accessibilityGroup(true)
        .accessibilityText(this.points.length > 0 ?
            `${this.title}，${this.points[Math.min(this.selected, this.points.length - 1)].detail}，触摸查看数据，双指缩放，单指左右移动` :
            `${this.title}暂无数据`)
    }
}
