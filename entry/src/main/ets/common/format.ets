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

export function formatPercent(current: number, total: number): string {
    if (total <= 0) {
        return '0%';
    }
    return `${Math.min(100, Math.max(0, current / total * 100)).toFixed(1)}%`;
}
