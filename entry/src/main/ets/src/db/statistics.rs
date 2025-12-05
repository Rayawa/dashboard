//! 统计系统数据库操作模块
//!
//! 提供统计数据的持久化和查询功能

use anyhow::Result;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, Row};
use std::net::IpAddr;

use super::Database;

/// 访问日志记录
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccessLog {
    pub timestamp: DateTime<Utc>,
    pub ip_address: IpAddr,
    pub user_agent: String,
    pub request_method: String,
    pub request_path: String,
}

/// UA 统计记录（总体）
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UaStatistic {
    pub user_agent: String,
    pub access_count: i64,
    pub first_seen_at: DateTime<Utc>,
    pub last_seen_at: DateTime<Utc>,
}

/// IP 统计记录（总体）
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct IpStatistic {
    pub ip_address: IpAddr,
    pub access_count: i64,
    pub first_seen_at: DateTime<Utc>,
    pub last_seen_at: DateTime<Utc>,
}

/// UA 每小时统计记录
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UaHourlyStatistic {
    pub user_agent: String,
    pub hour_timestamp: DateTime<Utc>,
    pub access_count: i64,
}

/// IP 每小时统计记录
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct IpHourlyStatistic {
    pub ip_address: IpAddr,
    pub hour_timestamp: DateTime<Utc>,
    pub access_count: i64,
}

/// 访问日志记录（带ID，从数据库查询）
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AccessLogRecord {
    pub id: i64,
    pub timestamp: DateTime<Utc>,
    pub ip_address: IpAddr,
    pub user_agent: String,
    pub request_method: String,
    pub request_path: String,
}

impl Database {
    /// 批量插入访问日志
    ///
    /// 使用批量插入提高性能
    pub async fn batch_insert_access_logs(&self, logs: &[AccessLog]) -> Result<u64> {
        if logs.is_empty() {
            return Ok(0);
        }

        let mut query_builder = sqlx::QueryBuilder::new(
            "INSERT INTO access_logs (timestamp, ip_address, user_agent, request_method, request_path) ",
        );

        query_builder.push_values(logs, |mut b, log| {
            b.push_bind(log.timestamp)
                .push_bind(log.ip_address)
                .push_bind(&log.user_agent)
                .push_bind(&log.request_method)
                .push_bind(&log.request_path);
        });

        let result = query_builder.build().execute(&self.pool).await?;
        Ok(result.rows_affected())
    }

