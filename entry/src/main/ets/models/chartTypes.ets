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
