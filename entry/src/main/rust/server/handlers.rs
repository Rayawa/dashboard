use axum::{
    Json,
    extract::{Path, Query, State},
    response::{
        IntoResponse,
        sse::{Event, Sse},
    },
};

use chrono::{DateTime, Local};
use serde_json::{Value as JsonValue, json};
use std::{convert::Infallible, str::FromStr, sync::Arc, time::Duration};
use tracing::{Level, event};

use crate::{
    db::AppCounts,
    model::{AppQuery, FullAppInfo, ShortAppInfo},
    server::state::{
        ApiResponse, AppListQuery, AppQueryParam, AppState, IntervalParams, RankingQuery,
        SubstanceListQuery,
    },
};

#[derive(Debug, serde::Serialize)]
struct Response {
    full_info: FullAppInfo,
    new_app: bool,
    new_info: bool,
    new_metric: bool,
    new_rating: bool,
    get_data: bool,
}

pub async fn query_app(
    state: Arc<AppState>,
    query: AppQuery,
    listed_at: Option<DateTime<Local>>,
    comment: Option<JsonValue>,
) -> Json<ApiResponse> {
    // 检查是否是新的应用
    let exists = state.db.app_exists(&query).await;

    match crate::sync::sync_app(
        &state.client,
        &state.db,
        state.cfg.api_url(),
        &query,
        listed_at,
        comment,
    )
    .await
    {
        Ok((new_info, new_metric, new_rating, full_info)) => Json(ApiResponse::success(
            Response {
                full_info,
                new_app: !exists,
                new_info,
                new_metric,
                new_rating,
                get_data: true,
            },
            None,
            None,
        )),
        Err(e) => {
            event!(
                Level::WARN,
                "http服务获取 appid: {query:?} 的信息失败: {e}, 尝试获取现有数据"
            );
            match state.db.get_full_app_info(&query).await {
                Ok(full_info) => Json(ApiResponse::success(
                    Response {
                        full_info,
                        new_app: false,
                        new_info: false,
                        new_metric: false,
                        new_rating: false,
                        get_data: false,
                    },
                    None,
                    None,
                )),
                Err(e) => {
                    event!(Level::WARN, "数据库里也没有 {query} 的数据: {e}");
                    Json(ApiResponse::error(
                        "对不起, 数据库里并没有这个应用的完整信息",
                    ))
                }
            }
        }
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/apps/pkg_name/{pkg_name}",
    params(
        ("pkg_name" = String, Path, description = "应用包名，例如：com.huawei.music")
    ),
    responses(
        (status = 200, description = "成功返回应用完整信息，包括基础信息、评分、下载量等", body = crate::server::state::ApiResponse),
        (status = 200, description = "如果在线获取失败，则返回数据库中的现有数据")
    ),
    tag = "应用查询"
)]
/// 根据应用包名查询应用详细信息
///
/// 该接口会优先从华为应用市场获取最新数据，如果获取失败则返回数据库中的历史数据。
/// 返回的数据包括：应用基础信息、版本信息、评分、下载量、开发者信息等。
pub async fn query_pkg(
    State(state): State<Arc<AppState>>,
    Path(pkg_name): Path<String>,
) -> Json<ApiResponse> {
    event!(
        Level::DEBUG,
        "http 服务正在尝试通过 pkg name 获取 {pkg_name} 的信息"
    );
    let query = AppQuery::pkg_name(&pkg_name);
    query_app(state, query, None, None).await
}

