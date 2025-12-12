use axum::{
    Json, Router,
    http::StatusCode,
    middleware,
    response::IntoResponse,
    routing::{get, post},
};
use tower_http::compression::CompressionLayer;
use tower_http::services::ServeDir;
use utoipa::OpenApi;

use std::sync::Arc;

use crate::server::statistics::{get_statistics, middle_response};
use crate::server::{frontend_handlers, handlers, statistics_handlers};
use crate::server::{
    middle::client_ip_middleware,
    state::{ApiResponse, AppState},
};

pub type AppRouter = Router<Arc<AppState>>;

pub fn feishu_router(app_state: Arc<AppState>) -> AppRouter {
    Router::new()
        .route("/meta.json", get(handlers::feishu_meta))
        .route("/table_meta", post(handlers::feishu_table_meta))
        .route("/records", post(handlers::feishu_records))
        .with_state(app_state)
}

pub fn temp_router(app_state: Arc<AppState>) -> AppRouter {
    Router::new()
        // .route("/temp", get(handlers::temp_handler))
        .with_state(app_state)
}

pub fn statistics_router(app_state: Arc<AppState>) -> AppRouter {
    Router::new()
        // 获取当前统计（内存）
        .route("/current", get(statistics_handlers::get_current_statistics))
        // 获取历史统计（数据库）
        .route("/history", get(statistics_handlers::get_history_statistics))
        // 获取每小时统计趋势
        .route("/hourly", get(statistics_handlers::get_hourly_statistics))
        // 获取访问日志 不行, 这玩意不给看
        // .route("/logs", get(statistics_handlers::get_access_logs))
        // 获取统计概览
        .route("/summary", get(statistics_handlers::get_statistics_summary))
        .with_state(app_state)
}

pub fn api_router(app_state: Arc<AppState>) -> AppRouter {
    Router::new()
        // 获取市场信息
        .route("/market_info", get(handlers::market_info))
        // SSE 同步状态流
        .route("/sync_status/stream", get(handlers::sync_status_stream))
        // 根据包名查询应用信息
        .route("/apps/pkg_name/{pkg_name}", get(handlers::query_pkg))
        // 根据应用ID查询应用信息
        .route("/apps/app_id/{app_id}", get(handlers::query_app_id))
        // 获取分页的应用信息
        .route("/apps/list/{page_count}", get(handlers::app_list_paged))
        // 获取应用图标URL
        .route("/apps/icon", get(handlers::get_app_icon))
        // 获取应用下载量历史数据
        .route(
            "/apps/metrics/{pkg_id}",
            get(handlers::get_app_download_history),
        )
        // 专题查询相关路由
        // 根据专题ID查询专题信息
        .route("/substance/{substance_id}", get(handlers::query_substance))
        // 获取分页的专题列表
        .route(
            "/substance/list/{page}",
            get(handlers::substance_list_paged),
        )
        // 新增排行API路由
        // 下载量增量排行榜
        .route(
            "/rankings/download_increase",
            get(handlers::download_increase),
        )
        // 获取评分排行榜
        .route("/rankings/ratings", get(handlers::get_rating_ranking))
        // 获取最新应用排行榜
        .route("/rankings/recent", get(handlers::get_recent_ranking))
        // 获取开发者排行榜
        .route("/rankings/developers", get(handlers::get_developer_ranking))
        // 获取星级分布
        .route("/charts/rating", get(handlers::get_rating_distribution))
        .route("/charts/min_sdk", get(handlers::get_min_sdk_distribution))
        .route(
            "/charts/target_sdk",
            get(handlers::get_target_sdk_distribution),
        )
        // 投稿
        .route("/submit", post(handlers::submit_app))
        .route(
            "/submit_substance/{substance_id}",
            post(handlers::submit_substance),
        )
        .nest("/feishu", feishu_router(app_state.clone()))
        .nest("/temp", temp_router(app_state.clone()))
        .nest("/statistics", statistics_router(app_state.clone()))
        .fallback(api_not_found)
        .with_state(app_state.clone())
}

/// 静态资源处理
async fn static_handler() -> impl IntoResponse {
    Json(get_statistics().await)
}

async fn serve_openapi() -> impl IntoResponse {
    static OPENAPI_SPEC: std::sync::OnceLock<String> = std::sync::OnceLock::new();

    let spec = OPENAPI_SPEC.get_or_init(|| {
        ApiDocs::openapi()
            .to_pretty_json()
            .expect("Failed to serialize OpenAPI specification")
    });

    (
        StatusCode::OK,
        [(axum::http::header::CONTENT_TYPE, "application/json")],
        spec.clone(),
    )
}

