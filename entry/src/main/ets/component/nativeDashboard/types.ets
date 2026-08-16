// 原生看板页面使用的 API 数据类型（对应 get_market 后端 /api/v0 响应结构）

export interface MarketInfoAppCount {
    total: number;
    apps: number;
    atomic_services: number;
    max_download_count: number;
}

export interface MarketInfoData {
    app_count: MarketInfoAppCount;
    substance_count: number;
    developer_count: number;
}

export interface MarketInfoResponse {
    success: boolean;
    data: MarketInfoData;
    timestamp?: string;
}

export interface AppSummary {
    app_id: string;
    pkg_name?: string;
    name?: string;
    developer_name?: string;
    kind_type_name?: string;
    kind_name?: string;
    tag_name?: string;
    average_rating?: number;
    total_star_rating_count?: number;
    download_count?: number;
    size_bytes?: number;
    updated_at?: string;
    created_at?: string;
    listed_at?: string;
    icon_url?: string;
}

export interface AppsListData {
    data?: AppSummary[];
    total_count?: number;
}

export interface AppsListResponse {
    success: boolean;
    data: AppsListData;
}

// 评分分布：star_1 在后端语义里是"无评分"桶
export interface RatingDistribution {
    star_1: number;
    star_2: number;
    star_3: number;
    star_4: number;
    star_5: number;
}

export interface RatingChartResponse {
    success: boolean;
    data: RatingDistribution;
}

// sdk 分布：后端返回 [sdk值, 数量] 的二维数组
export interface SdkChartResponse {
    success: boolean;
    data: number[][];
}

export interface SdkBucket {
    sdk: number;
    count: number;
}
