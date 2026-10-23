import type { ChartViewportState } from '../../common/types';
import { sdkDataLabel } from '../../common/SdkData';
import { InteractiveLineChart } from './InteractiveLineChart';
import type { LineChartPoint, LineChartSeries } from './InteractiveLineChart';

export interface HistoryPoint { date: string; values: Record<string, number>; }

@Component
export struct ApiHistoryChart {
    @Prop @Watch('prepareSeries') history: HistoryPoint[] = [];
    @Prop @Watch('prepareSeries') apiKeys: string[] = [];
    @Prop viewport: ChartViewportState = { zoom: 1, panRatio: 0 };
    onViewportChange?: (viewport: ChartViewportState) => void;

    @Prop active: boolean = true;
    @State private preparedSeries: LineChartSeries[] = [];
    aboutToAppear(): void { this.prepareSeries(); }

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

    private prepareSeries(): void {
        const colors = this.palette();
        // All series use the same dates so cross-series selection stays aligned.
        const count = Math.min(360, this.history.length);
        const history: HistoryPoint[] = [];
        for (let i = 0; i < count; i++) {
            history.push(this.history[Math.round(i * (this.history.length - 1) / Math.max(1, count - 1))]);
        }
        this.preparedSeries = this.apiKeys.map((key: string, index: number): LineChartSeries => ({
            label: sdkDataLabel(key),
            color: colors[index % colors.length],
            points: history.map((point: HistoryPoint): LineChartPoint => {
                const value = Number(point.values[key] ?? 0);
                return {
                    label: point.date,
                    value,
                    detail: `${point.date} · ${sdkDataLabel(key)} 占比 ${value.toFixed(2)}%`,
                } as LineChartPoint;
            }),
        } as LineChartSeries));
    }

    build() {
        Column({ space: 12 }) {
            Row() {
                Text('API 版本占比历史').fontSize(18).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).layoutWeight(1)
            }.width('100%')
            InteractiveLineChart({
                title: 'API版本占比历史',
                unit: '%',
                series: this.preparedSeries,
                active: this.active,
                showTitle: false,
                chartHeight: 280,
                responsiveAxisFont: true,
                viewport: this.viewport,
                onViewportChange: (viewport: ChartViewportState): void => {
                    if (this.onViewportChange) this.onViewportChange(viewport);
                },
            })
        }
        .width('100%').accessibilityText('API版本占比历史')
    }
}

