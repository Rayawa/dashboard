use anyhow::Result;
use chrono::{DateTime, Local};
use rust_decimal::Decimal;
use serde_json::Value;
use sqlx::{Row, postgres::types::PgInterval};

use std::{ops::Range, sync::OnceLock};

use crate::db::{AppCounts, Database, DbSearch, DownloadIncrement, PageInfo};
use crate::db::{
    AppIconInfo,
    read_data::{SELECT_APP_INFO_FIELDS, SELECT_APP_METRIC_FIELDS, SELECT_APP_RATING_FIELDS},
};
use crate::model::{
    AppInfo, AppMetric, AppQuery, AppRating, FullAppInfo, FullSubstanceInfo, ShortAppInfo,
    ShortAppRating, ShortSubstanceInfo,
};

pub static SELECT_MAX_LIMIT: OnceLock<u32> = OnceLock::new();

pub fn get_max_limit() -> u32 {
    *SELECT_MAX_LIMIT.get().unwrap_or(&100)
}


/// 递归清洗 JSON，逻辑与 SQL 中的 normalize_json_by_value 一致
/// 如果 Value 是字符串且包含 "trace" (不区分大小写)，则替换为 "TRACE_MASKED"
fn normalize_json_for_comparison(val: &Value) -> Value {
    match val {
        // 1. 如果是对象，递归处理每个字段的值
        Value::Object(map) => {
            let mut new_map = serde_json::Map::new();
            for (k, v) in map {
                new_map.insert(k.clone(), normalize_json_for_comparison(v));
            }
            Value::Object(new_map)
        }
        // 2. 如果是数组，递归处理每个元素
        Value::Array(arr) => {
            Value::Array(arr.iter().map(normalize_json_for_comparison).collect())
        }
        // 3. 如果是字符串，检查是否包含 "trace"
        Value::String(s) => {
            if s.to_lowercase().contains("trace") {
                Value::String("TRACE_MASKED".to_string())
            } else {
                Value::String(s.clone())
            }
        }
        // 4. 其他类型直接克隆
        _ => val.clone(),
    }
}

impl Database {
    /// aaa
    pub async fn app_query_to_app_id(&self, app: &AppQuery) -> Result<AppQuery> {
        Ok(match app {
            AppQuery::AppId(id) => AppQuery::app_id(id),
            AppQuery::PkgName(pkg_name) => {
                let query = "SELECT app_id FROM app_info WHERE pkg_name = $1";
                let row = sqlx::query(query)
                    .bind(pkg_name)
                    .fetch_one(&self.pool)
                    .await?;
                let app_id: String = row.get("app_id");
                AppQuery::app_id(app_id)
            }
        })
    }

    /// 检查 substance 是否存在
    pub async fn substance_exists(&self, substance_id: &str) -> bool {
        let query = "SELECT COUNT(*) FROM substance_info WHERE substance_id = $1";
        let count: Option<i64> = sqlx::query(query)
            .bind(substance_id)
            .fetch_one(&self.pool)
            .await
            .ok()
            .map(|r| r.get(0));

        count.map(|c| c > 0).unwrap_or(false)
    }

    /// 获取指定 substance 的最后一条原始JSON数据
    pub async fn get_last_substance_raw_json(&self, substance_id: &str) -> Option<Value> {
        let query = r#"
            SELECT raw_json_substance
            FROM substance_history
            WHERE substance_id = $1
            ORDER BY created_at DESC
            LIMIT 1
        "#;

        let result = sqlx::query(query)
            .bind(substance_id)
            .fetch_optional(&self.pool)
            .await
            .ok()?;

        result.and_then(|r| r.try_get("raw_json_substance").ok())
    }

    /// 检查新的 substance 数据是否与最后一条数据相同（忽略 trace 信息）
        pub async fn is_same_substance_data(&self, substance_id: &str, new_data: &Value) -> bool {
            self.get_last_substance_raw_json(substance_id)
                .await
                // 假设 .await 返回的是 Result<Option<Value>> 或 Option<Value>
                // 这里保留你原本的 map/unwrap_or 结构
                .map(|last_data| {
                    // 1. 清洗数据库里的旧数据
                    let cleaned_last = normalize_json_for_comparison(&last_data);
                    // 2. 清洗传入的新数据
                    let cleaned_new = normalize_json_for_comparison(new_data);

                    // 3. 比较清洗后的版本
                    cleaned_last == cleaned_new
                })
                .unwrap_or(false)
        }

    /// 获取指定应用的最后一条原始JSON数据
    pub async fn have_app_by_name(&self, app_name: &str) -> bool {
        let query = "SELECT COUNT(*) FROM app_info WHERE name = $1";
        let count: Option<i64> = sqlx::query(query)
            .bind(app_name)
            .fetch_one(&self.pool)
            .await
            .ok()
            .map(|r| r.get(0));

        count.map(|c| c > 0).unwrap_or(false)
    }