#[utoipa::path(
    get,
    path = "/api/v0/apps/app_id/{app_id}",
    params(
        ("app_id" = String, Path, description = "华为应用市场的应用ID，例如：C10084839")
    ),
    responses(
        (status = 200, description = "成功返回应用完整信息，包括基础信息、评分、下载量等", body = crate::server::state::ApiResponse),
        (status = 200, description = "如果在线获取失败，则返回数据库中的现有数据")
    ),
    tag = "应用查询"
)]
/// 根据应用ID查询应用详细信息
///
/// 该接口会优先从华为应用市场获取最新数据，如果获取失败则返回数据库中的历史数据。
/// 应用ID是华为应用市场为每个应用分配的唯一标识符。
pub async fn query_app_id(
    State(state): State<Arc<AppState>>,
    Path(app_id): Path<String>,
) -> Json<ApiResponse> {
    event!(
        Level::DEBUG,
        "http 服务正在尝试通过 appid 获取 {app_id} 的信息"
    );
    let query = AppQuery::app_id(&app_id);
    query_app(state, query, None, None).await
}

#[utoipa::path(
    get,
    path = "/api/v0/market_info",
    responses(
        (status = 200, description = "成功返回市场统计信息", body = crate::server::state::ApiResponse),
        (status = 200, description = "返回数据包括：应用总数、原子化服务数、开发者数、分页大小限制、同步状态、版本号等")
    ),
    tag = "市场信息"
)]
/// 获取华为应用市场统计信息
///
/// 该接口返回数据库中收录的应用市场统计数据，包括：
/// - app_count: 应用数量统计（总数、有图标数量等）
/// - substance_count: 专题数量
/// - developer_count: 开发者数量
/// - page_size_max: 分页查询的最大页面大小
/// - sync_status: 当前同步状态
/// - crate_version: 服务版本号
/// - user_agent: 请求华为API使用的User-Agent
pub async fn market_info(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    event!(Level::DEBUG, "http 服务正在尝试获取应用列表信息");
    #[derive(serde::Deserialize, serde::Serialize)]
    struct MarketInfo {
        app_count: AppCounts,
        substance_count: i64,
        developer_count: i64,
        page_size_max: u32,
        sync_status: crate::sync::SyncStatusInfo,
        crate_version: String,
        user_agent: String,
    }
    let app_count = if let Ok(app_count) = state.db.count_apps().await {
        app_count
    } else {
        return Json(ApiResponse::error(
            json!({"error": "Database error, faild to get app count"}),
        ));
    };
    let developer_count = if let Ok(developer_count) = state.db.count_developers().await {
        developer_count
    } else {
        return Json(ApiResponse::error(
            json!({"error": "Database error, faild to get dev count"}),
        ));
    };
    let substance_count = if let Ok(substance_count) = state.db.count_substances().await {
        substance_count
    } else {
        return Json(ApiResponse::error(
            json!({"error": "Database error, faild to get substance count"}),
        ));
    };
    let sync_status = crate::sync::get_sync_status();
    let data = MarketInfo {
        app_count,
        substance_count,
        developer_count,
        page_size_max: crate::db::query::get_max_limit(),
        sync_status,
        crate_version: env!("CARGO_PKG_VERSION").to_string(),
        user_agent: crate::sync::USER_AGENT.to_string(),
    };
    Json(ApiResponse::success(data, None, None))
}

