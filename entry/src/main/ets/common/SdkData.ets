import { formatSdkLabel } from './format';

export interface SdkDistributionData { labels: string[]; values: number[]; total: number; }

/** 接口返回的 API 等级和 SDK 编码统一为同一个版本键，供图表和图例共同使用。 */
export function sdkDataLabel(raw: string | number): string {
    const text = String(raw).trim();
    const value = Number(text.replace(/^API\s+/, ''));
    if (Number.isFinite(value) && Number.isInteger(value)) return formatSdkLabel(`API ${value}`);
    if (/^\d+\.\d+\.\d+(?: \(API \d+\))?$/.test(text)) return text;
    return '未知 SDK';
}

/** 已识别版本按语义版本降序；未识别的 API 等级单独排列，未知数据放最后。 */
export function compareSdkLabels(a: string, b: string): number {
    if (a === b) return 0;
    if (a === '未知 SDK') return 1;
    if (b === '未知 SDK') return -1;
    const av = a.match(/^(\d+)\.(\d+)\.(\d+)/);
    const bv = b.match(/^(\d+)\.(\d+)\.(\d+)/);
    if (av && bv) {
        return (Number(bv[1]) * 10000 + Number(bv[2]) * 100 + Number(bv[3])) -
            (Number(av[1]) * 10000 + Number(av[2]) * 100 + Number(av[3]));
    }
    if (av) return -1;
    if (bv) return 1;
    return Number(b.replace('API ', '')) - Number(a.replace('API ', ''));
}

export function sdkDistributionData(source: number[][]): SdkDistributionData {
    const grouped: Record<string, number> = {};
    let total = 0;
    for (const row of source) {
        if (row.length < 2) continue;
        const count = Number(row[1]);
        if (!Number.isFinite(count) || count <= 0) continue;
        const label = sdkDataLabel(row[0]);
        grouped[label] = (grouped[label] ?? 0) + count;
        total += count;
    }
    const labels = Object.keys(grouped).sort(compareSdkLabels);
    return { labels, values: labels.map((label: string): number => grouped[label]), total };
}

/** 历史数据沿用接口占比单位；同版本的不同编码相加，不再次计算占比。 */
export function sdkHistoryValues(source: Record<string, number>): Record<string, number> {
    const grouped: Record<string, number> = {};
    for (const key of Object.keys(source)) {
        const value = Number(source[key]);
        if (!Number.isFinite(value) || value < 0) continue;
        const label = sdkDataLabel(key);
        grouped[label] = (grouped[label] ?? 0) + value;
    }
    return grouped;
}