    /// 检查应用是否已存在
    pub async fn app_exists(&self, app_query: &AppQuery) -> bool {
        let query = format!(
            "SELECT COUNT(*) FROM app_info WHERE {} = $1",
            app_query.app_db_name()
        );
        let count: Option<i64> = sqlx::query(&query)
            .bind(app_query.name())
            .fetch_one(&self.pool)
            .await
            .ok()
            .map(|r| r.get(0));

        count.map(|c| c > 0).unwrap_or(false)
    }

    /// 获取指定应用的最后一条原始JSON数据
    pub async fn get_last_raw_json_data(&self, app: &AppQuery) -> Option<Value> {
        let query = format!(
            r#"
                SELECT raw_json_data
                FROM app_data_history
                WHERE {} = $1
                ORDER BY created_at DESC
                LIMIT 1
            "#,
            app.app_db_name()
        );

        let result = sqlx::query(&query)
            .bind(app.name())
            .fetch_optional(&self.pool)
            .await
            .ok()?;

        result.and_then(|r| r.try_get("raw_json_data").ok())
    }

    /// 获取指定应用的 created_at 时间
    pub async fn get_app_created_at(&self, app: &AppQuery) -> Result<Option<DateTime<Local>>> {
        let query = format!(
            "SELECT created_at FROM app_info WHERE {} = $1",
            app.app_db_name()
        );

        let result = sqlx::query(&query)
            .bind(app.name())
            .fetch_optional(&self.pool)
            .await?;

        match result {
            Some(row) => {
                let created_at: DateTime<Local> = row.get("created_at");
                Ok(Some(created_at))
            }
            None => Ok(None),
        }
    }

    pub async fn get_app_rating(&self, app: &AppQuery) -> Option<AppRating> {
        let query = format!(
            "SELECT {} FROM app_rating WHERE {} = $1 ORDER BY id DESC LIMIT 1",
            SELECT_APP_RATING_FIELDS,
            app.app_db_name()
        );

        let result = sqlx::query(&query)
            .bind(app.name())
            .fetch_optional(&self.pool)
            .await
            .ok()??;

        Self::read_app_rating_from_row(&result)
    }

    /// 检查新数据是否与最后一条数据相同
    pub async fn is_same_data(&self, app: &AppQuery, new_data: &Value) -> bool {
        self.get_last_raw_json_data(app)
            .await
            .map(|last_data| last_data == *new_data)
            .unwrap_or(false)
    }

    /// 实际检查 app info 是否相同
    pub async fn is_same_app_info(&self, app: &AppQuery, app_info: &AppInfo) -> bool {
        self.get_app_info(app)
            .await
            .map(|d| d == *app_info)
            .unwrap_or(false)
    }

    /// 检查是不是新的 app_rating
    pub async fn is_new_app_rating(&self, app: &AppQuery, app_rating: &AppRating) -> bool {
        self.get_app_rating(app)
            .await
            .map(|mut d| {
                d.update_from_db(app_rating);
                &d != app_rating
            })
            .unwrap_or(true)
    }

    /// 从 app_full_info 表查询完整应用信息
    pub async fn get_full_app_info(&self, app: &AppQuery) -> Result<FullAppInfo> {
        let query = format!(
            "SELECT * FROM app_full_info WHERE {} = $1",
            app.app_db_name()
        );
        let full_info = sqlx::query_as::<_, FullAppInfo>(&query)
            .bind(app.name())
            .fetch_one(&self.pool)
            .await?;

        Ok(full_info)
    }

    pub async fn get_app_info(&self, app: &AppQuery) -> Option<AppInfo> {
        let query = format!(
            "SELECT {} FROM app_info WHERE {} = $1",
            SELECT_APP_INFO_FIELDS,
            app.app_db_name(),
        );
        let row = sqlx::query(&query)
            .bind(app.name())
            .fetch_one(&self.pool)
            .await
            .ok()?;
        let data = Self::read_app_info_from_row(&row);

        Some(data)
    }

    /// 实际检查 app metric 是否相同
    pub async fn is_same_app_metric(&self, app: &AppQuery, app_metric: &AppMetric) -> bool {
        self.get_app_last_metric(app)
            .await
            .map(|last_metric| {
                let mut new_metric = app_metric.clone();
                new_metric.update_from_db(&last_metric);
                new_metric == last_metric
            })
            .unwrap_or(false)
    }