#[utoipa::path(
    get,
    path = "/api/v0/apps/list/{page_count}",
    params(
        ("page_count" = String, Path, description = "页码，从0开始"),
        AppListQuery
    ),
    responses(
        (status = 200, description = "成功返回分页的应用列表", body = crate::server::state::ApiResponse),
        (status = 200, description = "返回数据包含total_count（总数）和page_size（每页数量）")
    ),
    tag = "应用查询"
)]
/// 分页获取应用列表，支持多种排序和过滤选项
///
/// 查询参数说明：
/// - page_size: 每页数量，默认50，最大值受系统限制
/// - detail: 是否返回详细信息，true返回完整信息，false返回简要信息
/// - sort: 排序字段，支持：rating（评分）、downloads（下载量）、updated_at（更新时间）等
/// - desc: 是否降序排序，默认false
/// - search: 搜索关键词
/// - search_key: 搜索字段，支持：name（应用名）、pkg_name（包名）、developer（开发者）等
/// - exclude_huawei: 是否排除华为官方应用
/// - exclude_atomic: 是否排除原子化服务
pub async fn app_list_paged(
    State(state): State<Arc<AppState>>,
    Path(page): Path<String>,
    Query(query): Query<AppListQuery>,
) -> impl IntoResponse {
    if !query.is_valid_sort()
        && let Some(sort_key) = query.raw_sort_key()
    {
        return Json(ApiResponse::error(format!(
            "你在想什么, 不许按照 {} 排序",
            sort_key
        )));
    }
    if !query.is_valid_search()
        && let Some(search_key) = query.raw_search_key()
    {
        return Json(ApiResponse::error(format!(
            "你在想什么, 不许按照 {} 搜索",
            search_key
        )));
    }
    match page.parse::<u32>() {
        Ok(page) => {
            if query.detail() {
                match state
                    .db
                    .get_app_info_paginated_enhanced::<FullAppInfo>(
                        page,
                        query.page_size(),
                        &query.sort_key(),
                        query.desc.unwrap_or_default(),
                        query.search_option(),
                        query.exclude_huawei(),
                        query.exclude_atomic(),
                    )
                    .await
                {
                    Ok(apps) => {
                        let total_count = apps.total_count;
                        Json(ApiResponse::success(
                            apps,
                            Some(total_count),
                            Some(query.page_size()),
                        ))
                    }
                    Err(e) => {
                        event!(Level::WARN, "http服务获取分页应用信息失败: {e}");
                        Json(ApiResponse::error(
                            "Database error, faild to get paged info",
                        ))
                    }
                }
            } else {
                match state
                    .db
                    .get_app_info_paginated_enhanced::<ShortAppInfo>(
                        page,
                        query.page_size(),
                        &query.sort_key(),
                        query.desc.unwrap_or_default(),
                        query.search_option(),
                        query.exclude_huawei(),
                        query.exclude_atomic(),
                    )
                    .await
                {
                    Ok(apps) => {
                        let total_count = apps.total_count;
                        Json(ApiResponse::success(
                            apps,
                            Some(total_count),
                            Some(query.page_size()),
                        ))
                    }
                    Err(e) => {
                        event!(Level::WARN, "http服务获取分页应用信息失败: {e}");
                        Json(ApiResponse::error(
                            "Database error, faild to get paged info",
                        ))
                    }
                }
            }
        }
        Err(e) => Json(ApiResponse::error(format!(
            "Failed to parse page: {} what the fuck did you commit",
            e
        ))),
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/rankings/ratings",
    params(
        RankingQuery
    ),
    responses(
        (status = 200, description = "成功返回评分最高的应用列表", body = crate::server::state::ApiResponse)
    ),
    tag = "排行榜"
)]
/// 获取评分排行榜
///
/// 返回评分最高的应用列表，按照评分（rating）降序排序。
/// 可通过limit参数控制返回数量，默认返回前10个应用。
pub async fn get_rating_ranking(
    State(state): State<Arc<AppState>>,
    Query(query): Query<RankingQuery>,
) -> impl IntoResponse {
    let limit = query.limit.unwrap_or(10);
    event!(Level::DEBUG, "获取评分排行，限制: {}", limit);

    match state.db.get_top_rated_apps(limit).await {
        Ok(apps) => {
            let total_count = apps.len() as u32;
            Json(ApiResponse::success(apps, Some(total_count), Some(limit)))
        }
        Err(e) => {
            event!(Level::WARN, "获取评分排行失败: {e}");
            Json(ApiResponse::error(
                "Database error, faild to get rating ranking",
            ))
        }
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/rankings/recent",
    params(
        RankingQuery
    ),
    responses(
        (status = 200, description = "成功返回最近更新的应用列表", body = crate::server::state::ApiResponse)
    ),
    tag = "排行榜"
)]
/// 获取最近更新应用排行榜
///
/// 返回最近更新的应用列表，按照更新时间（updated_at）降序排序。
/// 可通过limit参数控制返回数量，默认返回前10个应用。
pub async fn get_recent_ranking(
    State(state): State<Arc<AppState>>,
    Query(query): Query<RankingQuery>,
) -> impl IntoResponse {
    let limit = query.limit.unwrap_or(10);
    event!(Level::DEBUG, "获取最近更新排行，限制: {}", limit);

    match state.db.get_recently_updated_apps(limit).await {
        Ok(apps) => {
            let all_count = state.db.count_apps().await.map(|c| c.apps as u32).ok();
            Json(ApiResponse::success(apps, all_count, Some(limit)))
        }
        Err(e) => {
            event!(Level::WARN, "获取最近更新排行失败: {e}");
            Json(ApiResponse::error(
                "Database error, faild to get recently updated ranking",
            ))
        }
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/rankings/developers",
    params(
        RankingQuery
    ),
    responses(
        (status = 200, description = "成功返回开发者排行榜，按应用数量降序排序", body = crate::server::state::ApiResponse)
    ),
    tag = "排行榜"
)]
/// 获取开发者排行榜
///
/// 返回发布应用数量最多的开发者列表，按照应用数量降序排序。
/// 可通过limit参数控制返回数量，默认返回前10个开发者。
/// 返回数据包括开发者名称和其发布的应用数量。
pub async fn get_developer_ranking(
    State(state): State<Arc<AppState>>,
    Query(query): Query<RankingQuery>,
) -> impl IntoResponse {
    let limit = query.limit.unwrap_or(10);
    event!(Level::DEBUG, "获取开发者排行，限制: {}", limit);

    match state.db.get_top_developers(limit).await {
        Ok(developers) => {
            let total_count = developers.len() as u32;
            Json(ApiResponse::success(
                developers,
                Some(total_count),
                Some(limit),
            ))
        }
        Err(e) => {
            event!(Level::WARN, "获取开发者排行失败: {e}");
            Json(ApiResponse::error("Database error".to_string()))
        }
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/charts/rating",
    responses(
        (status = 200, description = "成功返回1-5星的应用数量分布", body = crate::server::state::ApiResponse),
        (status = 200, description = "返回格式：{\"star_1\": 数量, \"star_2\": 数量, \"star_3\": 数量, \"star_4\": 数量, \"star_5\": 数量}")
    ),
    tag = "统计图表"
)]
/// 获取应用星级评分分布统计
///
/// 返回数据库中所有应用的星级评分分布情况，统计1星到5星各个评分区间的应用数量。
/// 用于生成评分分布图表或进行数据分析。
pub async fn get_rating_distribution(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    event!(Level::DEBUG, "http 服务正在尝试获取星级分布");
    match state.db.get_star_distribution().await {
        Ok((star_1, star_2, star_3, star_4, star_5)) => Json(ApiResponse::success(
            json!({"star_1": star_1, "star_2": star_2, "star_3": star_3, "star_4": star_4, "star_5": star_5}),
            None,
            None,
        )),
        Err(e) => {
            event!(Level::WARN, "http服务获取星级分布失败: {e}");
            Json(ApiResponse::error(json!({"error": "Database error"})))
        }
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/charts/min_sdk",
    responses(
        (status = 200, description = "成功返回各SDK版本的应用数量分布", body = crate::server::state::ApiResponse)
    ),
    tag = "统计图表"
)]
/// 获取应用最低支持SDK版本分布统计
///
/// 返回数据库中所有应用的最低支持SDK版本（minSdkVersion）分布情况。
/// 统计数据以SDK版本号为键，应用数量为值。
/// 用于了解开发者对不同Android版本的支持情况。
pub async fn get_min_sdk_distribution(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    event!(Level::DEBUG, "http 服务正在尝试获取最小支持SDK分布");
    match state.db.count_min_sdk().await {
        Ok(distribution) => Json(ApiResponse::success(distribution, None, None)),
        Err(e) => {
            event!(Level::WARN, "http服务获取最小支持SDK分布失败: {e}");
            Json(ApiResponse::error(json!({"error": "Database error"})))
        }
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/charts/target_sdk",
    responses(
        (status = 200, description = "成功返回各目标SDK版本的应用数量分布", body = crate::server::state::ApiResponse)
    ),
    tag = "统计图表"
)]
/// 获取应用目标SDK版本分布统计
///
/// 返回数据库中所有应用的目标SDK版本（targetSdkVersion）分布情况。
/// 统计数据以SDK版本号为键，应用数量为值。
/// 用于了解开发者针对的Android目标版本趋势。
pub async fn get_target_sdk_distribution(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    event!(Level::DEBUG, "http 服务正在尝试获取目标支持SDK分布");
    match state.db.count_target_sdk().await {
        Ok(distribution) => Json(ApiResponse::success(distribution, None, None)),
        Err(e) => {
            event!(Level::WARN, "http服务获取目标支持SDK分布失败: {e}");
            Json(ApiResponse::error(json!({"error": "Database error"})))
        }
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/apps/metrics/{pkg_id}",
    params(
        ("pkg_id" = String, Path, description = "应用包名，例如：com.huawei.music")
    ),
    responses(
        (status = 200, description = "成功返回应用的历史下载量数据", body = crate::server::state::ApiResponse),
        (status = 200, description = "数据按时间序列排列，包含每次记录的下载量和时间戳")
    ),
    tag = "应用查询"
)]
/// 获取指定应用的下载量历史变化数据
///
/// 返回指定应用的历史下载量记录，用于绘制下载量趋势图。
/// 数据来源于定期同步时记录的下载量快照。
pub async fn get_app_download_history(
    State(state): State<Arc<AppState>>,
    Path(pkg_name): Path<String>,
) -> impl IntoResponse {
    event!(
        Level::DEBUG,
        "http 服务正在尝试获取应用 {} 的下载量历史数据",
        pkg_name
    );
    match state.db.get_app_metrics_by_pkg_id(&pkg_name).await {
        Ok(metrics) => Json(ApiResponse::success(metrics, None, None)),
        Err(e) => {
            event!(
                Level::WARN,
                "http服务获取应用 {} 下载量历史失败: {e}",
                pkg_name
            );
            Json(ApiResponse::error("Database error"))
        }
    }
}

