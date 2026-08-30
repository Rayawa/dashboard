import { common } from '@kit.AbilityKit';
import { PromptAction } from '@kit.ArkUI';
import { CONTENT_MAX_WIDTH, RESPONSIVE_BREAKPOINT_LARGE, RESPONSIVE_BREAKPOINT_MEDIUM } from '../../common/constants';
import { setDetailTarget } from '../../common/appState';
import { fetchApiHistory, fetchAppsPage, fetchRatingDistribution, fetchSdkDistribution } from '../../common/MarketApi';
import { formatCount } from '../../common/format';
import { showToastSafely } from '../../common/safeUi';
import type { BaseAPIResponse, MarketApp, PageInfo, RatingDistribution } from '../../common/types';

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
    chart: DistributionChart = { title: '', labels: [], values: [], total: 1 };
    @State private selected: number = 0;

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

    build() {
        Column({ space: 12 }) {
            Text(this.chart.title)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary'))
                .width('100%')
                .accessibilityText(this.chart.title)
            if (this.chart.values.length > 0) {
                DataPanel({ values: this.chart.values, max: Math.max(this.chart.total, 1), type: DataPanelType.Circle })
                    .width(190)
                    .height(190)
                    .valueColors(this.colors())
                    .trackBackgroundColor($r('app.color.v3_surface_alt'))
                    .accessibilityText(`${this.chart.title}饼图，${this.selectedText()}`)
                Text(this.selectedText())
                    .fontSize(13)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .accessibilityText(this.selectedText())
                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
                    ForEach(this.chart.labels, (label: string, index: number) => {
                        Button(`${label} ${formatCount(this.chart.values[index])}`)
                            .fontSize(11)
                            .fontColor(index === this.selected ? $r('app.color.v3_surface') : $r('app.color.v3_text_primary'))
                            .backgroundColor(index === this.selected ? this.colors()[index % this.colors().length] : $r('app.color.v3_surface_alt'))
                            .height(34)
                            .margin(3)
                            .onClick(() => this.selected = index)
                            .accessibilityText(`查看${label}，数量${formatCount(this.chart.values[index])}`)
                    }, (label: string) => `${this.chart.title}-${label}`)
                }
                .width('100%')
                .accessibilityText(`${this.chart.title}图例`)
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
struct DownloadRankingPanel {
    title: string = '';
    apps: MarketApp[] = [];
    onOpen: (app: MarketApp) => void = () => {};

    private maxDownloads(): number {
        let max = 1;
        this.apps.forEach((app: MarketApp) => max = Math.max(max, app.download_count));
        return max;
    }

    private barWidth(app: MarketApp): string {
        return `${Math.max(4, app.download_count / this.maxDownloads() * 100)}%`;
    }

    build() {
        Column({ space: 10 }) {
            Text(this.title)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary'))
                .width('100%')
                .accessibilityText(this.title)
            ForEach(this.apps, (app: MarketApp, index: number) => {
                Column({ space: 5 }) {
                    Row({ space: 8 }) {
                        Text(`${index + 1}`)
                            .width(22)
                            .fontSize(12)
                            .fontWeight(FontWeight.Bold)
                            .fontColor($r('app.color.v3_accent_blue'))
                        Image(app.icon_url || $r('app.media.startIcon'))
                            .width(24)
                            .height(24)
                            .borderRadius(6)
                            .objectFit(ImageFit.Cover)
                            .alt($r('app.media.startIcon'))
                            .accessibilityText(`${app.name}应用图标`)
                        Text(app.name || '未知应用')
                            .fontSize(12)
                            .fontColor($r('app.color.v3_text_primary'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .layoutWeight(1)
                        Text(formatCount(app.download_count))
                            .fontSize(12)
                            .fontColor($r('app.color.v3_text_secondary'))
                    }
                    .width('100%')
                    Row() {
                        Row()
                            .height(5)
                            .width(this.barWidth(app))
                            .borderRadius(3)
                            .backgroundColor($r('app.color.v3_accent_cyan'))
                    }
                    .width('100%')
                    .height(5)
                    .borderRadius(3)
                    .backgroundColor($r('app.color.v3_chart_grid'))
                }
                .width('100%')
                .padding({ top: 4, bottom: 4 })
                .onClick(() => this.onOpen(app))
                .accessibilityGroup(true)
                .accessibilityText(`第${index + 1}名${app.name}，下载量${formatCount(app.download_count)}，点击查看详情`)
            }, (app: MarketApp) => `${this.title}-${app.app_id}`)
        }
        .width('100%')
        .padding(16)
        .borderRadius(18)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .accessibilityGroup(true)
        .accessibilityText(this.title)
    }
}

@Component
struct ApiHistoryChart {
    @Prop history: HistoryPoint[] = [];
    @Prop apiKeys: string[] = [];
    private settings: RenderingContextSettings = new RenderingContextSettings(true);
    private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
    @State private canvasWidth: number = 320;
    @State private canvasHeight: number = 210;
    @State private selectedApiIndex: number = 0;
    @State private selectedDateIndex: number = 0;

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
            console.warn('[Dashboard][pages/v3/OverviewPage][WARN]', `[overview] 图表颜色资源读取失败，使用内置配色: ${JSON.stringify(error)}`);
        }
        const left = 28;
        const top = 16;
        const right = 12;
        const bottom = 24;
        const drawWidth = Math.max(1, this.canvasWidth - left - right);
        const drawHeight = Math.max(1, this.canvasHeight - top - bottom);
        const values = this.history.map((point: HistoryPoint) => point.values[this.currentKey()] ?? 0);
        let maxValue = 1;
        values.forEach((value: number) => maxValue = Math.max(maxValue, value));
        this.canvasContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
        this.canvasContext.strokeStyle = gridColor;
        this.canvasContext.lineWidth = 1;
        for (let row = 0; row <= 4; row++) {
            const y = top + drawHeight / 4 * row;
            this.canvasContext.beginPath();
            this.canvasContext.moveTo(left, y);
            this.canvasContext.lineTo(left + drawWidth, y);
            this.canvasContext.stroke();
        }
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
                        this.selectedApiIndex = index;
                        setTimeout(() => this.draw(), 0);
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
                    setTimeout(() => this.draw(), 0);
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
export struct OverviewPage {
    @Consume('pageStack') private pageStack: NavPathStack;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    @State private loading: boolean = false;
    @State private loaded: boolean = false;
    @State private fromCache: boolean = false;
    @State private ratingChart: DistributionChart = { title: '应用评分分布', labels: [], values: [], total: 1 };
    @State private minSdkChart: DistributionChart = { title: '最低 SDK 分布', labels: [], values: [], total: 1 };
    @State private targetSdkChart: DistributionChart = { title: '目标 SDK 分布', labels: [], values: [], total: 1 };
    @State private history: HistoryPoint[] = [];
    @State private apiKeys: string[] = [];
    @State private topApps: MarketApp[] = [];
    @State private nonHuaweiApps: MarketApp[] = [];

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
        Promise.all([
            fetchRatingDistribution(force),
            fetchSdkDistribution('min_sdk', force),
            fetchSdkDistribution('target_sdk', force),
            fetchApiHistory(force),
            fetchAppsPage(1, 10, 'download_count', true, undefined, undefined, false, force, false),
            fetchAppsPage(1, 10, 'download_count', true, undefined, undefined, false, force, true),
        ]).then((results) => {
            const ratingResponse = results[0].data as BaseAPIResponse<RatingDistribution>;
            const rating = ratingResponse.data;
            const ratingValues = [rating.star_1, rating.star_2, rating.star_3, rating.star_4, rating.star_5];
            this.ratingChart = {
                title: '应用评分分布',
                labels: ['无评分', '[1–2) 星', '[2–3) 星', '[3–4) 星', '[4–5] 星'],
                values: ratingValues,
                total: ratingValues.reduce((sum: number, value: number) => sum + value, 0),
            };
            this.minSdkChart = this.distribution('最低 SDK 分布', results[1].data.data as number[][]);
            this.targetSdkChart = this.distribution('目标 SDK 分布', results[2].data.data as number[][]);
            const rawHistory = results[3].data.data as object[];
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
            const topResponse = results[4].data as BaseAPIResponse<PageInfo<MarketApp>>;
            const nonHuaweiResponse = results[5].data as BaseAPIResponse<PageInfo<MarketApp>>;
            this.topApps = topResponse.data.data ?? [];
            this.nonHuaweiApps = nonHuaweiResponse.data.data ?? [];
            this.fromCache = results.some((item) => item.stale);
            this.loaded = true;
        }).catch((error: Error) => {
            console.error('[Dashboard][pages/v3/OverviewPage][ERROR]', `图表加载失败: ${error.message}`);
            showToastSafely(this.prompt, `图表加载失败：${error.message}`, 2500, 'V3Overview');
        }).finally(() => this.loading = false);
    }

    build() {
        Scroll() {
            Column({ space: 14 }) {
                Row() {
                    Column({ space: 4 }) {
                        Text('应用概况')
                            .fontSize(26)
                            .fontWeight(FontWeight.Bold)
                            .fontColor($r('app.color.v3_text_primary'))
                            .accessibilityText('应用概况')
                        Text('点击图例、选择 API 或拖动时间轴查看详细数据')
                            .fontSize(13)
                            .fontColor($r('app.color.v3_text_secondary'))
                            .accessibilityText('图表支持点击图例选择API和拖动时间轴交互')
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    Button('刷新')
                        .backgroundColor($r('app.color.v3_accent_blue'))
                        .enabled(!this.loading)
                        .onClick(() => this.load(true))
                        .accessibilityText(this.loading ? '图表正在刷新' : '刷新全部图表')
                }
                .width('100%')
                .padding({ top: 20, left: 4, right: 4 })

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

                GridRow({
                    columns: { xs: 4, sm: 8, md: 12 },
                    gutter: { x: 12, y: 12 },
                    breakpoints: {
                        value: [RESPONSIVE_BREAKPOINT_MEDIUM, RESPONSIVE_BREAKPOINT_LARGE],
                        reference: BreakpointsReference.WindowSize,
                    },
                }) {
                    GridCol({ span: { xs: 4, sm: 4, md: 6 } }) {
                        DownloadRankingPanel({
                            title: '总下载榜',
                            apps: this.topApps,
                            onOpen: (app: MarketApp) => this.openDetail(app),
                        })
                    }
                    GridCol({ span: { xs: 4, sm: 4, md: 6 } }) {
                        DownloadRankingPanel({
                            title: '非华为应用下载榜',
                            apps: this.nonHuaweiApps,
                            onOpen: (app: MarketApp) => this.openDetail(app),
                        })
                    }
                }
                .width('100%')
                .accessibilityText('应用下载排行榜')

                Blank().height(96)
            }
            .width('100%')
            .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
            .padding({ left: 14, right: 14 })
            .onAppear(() => {
                if (!this.loaded) {
                    this.load(false);
                }
            })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.background'))
        .accessibilityText('应用概况页面')
    }

    private openDetail(app: MarketApp): void {
        setDetailTarget({ appId: app.app_id, packageName: app.pkg_name });
        this.pageStack.pushPathByName('AppDetailPage', null);
    }
}
