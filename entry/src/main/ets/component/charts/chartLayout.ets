export interface ChartAxisScale {
    maximum: number;
    intervals: number;
    labels: string[];
}

export function chartPercentLabel(value: number): string {
    if (!Number.isFinite(value)) return '-';
    if (value > 0 && value < 0.01) return '<0.01%';
    if (value < 0 && value > -0.01) return '>-0.01%';
    return `${Number(value.toFixed(2))}%`;
}

/** Only axis ticks are abbreviated. Data summaries and application fields keep their exact values. */
export function chartAxisLabel(value: number, unit: string): string {
    if (!Number.isFinite(value)) return '-';
    if (unit === '%') return `${Number(value.toFixed(2))}%`;
    if (unit === '分') return String(Number(value.toFixed(1)));
    const absolute = Math.abs(value);
    if (absolute >= 1e16) return value.toExponential(1).replace('.0e', 'e').replace('e+', 'e');
    if (absolute >= 1e12) return `${Number((value / 1e12).toFixed(1))}万亿`;
    if (absolute >= 1e8) return `${Number((value / 1e8).toFixed(1))}亿`;
    if (absolute >= 1e4) return `${Number((value / 1e4).toFixed(1))}万`;
    return String(Number(value.toFixed(2)));
}

export function chartAxisScale(dataMaximum: number, unit: string): ChartAxisScale {
    const value = Number.isFinite(dataMaximum) ? Math.max(1, dataMaximum) : 1;
    let maximum: number;
    let intervals: number;
    if (unit === '分' && value <= 5) {
        maximum = 5;
        intervals = 5;
    } else {
        const rawStep = value / 4;
        const magnitude = Math.pow(10, Math.floor(Math.log10(rawStep)));
        const fraction = rawStep / magnitude;
        const stepFactor = fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 2.5 ? 2.5 : fraction <= 5 ? 5 : 10;
        const step = Math.max(unit === '%' ? 0 : 1, stepFactor * magnitude);
        intervals = Math.max(1, Math.ceil(value / step));
        maximum = step * intervals;
        if (!Number.isFinite(maximum)) { maximum = value; intervals = 4; }
    }
    const labels: string[] = [];
    for (let row = 0; row <= intervals; row++) {
        labels.push(chartAxisLabel(maximum / intervals * (intervals - row), unit));
    }
    return { maximum, intervals, labels };
}

export function chartDateLines(label: string): string[] {
    const match = label.match(/^(\d{4})-(\d{2})-(\d{2})(?:\b|T)/);
    return match ? [`${match[2]}-${match[3]}`, match[1]] : [label];
}

/** Include both visible endpoints and use viewport density, including after pinch zoom and pan. */
export function chartDateIndices(count: number, width: number, zoom: number, pan: number,
    spacing: number = 64): number[] {
    if (count <= 0) return [];
    if (count === 1) return [0];
    const step = width * zoom / (count - 1);
    const first = Math.max(0, Math.ceil(pan / Math.max(0.001, step)));
    const last = Math.min(count - 1, Math.floor((pan + width) / Math.max(0.001, step)));
    if (last < first) return [];
    const slots = Math.min(last - first + 1, Math.max(2, Math.floor(width / spacing) + 1));
    const indices: number[] = [];
    for (let slot = 0; slot < slots; slot++) {
        const index = Math.round(first + (last - first) * slot / Math.max(1, slots - 1));
        if (indices.length === 0 || indices[indices.length - 1] !== index) indices.push(index);
    }
    return indices;
}

export function chartLegendColumns(width: number, minimum: number = 150, maximum: number = 6): number {
    return Math.max(1, Math.min(maximum, Math.floor((width + 6) / (minimum + 6))));
}