#[utoipa::path(
    post,
    path = "/api/v0/submit_substance/{substance_id}",
    params(
        ("substance_id" = String, Path, description = "专题ID，例如：05998b06c4aa47469b2f26586bec699c")
    ),
    request_body(
        content = serde_json::Value,
        description = "请求体可选，支持comment字段添加备注信息",
        example = json!({"comment": "用户提交的备注信息"})
    ),
    responses(
        (status = 200, description = "成功获取并保存专题及其关联的应用信息", body = crate::server::state::ApiResponse),
        (status = 200, description = "返回专题数据、是否为新记录、关联应用数量")
    ),
    tag = "应用提交"
)]
/// 提交专题信息
///
/// 从华为应用市场获取指定专题的信息，并自动获取其关联的所有应用数据。
/// 如果数据库中不存在该专题，会将其保存到数据库。
/// 同时会同步所有关联的应用信息。
pub async fn submit_substance(
    State(state): State<Arc<AppState>>,
    Path(substance_id): Path<String>,
    Json(data): Json<JsonValue>,
) -> impl IntoResponse {
    event!(Level::INFO, "http 服务正在尝试提交专题 {}", substance_id);

    let comment = data.get("comment").cloned();

    match crate::sync::get_app_from_substance(&state.client, state.cfg.api_url(), &substance_id)
        .await
    {
        Ok((substance, raw_value)) => {
            for query in substance.data.iter() {
                match crate::sync::sync_app(
                    &state.client,
                    &state.db,
                    state.cfg.api_url(),
                    query,
                    None,
                    None,
                )
                .await
                {
                    Ok((_new_info, _new_metric, _new_rating, _full_info)) => {
                        event!(
                            Level::INFO,
                            "专题 {query} ({}) 对应的应用数据保存成功",
                            substance.say_my_name()
                        );
                    }
                    Err(e) => {
                        event!(
                            Level::WARN,
                            "http服务获取并保存专题 {} 对应的应用信息失败: {e}",
                            substance_id
                        );
                    }
                }
            }
            // 保存专题数据
            let is_new = match state
                .db
                .save_substance(&substance, &raw_value, comment)
                .await
            {
                Ok(b) => b,
                Err(e) => {
                    event!(Level::WARN, "专题 {} 对应的数据保存失败: {e}", substance_id);
                    return Json(ApiResponse::error("Database error"));
                }
            };
            let len = substance.data.len();
            Json(ApiResponse::success(
                json!({"data": substance, "is_new": is_new}),
                Some(len as u32),
                None,
            ))
        }
        Err(e) => {
            event!(Level::WARN, "http服务获取专题 {} 失败: {e}", substance_id);
            Json(ApiResponse::error("Failed to get substance"))
        }
    }
}

