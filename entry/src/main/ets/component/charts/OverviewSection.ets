import { common } from '@kit.AbilityKit';
import { RESPONSIVE_BREAKPOINT_LARGE, RESPONSIVE_BREAKPOINT_MEDIUM } from '../../common/constants';
import { fetchApiHistory, fetchRatingDistribution, fetchSdkDistribution } from '../../common/MarketApi';
import { formatCount } from '../../common/format';
import { vibration } from '../../common/vibration';
import type { BaseAPIResponse, RatingDistribution } from '../../common/types';

interface DistributionChart {
    title: string;
    labels: string[];
    values: number[];
    total: number;
}

interface HistoryPoint {
    date: string;
    values: Record<string, number>;
}

@Component
struct DistributionPanel {
    @Prop @Watch('onChartChanged') chart: DistributionChart = { title: '', labels: [], values: [], total: 1 };
    @State private selected: number = 0;
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;

    private onChartChanged(): void {
        this.selected = 0;
    }

    private colors(): ResourceColor[] {
        return [
            $r('app.color.v3_accent_blue'),
            $r('app.color.v3_accent_cyan'),
            $r('app.color.v3_accent_green'),
            $r('app.color.v3_accent_orange'),
            $r('app.color.v3_accent_red'),
            $r('app.color.v3_accent_purple'),
        ];
    }

    private selectedText(): string {
        if (this.chart.labels.length === 0) {
            return '暂无数据';
        }
        const value = this.chart.values[this.selected] ?? 0;
        const percent = this.chart.total > 0 ? value / this.chart.total * 100 : 0;
        return `${this.chart.labels[this.selected]}：${formatCount(value)}，${percent.toFixed(1)}%`;
    }

    private maximum(): number {
        let maximum = 1;
        this.chart.values.forEach((value: number) => maximum = Math.max(maximum, value));
        return maximum;
    }

    private barWidth(value: number): string {
        return `${Math.max(2, value / this.maximum() * 100)}%`;
    }

    build() {
        Column({ space: 12 }) {
            Text(this.chart.title)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary'))
                .width('100%')
                .accessibilityText(this.chart.title)
            if (this.chart.values.length > 0) {
                Column({ space: 9 }) {
                    ForEach(this.chart.labels, (label: string, index: number) => {
                        Column({ space: 4 }) {
                            Row() {
                                Text(label)
                                    .fontSize(11)
                                    .fontColor($r('app.color.v3_text_secondary'))
                                    .layoutWeight(1)
                                Text(formatCount(this.chart.values[index]))
                                    .fontSize(11)
                                    .fontColor($r('app.color.v3_text_primary'))
                            }
                            .width('100%')
                            Row() {
                                Row()
                                    .width(this.barWidth(this.chart.values[index]))
                                    .height(9)
                                    .borderRadius(5)
                                    .backgroundColor(this.colors()[index % this.colors().length])
                            }
                            .width('100%')
                            .height(10)
                            .border({ width: { left: 1, bottom: 1 }, color: $r('app.color.v3_chart_grid') })
                        }
                        .width('100%')
                        .padding({ top: 2, bottom: 2 })
                        .onClick(() => {
                            if (this.vibrationEnabled) vibration.dotVibration();
                            this.selected = index;
                        })
                        .accessibilityText(`${label}，数量${formatCount(this.chart.values[index])}`)
                    }, (label: string) => `${this.chart.title}-${label}`)
                }
                .width('100%')
                .accessibilityText(`${this.chart.title}柱状图，带横轴和纵轴`)
                Text(this.selectedText())
                    .fontSize(13)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .accessibilityText(this.selectedText())
            } else {
                Text('暂无数据')
                    .fontColor($r('app.color.v3_text_secondary'))
                    .padding(30)
                    .accessibilityText(`${this.chart.title}暂无数据`)
            }
        }
        .width('100%')
        .padding(16)
        .borderRadius(18)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .accessibilityGroup(true)
        .accessibilityText(this.chart.title)
    }
}

@Component
struct ApiHistoryChart {
    @Prop @Watch('onDataChanged') history: HistoryPoint[] = [];
    @Prop @Watch('onDataChanged') apiKeys: string[] = [];
    private settings: RenderingContextSettings = new RenderingContextSettings(true);
    private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
    @State private canvasWidth: number = 320;
    @State private canvasHeight: number = 210;
    @State private selectedApiIndex: number = 0;
    @State private selectedDateIndex: number = 0;
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;

