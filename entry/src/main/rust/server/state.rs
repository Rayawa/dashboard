use reqwest::Client;
use serde::{Deserialize, Serialize};
use sqlx::postgres::types::PgInterval;
use utoipa::{IntoParams, ToSchema};

use crate::{
    config::Config,
    db::{Database, DbSearch},
    model::AppQuery,
};

/// 应用状态，包含数据库连接、HTTP客户端和配置
#[derive(Clone)]
pub struct AppState {
    pub db: Database,
    pub client: Client,
    pub cfg: Config,
}

impl AppState {
    /// 创建新的应用状态
    pub fn new(db: Database, client: Client, cfg: Config) -> Self {
        Self { db, client, cfg }
    }
}

/// 用于API响应的统一格式
#[derive(Serialize, Deserialize, Clone, Debug, ToSchema)]
pub struct ApiResponse {
    /// 请求是否成功
    pub success: bool,
    /// 返回的数据，通常为任意 JSON 值
    pub data: serde_json::Value,
    /// 可选的总条目数（用于分页）
    pub total: Option<u32>,
    /// 可选的分页限制（用于分页）
    pub limit: Option<u32>,
    /// 响应生成时间戳（UTC）
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

impl ApiResponse {
    /// 创建成功的API响应
    pub fn success<T: serde::Serialize>(data: T, total: Option<u32>, limit: Option<u32>) -> Self {
        Self {
            success: true,
            data: serde_json::to_value(data).unwrap_or_default(),
            total,
            limit,
            timestamp: chrono::Utc::now(),
        }
    }

    /// 创建失败的API响应
    pub fn error(error_msg: impl ToString) -> Self {
        Self {
            success: false,
            data: serde_json::json!({"error": error_msg.to_string()}),
            total: None,
            limit: None,
            timestamp: chrono::Utc::now(),
        }
    }
    /// 创建失败的API响应
    pub fn error_with_value(error: serde_json::Value) -> Self {
        Self {
            success: false,
            data: error,
            total: None,
            limit: None,
            timestamp: chrono::Utc::now(),
        }
    }
}

/// 用于排行API的查询参数
#[derive(Deserialize, Serialize, Clone, Debug, ToSchema, IntoParams)]
pub struct RankingQuery {
    /// 最大返回数量
    pub limit: Option<u32>,
    /// 排除的包名模式
    pub exclude_pattern: Option<String>,
    /// 时间范围，例如 "7d", "30d"
    pub time_range: Option<String>,
}

impl Default for RankingQuery {
    fn default() -> Self {
        Self {
            limit: Some(10),
            exclude_pattern: None,
            time_range: None,
        }
    }
}

/// 用于查询应用列表的查询参数
#[derive(Deserialize, Serialize, Clone, Debug, Default, ToSchema, IntoParams)]
pub struct AppListQuery {
    /// 排序字段
    pub sort: Option<String>,
    /// 是否降序
    pub desc: Option<bool>,
    /// 搜索字段名称
    pub search_key: Option<String>,
    /// 搜索字段的值
    pub search_value: Option<String>,
    /// 是否精确匹配
    pub search_exact: Option<bool>,
    /// 搜索时是否排除空值
    pub search_not_null: Option<bool>,
    /// 每页大小
    pub page_size: Option<u32>,
    /// 返回详细信息（true）或简略信息（false）
    pub detail: Option<bool>,
    /// 是否排除华为来源应用
    pub exclude_huawei: Option<bool>,
    /// 是否排除原子化应用
    pub exclude_atomic: Option<bool>,
}

impl AppListQuery {
    pub fn is_valid_sort(&self) -> bool {
        if let Some(sort_field) = &self.sort {
            matches!(
                sort_field.as_str(),
                "download_count"
                    | "average_rating"
                    | "total_star_rating_count"
                    | "price"
                    | "size_bytes"
                    | "rating_count"
                    | "created_at"
                    | "listed_at"
                    | "metrics_created_at"
                    | "rating_created_at"
                    | "version"
                    | "version_code"
            )
        } else {
            false
        }
    }
    pub fn exclude_huawei(&self) -> bool {
        self.exclude_huawei.unwrap_or(false)
    }
    pub fn exclude_atomic(&self) -> bool {
        self.exclude_atomic.unwrap_or(false)
    }

    pub fn sort_key(&self) -> String {
        if self.is_valid_sort() {
            self.sort.as_deref().unwrap_or("created_at").to_string()
        } else {
            "created_at".to_string()
        }
    }

    pub fn raw_sort_key(&self) -> Option<String> {
        self.sort.clone()
    }

