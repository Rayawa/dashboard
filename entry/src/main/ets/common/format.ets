export function formatCount(value: number | undefined): string {
    if (value === undefined || value === null) {
        return '-';
    }
    return String(value);
}

const SDK_VERSION_NAMES: Record<string, string> = {
    '12': '5.0.0', '13': '5.0.1', '14': '5.0.2', '15': '5.0.3', '16': '5.0.4',
    '17': '5.0.5', '18': '5.1.0', '19': '5.1.1', '20': '6.0.0', '21': '6.0.1',
    '22': '6.0.2', '23': '6.1.0', '24': '6.1.1', '26': '26.0.0',
};

/** 接口同时包含 API 等级、十进制版本号和带 API 后缀的 HAP 版本号。 */
export function formatSdkVersion(value: number | undefined): string {
    const sdk = Number(value);
    if (!Number.isFinite(sdk) || sdk <= 0 || !Number.isInteger(sdk)) return '-';
    if (sdk < 10000) {
        const name = SDK_VERSION_NAMES[String(sdk)];
        return name ? `${name} (API ${sdk})` : `API ${sdk}`;
    }
    const packed = sdk >= 10000000 ? Math.floor(sdk / 1000) : sdk;
    const major = Math.floor(packed / 10000);
    const minor = Math.floor(packed / 100) % 100;
    const patch = packed % 100;
    if (major < 1 || major > 99) return String(sdk);
    const version = `${major}.${minor}.${patch}`;
    return sdk >= 10000000 ? `${version} (API ${sdk % 1000})` : version;
}

/** 图表保留原始版本键用于颜色、排序和选中状态，只处理可见文字。 */
export function formatSdkLabel(label: string): string {
    const match = label.match(/^API (-?\d+)$/);
    if (!match) return label;
    const version = formatSdkVersion(Number(match[1]));
    if (version === '-') return '未知 SDK';
    const name = version.split(' (API ')[0];
    for (const api of Object.keys(SDK_VERSION_NAMES)) {
        if (SDK_VERSION_NAMES[api] === name) return `${name} (API ${api})`;
    }
    return version;
}

export function formatScore(value: number): string {
    if (!Number.isFinite(value)) return '-';
    const rounded = Number(value.toFixed(2));
    return (rounded === 0 ? 0 : rounded).toFixed(2);
}

export function formatDownloadCount(value: number | undefined): string {
    return formatCount(value);
}

export function formatExactCount(value: number | undefined): string {
    if (value === undefined || value === null) {
        return '-';
    }
    return String(value);
}

export function formatBytes(bytes: number | undefined): string {
    if (bytes === undefined || bytes === null) {
        return '-';
    }
    return `${bytes} B`;
}

export function formatDateTime(value: string | undefined): string {
    if (!value) {
        return '-';
    }
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
        return value;
    }
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day} ${hour}:${minute}`;
}

export function formatDuration(seconds: number | undefined): string {
    if (seconds === undefined || seconds === null || !Number.isFinite(seconds) || seconds < 0) return '-';
    const total = Math.floor(seconds);
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor((total % 3600) / 60);
    const secs = total % 60;
    if (hours > 0) return `${hours}小时${minutes}分`;
    if (minutes > 0) return `${minutes}分${secs}秒`;
    return `${secs}秒`;
}