#[utoipa::path(
    post,
    path = "/api/v0/submit",
    request_body = serde_json::Value,
    responses(
        (status = 200, description = "提交应用信息，需要提供app_id或pkg_name", body = crate::server::state::ApiResponse)
    ),
    tag = "应用提交"
)]
pub async fn submit_app(
    State(state): State<Arc<AppState>>,
    Json(data): Json<JsonValue>,
) -> Json<ApiResponse> {
    // 获取 app_id 或者 pkg_name
    let app_id = data.get("app_id").and_then(|v| v.as_str());
    let pkg_name = data.get("pkg_name").and_then(|v| v.as_str());
    if app_id.is_none() && pkg_name.is_none() {
        return Json(ApiResponse::error(
            "app_id 和 pkg_name 至少给一个, 总不能一个不给吧".to_string(),
        ));
    } else if app_id.is_some() && pkg_name.is_some() {
        return Json(ApiResponse::error(
            "app_id 和 pkg_name 至多给一个, 你两个都给是什么意思".to_string(),
        ));
    }
    let query = match (app_id, pkg_name) {
        (Some(id), None) => AppQuery::app_id(id),
        (None, Some(name)) => AppQuery::pkg_name(name),
        _ => unreachable!(),
    };
    let app_exists = state.db.app_exists(&query).await;

    let listed_at: Option<DateTime<Local>> = data
        .get("listed_at")
        .and_then(|v| v.as_str())
        .and_then(|d| DateTime::from_str(d).ok());

    let comment = data.get("comment");

    let comment_str = comment
        .map(|c| c.to_string())
        .unwrap_or_else(|| "None".to_string());

    println!(
        "接收到投稿 data: query: {:?}, listed_at: {:?}, comment: {:?}",
        query, listed_at, comment_str
    );
    if app_exists {
        query_app(state, query, None, None).await
    } else {
        query_app(state, query, listed_at, comment.cloned()).await
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/feishu/meta.json",
    responses(
        (status = 200, description = "获取飞书数据连接器元信息", body = serde_json::Value)
    ),
    tag = "飞书集成"
)]
pub async fn feishu_meta(State(_state): State<Arc<AppState>>) -> impl IntoResponse {
    event!(Level::INFO, "Feishu 正在获取元信息");
    Json(serde_json::json! {{
      "schemaVersion": 1,
      "version": env!("CARGO_PKG_VERSION"),
      "type": "data_connector",
    }})
}