    /// UPSERT UA 统计数据（总体）
    ///
    /// 如果记录存在则更新访问次数和最后访问时间，否则插入新记录
    pub async fn upsert_ua_statistics(
        &self,
        user_agent: &str,
        access_count: u64,
        first_seen: DateTime<Utc>,
        last_seen: DateTime<Utc>,
    ) -> Result<()> {
        sqlx::query(
            r#"
            INSERT INTO ua_statistics (user_agent, access_count, first_seen_at, last_seen_at)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (user_agent) DO UPDATE SET
                access_count = EXCLUDED.access_count,
                last_seen_at = GREATEST(ua_statistics.last_seen_at, EXCLUDED.last_seen_at)
            "#,
        )
        .bind(user_agent)
        .bind(access_count as i64)
        .bind(first_seen)
        .bind(last_seen)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// UPSERT IP 统计数据（总体）
    ///
    /// 如果记录存在则更新访问次数和最后访问时间，否则插入新记录
    pub async fn upsert_ip_statistics(
        &self,
        ip_address: IpAddr,
        access_count: u64,
        first_seen: DateTime<Utc>,
        last_seen: DateTime<Utc>,
    ) -> Result<()> {
        sqlx::query(
            r#"
            INSERT INTO ip_statistics (ip_address, access_count, first_seen_at, last_seen_at)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (ip_address) DO UPDATE SET
                access_count = EXCLUDED.access_count,
                last_seen_at = GREATEST(ip_statistics.last_seen_at, EXCLUDED.last_seen_at)
            "#,
        )
        .bind(ip_address)
        .bind(access_count as i64)
        .bind(first_seen)
        .bind(last_seen)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// UPSERT UA 每小时统计数据
    ///
    /// 如果记录存在则累加访问次数，否则插入新记录
    pub async fn upsert_ua_hourly_statistics(
        &self,
        user_agent: &str,
        hour_timestamp: DateTime<Utc>,
        access_count: u64,
    ) -> Result<()> {
        sqlx::query(
            r#"
            INSERT INTO ua_hourly_statistics (user_agent, hour_timestamp, access_count)
            VALUES ($1, $2, $3)
            ON CONFLICT (user_agent, hour_timestamp) DO UPDATE SET
                access_count = EXCLUDED.access_count
            "#,
        )
        .bind(user_agent)
        .bind(hour_timestamp)
        .bind(access_count as i64)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// UPSERT IP 每小时统计数据
    ///
    /// 如果记录存在则累加访问次数，否则插入新记录
    pub async fn upsert_ip_hourly_statistics(
        &self,
        ip_address: IpAddr,
        hour_timestamp: DateTime<Utc>,
        access_count: u64,
    ) -> Result<()> {
        sqlx::query(
            r#"
            INSERT INTO ip_hourly_statistics (ip_address, hour_timestamp, access_count)
            VALUES ($1, $2, $3)
            ON CONFLICT (ip_address, hour_timestamp) DO UPDATE SET
                access_count = EXCLUDED.access_count
            "#,
        )
        .bind(ip_address)
        .bind(hour_timestamp)
        .bind(access_count as i64)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// 批量 UPSERT UA 统计数据
    ///
    /// 使用批量操作提高性能
    pub async fn batch_upsert_ua_statistics(
        &self,
        stats: &[(String, u64, DateTime<Utc>, DateTime<Utc>)],
    ) -> Result<u64> {
        if stats.is_empty() {
            return Ok(0);
        }

        let mut query_builder = sqlx::QueryBuilder::new(
            r#"INSERT INTO ua_statistics (user_agent, access_count, first_seen_at, last_seen_at) "#,
        );

        query_builder.push_values(stats, |mut b, stat| {
            b.push_bind(&stat.0)
                .push_bind(stat.1 as i64)
                .push_bind(stat.2)
                .push_bind(stat.3);
        });

        query_builder.push(
            r#" ON CONFLICT (user_agent) DO UPDATE SET
                access_count = ua_statistics.access_count + EXCLUDED.access_count,
                last_seen_at = GREATEST(ua_statistics.last_seen_at, EXCLUDED.last_seen_at)"#,
        );

        let result = query_builder.build().execute(&self.pool).await?;
        Ok(result.rows_affected())
    }

    /// 批量 UPSERT IP 统计数据
    ///
    /// 使用批量操作提高性能
    pub async fn batch_upsert_ip_statistics(
        &self,
        stats: &[(IpAddr, u64, DateTime<Utc>, DateTime<Utc>)],
    ) -> Result<u64> {
        if stats.is_empty() {
            return Ok(0);
        }

        let mut query_builder = sqlx::QueryBuilder::new(
            r#"INSERT INTO ip_statistics (ip_address, access_count, first_seen_at, last_seen_at) "#,
        );

        query_builder.push_values(stats, |mut b, stat| {
            b.push_bind(stat.0)
                .push_bind(stat.1 as i64)
                .push_bind(stat.2)
                .push_bind(stat.3);
        });

        query_builder.push(
            r#" ON CONFLICT (ip_address) DO UPDATE SET
                access_count = ip_statistics.access_count + EXCLUDED.access_count,
                last_seen_at = GREATEST(ip_statistics.last_seen_at, EXCLUDED.last_seen_at)"#,
        );

        let result = query_builder.build().execute(&self.pool).await?;
        Ok(result.rows_affected())
    }

    /// 批量 UPSERT UA 每小时统计数据
    ///
    /// 使用批量操作提高性能
    pub async fn batch_upsert_ua_hourly_statistics(
        &self,
        stats: &[(String, DateTime<Utc>, u64)],
    ) -> Result<u64> {
        if stats.is_empty() {
            return Ok(0);
        }

        let mut query_builder = sqlx::QueryBuilder::new(
            r#"INSERT INTO ua_hourly_statistics (user_agent, hour_timestamp, access_count) "#,
        );

        query_builder.push_values(stats, |mut b, stat| {
            b.push_bind(&stat.0)
                .push_bind(stat.1)
                .push_bind(stat.2 as i64);
        });

        query_builder.push(
            r#" ON CONFLICT (user_agent, hour_timestamp) DO UPDATE SET
                access_count = ua_hourly_statistics.access_count + EXCLUDED.access_count"#,
        );

        let result = query_builder.build().execute(&self.pool).await?;
        Ok(result.rows_affected())
    }

    /// 批量 UPSERT IP 每小时统计数据
    ///
    /// 使用批量操作提高性能
    pub async fn batch_upsert_ip_hourly_statistics(
        &self,
        stats: &[(IpAddr, DateTime<Utc>, u64)],
    ) -> Result<u64> {
        if stats.is_empty() {
            return Ok(0);
        }

        let mut query_builder = sqlx::QueryBuilder::new(
            r#"INSERT INTO ip_hourly_statistics (ip_address, hour_timestamp, access_count) "#,
        );

        query_builder.push_values(stats, |mut b, stat| {
            b.push_bind(stat.0)
                .push_bind(stat.1)
                .push_bind(stat.2 as i64);
        });

        query_builder.push(
            r#" ON CONFLICT (ip_address, hour_timestamp) DO UPDATE SET
                access_count = ip_hourly_statistics.access_count + EXCLUDED.access_count"#,
        );

        let result = query_builder.build().execute(&self.pool).await?;
        Ok(result.rows_affected())
    }

    /// 从数据库加载 UA 统计数据
    pub async fn load_ua_statistics(&self) -> Result<Vec<UaStatistic>> {
        let records = sqlx::query_as::<_, UaStatistic>(
            r#"
            SELECT user_agent, access_count, first_seen_at, last_seen_at
            FROM ua_statistics
            ORDER BY access_count DESC
            "#,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(records)
    }

    /// 从数据库加载 IP 统计数据
    pub async fn load_ip_statistics(&self) -> Result<Vec<IpStatistic>> {
        let records = sqlx::query_as::<_, IpStatistic>(
            r#"
            SELECT ip_address, access_count, first_seen_at, last_seen_at
            FROM ip_statistics
            ORDER BY access_count DESC
            "#,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(records)
    }

    /// 查询 UA 统计数据（分页）
    pub async fn query_ua_statistics(
        &self,
        page: u32,
        page_size: u32,
    ) -> Result<(Vec<UaStatistic>, i64)> {
        let offset = (page.saturating_sub(1)) * page_size;

        let total: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM ua_statistics")
            .fetch_one(&self.pool)
            .await?;

        let records = sqlx::query_as::<_, UaStatistic>(
            r#"
            SELECT user_agent, access_count, first_seen_at, last_seen_at
            FROM ua_statistics
            ORDER BY access_count DESC
            LIMIT $1 OFFSET $2
            "#,
        )
        .bind(page_size as i64)
        .bind(offset as i64)
        .fetch_all(&self.pool)
        .await?;

        Ok((records, total.0))
    }

    /// 查询 IP 统计数据（分页）
    pub async fn query_ip_statistics(
        &self,
        page: u32,
        page_size: u32,
    ) -> Result<(Vec<IpStatistic>, i64)> {
        let offset = (page.saturating_sub(1)) * page_size;

        let total: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM ip_statistics")
            .fetch_one(&self.pool)
            .await?;

        let records = sqlx::query_as::<_, IpStatistic>(
            r#"
            SELECT ip_address, access_count, first_seen_at, last_seen_at
            FROM ip_statistics
            ORDER BY access_count DESC
            LIMIT $1 OFFSET $2
            "#,
        )
        .bind(page_size as i64)
        .bind(offset as i64)
        .fetch_all(&self.pool)
        .await?;

        Ok((records, total.0))
    }

    /// 查询 UA 每小时统计数据
    pub async fn query_ua_hourly_statistics(
        &self,
        user_agent: &str,
        start_time: DateTime<Utc>,
        end_time: DateTime<Utc>,
    ) -> Result<Vec<UaHourlyStatistic>> {
        let records = sqlx::query_as::<_, UaHourlyStatistic>(
            r#"
            SELECT user_agent, hour_timestamp, access_count
            FROM ua_hourly_statistics
            WHERE user_agent = $1 AND hour_timestamp BETWEEN $2 AND $3
            ORDER BY hour_timestamp ASC
            "#,
        )
        .bind(user_agent)
        .bind(start_time)
        .bind(end_time)
        .fetch_all(&self.pool)
        .await?;

        Ok(records)
    }

    /// 查询 IP 每小时统计数据
    pub async fn query_ip_hourly_statistics(
        &self,
        ip_address: IpAddr,
        start_time: DateTime<Utc>,
        end_time: DateTime<Utc>,
    ) -> Result<Vec<IpHourlyStatistic>> {
        let records = sqlx::query_as::<_, IpHourlyStatistic>(
            r#"
            SELECT ip_address, hour_timestamp, access_count
            FROM ip_hourly_statistics
            WHERE ip_address = $1 AND hour_timestamp BETWEEN $2 AND $3
            ORDER BY hour_timestamp ASC
            "#,
        )
        .bind(ip_address)
        .bind(start_time)
        .bind(end_time)
        .fetch_all(&self.pool)
        .await?;

        Ok(records)
    }

    /// 查询访问日志（分页）
    pub async fn query_access_logs(
        &self,
        page: u32,
        page_size: u32,
        ip_filter: Option<IpAddr>,
        ua_filter: Option<String>,
        path_filter: Option<String>,
    ) -> Result<(Vec<AccessLogRecord>, i64)> {
        let offset = (page.saturating_sub(1)) * page_size;

        // 构建查询条件
        let mut where_clauses = Vec::new();
        let mut bind_index = 3; // 从 3 开始，因为 1 和 2 已被 LIMIT 和 OFFSET 使用

        if ip_filter.is_some() {
            where_clauses.push(format!("ip_address = ${}", bind_index));
            bind_index += 1;
        }
        if ua_filter.is_some() {
            where_clauses.push(format!("user_agent LIKE ${}", bind_index));
            bind_index += 1;
        }
        if path_filter.is_some() {
            where_clauses.push(format!("request_path LIKE ${}", bind_index));
        }

        let where_clause = if where_clauses.is_empty() {
            String::new()
        } else {
            format!("WHERE {}", where_clauses.join(" AND "))
        };

        // 查询总数
        let count_query = format!("SELECT COUNT(*) FROM access_logs {}", where_clause);
        let mut count_query_builder = sqlx::query_as::<_, (i64,)>(&count_query);

        if let Some(ip) = ip_filter {
            count_query_builder = count_query_builder.bind(ip);
        }
        if let Some(ref ua) = ua_filter {
            count_query_builder = count_query_builder.bind(format!("%{}%", ua));
        }
        if let Some(ref path) = path_filter {
            count_query_builder = count_query_builder.bind(format!("%{}%", path));
        }

        let total: (i64,) = count_query_builder.fetch_one(&self.pool).await?;

        // 查询数据
        let select_query = format!(
            "SELECT id, timestamp, ip_address, user_agent, request_method, request_path FROM access_logs {} ORDER BY timestamp DESC LIMIT $1 OFFSET $2",
            where_clause
        );

        let mut query_builder = sqlx::query_as::<_, AccessLogRecord>(&select_query)
            .bind(page_size as i64)
            .bind(offset as i64);

        if let Some(ip) = ip_filter {
            query_builder = query_builder.bind(ip);
        }
        if let Some(ref ua) = ua_filter {
            query_builder = query_builder.bind(format!("%{}%", ua));
        }
        if let Some(ref path) = path_filter {
            query_builder = query_builder.bind(format!("%{}%", path));
        }

        let records = query_builder.fetch_all(&self.pool).await?;

        Ok((records, total.0))
    }

    /// 清理旧的访问日志
    pub async fn cleanup_old_access_logs(&self, days_to_keep: i32) -> Result<u64> {
        let result = sqlx::query("SELECT cleanup_old_access_logs($1)")
            .bind(days_to_keep)
            .fetch_one(&self.pool)
            .await?;

        let deleted_count: i32 = result.try_get(0).unwrap_or(0);
        Ok(deleted_count as u64)
    }

    /// 清理旧的每小时统计数据
    pub async fn cleanup_old_hourly_statistics(&self, days_to_keep: i32) -> Result<u64> {
        let result = sqlx::query("SELECT cleanup_old_hourly_statistics($1)")
            .bind(days_to_keep)
            .fetch_one(&self.pool)
            .await?;

        let deleted_count: i32 = result.try_get(0).unwrap_or(0);
        Ok(deleted_count as u64)
    }
}
