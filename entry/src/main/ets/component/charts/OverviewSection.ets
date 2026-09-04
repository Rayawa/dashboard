import { common } from '@kit.AbilityKit';
import { RESPONSIVE_BREAKPOINT_LARGE, RESPONSIVE_BREAKPOINT_MEDIUM } from '../../common/constants';
import { fetchApiHistory, fetchRatingDistribution, fetchSdkDistribution } from '../../common/MarketApi';
import { formatCount } from '../../common/format';
import { vibration } from '../../common/vibration';
import type { BaseAPIResponse, RatingDistribution } from '../../common/types';
import { InteractiveLineChart } from './InteractiveLineChart';
import type { LineChartPoint, LineChartSeries } from './InteractiveLineChart';

interface DistributionChart { title: string; labels: string[]; values: number[]; total: number; }
interface HistoryPoint { date: string; values: Record<string, number>; }

@Component
struct DistributionPanel {
    @Prop @Watch('onChartChanged') chart: DistributionChart = { title: '', labels: [], values: [], total: 1 };
    @State private selected: number = 0;
    @State private canvasSize: number = 220;
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;
    private settings: RenderingContextSettings = new RenderingContextSettings(true);
    private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
    private canvasReady: boolean = false;
    private drawProgress: number = 1;
    private animationToken: number = 0;

    private onChartChanged(): void {
        this.selected = 0;
        setTimeout((): void => this.animatePie(), 0);
    }
    private animatePie(): void {
        if (!this.canvasReady || this.chart.total <= 0) {
            this.draw();
            return;
        }
        const token = ++this.animationToken;
        const startedAt = Date.now();
        this.drawProgress = 0;
        const tick = (): void => {
            if (token !== this.animationToken) return;
            const elapsed = Math.min(1, (Date.now() - startedAt) / 700);
            this.drawProgress = 1 - Math.pow(1 - elapsed, 3);
            this.draw();
            if (elapsed < 1) setTimeout(tick, 16);
        };
        tick();
    }
    private colors(): Resource[] {
        return [
            $r('app.color.diff_content'), $r('app.color.v3_accent_cyan'), $r('app.color.v3_accent_green'),
            $r('app.color.v3_accent_orange'), $r('app.color.v3_accent_red'), $r('app.color.v3_accent_purple'),
        ];
    }
    private selectedText(): string {
        if (this.chart.labels.length === 0) return '暂无数据';
        const value = this.chart.values[this.selected] ?? 0;
        const percent = this.chart.total > 0 ? value / this.chart.total * 100 : 0;
        return `${this.chart.labels[this.selected]}：${formatCount(value)}，${percent.toFixed(1)}%`;
    }