    /// 获取 app 最后一次的 metric
    pub async fn get_app_last_metric(&self, app: &AppQuery) -> Option<AppMetric> {
        let query = format!(
            "SELECT {} FROM app_metrics WHERE {} = $1 ORDER BY id DESC LIMIT 1",
            SELECT_APP_METRIC_FIELDS,
            app.app_db_name()
        );
        let row = sqlx::query(&query)
            .bind(app.name())
            .fetch_optional(&self.pool)
            .await
            .ok()?;
        match row {
            Some(row) => {
                let data = Self::read_app_metric_from_row(&row);
                Some(data)
            }
            None => None,
        }
    }

    /// 获取数据库中所有的 pkg_name
    pub async fn get_all_pkg_names(&self) -> Result<Vec<String>, sqlx::Error> {
        const QUERY: &str = "SELECT pkg_name FROM app_info";

        sqlx::query_scalar(QUERY).fetch_all(&self.pool).await
    }

    /// 获取数据库中所有的 app_id
    pub async fn get_all_app_ids(&self) -> Result<Vec<String>, sqlx::Error> {
        const QUERY: &str = "SELECT app_id FROM app_info";

        sqlx::query_scalar(QUERY).fetch_all(&self.pool).await
    }

    /// 获取数据库中所有的 app name
    pub async fn get_all_app_name(&self) -> Result<Vec<String>, sqlx::Error> {
        const QUERY: &str = "SELECT name FROM app_info";

        sqlx::query_scalar(QUERY).fetch_all(&self.pool).await
    }

    /// 获取数据库中所有的 app_id
    pub async fn get_all_alliance_app_id(&self) -> Result<Vec<i64>, sqlx::Error> {
        const QUERY: &str = "SELECT alliance_app_id FROM app_info";

        sqlx::query_scalar(QUERY).fetch_all(&self.pool).await
    }

    /// 获取所有专题 ID
    pub async fn get_all_substance_id(&self) -> Result<Vec<String>, sqlx::Error> {
        const QUERY: &str = "SELECT substance_id FROM substance_info";

        sqlx::query_scalar(QUERY).fetch_all(&self.pool).await
    }

    /// 分页查询 app_info 数据,按照创建时间排序
    ///
    /// # 参数
    /// - `range`: 范围参数,例如 0..10 表示获取前10条记录
    ///
    /// # 示例
    /// ```rust
    /// let db = Database::new("postgres://...", 5).await?;
    /// let apps = db.get_app_info_paginated(0..10).await?;
    /// println!("获取到 {} 条应用信息", apps.len());
    /// ```
    pub async fn get_app_info_paginated(
        &self,
        range: Range<u32>,
        sort_key: &str,
        sort_desc: bool,
        search: Option<DbSearch>,
        exclude_huawei: bool,
        exclude_atomic: bool,
    ) -> Result<Vec<FullAppInfo>> {
        let limit = (range.end - range.start) as i64;
        let limit = limit.min(get_max_limit() as i64);
        let offset = range.start as i64;

        let order_clause = if sort_desc { "DESC" } else { "ASC" };

        let app_infos = match search {
            Some(search) => {
                // 搜索模式下参数绑定： $1(value), $2(limit), $3(offset), $4(bool), $5(bool), $6(bool)
                let key = search.key.as_str();
                let search_method = search.search_method();
                let query = format!(
                    r#"
                    SELECT *
                    FROM app_full_info
                    WHERE {key}::text {search_method} $1
                    AND (NOT $6::boolean OR {sort_key} IS NOT NULL)
                    AND (NOT $4::boolean OR dev_en_name NOT ILIKE '%huawei%')
                    AND (NOT $5::boolean OR pkg_name NOT LIKE 'com.atomicservice%')
                    ORDER BY {sort_key} {order_clause}
                    LIMIT $2 OFFSET $3
                "#
                );
                sqlx::query_as::<_, FullAppInfo>(&query)
                    .bind(search.search_value()) // $1 (搜索值)
                    .bind(limit) // $2 (LIMIT)
                    .bind(offset) // $3 (OFFSET)
                    .bind(exclude_huawei) // $4 (排除华为)
                    .bind(exclude_atomic) // $5 (排除 Atomic)
                    .bind(search.not_null) // $6 (not null 检查)
                    .fetch_all(&self.pool)
                    .await?
            }
            None => {
                // 无搜索模式下参数绑定： $1(limit), $2(offset), $3(bool), $4(bool)
                let query = format!(
                    r#"
                    SELECT *
                    FROM app_full_info
                    WHERE {sort_key} IS NOT NULL
                    AND app_id != 'C5765880207854862721'
                    AND (NOT $3::boolean OR dev_en_name NOT ILIKE '%huawei%')
                    AND (NOT $4::boolean OR pkg_name NOT LIKE 'com.atomicservice%')
                    ORDER BY {sort_key} {order_clause}
                    LIMIT $1 OFFSET $2
                "#
                );
                sqlx::query_as::<_, FullAppInfo>(&query)
                    .bind(limit) // $1 (LIMIT)
                    .bind(offset) // $2 (OFFSET)
                    .bind(exclude_huawei) // $3 (排除华为)
                    .bind(exclude_atomic) // $4 (排除 Atomic)
                    .fetch_all(&self.pool)
                    .await?
            }
        };

        Ok(app_infos)
    }

