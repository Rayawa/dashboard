import { http } from '@kit.NetworkKit';
import {
    customUserAgent,
    DEFAULT_NETWORK_TIMEOUT_MS,
    SAPIBaseURL,
    SBaseURL,
    TBaseURL,
} from './constants';

export interface DashboardVisibilityConfig {
    showInstallCount: boolean;
    showTotalDownloadRanking: boolean;
    showDownloadHistory: boolean;
    showNonHuaweiDownloadRanking: boolean;
    showAppDownloadMetrics: boolean;
    showTSite: boolean;
}

interface DashboardVisibilityData {
    show_install_count?: boolean;
    show_total_download_ranking?: boolean;
    show_download_history?: boolean;
    show_non_huawei_download_ranking?: boolean;
    show_app_download_metrics?: boolean;
    show_t_site?: boolean;
}

interface DashboardVisibilityResponse {
    success: boolean;
    data?: DashboardVisibilityData;
}

export function createRestrictedDashboardConfig(): DashboardVisibilityConfig {
    return {
        showInstallCount: false,
        showTotalDownloadRanking: false,
        showDownloadHistory: false,
        showNonHuaweiDownloadRanking: false,
        showAppDownloadMetrics: false,
        showTSite: false,
    };
}

export async function fetchDashboardConfig(): Promise<DashboardVisibilityConfig> {
    const request = http.createHttp();
    try {
        const response = await request.request(
            `${SAPIBaseURL.toString()}dashboard/config`,
            {
                method: http.RequestMethod.GET,
                header: { 'User-Agent': customUserAgent },
                expectDataType: http.HttpDataType.STRING,
                usingCache: false,
                connectTimeout: DEFAULT_NETWORK_TIMEOUT_MS,
                readTimeout: DEFAULT_NETWORK_TIMEOUT_MS,
            },
        );
        if (response.responseCode < 200 || response.responseCode >= 300) {
            throw new Error(`HTTP ${response.responseCode}`);
        }
        const result = JSON.parse(response.result.toString()) as DashboardVisibilityResponse;
        if (!result.success || !result.data) {
            throw new Error('Dashboard config response is invalid');
        }
        return {
            showInstallCount: result.data.show_install_count === true,
            showTotalDownloadRanking: result.data.show_total_download_ranking === true,
            showDownloadHistory: result.data.show_download_history === true,
            showNonHuaweiDownloadRanking: result.data.show_non_huawei_download_ranking === true,
            showAppDownloadMetrics: result.data.show_app_download_metrics === true,
            showTSite: result.data.show_t_site === true,
        };
    } finally {
        request.destroy();
    }
}

export async function resolveDashboardAppDetailUrl(appId: string): Promise<string> {
    let config = createRestrictedDashboardConfig();
    try {
        config = await fetchDashboardConfig();
    } catch (error) {
        const message = (error as Error).message;
        console.warn(`Dashboard config load failed while resolving detail URL: ${message}`);
    }
    const encodedAppId = encodeURIComponent(appId);
    return config.showTSite
        ? `${TBaseURL.toString()}app/${encodedAppId}`
        : `${SBaseURL.toString()}?app_id=${encodedAppId}`;
}
