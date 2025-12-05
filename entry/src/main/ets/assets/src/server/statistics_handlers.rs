//! 统计查询 HTTP 接口处理器
//!
//! 提供统计数据的查询接口

use axum::{
    Json,
    extract::{Query, State},
    http::StatusCode,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::{net::IpAddr, sync::Arc};
use tracing::error;
use utoipa::{IntoParams, ToSchema};

use crate::{db::statistics::AccessLogRecord, server::state::AppState};

use super::statistics;

/// 当前统计响应
#[derive(Debug, Serialize, ToSchema)]
pub struct CurrentStatisticsResponse {
    /// UA 统计列表
    pub ua: Vec<UaStatEntry>,
    /// IP 统计列表
    pub ip: Vec<IpStatEntry>,
    /// UA 总数
    pub total_ua_count: usize,
    /// IP 总数
    pub total_ip_count: usize,
}

/// UA 统计条目
#[derive(Debug, Serialize, ToSchema)]
pub struct UaStatEntry {
    /// User Agent 字符串
    pub user_agent: String,
    /// 访问次数
    pub count: u64,
}

/// IP 统计条目
#[derive(Debug, Serialize, ToSchema)]
pub struct IpStatEntry {
    /// IP 地址
    pub ip_address: String,
    /// 访问次数
    pub count: u64,
}

/// 历史统计查询参数
#[derive(Debug, Deserialize, ToSchema, IntoParams)]
pub struct HistoryQueryParams {
    /// 页码
    #[serde(default = "default_page")]
    pub page: u32,
    /// 每页大小
    #[serde(default = "default_page_size")]
    pub page_size: u32,
    /// 统计类型："ua" 或 "ip"
    #[serde(default)]
    pub stat_type: String,
}

fn default_page() -> u32 {
    1
}

fn default_page_size() -> u32 {
    50
}

/// 历史统计响应
#[derive(Debug, Serialize, ToSchema)]
pub struct HistoryStatisticsResponse<T> {
    /// 数据列表
    pub data: Vec<T>,
    /// 总记录数
    pub total: i64,
    /// 当前页码
    pub page: u32,
    /// 每页大小
    pub page_size: u32,
    /// 总页数
    pub total_pages: u32,
}

/// 每小时统计查询参数
#[derive(Debug, Deserialize, ToSchema, IntoParams)]
pub struct HourlyQueryParams {
    /// 统计类型："ua" 或 "ip"
    pub stat_type: String,
    /// 目标：user_agent 或 ip_address
    pub target: String,
    /// 开始时间（RFC3339格式）
    #[serde(default)]
    pub start_time: Option<String>,
    /// 结束时间（RFC3339格式）
    #[serde(default)]
    pub end_time: Option<String>,
}

/// 访问日志查询参数
#[derive(Debug, Deserialize, ToSchema, IntoParams)]
pub struct AccessLogQueryParams {
    /// 页码
    #[serde(default = "default_page")]
    pub page: u32,
    /// 每页大小
    #[serde(default = "default_page_size")]
    pub page_size: u32,
    /// IP 地址过滤
    #[serde(default)]
    pub ip: Option<String>,
    /// User Agent 过滤
    #[serde(default)]
    pub ua: Option<String>,
    /// 路径过滤
    #[serde(default)]
    pub path: Option<String>,
}

#[utoipa::path(
    get,
    path = "/api/v0/statistics/current",
    responses(
        (status = 200, description = "获取当前统计数据（内存中的实时数据），包括UA和IP访问统计")
    ),
    tag = "访问统计"
)]
/// 获取当前统计数据（内存中的实时数据）
///
/// GET /api/statistics/current
pub async fn get_current_statistics() -> Json<CurrentStatisticsResponse> {
    let stats = statistics::get_statistics().await;

    let mut ua: Vec<_> = stats
        .ua
        .into_iter()
        .map(|(user_agent, count)| UaStatEntry { user_agent, count })
        .collect();
    ua.sort_by(|a, b| b.count.cmp(&a.count));

    let mut ip: Vec<_> = stats
        .ip
        .into_iter()
        .map(|(ip_address, count)| IpStatEntry {
            ip_address: ip_address.to_string(),
            count,
        })
        .collect();
    ip.sort_by(|a, b| b.count.cmp(&a.count));

    let total_ua_count = ua.len();
    let total_ip_count = ip.len();

    Json(CurrentStatisticsResponse {
        ua,
        ip,
        total_ua_count,
        total_ip_count,
    })
}

