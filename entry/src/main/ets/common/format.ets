export function formatCount(value: number | undefined): string {
    if (value === undefined || value === null) {
        return '-';
    }
    if (value >= 100000000) {
        return `${(value / 100000000).toFixed(2)}亿`;
    }
    if (value >= 10000) {
        return `${(value / 10000).toFixed(2)}万`;
    }
    return String(value);
}

/** 下载量低于一千时不展示具体数值。 */
export function formatDownloadCount(value: number | undefined): string {
    if (value === undefined || value === null) {
        return '-';
    }
    if (value < 1000) {
        return '<1千';
    }
    return formatCount(value);
}

export function formatExactCount(value: number | undefined): string {
    if (value === undefined || value === null) {
        return '-';
    }
    return String(value);
}

export function formatBytes(bytes: number | undefined): string {
    if (!bytes || bytes <= 0) {
        return '0 B';
    }
    if (bytes >= 1024 * 1024 * 1024) {
        return `${(bytes / 1024 / 1024 / 1024).toFixed(2)} GB`;
    }
    if (bytes >= 1024 * 1024) {
        return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
    }
    if (bytes >= 1024) {
        return `${(bytes / 1024).toFixed(1)} KB`;
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