#[utoipa::path(
    post,
    path = "/api/v0/feishu/table_meta",
    responses(
        (status = 200, description = "获取飞书表格元信息", body = serde_json::Value)
    ),
    tag = "飞书集成"
)]
pub async fn feishu_table_meta(State(_state): State<Arc<AppState>>) -> impl IntoResponse {
    event!(Level::INFO, "Feishu 正在获取表格元信息");
    Json(serde_json::json! {{}})
}

#[utoipa::path(
    post,
    path = "/api/v0/feishu/records",
    responses(
        (status = 200, description = "获取飞书记录", body = serde_json::Value)
    ),
    tag = "飞书集成"
)]
pub async fn feishu_records(State(_state): State<Arc<AppState>>) -> impl IntoResponse {
    event!(Level::INFO, "Feishu 正在获取记录");
    Json(serde_json::json! {{}})
}

#[utoipa::path(
    get,
    path = "/api/v0/rankings/download_increase",
    params(
        IntervalParams
    ),
    responses(
        (status = 200, description = "获取应用下载量增长排行榜（指定时间区间）", body = crate::server::state::ApiResponse)
    ),
    tag = "排行榜"
)]
pub async fn download_increase(
    State(state): State<Arc<AppState>>,
    Query(interval): Query<IntervalParams>,
) -> impl IntoResponse {
    // event!(Level::INFO, "正在计算应用下载量增长数据");
    let pg_interval = interval.to_pg_interval();
    let limit = interval.limit();
    match state
        .db
        .calculate_download_increase(
            pg_interval,
            limit,
            interval.page,
            interval.exclude_huawei(),
            interval.exclude_atomic(),
            interval.listed_interval(),
        )
        .await
    {
        Ok((data, total)) => Json(ApiResponse::success(data, Some(total as u32), Some(limit))),
        Err(e) => {
            event!(Level::WARN, "计算应用下载量增长数据失败: {e}");
            Json(ApiResponse::error("Database error".to_string()))
        }
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/apps/icon",
    params(
        AppQueryParam
    ),
    responses(
        (status = 200, description = "获取应用图标URL", body = crate::server::state::ApiResponse)
    ),
    tag = "应用查询"
)]
pub async fn get_app_icon(
    State(state): State<Arc<AppState>>,
    Query(app_query): Query<AppQueryParam>,
) -> impl IntoResponse {
    if let Some(query) = app_query.as_query() {
        if let Some(icon_url) = state.db.get_app_icon(&query).await {
            Json(ApiResponse::success(icon_url, Some(1), Some(1)))
        } else {
            Json(ApiResponse::error("App icon not found"))
        }
    } else {
        Json(ApiResponse::error("app_id or pkg_name is required"))
    }
}