    private onDataChanged(): void {
        this.selectedApiIndex = Math.min(this.selectedApiIndex, Math.max(0, this.apiKeys.length - 1));
        this.selectedDateIndex = Math.min(this.selectedDateIndex, Math.max(0, this.history.length - 1));
        setTimeout((): void => this.draw(), 0);
    }

    private options(): SelectOption[] {
        return this.apiKeys.map((key: string) => ({ value: `API ${key}` } as SelectOption));
    }

    private currentKey(): string {
        return this.apiKeys[this.selectedApiIndex] ?? '';
    }

    private currentValue(): string {
        if (this.history.length === 0) {
            return '暂无数据';
        }
        const point = this.history[Math.min(this.selectedDateIndex, this.history.length - 1)];
        const value = point.values[this.currentKey()] ?? 0;
        return `${point.date} · API ${this.currentKey()} 占比 ${value.toFixed(2)}%`;
    }

    private draw(): void {
        this.canvasContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
        if (this.history.length < 2 || this.currentKey() === '') {
            return;
        }
        const host = this.getUIContext().getHostContext() as common.UIAbilityContext;
        let lineColor: number = 0xFF2F80ED;
        let gridColor: number = 0x332F80ED;
        try {
            lineColor = host.resourceManager.getColorSync($r('app.color.v3_accent_blue').id);
            gridColor = host.resourceManager.getColorSync($r('app.color.v3_chart_grid').id);
        } catch (error) {
            console.warn('[Dashboard][component/charts/OverviewSection][WARN]', `图表颜色资源读取失败，使用内置配色: ${JSON.stringify(error)}`);
        }
        let textColor: number = 0xFF666666;
        try {
            textColor = host.resourceManager.getColorSync($r('app.color.v3_text_secondary').id);
        } catch (_error) {
        }
        const left = 48;
        const top = 16;
        const right = 12;
        const bottom = 24;
        const drawWidth = Math.max(1, this.canvasWidth - left - right);
        const drawHeight = Math.max(1, this.canvasHeight - top - bottom);
        const values = this.history.map((point: HistoryPoint) => point.values[this.currentKey()] ?? 0);
        let maxValue = 1;
        values.forEach((value: number) => maxValue = Math.max(maxValue, value));
        this.canvasContext.strokeStyle = gridColor;
        this.canvasContext.lineWidth = 1;
        for (let row = 0; row <= 4; row++) {
            const y = top + drawHeight / 4 * row;
            this.canvasContext.beginPath();
            this.canvasContext.moveTo(left, y);
            this.canvasContext.lineTo(left + drawWidth, y);
            this.canvasContext.stroke();
            this.canvasContext.fillStyle = textColor;
            this.canvasContext.font = '10px sans-serif';
            this.canvasContext.textAlign = 'right';
            this.canvasContext.fillText(`${(maxValue * (4 - row) / 4).toFixed(1)}%`, left - 6, y + 3);
        }
        this.canvasContext.beginPath();
        this.canvasContext.moveTo(left, top);
        this.canvasContext.lineTo(left, top + drawHeight);
        this.canvasContext.lineTo(left + drawWidth, top + drawHeight);
        this.canvasContext.stroke();
        this.canvasContext.strokeStyle = lineColor;
        this.canvasContext.lineWidth = 3;
        this.canvasContext.beginPath();
        values.forEach((value: number, index: number) => {
            const x = left + drawWidth * index / Math.max(1, values.length - 1);
            const y = top + drawHeight * (1 - value / maxValue);
            if (index === 0) {
                this.canvasContext.moveTo(x, y);
            } else {
                this.canvasContext.lineTo(x, y);
            }
        });
        this.canvasContext.stroke();
        this.canvasContext.fillStyle = textColor;
        this.canvasContext.textAlign = 'left';
        this.canvasContext.fillText(this.history[0].date, left, this.canvasHeight - 5);
        this.canvasContext.textAlign = 'right';
        this.canvasContext.fillText(this.history[this.history.length - 1].date, this.canvasWidth - right, this.canvasHeight - 5);
    }

