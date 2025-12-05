use crate::model::{AppInfo, AppMetric, AppRating, AppRecord, FullAppInfo, raw::RawAppData};
use crate::sync::substance::SubstanceData;

use anyhow::Result;
use chrono::{DateTime, Local, NaiveDate};
use serde::{Deserialize, Serialize};
use serde_json::Value as JsonValue;

use sqlx::{
    FromRow,
    postgres::{PgPool, PgPoolOptions},
};

pub mod insert;
pub mod query;
pub mod read_data;
pub mod statistics;

/// 分页查询结果
#[derive(Debug, Deserialize, Serialize)]
pub struct PageInfo<D> {
    pub data: Vec<D>,
    pub total_count: u32,
    pub page: u32,
    pub page_size: u32,
    pub total_pages: u32,
}

#[derive(Debug, Clone)]
pub struct Database {
    pub pool: PgPool,
}

#[derive(Debug, Clone)]
pub struct DbSearch {
    pub key: String,
    pub value: String,
    pub is_exact: bool,
    pub not_null: bool,
}

#[derive(Debug, Serialize, FromRow)]
pub struct DownloadIncrement {
    pub app_id: String,
    pub name: String,
    pub pkg_name: String,
    pub current_period_date: NaiveDate,
    pub prior_period_date: NaiveDate,
    pub current_download_count: i64,
    pub prior_download_count: i64,
    pub download_increment: i64,
}

#[derive(Debug, FromRow, Deserialize, Serialize)]
pub struct AppCounts {
    pub total: i64,
    pub apps: i64,
    pub atomic_services: i64,
}

#[derive(Debug, FromRow, Deserialize, Serialize)]
pub struct AppIconInfo {
    pub app_id: String,
    pub pkg_name: String,
    pub name: String,
    pub icon_url: String,
}

impl DbSearch {
    pub fn new(key: String, value: String, is_exact: bool, not_null: bool) -> Self {
        Self {
            key,
            value,
            is_exact,
            not_null,
        }
    }
    pub fn exact(key: String, value: String, not_null: bool) -> Self {
        Self {
            key,
            value,
            is_exact: true,
            not_null,
        }
    }
    pub fn fuzzy(key: String, value: String, not_null: bool) -> Self {
        Self {
            key,
            value,
            is_exact: false,
            not_null,
        }
    }
    /// exact: 不动
    /// not exact: %value%
    pub fn search_value(&self) -> String {
        if self.is_exact || self.is_int_search() {
            self.value.clone()
        } else {
            format!("%{}%", self.value)
        }
    }
    pub fn is_int_search(&self) -> bool {
        matches!(self.key.as_str(), "minsdk" | "target_sdk")
    }
    pub fn search_method(&self) -> String {
        if self.is_int_search() {
            "="
        } else {
            "ILIKE"
        }.to_string()
    }
}

impl Database {
    /// 创建数据库连接池
    pub async fn new(database_url: &str, max_connect: u32) -> Result<Self> {
        let pool = PgPoolOptions::new()
            .max_connections(max_connect)
            .connect(database_url)
            .await?;

        Ok(Self { pool })
    }

    /// 保存应用数据到数据库
    /// 返回布尔值表示是否插入了新数据，以及从 app_full_info 查询到的最新完整数据
    /// 返回: (info_updated, metric_updated, rating_updated, full_app_info)
    pub async fn save_app_data(
        &self,
        data: RawAppData,
        listed_at: Option<DateTime<Local>>,
        comment: Option<JsonValue>,
    ) -> Result<(bool, bool, bool, FullAppInfo)> {
        // 转换原始JSON数据用于比较
        let query = data.id_query();
        let app_id = data.app_id();

        let raw_data = data.app_info;
        let raw_value = data.app_info_json;
        let exists = self.app_exists(&query).await;

        // 检查并更新 app_info 和 app_metrics
        let insert_data = if exists && self.is_same_data(&query, &raw_value).await {
            (false, false)
        } else {
            let mut app_info: AppInfo = (&raw_data).into();
            app_info.comment = comment;
            if let Some(listed_at) = listed_at {
                app_info.listed_at = listed_at;
            }

            // 转换并保存应用信息
            let info_new = if self.is_same_app_info(&query, &app_info).await {
                false
            } else {
                self.insert_app_info(&app_info).await?;
                true
            };

            // 保存指标信息
            let app_metric = AppMetric::from_raw_data(&raw_data);
            let metric_new = if self.is_same_app_metric(&query, &app_metric).await {
                false
            } else {
                self.insert_app_metric(&app_metric).await?;
                true
            };
            (info_new, metric_new)
        };

        // 保存评分信息（如果有）
        let insert_rate = if let Some(raw_star) = data.app_rating.as_ref() {
            let app_rating = AppRating::from_raw_star(&raw_data, raw_star);
            // is_new_app_rating 返回 true 表示与数据库不同，需要插入
            if self.is_new_app_rating(&query, &app_rating).await {
                self.insert_app_rating(&app_rating).await?;
                true
            } else {
                false
            }
        } else {
            false
        };

        // 保存/覆盖 备案信息 (如果有的话)
        if let Some(record) = data.app_record.as_ref() {
            let app_record = AppRecord::from_raw_record(&app_id, record);
            self.insert_app_record(&app_record).await?;
        }

        // 如果有数据更新，记录历史
        if insert_data.0 || insert_data.1 {
            self.insert_data_history(&app_id, &raw_value).await?;
        }

        // 从 app_full_info 表查询最新的完整数据（trigger 已自动更新）
        let full_info = self.get_full_app_info(&query).await?;

        Ok((insert_data.0, insert_data.1, insert_rate, full_info))
    }

    /// 保存 substance 数据到数据库
    pub async fn save_substance(
        &self,
        substance: &SubstanceData,
        raw_substance: &JsonValue,
        comment: Option<JsonValue>,
    ) -> Result<bool> {
        let is_new = !self.substance_exists(&substance.id).await;
        self.insert_substance(substance, if is_new { comment } else { None })
            .await?;

        // 只在数据发生变化时插入历史记录
        if !self.is_same_substance_data(&substance.id, raw_substance).await {
            self.insert_substance_history(&substance.id, raw_substance)
                .await?;
        }

        for app_query in &substance.data {
            let query = self.app_query_to_app_id(app_query).await?;
            self.insert_substance_app_map(&substance.id, query.name())
                .await?;
        }

        // println!(
        //     "{}",
        //     format!("插入新的 substance {} ({})", substance.id, substance.title).bright_green()
        // );

        Ok(is_new)
    }
}