#[utoipa::path(
    get,
    path = "/api/v0/sync_status/stream",
    responses(
        (status = 200, description = "SSE流：实时推送同步状态信息")
    ),
    tag = "市场信息"
)]
pub async fn sync_status_stream() -> impl IntoResponse {
    // 动态控制发送频率：sync_all=true 时每 1 秒，否则每 5 秒
    // 首次立即发送，之后依据上次状态决定等待时长
    let initial_is_syncing = crate::sync::get_sync_status().is_syncing_all;
    let stream = futures::stream::unfold(
        (true, initial_is_syncing),
        |(first, prev_syncing)| async move {
            if !first {
                let wait = if prev_syncing {
                    Duration::from_secs(1)
                } else {
                    Duration::from_secs(5)
                };
                tokio::time::sleep(wait).await;
            }
            let sync_status = crate::sync::get_sync_status();
            let event = Event::default()
                .data(serde_json::to_string(&sync_status).unwrap_or_else(|_| "{}".to_string()))
                .event("sync_status");

            Some((
                Ok::<_, Infallible>(event),
                (false, sync_status.is_syncing_all),
            ))
        },
    );

    Sse::new(stream).keep_alive(
        axum::response::sse::KeepAlive::new()
            .interval(Duration::from_secs(15))
            .text("keepalive"),
    )
}