#[utoipa::path(
    get,
    path = "/api/v0/statistics/history",
    params(
        HistoryQueryParams
    ),
    responses(
        (status = 200, description = "获取历史统计数据（数据库中的持久化数据），支持UA和IP统计查询")
    ),
    tag = "访问统计"
)]
/// 获取历史统计数据（数据库中的持久化数据）
///
/// GET /api/statistics/history?stat_type=ua&page=1&page_size=50
pub async fn get_history_statistics(
    State(state): State<Arc<AppState>>,
    Query(params): Query<HistoryQueryParams>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let page = params.page.max(1);
    let page_size = params.page_size.clamp(1, 1000);

    match params.stat_type.as_str() {
        "ua" => {
            let (data, total) = state
                .db
                .query_ua_statistics(page, page_size)
                .await
                .map_err(|e| {
                    error!("查询 UA 历史统计失败: {:?}", e);
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        format!("查询失败: {}", e),
                    )
                })?;

            let total_pages = ((total as f64) / (page_size as f64)).ceil() as u32;

            Ok(Json(serde_json::json!(HistoryStatisticsResponse {
                data,
                total,
                page,
                page_size,
                total_pages,
            })))
        }
        "ip" => {
            let (data, total) = state
                .db
                .query_ip_statistics(page, page_size)
                .await
                .map_err(|e| {
                    error!("查询 IP 历史统计失败: {:?}", e);
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        format!("查询失败: {}", e),
                    )
                })?;

            let total_pages = ((total as f64) / (page_size as f64)).ceil() as u32;

            Ok(Json(serde_json::json!(HistoryStatisticsResponse {
                data,
                total,
                page,
                page_size,
                total_pages,
            })))
        }
        _ => Err((
            StatusCode::BAD_REQUEST,
            "stat_type 参数必须是 'ua' 或 'ip'".to_string(),
        )),
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/statistics/hourly",
    params(
        HourlyQueryParams
    ),
    responses(
        (status = 200, description = "获取每小时统计趋势，按时间段查询指定UA或IP的访问趋势")
    ),
    tag = "访问统计"
)]
/// 获取每小时统计趋势
///
/// GET /api/statistics/hourly?stat_type=ua&target=Mozilla/5.0...&start_time=...&end_time=...
pub async fn get_hourly_statistics(
    State(state): State<Arc<AppState>>,
    Query(params): Query<HourlyQueryParams>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    // 解析时间范围，默认最近 24 小时
    let end_time = if let Some(end_str) = params.end_time {
        DateTime::parse_from_rfc3339(&end_str)
            .map(|dt| dt.with_timezone(&Utc))
            .map_err(|e| (StatusCode::BAD_REQUEST, format!("end_time 格式错误: {}", e)))?
    } else {
        Utc::now()
    };

    let start_time = if let Some(start_str) = params.start_time {
        DateTime::parse_from_rfc3339(&start_str)
            .map(|dt| dt.with_timezone(&Utc))
            .map_err(|e| {
                (
                    StatusCode::BAD_REQUEST,
                    format!("start_time 格式错误: {}", e),
                )
            })?
    } else {
        end_time - chrono::Duration::hours(24)
    };

    match params.stat_type.as_str() {
        "ua" => {
            let data = state
                .db
                .query_ua_hourly_statistics(&params.target, start_time, end_time)
                .await
                .map_err(|e| {
                    error!("查询 UA 每小时统计失败: {:?}", e);
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        format!("查询失败: {}", e),
                    )
                })?;

            Ok(Json(serde_json::json!({
                "stat_type": "ua",
                "target": params.target,
                "start_time": start_time,
                "end_time": end_time,
                "data": data,
            })))
        }
        "ip" => {
            let ip_addr: IpAddr = params
                .target
                .parse()
                .map_err(|e| (StatusCode::BAD_REQUEST, format!("IP 地址格式错误: {}", e)))?;

            let data = state
                .db
                .query_ip_hourly_statistics(ip_addr, start_time, end_time)
                .await
                .map_err(|e| {
                    error!("查询 IP 每小时统计失败: {:?}", e);
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        format!("查询失败: {}", e),
                    )
                })?;

            Ok(Json(serde_json::json!({
                "stat_type": "ip",
                "target": params.target,
                "start_time": start_time,
                "end_time": end_time,
                "data": data,
            })))
        }
        _ => Err((
            StatusCode::BAD_REQUEST,
            "stat_type 参数必须是 'ua' 或 'ip'".to_string(),
        )),
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/statistics/logs",
    params(
        AccessLogQueryParams
    ),
    responses(
        (status = 200, description = "获取访问详细日志，支持按IP、UA、路径过滤")
    ),
    tag = "访问统计"
)]
/// 获取访问详细日志
///
/// GET /api/statistics/logs?page=1&page_size=50&ip=...&ua=...&path=...
pub async fn get_access_logs(
    State(state): State<Arc<AppState>>,
    Query(params): Query<AccessLogQueryParams>,
) -> Result<Json<HistoryStatisticsResponse<AccessLogRecord>>, (StatusCode, String)> {
    let page = params.page.max(1);
    let page_size = params.page_size.clamp(1, 1000);

    let ip_filter = if let Some(ip_str) = params.ip {
        Some(
            ip_str
                .parse::<IpAddr>()
                .map_err(|e| (StatusCode::BAD_REQUEST, format!("IP 地址格式错误: {}", e)))?,
        )
    } else {
        None
    };

    let (data, total) = state
        .db
        .query_access_logs(page, page_size, ip_filter, params.ua, params.path)
        .await
        .map_err(|e| {
            error!("查询访问日志失败: {:?}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("查询失败: {}", e),
            )
        })?;

    let total_pages = ((total as f64) / (page_size as f64)).ceil() as u32;

    Ok(Json(HistoryStatisticsResponse {
        data,
        total,
        page,
        page_size,
        total_pages,
    }))
}