    /// Count the number of distinct developers
    pub async fn count_developers(&self) -> Result<i64, sqlx::Error> {
        sqlx::query_scalar(
            r#"
            SELECT COUNT(DISTINCT developer_name)
            FROM app_info
            WHERE developer_name IS NOT NULL
            "#,
        )
        .fetch_one(&self.pool)
        .await
    }

    /// 获取星级分布统计从 app_info 表
    ///
    /// 评分范围：无评分、1-2星、2-3星、3-4星、4-5星
    pub async fn get_star_distribution(&self) -> Result<(i64, i64, i64, i64, i64), sqlx::Error> {
        sqlx::query_as::<_, (i64, i64, i64, i64, i64)>(
            r#"
            SELECT
                COUNT(*) FILTER (WHERE average_rating IS NULL OR average_rating = 0.0) AS range_no_rating,
                COUNT(*) FILTER (WHERE average_rating >= 1.0 AND average_rating < 2.0) AS range_1_2,
                COUNT(*) FILTER (WHERE average_rating >= 2.0 AND average_rating < 3.0) AS range_2_3,
                COUNT(*) FILTER (WHERE average_rating >= 3.0 AND average_rating < 4.0) AS range_3_4,
                COUNT(*) FILTER (WHERE average_rating >= 4.0 AND average_rating <= 5.0) AS range_4_5
            FROM app_full_info
            "#,
        )
        .fetch_one(&self.pool)
        .await
    }