/// 根据 substance_id 查询专题信息
#[utoipa::path(
    get,
    path = "/api/v0/substance/{substance_id}",
    params(
        ("substance_id" = String, Path, description = "专题ID")
    ),
    responses(
        (status = 200, description = "返回专题信息", body = ApiResponse)
    ),
    tag = "专题查询"
)]
pub async fn query_substance(
    State(state): State<Arc<AppState>>,
    Path(substance_id): Path<String>,
) -> impl IntoResponse {
    match state.db.get_substance_by_id(&substance_id).await {
        Ok(Some(substance)) => Json(ApiResponse::success(substance, Some(1), Some(1))),
        Ok(None) => {
            // 数据库不存在，尝试从华为服务器获取
            event!(
                Level::INFO,
                "专题 {} 在数据库中不存在，尝试从华为服务器获取",
                substance_id
            );
            match crate::sync::substance::get_app_from_substance(
                &state.client,
                state.cfg.api_url(),
                &substance_id,
            )
            .await
            {
                Ok((substance_data, raw_data)) => {
                    // 保存到数据库
                    if let Err(e) = state
                        .db
                        .save_substance(&substance_data, &raw_data, None)
                        .await
                    {
                        event!(Level::WARN, "保存专题 {} 到数据库失败: {}", substance_id, e);
                        return Json(ApiResponse::error("专题保存到数据库失败"));
                    }

                    // 重新从数据库查询
                    match state.db.get_substance_by_id(&substance_id).await {
                        Ok(Some(substance)) => {
                            Json(ApiResponse::success(substance, Some(1), Some(1)))
                        }
                        Ok(None) => Json(ApiResponse::error("专题获取成功但查询失败")),
                        Err(e) => {
                            event!(Level::WARN, "查询新保存的专题信息失败: {}", e);
                            Json(ApiResponse::error("数据库查询错误"))
                        }
                    }
                }
                Err(e) => {
                    event!(
                        Level::WARN,
                        "从华为服务器获取专题 {} 失败: {}",
                        substance_id,
                        e
                    );
                    Json(ApiResponse::error("专题不存在"))
                }
            }
        }
        Err(e) => {
            event!(Level::WARN, "查询专题信息失败: {}", e);
            Json(ApiResponse::error("数据库查询错误"))
        }
    }
}

/// 分页获取专题列表
#[utoipa::path(
    get,
    path = "/api/v0/substance/list/{page}",
    params(
        ("page" = u32, Path, description = "页码（从0开始）"),
        SubstanceListQuery
    ),
    responses(
        (status = 200, description = "返回专题列表", body = ApiResponse)
    ),
    tag = "专题查询"
)]
pub async fn substance_list_paged(
    State(state): State<Arc<AppState>>,
    Path(page): Path<String>,
    Query(query): Query<SubstanceListQuery>,
) -> impl IntoResponse {
    if !query.is_valid_sort()
        && let Some(sort_key) = query.raw_sort_key()
    {
        return Json(ApiResponse::error(format!(
            "你在想什么, 不许按照 {} 排序",
            sort_key
        )));
    }

    match page.parse::<u32>() {
        Ok(page) => {
            match state
                .db
                .get_substance_list_paged(
                    page,
                    query.page_size(),
                    &query.sort_key(),
                    query.desc.unwrap_or_default(),
                )
                .await
            {
                Ok(substances) => {
                    let total_count = substances.data.len() as u32;
                    Json(ApiResponse::success(
                        substances,
                        Some(total_count),
                        Some(query.page_size()),
                    ))
                }
                Err(e) => {
                    event!(Level::WARN, "http服务获取分页专题信息失败: {}", e);
                    Json(ApiResponse::error("数据库错误，获取分页信息失败"))
                }
            }
        }
        Err(e) => Json(ApiResponse::error(format!(
            "页码解析失败: {} 你提交的是什么玩意",
            e
        ))),
    }
}