    build() {
        Column({ space: 12 }) {
            Row() {
                Text('Harmony API 版本占比历史')
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary'))
                    .layoutWeight(1)
                    .accessibilityText('Harmony API版本占比历史折线图')
                Select(this.options())
                    .selected(this.selectedApiIndex)
                    .value(`API ${this.currentKey()}`)
                    .backgroundColor($r('app.color.v3_surface_alt'))
                    .onSelect((index: number) => {
                        if (this.vibrationEnabled) vibration.dotVibration();
                        this.selectedApiIndex = index;
                        setTimeout((): void => {
                            this.draw();
                        }, 0);
                    })
                    .accessibilityText('选择要查看的Harmony API版本')
            }
            .width('100%')

            Canvas(this.canvasContext)
                .width('100%')
                .height(210)
                .onReady(() => this.draw())
                .onAreaChange((oldArea: Area, newArea: Area) => {
                    this.canvasWidth = Number(newArea.width);
                    this.canvasHeight = Number(newArea.height);
                    setTimeout((): void => {
                        this.draw();
                    }, 0);
                })
                .accessibilityText(`API历史折线图，${this.currentValue()}`)

            if (this.history.length > 0) {
                Slider({
                    value: this.selectedDateIndex,
                    min: 0,
                    max: Math.max(0, this.history.length - 1),
                    step: 1,
                    style: SliderStyle.InSet,
                })
                    .selectedColor($r('app.color.v3_accent_blue'))
                    .trackColor($r('app.color.v3_chart_grid'))
                    .onChange((value: number) => this.selectedDateIndex = Math.round(value))
                    .accessibilityText('拖动查看不同日期的API占比')
                Text(this.currentValue())
                    .fontSize(13)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .accessibilityText(this.currentValue())
            }
        }
        .width('100%')
        .padding(16)
        .borderRadius(18)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .accessibilityGroup(true)
        .accessibilityText('Harmony API版本占比历史')
    }
}

@Component
export struct OverviewSection {
    @Prop @Watch('onRefreshVersionChanged') refreshVersion: number = 0;
    @State private loading: boolean = false;
    @State private loaded: boolean = false;
    @State private fromCache: boolean = false;
    @State private ratingChart: DistributionChart = { title: '应用评分分布', labels: [], values: [], total: 1 };
    @State private minSdkChart: DistributionChart = { title: '最低 SDK 分布', labels: [], values: [], total: 1 };
    @State private targetSdkChart: DistributionChart = { title: '目标 SDK 分布', labels: [], values: [], total: 1 };
    @State private history: HistoryPoint[] = [];
    @State private apiKeys: string[] = [];

    private onRefreshVersionChanged(): void {
        if (this.refreshVersion > 0) {
            this.load(true);
        }
    }
    private pendingLoads: number = 0;
    private failedLoads: number = 0;

    private distribution(title: string, source: number[][]): DistributionChart {
        const sorted = source.slice().sort((a: number[], b: number[]) => b[1] - a[1]);
        const visible = sorted.slice(0, 7);
        if (sorted.length > 7) {
            const other = sorted.slice(7).reduce((sum: number, item: number[]) => sum + Number(item[1]), 0);
            visible.push([-1, other]);
        }
        const values = visible.map((item: number[]) => Number(item[1]));
        return {
            title,
            labels: visible.map((item: number[]) => item[0] === -1 ? '其他' : `API ${item[0]}`),
            values,
            total: values.reduce((sum: number, value: number) => sum + value, 0),
        };
    }