/// 统计概览
///
/// GET /api/statistics/summary
#[derive(Debug, Serialize, ToSchema)]
pub struct StatisticsSummary {
    /// UA 类型总数
    pub total_ua_types: usize,
    /// IP 总数
    pub total_ips: usize,
    /// 总请求数
    pub total_requests: u64,
    /// 最活跃的 UA
    pub most_active_ua: Option<String>,
    /// 最活跃的 IP
    pub most_active_ip: Option<String>,
}

#[utoipa::path(
    get,
    path = "/api/v0/statistics/summary",
    responses(
        (status = 200, description = "获取统计概览，包括总请求数、活跃UA和IP等汇总信息")
    ),
    tag = "访问统计"
)]
pub async fn get_statistics_summary() -> Json<StatisticsSummary> {
    let stats = statistics::get_statistics().await;

    let total_ua_types = stats.ua.len();
    let total_ips = stats.ip.len();
    let total_requests: u64 = stats.ua.values().sum::<u64>() + stats.ip.values().sum::<u64>();

    let most_active_ua = stats
        .ua
        .iter()
        .max_by_key(|(_, count)| *count)
        .map(|(ua, _)| ua.clone());

    let most_active_ip = stats
        .ip
        .iter()
        .max_by_key(|(_, count)| *count)
        .map(|(ip, _)| ip.to_string());

    Json(StatisticsSummary {
        total_ua_types,
        total_ips,
        total_requests,
        most_active_ua,
        most_active_ip,
    })
}
