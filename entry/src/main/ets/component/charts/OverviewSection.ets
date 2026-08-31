import { RESPONSIVE_BREAKPOINT_LARGE, RESPONSIVE_BREAKPOINT_MEDIUM } from '../../common/constants';
import { fetchApiHistory, fetchRatingDistribution, fetchSdkDistribution } from '../../common/MarketApi';
import { formatCount } from '../../common/format';
import { vibration } from '../../common/vibration';
import type { BaseAPIResponse, RatingDistribution } from '../../common/types';
import { InteractiveLineChart } from './InteractiveLineChart';
import type { LineChartPoint } from './InteractiveLineChart';

interface DistributionChart { title: string; labels: string[]; values: number[]; total: number; }
interface HistoryPoint { date: string; values: Record<string, number>; }

@Component
struct DistributionPanel {
    @Prop @Watch('onChartChanged') chart: DistributionChart = { title: '', labels: [], values: [], total: 1 };
    @State private selected: number = 0;
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;

    private onChartChanged(): void { this.selected = 0; }
    private colors(): ResourceColor[] {
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
    private maximum(): number {
        let maximum = 1;
        for (const value of this.chart.values) maximum = Math.max(maximum, value);
        return maximum;
    }
    private barWidth(value: number): string { return `${Math.max(2, value / this.maximum() * 100)}%`; }

    build() {
        Column({ space: 12 }) {
            Text(this.chart.title).fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary')).width('100%').accessibilityText(this.chart.title)
            if (this.chart.values.length > 0) {
                Column({ space: 10 }) {
                    ForEach(this.chart.labels, (label: string, index: number) => {
                        Column({ space: 5 }) {
                            Row() {
                                Text(label).fontSize(14).fontColor($r('app.color.v3_text_secondary')).layoutWeight(1)
                                Text(formatCount(this.chart.values[index])).fontSize(14)
                                    .fontColor($r('app.color.v3_text_primary'))
                            }.width('100%')
                            Row() {
                                Row().width(this.barWidth(this.chart.values[index])).height(11).borderRadius(6)
                                    .backgroundColor(this.colors()[index % this.colors().length])
                            }
                            .width('100%').height(12)
                            .border({ width: { left: 1, bottom: 1 }, color: $r('app.color.v3_chart_grid') })
                        }
                        .width('100%').padding({ top: 2, bottom: 2 })
                        .onClick(() => {
                            if (this.vibrationEnabled) vibration.dotVibration();
                            this.selected = index;
                        })
                        .accessibilityText(`${label}，数量${formatCount(this.chart.values[index])}`)
                    }, (label: string) => `${this.chart.title}-${label}`)
                }.width('100%').accessibilityText(`${this.chart.title}分布图，触摸柱形查看数据`)
                Text(this.selectedText()).fontSize(14).fontColor($r('app.color.v3_text_secondary'))
                    .accessibilityText(this.selectedText())
            } else {
                Text('暂无数据').fontColor($r('app.color.v3_text_secondary')).padding(30)
                    .accessibilityText(`${this.chart.title}暂无数据`)
            }
        }
        .width('100%').padding(16).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .accessibilityGroup(true).accessibilityText(`${this.chart.title}，${this.selectedText()}`)
    }
}

@Component
struct ApiHistoryChart {
    @Prop history: HistoryPoint[] = [];
    @Prop apiKeys: string[] = [];
    @State private selectedApiIndex: number = 0;
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;

    private options(): SelectOption[] {
        return this.apiKeys.map((key: string) => ({ value: `API ${key}` } as SelectOption));
    }
    private currentKey(): string { return this.apiKeys[this.selectedApiIndex] ?? ''; }
    private points(): LineChartPoint[] {
        const key = this.currentKey();
        return this.history.map((point: HistoryPoint) => {
            const value = point.values[key] ?? 0;
            return { label: point.date, value, detail: `${point.date} · API ${key} 占比 ${value.toFixed(2)}%` };
        });
    }

    build() {
        Column({ space: 12 }) {
            Row() {
                Text('Harmony API 版本占比历史').fontSize(18).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).layoutWeight(1)
                if (this.apiKeys.length > 0) {
                    Select(this.options()).selected(this.selectedApiIndex).value(`API ${this.currentKey()}`)
                        .backgroundColor($r('app.color.v3_surface_alt'))
                        .onSelect((index: number) => {
                            if (this.vibrationEnabled) vibration.dotVibration();
                            this.selectedApiIndex = index;
                        })
                        .accessibilityText('选择要查看的Harmony API版本')
                }
            }.width('100%')
            InteractiveLineChart({
                title: 'Harmony API版本占比历史', unit: '%', points: this.points(),
                lineColor: $r('app.color.diff_content'), showTitle: false,
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
            this.apiKeys = next.length > 0 ? Object.keys(next[next.length - 1].values)
                .sort((a: string, b: string) => Number(a) - Number(b)) : [];
            this.fromCache = this.fromCache || result.stale;
        }).catch((error: Error) => this.failed('Harmony API 历史', error)).finally(() => this.finish());
    }

    build() {
        Column({ space: 14 }) {
            Text('触摸图表查看数据；折线图支持双指缩放和单指左右移动').fontSize(13)
                .fontColor($r('app.color.v3_text_secondary')).width('100%')
                .accessibilityText('图表支持触摸查看数据，折线图支持双指缩放和单指左右移动')
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