    private legendText(index: number): string {
        const value = this.chart.values[index] ?? 0;
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

    private draw(): void {
        const size = this.canvasSize;
        this.context.clearRect(0, 0, size, size);
        if (this.chart.total <= 0 || this.chart.values.length === 0) return;
        const colors = this.colors();
        const center = size / 2;
        const radius = Math.max(20, center - 12);
        let startAngle = -Math.PI / 2;
        const surfaceColor = this.resolvedColor($r('app.color.v3_surface'));
        for (let index = 0; index < this.chart.values.length; index++) {
            const sweep = Math.PI * 2 * this.chart.values[index] / this.chart.total * this.drawProgress;
            const endAngle = startAngle + sweep;
            this.context.beginPath();
            this.context.moveTo(center, center);
            this.context.arc(center, center, radius, startAngle, endAngle);
            this.context.closePath();
            this.context.fillStyle = this.resolvedColor(colors[index % colors.length]);
            this.context.fill();
            this.context.strokeStyle = surfaceColor;
            this.context.lineWidth = 2;
            this.context.stroke();
            if (index === this.selected && this.drawProgress >= 1) {
                this.context.beginPath();
                this.context.arc(center, center, radius + 4, startAngle, endAngle);
                this.context.strokeStyle = this.resolvedColor(colors[index % colors.length]);
                this.context.lineWidth = 4;
                this.context.stroke();
            }
            startAngle = endAngle;
        }
    }

    private selectAt(x: number, y: number): void {
        if (this.chart.total <= 0) return;
        const center = this.canvasSize / 2;
        const dx = x - center;
        const dy = y - center;
        if (Math.sqrt(dx * dx + dy * dy) > center) return;
        let angle = Math.atan2(dy, dx) + Math.PI / 2;
        if (angle < 0) angle += Math.PI * 2;
        let accumulated = 0;
        for (let index = 0; index < this.chart.values.length; index++) {
            accumulated += Math.PI * 2 * this.chart.values[index] / this.chart.total;
            if (angle <= accumulated) {
                if (index !== this.selected && this.vibrationEnabled) vibration.dotVibration();
                this.selected = index;
                this.draw();
                return;
            }
        }
    }

    aboutToDisappear(): void {
        this.animationToken++;
    }

    build() {
        Column({ space: 12 }) {
            Text(this.chart.title).fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary')).width('100%').accessibilityText(this.chart.title)
            if (this.chart.values.length > 0) {
                Canvas(this.context)
                    .width(this.canvasSize).height(this.canvasSize).align(Alignment.Center)
                    .onReady((): void => {
                        this.canvasReady = true;
                        this.animatePie();
                    })
                    .onTouch((event: TouchEvent): void => {
                        if (event.type === TouchType.Down && event.touches.length > 0) {
                            this.selectAt(event.touches[0].x, event.touches[0].y);
                        }
                    })
                    .accessibilityText(`${this.chart.title}饼图，点一下扇区可以查看具体数据`)
                GridRow({ columns: 2, gutter: { x: 8, y: 8 } }) {
                    ForEach(this.chart.labels, (label: string, index: number) => {
                        GridCol({ span: 1 }) {
                            Row({ space: 7 }) {
                                Row().width(10).height(10).borderRadius(5)
                                    .backgroundColor(this.colors()[index % this.colors().length])
                                Column({ space: 2 }) {
                                    Text(label).fontSize(14).fontWeight(FontWeight.Medium)
                                        .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                                    Text(this.legendText(index)).fontSize(12)
                                        .fontColor($r('app.color.v3_text_secondary')).maxLines(1)
                                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                            }
                            .width('100%').padding(8).borderRadius(10)
                            .backgroundColor(index === this.selected ?
                                $r('app.color.v3_surface_alt') : Color.Transparent)
                            .onClick(() => {
                                if (this.vibrationEnabled) vibration.dotVibration();
                                this.selected = index;
                                this.draw();
                            })
                            .accessibilityText(`${label}，${this.legendText(index)}`)
                        }
                    }, (label: string) => `${this.chart.title}-${label}`)
                }.width('100%').accessibilityText(`${this.chart.title}图例`)
                Text(this.selectedText()).fontSize(15).fontColor($r('app.color.v3_text_secondary'))
                    .accessibilityText(this.selectedText())
            } else {
                Text('暂无数据').fontColor($r('app.color.v3_text_secondary')).padding(30)
                    .accessibilityText(`${this.chart.title}暂无数据`)
            }
        }
        .width('100%').padding(16).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .onAreaChange((_oldArea: Area, area: Area): void => {
            const width = Number(area.width);
            if (width > 0) {
                this.canvasSize = Math.max(176, Math.min(232, width - 48));
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

    private palette(): Resource[] {
        return [
            $r('app.color.diff_content'),
            $r('app.color.v3_accent_cyan'),
            $r('app.color.v3_accent_green'),
            $r('app.color.v3_accent_orange'),
            $r('app.color.v3_accent_red'),
            $r('app.color.v3_accent_purple'),
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
    private pendingLoads: number = 0;
    private reloadAfterCurrent: boolean = false;

    private onRefreshVersionChanged(): void { if (this.refreshVersion > 0) this.load(true); }
    private distribution(title: string, source: number[][]): DistributionChart {
        const sorted = source.slice().sort((a: number[], b: number[]) => b[1] - a[1]);
        const visible = sorted.slice(0, 7);
        if (sorted.length > 7) {
            visible.push([-1, sorted.slice(7).reduce((sum: number, item: number[]) => sum + Number(item[1]), 0)]);
        }
        const values = visible.map((item: number[]) => Number(item[1]));
        return {
            title, labels: visible.map((item: number[]) => item[0] === -1 ? '其他' : `API ${item[0]}`), values,
            total: values.reduce((sum: number, value: number) => sum + value, 0),
        };
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
            const values = [rating.star_1, rating.star_2, rating.star_3, rating.star_4, rating.star_5];
            this.ratingChart = { title: '应用评分分布', labels: ['1 星', '2 星', '3 星', '4 星', '5 星'],
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
            this.apiKeys = Object.keys(discovered).sort((a: string, b: string) => Number(a) - Number(b));
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
            GridRow({
                columns: { xs: 4, sm: 8, md: 12 }, gutter: { x: 12, y: 12 },
                breakpoints: { value: [RESPONSIVE_BREAKPOINT_MEDIUM, RESPONSIVE_BREAKPOINT_LARGE],
                    reference: BreakpointsReference.WindowSize },
            }) {
                GridCol({ span: { xs: 4, sm: 4, md: 4 } }) { DistributionPanel({ chart: this.ratingChart }) }
                GridCol({ span: { xs: 4, sm: 4, md: 4 } }) { DistributionPanel({ chart: this.targetSdkChart }) }
                GridCol({ span: { xs: 4, sm: 8, md: 4 } }) { DistributionPanel({ chart: this.minSdkChart }) }
            }.width('100%').accessibilityText('三个分布图表')
            ApiHistoryChart({ history: this.history, apiKeys: this.apiKeys })
        }
        .width('100%').onAppear(() => { if (!this.loaded) this.load(false); })
        .accessibilityText('应用概况页面')
    }
}