    private load(force: boolean): void {
        if (this.loading) {
            return;
        }
        this.loading = true;
        this.fromCache = false;
        this.pendingLoads = 4;
        this.failedLoads = 0;
        const finish = (): void => {
            this.pendingLoads--;
            if (this.pendingLoads <= 0) {
                this.loading = false;
                this.loaded = true;
            }
        };
        const failed = (name: string, error: Error): void => {
            this.failedLoads++;
            console.error('[Dashboard][component/charts/OverviewSection][ERROR]', `${name}加载失败: ${error.message}`);
        };

        fetchRatingDistribution(force).then((result) => {
            const ratingResponse = result.data as BaseAPIResponse<RatingDistribution>;
            if (!ratingResponse.success || !ratingResponse.data) {
                throw new Error('评分接口未返回有效数据');
            }
            const rating = ratingResponse.data;
            const ratingValues = [rating.star_1, rating.star_2, rating.star_3, rating.star_4, rating.star_5];
            this.ratingChart = {
                title: '应用评分分布',
                labels: ['1 星', '2 星', '3 星', '4 星', '5 星'],
                values: ratingValues,
                total: ratingValues.reduce((sum: number, value: number) => sum + value, 0),
            };
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => failed('评分分布', error)).finally(() => finish());

        fetchSdkDistribution('min_sdk', force).then((result) => {
            if (!result.data.success || !result.data.data) {
                throw new Error('最低 SDK 接口未返回有效数据');
            }
            this.minSdkChart = this.distribution('最低 SDK 分布', result.data.data as number[][]);
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => failed('最低 SDK 分布', error)).finally(() => finish());

        fetchSdkDistribution('target_sdk', force).then((result) => {
            if (!result.data.success || !result.data.data) {
                throw new Error('目标 SDK 接口未返回有效数据');
            }
            this.targetSdkChart = this.distribution('目标 SDK 分布', result.data.data as number[][]);
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => failed('目标 SDK 分布', error)).finally(() => finish());

        fetchApiHistory(force).then((result) => {
            if (!result.data.success || !result.data.data) {
                throw new Error('API 历史接口未返回有效数据');
            }
            const rawHistory = result.data.data as object[];
            const history: HistoryPoint[] = [];
            rawHistory.forEach((raw: object) => {
                const tuple = raw as object[];
                if (tuple.length >= 2) {
                    history.push({ date: String(tuple[0]), values: tuple[1] as Record<string, number> });
                }
            });
            this.history = history;
            if (history.length > 0) {
                this.apiKeys = Object.keys(history[history.length - 1].values).sort((a: string, b: string) => Number(a) - Number(b));
            }
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => failed('Harmony API 历史', error)).finally(() => finish());

    }

    build() {
        Column({ space: 14 }) {
                Column({ space: 4 }) {
                    Text('点击柱形、选择 API 或拖动时间轴查看详细数据')
                        .fontSize(13)
                        .fontColor($r('app.color.v3_text_secondary'))
                        .accessibilityText('图表支持点击图例选择API和拖动时间轴交互')
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .padding({ top: 12, left: 4, right: 4 })

                if (this.fromCache) {
                    Text('网络不可用，当前图表来自本地离线缓存')
                        .fontSize(13)
                        .fontColor($r('app.color.v3_text_primary'))
                        .padding(12)
                        .width('100%')
                        .borderRadius(12)
                        .backgroundColor($r('app.color.v3_warning_bg'))
                        .accessibilityText('网络不可用，当前图表来自本地离线缓存')
                }

                if (this.loading && !this.loaded) {
                    LoadingProgress()
                        .width(34)
                        .height(34)
                        .color($r('app.color.v3_accent_blue'))
                        .margin(50)
                        .accessibilityText('应用概况图表加载中')
                }

                GridRow({
                    columns: { xs: 4, sm: 8, md: 12 },
                    gutter: { x: 12, y: 12 },
                    breakpoints: {
                        value: [RESPONSIVE_BREAKPOINT_MEDIUM, RESPONSIVE_BREAKPOINT_LARGE],
                        reference: BreakpointsReference.WindowSize,
                    },
                }) {
                    GridCol({ span: { xs: 4, sm: 4, md: 4 } }) {
                        DistributionPanel({ chart: this.ratingChart })
                    }
                    GridCol({ span: { xs: 4, sm: 4, md: 4 } }) {
                        DistributionPanel({ chart: this.targetSdkChart })
                    }
                    GridCol({ span: { xs: 4, sm: 8, md: 4 } }) {
                        DistributionPanel({ chart: this.minSdkChart })
                    }
                }
                .width('100%')
                .accessibilityText('三个分布图表')

                ApiHistoryChart({ history: this.history, apiKeys: this.apiKeys })

        }
        .width('100%')
        .onAppear(() => {
            if (!this.loaded) {
                this.load(false);
            }
        })
        .accessibilityText('应用概况页面')
    }
}