    /// 统计专题数量
    pub async fn count_substances(&self) -> Result<i64, sqlx::Error> {
        sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM substance_info
            "#,
        )
        .fetch_one(&self.pool)
        .await
    }

    /// 分页查询 app_info 数据（增强版），返回分页信息和数据
    ///
    /// # 参数
    /// - `page`: 页码（从1开始）
    /// - `page_size`: 每页大小
    ///
    /// # 示例
    /// ```rust
    /// let db = Database::new("postgres://...", 5).await?;
    /// let result = db.get_app_info_paginated_enhanced(1, 10).await?;
    /// println!("第 {} 页，共 {} 页，总计 {} 条记录",
    ///     result.page, result.total_pages, result.total_count);
    /// ```
    #[allow(clippy::too_many_arguments)]
    pub async fn get_app_info_paginated_enhanced<D: From<FullAppInfo>>(
        &self,
        page: u32,
        page_size: u32,
        sort_key: &str,
        sort_desc: bool,
        search: Option<DbSearch>,
        exclude_huawei: bool,
        exclude_atomic: bool,
    ) -> Result<PageInfo<D>> {
        // --- 1. 动态统计总数 (使用 SQL 条件判断) ---
        let total_count: i64 = match &search {
            Some(search @ DbSearch {
                key,
                value: _,
                is_exact: _,
                not_null,
            }) => {
                // 搜索模式下的 COUNT 查询： $1(value), $2(bool: huawei), $3(bool: atomic), $4(bool: not_null)
                let search_method = search.search_method();
                let query = format!(
                    r#"
                    SELECT COUNT(*)
                    FROM app_full_info
                    WHERE {key}::text {search_method} $1
                    AND (NOT $4::boolean OR {key} IS NOT NULL)
                    AND (NOT $2::boolean OR dev_en_name NOT ILIKE '%huawei%')
                    AND (NOT $3::boolean OR pkg_name NOT LIKE 'com.atomicservice%')
                    "#
                );
                let result: (i64,) = sqlx::query_as(&query)
                    .bind(search.search_value()) // $1 (Search Value)
                    .bind(exclude_huawei) // $2
                    .bind(exclude_atomic) // $3
                    .bind(not_null) // $4
                    .fetch_one(&self.pool)
                    .await?;
                result.0
            }
            None => {
                // 非搜索模式下的 COUNT 查询： $1(bool: huawei), $2(bool: atomic)
                let query = r#"
                    SELECT COUNT(*)
                    FROM app_full_info
                    WHERE (NOT $1::boolean OR dev_en_name NOT ILIKE '%huawei%')
                    AND (NOT $2::boolean OR pkg_name NOT LIKE 'com.atomicservice%')
                "#;
                let result: (i64,) = sqlx::query_as(query)
                    .bind(exclude_huawei) // $1
                    .bind(exclude_atomic) // $2
                    .fetch_one(&self.pool)
                    .await?;
                result.0
            }
        };
        // --- 2. 分页逻辑 ---
        let total_pages = if page_size == 0 {
            0
        } else {
            ((total_count as f32 / page_size as f32).ceil()) as u32
        };
        let offset = (page.saturating_sub(1)) * page_size;
        // --- 3. 调用分页查询（使用上一个函数实现） ---
        let data = self
            .get_app_info_paginated(
                offset..(offset + page_size),
                sort_key,
                sort_desc,
                search,
                exclude_huawei,
                exclude_atomic,
            )
            .await?
            .into_iter()
            .map(D::from)
            .collect();

        Ok(PageInfo {
            data,
            total_count: total_count as u32,
            page,
            page_size,
            total_pages,
        })
    }

    /// 获取数据库内应用数量
    pub async fn count_apps(&self) -> Result<AppCounts> {
        const QUERY: &str = r#"
        SELECT
            COUNT(*) AS total,
            SUM(CASE WHEN pkg_name NOT LIKE 'com.atomicservice.%' THEN 1 ELSE 0 END) AS apps,
            SUM(CASE WHEN pkg_name LIKE 'com.atomicservice.%' THEN 1 ELSE 0 END) AS atomic_services
        FROM
            app_info
        "#;

        Ok(sqlx::query_as(QUERY).fetch_one(&self.pool).await?)
    }

    /// 获取 app_info 表中的总记录数
    ///
    /// # 示例
    /// ```rust
    /// let db = Database::new("postgres://...", 5).await?;
    /// let count = db.get_app_info_count().await?;
    /// println!("总共有 {} 条应用记录", count);
    /// ```
    pub async fn get_app_info_count(&self) -> Result<u32> {
        const QUERY: &str = "SELECT COUNT(*) FROM app_info";

        let count: i64 = sqlx::query_scalar(QUERY).fetch_one(&self.pool).await?;

        Ok(count as u32)
    }

    /// 获取指定 pkg_id 的所有 app_metric 信息
    pub async fn get_app_metrics_by_pkg_id(&self, pkg_id: &str) -> Result<Vec<AppMetric>> {
        const QUERY: &str = r#"
            SELECT
                am.id,
                am.app_id,
                am.version,
                am.version_code,
                am.size_bytes,
                am.sha256,
                am.info_score,
                am.info_rate_count,
                am.download_count,
                am.price,
                am.release_date,
                am.new_features,
                am.upgrade_msg,
                am.target_sdk,
                am.minsdk,
                am.compile_sdk_version,
                am.min_hmos_api_level,
                am.api_release_type,
                am.created_at metrics_created_at
            FROM app_metrics am
            JOIN app_info ai ON am.app_id = ai.app_id
            WHERE ai.pkg_name = $1
            ORDER BY am.created_at DESC
        "#;

        let rows = sqlx::query(QUERY)
            .bind(pkg_id)
            .fetch_all(&self.pool)
            .await?;

        let app_metrics = rows.iter().map(Self::read_app_metric_from_row).collect();

        Ok(app_metrics)
    }

    /// 获取评分最高的应用排行
    ///
    /// # 参数
    /// - `limit`: 返回的应用数量
    ///
    /// # 示例
    /// ```rust
    /// let db = Database::new("postgres://...", 5).await?;
    /// let top_rated_apps = db.get_top_rated_apps(10).await?;
    /// println!("评分最高的应用: {:?}", top_rated_apps);
    /// ```
    pub async fn get_top_rated_apps(&self, limit: u32) -> Result<Vec<ShortAppRating>> {
        const QUERY: &str = r#"
            SELECT
                ai.app_id,
                ai.name,
                ai.pkg_name,
                ai.developer_name,
                ai.icon_url,
                ar.average_rating::text,
                ar.total_star_rating_count
            FROM app_info ai
            JOIN app_rating ar ON ai.app_id = ar.app_id
            ORDER BY ar.average_rating DESC, ar.total_star_rating_count DESC
            LIMIT $1
        "#;

        let rows = sqlx::query(QUERY)
            .bind(limit.min(get_max_limit()) as i64)
            .fetch_all(&self.pool)
            .await?;

        let mut app_ratings = Vec::new();
        for row in rows {
            let app_rating = ShortAppRating {
                app_id: row.get("app_id"),
                name: row.get("name"),
                pkg_name: row.get("pkg_name"),
                developer_name: row.get("developer_name"),
                icon_url: row.get("icon_url"),
                average_rating: {
                    let raw: String = row.get("average_rating");
                    raw.parse().unwrap_or(Decimal::ZERO)
                },
                total_star_rating_count: row.get("total_star_rating_count"),
            };
            app_ratings.push(app_rating);
        }

        Ok(app_ratings)
    }

    /// 获取最近更新的应用排行
    ///
    /// # 参数
    /// - `limit`: 返回的应用数量
    ///
    /// # 示例
    /// ```rust
    /// let db = Database::new("postgres://...", 5).await?;
    /// let recently_updated_apps = db.get_recently_updated_apps(10).await?;
    /// println!("最近更新的应用: {:?}", recently_updated_apps);
    /// ```
    pub async fn get_recently_updated_apps(&self, limit: u32) -> Result<Vec<FullAppInfo>> {
        const QUERY: &str = r#"
            SELECT
                *
            FROM app_full_info
            ORDER BY release_date DESC
            LIMIT $1
        "#;

        let rows = sqlx::query_as::<_, FullAppInfo>(QUERY)
            .bind(limit.min(get_max_limit()) as i64)
            .fetch_all(&self.pool)
            .await?;

        Ok(rows)
    }

    /// 获取价格最高的应用排行
    ///
    /// # 参数
    /// - `limit`: 返回的应用数量
    ///
    /// # 示例
    /// ```rust
    /// let db = Database::new("postgres://...", 5).await?;
    /// let top_priced_apps = db.get_top_priced_apps(10).await?;
    /// println!("价格最高的应用: {:?}", top_priced_apps);
    /// ```
    pub async fn get_top_priced_apps(&self, limit: u32) -> Result<Vec<AppMetric>> {
        const QUERY: &str = r#"
            SELECT
                am.id,
                am.app_id,
                am.version,
                am.version_code,
                am.size_bytes,
                am.sha256,
                am.info_score,
                am.info_rate_count,
                am.download_count,
                am.price,
                am.release_date,
                am.new_features,
                am.upgrade_msg,
                am.target_sdk,
                am.minsdk,
                am.compile_sdk_version,
                am.min_hmos_api_level,
                am.api_release_type,
                am.created_at
            FROM app_metrics am
            ORDER BY am.price DESC
            LIMIT $1
        "#;

        let rows = sqlx::query(QUERY)
            .bind(limit.min(get_max_limit()) as i64)
            .fetch_all(&self.pool)
            .await?;

        let app_metrics = rows.iter().map(Self::read_app_metric_from_row).collect();

        Ok(app_metrics)
    }

    /// 获取开发者排行（按发布应用数量）
    ///
    /// # 参数
    /// - `limit`: 返回的开发者数量
    ///
    /// # 示例
    /// ```rust
    /// let db = Database::new("postgres://...", 5).await?;
    /// let top_developers = db.get_top_developers(10).await?;
    /// println!("发布应用最多的开发者: {:?}", top_developers);
    /// ```
    pub async fn get_top_developers(&self, limit: u32) -> Result<Vec<(String, String, i64)>> {
        const QUERY: &str = r#"
            SELECT
                dev_id,
                developer_name,
                COUNT(*) as app_count
            FROM app_info
            GROUP BY dev_id, developer_name
            ORDER BY app_count DESC
            LIMIT $1
        "#;

        let rows = sqlx::query(QUERY)
            .bind(limit.min(get_max_limit()) as i64)
            .fetch_all(&self.pool)
            .await?;

        let mut developers = Vec::new();
        for row in rows {
            let dev_id: String = row.get("dev_id");
            let developer_name: String = row.get("developer_name");
            let app_count: i64 = row.get("app_count");
            developers.push((dev_id, developer_name, app_count));
        }

        Ok(developers)
    }

    /// 统计各种设备的兼容数量
    pub async fn count_device_code(&self) -> Result<Vec<(String, u32)>> {
        const QUERY: &str = r#"SELECT
            unnest(main_device_codes) AS device_code,
            COUNT(*) AS count
        FROM
            app_full_info
        GROUP BY
            device_code
        ORDER BY
            count DESC, device_code"#;

        let rows = sqlx::query(QUERY).fetch_all(&self.pool).await?;

        let mut device_codes = Vec::new();
        for row in rows {
            let device_code = row.get("device_code");
            let count: i32 = row.get("count");

            device_codes.push((device_code, count as u32));
        }

        Ok(device_codes)
    }

    /// 统计 min sdk 版本分布
    pub async fn count_min_sdk(&self) -> Result<Vec<(i32, u32)>> {
        const QUERY: &str = r#"SELECT
            minsdk,
            COUNT(app_id) AS app_count
        FROM
            app_full_info
        where pkg_name not like 'com.atomicservice%'
        GROUP BY
            minsdk
        ORDER BY
            minsdk;"#;

        let rows = sqlx::query(QUERY).fetch_all(&self.pool).await?;

        let mut min_sdks = Vec::new();
        for row in rows {
            let minsdk: i32 = row.get("minsdk");
            let count: i64 = row.get("app_count");

            min_sdks.push((minsdk, count as u32));
        }

        Ok(min_sdks)
    }

    /// 统计 target sdk 版本分布
    pub async fn count_target_sdk(&self) -> Result<Vec<(i32, u32)>> {
        const QUERY: &str = r#"SELECT
            target_sdk,
            COUNT(app_id) AS app_count
        FROM
            app_full_info
        where pkg_name not like 'com.atomicservice%'
        GROUP BY
            target_sdk
        ORDER BY
            target_sdk;"#;

        let rows = sqlx::query(QUERY).fetch_all(&self.pool).await?;

        let mut target_sdks = Vec::new();
        for row in rows {
            let target_sdk: i32 = row.get("target_sdk");
            let count: i64 = row.get("app_count");

            target_sdks.push((target_sdk, count as u32));
        }

        Ok(target_sdks)
    }
    pub async fn calculate_download_increase(
        &self,
        download_interval: PgInterval,
        limit: u32,
        page: Option<u32>,
        exclude_huawei: bool,
        exclude_atomic: bool,
        listed_interval: Option<PgInterval>,
    ) -> Result<(Vec<DownloadIncrement>, i64)> {
        let offset = page.unwrap_or(0) as i64;
        let safe_limit = limit.min(get_max_limit()) as i64;

        // $1: download_interval
        // <HUAWEI>: exclude_huawei
        // <ATOMIC>: exclude_atomic
        // <LISTED>: listed_interval (Original: $6)
        const BASE_LOGIC_TEMPLATE: &str = r#"
        WITH period_dates AS (
            SELECT
                (NOW() AT TIME ZONE 'Asia/Shanghai')::date AS current_period_date,
                ((NOW() AT TIME ZONE 'Asia/Shanghai')::date - $1::interval)::date AS prior_period_date
        ),
        time_ranges AS (
            SELECT
                current_period_date, prior_period_date,
                (current_period_date::timestamp AT TIME ZONE 'Asia/Shanghai') AS current_start_ts,
                ((current_period_date + interval '1 day')::timestamp AT TIME ZONE 'Asia/Shanghai') AS current_end_ts
            FROM period_dates
        ),
        current_period_metrics AS (
            SELECT DISTINCT ON (app_id)
                app_id, pkg_name, download_count, created_at
            FROM app_metrics
            WHERE created_at >= (SELECT current_start_ts FROM time_ranges)
              AND created_at < (SELECT current_end_ts FROM time_ranges)
            ORDER BY app_id, created_at DESC
        )
        SELECT <SELECT_CLAUSE>
        FROM
            current_period_metrics cpm
        INNER JOIN app_info ai ON cpm.app_id = ai.app_id
        CROSS JOIN time_ranges tr
        INNER JOIN LATERAL (
            SELECT am.download_count
            FROM app_metrics am
            WHERE am.app_id = cpm.app_id
                AND am.created_at < (tr.prior_period_date + interval '1 day')::timestamp AT TIME ZONE 'Asia/Shanghai'
            ORDER BY am.created_at DESC
            LIMIT 1
        ) ppm ON TRUE
        WHERE
            cpm.download_count > ppm.download_count
            AND (NOT <HUAWEI>::boolean OR ai.dev_en_name NOT ILIKE '%huawei%')
            AND (NOT <ATOMIC>::boolean OR cpm.pkg_name NOT LIKE 'com.atomicservice%')
            AND (<LISTED> IS NULL OR ai.listed_at >= (NOW() AT TIME ZONE 'Asia/Shanghai')::date - <LISTED>)
        <ORDER_LIMIT_CLAUSE>
        "#;

        // --- 1. 构建主查询 ---
        let select_clause = "
            cpm.app_id, ai.name AS name, cpm.pkg_name,
            tr.current_period_date, tr.prior_period_date,
            cpm.download_count AS current_download_count,
            ppm.download_count AS prior_download_count,
            (cpm.download_count - ppm.download_count) AS download_increment
        ";

        // 主查询参数: $1: interval, $2: limit, $3: offset, $4: huawei, $5: atomic, $6: listed
        let query = BASE_LOGIC_TEMPLATE
            .replace("<SELECT_CLAUSE>", select_clause)
            .replace("<HUAWEI>", "$4")
            .replace("<ATOMIC>", "$5")
            .replace("<LISTED>", "$6")
            .replace(
                "<ORDER_LIMIT_CLAUSE>",
                &format!(
                    "ORDER BY download_increment DESC, ai.name LIMIT {} OFFSET {};",
                    safe_limit, offset
                ),
            );

        // --- 2. 构建计数查询 ---
        // 计数查询参数: $1: interval, $2: huawei, $3: atomic, $4: listed
        let count_query = BASE_LOGIC_TEMPLATE
            .replace("<SELECT_CLAUSE>", "COUNT(*)")
            .replace("<HUAWEI>", "$2")
            .replace("<ATOMIC>", "$3")
            .replace("<LISTED>", "$4")
            .replace("<ORDER_LIMIT_CLAUSE>", ""); // 无排序和限制

        // --- 3. 执行查询 ---

        let results = sqlx::query_as::<_, DownloadIncrement>(&query)
            .bind(download_interval) // $1
            .bind(safe_limit) // $2 (注入 $2, $3 但实际参数在 $4, $5, $6)
            .bind(offset) // $3
            .bind(exclude_huawei) // $4
            .bind(exclude_atomic) // $5
            .bind(listed_interval) // $6
            .fetch_all(&self.pool)
            .await?;

        let total_count: i64 = sqlx::query_scalar(&count_query)
            .bind(download_interval) // $1
            .bind(exclude_huawei) // $2
            .bind(exclude_atomic) // $3
            .bind(listed_interval) // $4
            .fetch_one(&self.pool)
            .await?;

        Ok((results, total_count))
    }

    pub async fn get_app_icon(&self, app_query: &AppQuery) -> Option<AppIconInfo> {
        let query = format!(
            "SELECT app_id, pkg_name, name, icon_url
            FROM app_info WHERE {} = $1",
            app_query.app_db_name()
        );

        sqlx::query_as::<_, AppIconInfo>(&query)
            .bind(app_query.name())
            .fetch_optional(&self.pool)
            .await
            .ok()?
    }

    /// 根据 substance_id 查询专题信息
    pub async fn get_substance_by_id(
        &self,
        substance_id: &str,
    ) -> Result<Option<FullSubstanceInfo>> {
        // 先查询专题基本信息
        #[derive(sqlx::FromRow)]
        struct SubstanceBasicInfo {
            substance_id: String,
            title: String,
            subtitle: Option<String>,
            name: Option<String>,
            comment: Option<serde_json::Value>,
            created_at: DateTime<Local>,
        }

        const SUBSTANCE_QUERY: &str = r#"
            SELECT substance_id, title, subtitle, name, comment, created_at
            FROM substance_info
            WHERE substance_id = $1
        "#;

        let substance_info: Option<SubstanceBasicInfo> = sqlx::query_as(SUBSTANCE_QUERY)
            .bind(substance_id)
            .fetch_optional(&self.pool)
            .await?;

        let Some(info) = substance_info else {
            return Ok(None);
        };

        // 查询该专题下的所有应用
        const APPS_QUERY: &str = r#"
            SELECT
                ai.app_id,
                ai.name,
                ai.pkg_name,
                ai.icon_url,
                ai.created_at as create_at
            FROM substance_app_map sam
            INNER JOIN app_info ai ON sam.app_id = ai.app_id
            WHERE sam.substance_id = $1
            ORDER BY ai.app_id
        "#;

        let apps: Vec<ShortAppInfo> = sqlx::query_as(APPS_QUERY)
            .bind(substance_id)
            .fetch_all(&self.pool)
            .await?;

        Ok(Some(FullSubstanceInfo {
            substance_id: info.substance_id,
            title: info.title,
            subtitle: info.subtitle,
            name: info.name,
            comment: info.comment,
            created_at: info.created_at,
            apps,
        }))
    }

    /// 分页获取专题列表（简略信息）
    pub async fn get_substance_list_paged(
        &self,
        page: u32,
        page_size: u32,
        sort_key: &str,
        desc: bool,
    ) -> Result<PageInfo<ShortSubstanceInfo>> {
        let safe_limit = page_size.min(get_max_limit());
        let offset = page * safe_limit;

        // 验证排序字段
        let valid_sort_fields = ["created_at", "substance_id"];
        let sort_field = if valid_sort_fields.contains(&sort_key) {
            sort_key
        } else {
            "created_at"
        };

        let order = if desc { "DESC" } else { "ASC" };

        // 构建查询语句
        let query = format!(
            r#"
            SELECT substance_id, title, subtitle, created_at
            FROM substance_info
            ORDER BY {} {}
            LIMIT $1 OFFSET $2
            "#,
            sort_field, order
        );

        let count_query = "SELECT COUNT(*) FROM substance_info";

        let results = sqlx::query_as::<_, ShortSubstanceInfo>(&query)
            .bind(safe_limit as i64)
            .bind(offset as i64)
            .fetch_all(&self.pool)
            .await?;

        let total_count: i64 = sqlx::query_scalar(count_query)
            .fetch_one(&self.pool)
            .await?;

        let total_count = total_count as u32;
        let total_pages = total_count.div_ceil(safe_limit);

        Ok(PageInfo {
            data: results,
            total_count,
            page,
            page_size: safe_limit,
            total_pages,
        })
    }
}