/// 创建应用路由
pub fn create_router(app_state: Arc<AppState>) -> Router {
    Router::new()
        // Dashboard routes
        .route("/", get(frontend_handlers::redirect_to_dashboard))
        .route("/dashboard", get(frontend_handlers::serve_dashboard))
        .route("/favicon.ico", get(frontend_handlers::serve_favicon))
        .route("/static", get(static_handler))
        .route("/openapi.json", get(serve_openapi))
        .route("/update.md", get(frontend_handlers::serve_update))
        // API 文档页面
        .route("/swagger-ui", get(frontend_handlers::serve_swagger_ui))
        .route("/docs", get(frontend_handlers::serve_swagger_ui))
        .nest_service("/js", ServeDir::new("assets/js"))
        .nest("/api/v0", api_router(app_state.clone()))
        .fallback(frontend_handlers::serve_not_found)
        .with_state(app_state)
        .layer(CompressionLayer::new())
        .layer(middleware::from_fn(middle_response))
        .layer(middleware::from_fn(client_ip_middleware))
}

#[derive(OpenApi)]
#[openapi(
    info(
        title = "鸿蒙应用市场 第三方API",
        description = "鸿蒙应用市场 第三方API - 提供鸿蒙应用市场数据查询、统计分析等功能",
        version = env!("CARGO_PKG_VERSION"),
        license(
            name = "GPL-3.0",
            identifier = "GPL-3.0"
        )
    ),
    paths(
        // 应用查询
        handlers::query_pkg,
        handlers::query_app_id,
        handlers::app_list_paged,
        handlers::get_app_icon,
        handlers::get_app_download_history,
        // 市场信息
        handlers::market_info,
        handlers::sync_status_stream,
        // 排行榜
        handlers::get_rating_ranking,
        handlers::get_recent_ranking,
        handlers::get_developer_ranking,
        handlers::download_increase,
        // 统计图表
        handlers::get_rating_distribution,
        handlers::get_min_sdk_distribution,
        handlers::get_target_sdk_distribution,
        // 应用提交
        handlers::submit_app,
        handlers::submit_substance,
        // 专题查询
        handlers::query_substance,
        handlers::substance_list_paged,
        // 飞书集成
        handlers::feishu_meta,
        handlers::feishu_table_meta,
        handlers::feishu_records,
        // 访问统计
        statistics_handlers::get_current_statistics,
        statistics_handlers::get_history_statistics,
        statistics_handlers::get_hourly_statistics,
        // statistics_handlers::get_access_logs,
        statistics_handlers::get_statistics_summary,
    ),
    components(
        schemas(
            // API 基础类型
            crate::server::state::ApiResponse,
            crate::server::state::AppListQuery,
            crate::server::state::AppQueryParam,
            crate::server::state::IntervalParams,
            crate::server::state::RankingQuery,
            crate::server::state::SubstanceListQuery,
            // 应用模型
            crate::model::FullAppInfo,
            crate::model::ShortAppInfo,
            crate::model::ShortAppRating,
            // 专题模型
            crate::model::FullSubstanceInfo,
            crate::model::ShortSubstanceInfo,
            // 统计类型
            crate::server::statistics_handlers::CurrentStatisticsResponse,
            crate::server::statistics_handlers::UaStatEntry,
            crate::server::statistics_handlers::IpStatEntry,
            crate::server::statistics_handlers::HistoryQueryParams,
            crate::server::statistics_handlers::HourlyQueryParams,
            crate::server::statistics_handlers::AccessLogQueryParams,
            crate::server::statistics_handlers::StatisticsSummary,
        )
    ),
    tags(
        (name = "应用查询", description = "应用信息查询相关接口"),
        (name = "市场信息", description = "市场统计信息和同步状态"),
        (name = "排行榜", description = "各类应用排行榜"),
        (name = "统计图表", description = "数据分布统计图表"),
        (name = "应用提交", description = "应用信息提交接口"),
        (name = "专题查询", description = "专题信息查询相关接口"),
        (name = "飞书集成", description = "飞书数据连接器集成(目前未实现)"),
        (name = "访问统计", description = "API访问统计分析"),
    )
)]
struct ApiDocs;

/// API-specific 404 handler returning JSON error
async fn api_not_found() -> impl IntoResponse {
    let payload = ApiResponse::error("Api Not Found");
    (StatusCode::NOT_FOUND, Json(payload))
}