    pub fn page_size(&self) -> u32 {
        self.page_size.unwrap_or(100)
    }

    pub fn detail(&self) -> bool {
        self.detail.unwrap_or(true)
    }

    pub fn is_valid_search(&self) -> bool {
        if let Some(key) = &self.search_key {
            matches!(
                key.as_str(),
                "name"
                    | "pkg_name"
                    | "app_id"
                    | "dev_id"
                    | "developer_name"
                    | "dev_en_name"
                    | "description"
                    | "supplier"
                    | "kind_name"
                    | "kind_type_name"
                    | "tag_name"
                    | "minsdk"
                    | "target_sdk"
            )
        } else {
            false
        }
    }

    pub fn raw_search_key(&self) -> Option<String> {
        self.search_key.clone()
    }

    pub fn search_option(&self) -> Option<DbSearch> {
        if !self.is_valid_search() {
            return None;
        }
        match (&self.search_key, &self.search_value) {
            (Some(key), Some(value)) => Some(DbSearch::new(
                key.clone(),
                value.clone(),
                self.search_exact.unwrap_or(false),
                self.search_not_null.unwrap_or(true),
            )),
            _ => None,
        }
    }
}

// 定义一个结构体来接收 URL 查询参数
#[derive(Debug, Deserialize, Serialize, ToSchema, IntoParams)]
pub struct IntervalParams {
    /// 月数间隔
    months: Option<u32>,
    /// 天数间隔
    days: Option<u32>,
    /// 返回限制
    limit: Option<u32>,
    /// 已上架天数
    listed_days: Option<u32>,
    /// 已上架月数
    listed_months: Option<u32>,
    /// 分页页码
    pub page: Option<u32>,
    /// 是否排除华为来源
    exclude_huawei: Option<bool>,
    /// 是否排除原子化应用
    exclude_atomic: Option<bool>,
}

impl IntervalParams {
    pub fn to_pg_interval(&self) -> PgInterval {
        PgInterval {
            months: self.months.unwrap_or(0) as i32,
            days: self.days.unwrap_or(1) as i32,
            microseconds: 0,
        }
    }
    pub fn listed_interval(&self) -> Option<PgInterval> {
        if self.listed_months.is_none() && self.listed_days.is_none() {
            return None;
        }
        Some(PgInterval {
            months: self.listed_months.unwrap_or(0) as i32,
            days: self.listed_days.unwrap_or(0) as i32,
            microseconds: 0,
        })
    }
    pub fn limit(&self) -> u32 {
        self.limit.unwrap_or(100)
    }
    pub fn exclude_huawei(&self) -> bool {
        self.exclude_huawei.unwrap_or(false)
    }
    pub fn exclude_atomic(&self) -> bool {
        self.exclude_atomic.unwrap_or(false)
    }
}

// 用来请求某个 app 信息的 query
#[derive(Debug, Deserialize, Serialize, ToSchema, IntoParams)]
pub struct AppQueryParam {
    /// 应用 ID
    pub app_id: Option<String>,
    /// 包名
    pub pkg_name: Option<String>,
}

impl AppQueryParam {
    pub fn is_valid(&self) -> bool {
        self.app_id.is_some() || self.pkg_name.is_some()
    }

    pub fn as_query(&self) -> Option<AppQuery> {
        if let Some(app_id) = &self.app_id {
            Some(AppQuery::AppId(app_id.clone()))
        } else {
            self.pkg_name
                .as_ref()
                .map(|pkg_name| AppQuery::PkgName(pkg_name.clone()))
        }
    }
}

// 专题列表查询参数
#[derive(Debug, Deserialize, Serialize, ToSchema, IntoParams)]
pub struct SubstanceListQuery {
    /// 排序字段
    pub sort: Option<String>,
    /// 是否降序
    pub desc: Option<bool>,
    /// 每页大小
    pub page_size: Option<u32>,
}

impl SubstanceListQuery {
    pub fn is_valid_sort(&self) -> bool {
        if let Some(sort_field) = &self.sort {
            matches!(sort_field.as_str(), "created_at" | "substance_id")
        } else {
            false
        }
    }

    pub fn sort_key(&self) -> String {
        if self.is_valid_sort() {
            self.sort.as_deref().unwrap_or("created_at").to_string()
        } else {
            "created_at".to_string()
        }
    }

    pub fn raw_sort_key(&self) -> Option<String> {
        self.sort.clone()
    }

    pub fn page_size(&self) -> u32 {
        self.page_size.unwrap_or(100)
    }
}
