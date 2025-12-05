use axum::{Extension, body::Body, http::Request, middleware::Next, response::IntoResponse};
use axum_client_ip::ClientIp;
use chrono::{DateTime, Duration, Timelike, Utc};
use colored::Colorize;
use dashmap::DashMap;
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, net::IpAddr, sync::OnceLock};
use tokio::sync::mpsc;
use tokio_util::sync::CancellationToken;
use tracing::{Level, event};

use crate::db::{Database, statistics::AccessLog};

/// 统计条目结构体 - 存储完整的统计信息
#[derive(Debug, Clone)]
struct StatisticEntry {
    count: u64,
    delta_since_last_sync: u64, // 自上次同步以来的增量
    first_seen_at: DateTime<Utc>,
    last_seen_at: DateTime<Utc>,
}

/// 每小时统计条目结构体
#[derive(Debug, Clone)]
struct HourlyEntry {
    count: u64,
    delta_since_last_sync: u64, // 自上次同步以来的增量
}

/// UA 统计 - 存储完整的统计信息
static UA_STATS: OnceLock<DashMap<String, StatisticEntry>> = OnceLock::new();
/// IP 统计 - 存储完整的统计信息
static IP_STATS: OnceLock<DashMap<IpAddr, StatisticEntry>> = OnceLock::new();

/// UA 每小时统计 - key: (user_agent, hour_timestamp)
static UA_HOURLY_COUNTS: OnceLock<DashMap<(String, DateTime<Utc>), HourlyEntry>> = OnceLock::new();
/// IP 每小时统计 - key: (ip_address, hour_timestamp)
static IP_HOURLY_COUNTS: OnceLock<DashMap<(IpAddr, DateTime<Utc>), HourlyEntry>> = OnceLock::new();

// 统计条目的最大数量配置（由 config.toml 初始化）
pub static MAX_UA_ENTRIES: OnceLock<usize> = OnceLock::new();
pub static MAX_IP_ENTRIES: OnceLock<usize> = OnceLock::new();

/// 访问日志队列 - 用于异步收集访问日志
static ACCESS_LOG_SENDER: OnceLock<mpsc::UnboundedSender<AccessLog>> = OnceLock::new();

/// 是否启用详细访问日志
static ENABLE_DETAILED_LOGS: OnceLock<bool> = OnceLock::new();

/// 取消令牌 - 用于优雅关闭后台任务
static CANCELLATION_TOKEN: OnceLock<CancellationToken> = OnceLock::new();

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Statistics {
    pub ua: HashMap<String, u64>,
    pub ip: HashMap<IpAddr, u64>,
}

/// 带时间戳的统计信息
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StatisticsWithTimestamps {
    pub ua: HashMap<String, (u64, DateTime<Utc>, DateTime<Utc>)>,
    pub ip: HashMap<IpAddr, (u64, DateTime<Utc>, DateTime<Utc>)>,
}

/// 获取当前小时的时间戳（整点）
fn get_hour_timestamp(now: DateTime<Utc>) -> DateTime<Utc> {
    now.with_minute(0)
        .unwrap()
        .with_second(0)
        .unwrap()
        .with_nanosecond(0)
        .unwrap()
}

/// 初始化统计系统
///
/// 从数据库加载历史统计数据到内存
pub async fn initialize_statistics(db: &Database, enable_logs: bool) -> anyhow::Result<()> {
    event!(Level::INFO, "初始化统计系统...");

    ENABLE_DETAILED_LOGS.get_or_init(|| enable_logs);

    // 从数据库加载 UA 统计
    let ua_stats = db.load_ua_statistics().await?;
    let ua_map = UA_STATS.get_or_init(DashMap::new);
    for stat in ua_stats {
        ua_map.insert(
            stat.user_agent,
            StatisticEntry {
                count: stat.access_count as u64,
                delta_since_last_sync: 0, // 初始化为0
                first_seen_at: stat.first_seen_at,
                last_seen_at: stat.last_seen_at,
            },
        );
    }
    event!(Level::INFO, ua_count = ua_map.len(), "已加载 UA 统计记录");

    // 从数据库加载 IP 统计
    let ip_stats = db.load_ip_statistics().await?;
    let ip_map = IP_STATS.get_or_init(DashMap::new);
    for stat in ip_stats {
        ip_map.insert(
            stat.ip_address,
            StatisticEntry {
                count: stat.access_count as u64,
                delta_since_last_sync: 0, // 初始化为0
                first_seen_at: stat.first_seen_at,
                last_seen_at: stat.last_seen_at,
            },
        );
    }
    event!(Level::INFO, ip_count = ip_map.len(), "已加载 IP 统计记录");

    // 初始化每小时统计的 DashMap
    UA_HOURLY_COUNTS.get_or_init(DashMap::new);
    IP_HOURLY_COUNTS.get_or_init(DashMap::new);

    event!(Level::INFO, "统计系统初始化完成");
    Ok(())
}

/// 启动统计数据同步任务
///
/// 定期将内存中的统计数据同步到数据库
pub fn start_statistics_sync_task(
    db: Database,
    interval_seconds: u64,
) -> tokio::task::JoinHandle<()> {
    event!(
        Level::INFO,
        interval_seconds = interval_seconds,
        "启动统计同步任务"
    );

    // 创建访问日志队列
    let (tx, mut rx) = mpsc::unbounded_channel::<AccessLog>();
    ACCESS_LOG_SENDER.get_or_init(|| tx);

    // 创建取消令牌
    let cancel_token = CANCELLATION_TOKEN
        .get_or_init(CancellationToken::new)
        .clone();

    tokio::spawn(async move {
        let mut sync_interval =
            tokio::time::interval(std::time::Duration::from_secs(interval_seconds));
        // let mut cleanup_interval = tokio::time::interval(std::time::Duration::from_secs(3600)); // 每小时清理一次
        let mut access_logs_buffer = Vec::new();

        loop {
            tokio::select! {
                _ = cancel_token.cancelled() => {
                    event!(Level::INFO, "收到关闭信号，正在同步最后的数据...");
                    // 同步剩余的数据
                    if let Err(e) = sync_statistics_to_db(&db, &access_logs_buffer).await {
                        event!(Level::ERROR, error = ?e, "最终同步失败");
                    }
                    event!(Level::INFO, "统计同步任务已退出");
                    break;
                }
                _ = sync_interval.tick() => {
                    // 同步统计数据到数据库
                    if let Err(e) = sync_statistics_to_db(&db, &access_logs_buffer).await {
                        event!(Level::ERROR, error = ?e, "同步统计数据到数据库失败");
                    } else {
                        event!(Level::INFO, "统计数据同步完成");
                    }
                    access_logs_buffer.clear();
                }
                // _ = cleanup_interval.tick() => {
                //     // 清理旧的每小时统计数据（保留最近 7 天）
                //     cleanup_old_hourly_data();
                // }
                Some(log) = rx.recv() => {
                    // 收集访问日志
                    access_logs_buffer.push(log);

                    // 如果缓冲区过大，立即同步
                    if access_logs_buffer.len() >= 1000 {
                        if let Err(e) = sync_statistics_to_db(&db, &access_logs_buffer).await {
                            event!(Level::ERROR, error = ?e, "批量同步访问日志失败");
                        } else {
                            event!(Level::INFO, batch_size = access_logs_buffer.len(), "批量同步访问日志完成");
                        }
                        access_logs_buffer.clear();
                    }
                }
            }
        }
    })
}

/// 同步统计数据到数据库
async fn sync_statistics_to_db(db: &Database, access_logs: &[AccessLog]) -> anyhow::Result<()> {
    event!(Level::INFO, "正在同步访问日志");

    // 1. 批量插入访问日志
    if !access_logs.is_empty() {
        let count = db.batch_insert_access_logs(access_logs).await?;
        event!(Level::INFO, inserted_log_count = count, "插入访问日志完成");
    }

    // 2. 同步 UA 总体统计
    // 先收集数据，避免在异步操作中持有锁
    let ua_map = UA_STATS.get_or_init(DashMap::new);
    // 只收集有增量变化的条目
    let ua_data: Vec<(String, u64, DateTime<Utc>, DateTime<Utc>)> = ua_map
        .iter()
        .filter(|entry| entry.value().delta_since_last_sync > 0) // 只同步有变化的
        .map(|entry| {
            let key = entry.key();
            let value = entry.value();
            (
                key.clone(),
                value.delta_since_last_sync, // 发送增量而不是总数
                value.first_seen_at,
                value.last_seen_at,
            )
        })
        .collect();

    // 批量同步 UA 总体统计
    if !ua_data.is_empty() {
        let affected = db.batch_upsert_ua_statistics(&ua_data).await?;
        event!(Level::INFO, ua_affected = affected, "批量同步 UA 统计完成");

        // 同步成功后，重置增量计数器
        for mut entry in ua_map.iter_mut() {
            entry.value_mut().delta_since_last_sync = 0;
        }
    }

    // 3. 同步 IP 总体统计
    // 先收集数据，避免在异步操作中持有锁
    let ip_map = IP_STATS.get_or_init(DashMap::new);
    // 只收集有增量变化的条目
    let ip_data: Vec<(IpAddr, u64, DateTime<Utc>, DateTime<Utc>)> = ip_map
        .iter()
        .filter(|entry| entry.value().delta_since_last_sync > 0) // 只同步有变化的
        .map(|entry| {
            let key = entry.key();
            let value = entry.value();
            (
                *key,
                value.delta_since_last_sync,
                value.first_seen_at,
                value.last_seen_at,
            ) // 发送增量
        })
        .collect();

    // 批量同步 IP 总体统计
    if !ip_data.is_empty() {
        let affected = db.batch_upsert_ip_statistics(&ip_data).await?;
        event!(Level::INFO, ip_affected = affected, "批量同步 IP 统计完成");

        // 同步成功后，重置增量计数器
        for mut entry in ip_map.iter_mut() {
            entry.value_mut().delta_since_last_sync = 0;
        }
    }

    // 4. 同步 UA 每小时统计
    // 先收集数据，避免在异步操作中持有锁
    let ua_hourly_map = UA_HOURLY_COUNTS.get_or_init(DashMap::new);
    // 只收集有增量变化的条目
    let ua_hourly_data: Vec<(String, DateTime<Utc>, u64)> = ua_hourly_map
        .iter()
        .filter(|entry| entry.value().delta_since_last_sync > 0) // 只同步有变化的
        .map(|entry| {
            let (user_agent, hour_timestamp) = entry.key();
            (
                user_agent.clone(),
                *hour_timestamp,
                entry.value().delta_since_last_sync,
            ) // 发送增量
        })
        .collect();

    // 批量同步 UA 每小时统计
    if !ua_hourly_data.is_empty() {
        let affected = db
            .batch_upsert_ua_hourly_statistics(&ua_hourly_data)
            .await?;
        event!(
            Level::INFO,
            ua_hourly_affected = affected,
            "批量同步 UA 每小时统计完成"
        );

        // 同步成功后，重置增量计数器
        for mut entry in ua_hourly_map.iter_mut() {
            entry.value_mut().delta_since_last_sync = 0;
        }
    }

    // 5. 同步 IP 每小时统计
    // 先收集数据，避免在异步操作中持有锁
    let ip_hourly_map = IP_HOURLY_COUNTS.get_or_init(DashMap::new);
    // 只收集有增量变化的条目
    let ip_hourly_data: Vec<(IpAddr, DateTime<Utc>, u64)> = ip_hourly_map
        .iter()
        .filter(|entry| entry.value().delta_since_last_sync > 0) // 只同步有变化的
        .map(|entry| {
            let (ip, hour_timestamp) = entry.key();
            (*ip, *hour_timestamp, entry.value().delta_since_last_sync) // 发送增量
        })
        .collect();

    // 批量同步 IP 每小时统计
    if !ip_hourly_data.is_empty() {
        let affected = db
            .batch_upsert_ip_hourly_statistics(&ip_hourly_data)
            .await?;
        event!(
            Level::INFO,
            ip_hourly_affected = affected,
            "批量同步 IP 每小时统计完成"
        );

        // 同步成功后，重置增量计数器
        for mut entry in ip_hourly_map.iter_mut() {
            entry.value_mut().delta_since_last_sync = 0;
        }
    }

    Ok(())
}

pub async fn get_statistics() -> Statistics {
    let ua_map = UA_STATS.get_or_init(DashMap::new);
    let ip_map = IP_STATS.get_or_init(DashMap::new);

    // 直接迭代收集，不需要全局锁
    let ua = ua_map
        .iter()
        .map(|entry| (entry.key().clone(), entry.value().count))
        .collect();
    let ip = ip_map
        .iter()
        .map(|entry| (*entry.key(), entry.value().count))
        .collect();

    Statistics { ua, ip }
}

/// 获取带时间戳的统计信息
pub async fn get_statistics_with_timestamps() -> StatisticsWithTimestamps {
    let ua_map = UA_STATS.get_or_init(DashMap::new);
    let ip_map = IP_STATS.get_or_init(DashMap::new);

    let ua = ua_map
        .iter()
        .map(|entry| {
            let key = entry.key();
            let value = entry.value();
            (
                key.clone(),
                (value.count, value.first_seen_at, value.last_seen_at),
            )
        })
        .collect();
    let ip = ip_map
        .iter()
        .map(|entry| {
            let key = entry.key();
            let value = entry.value();
            (*key, (value.count, value.first_seen_at, value.last_seen_at))
        })
        .collect();

    StatisticsWithTimestamps { ua, ip }
}

#[allow(unused)]
/// 清理旧的每小时统计数据（保留最近 7 天）
fn cleanup_old_hourly_data() {
    let now = Utc::now();
    let cutoff = now - Duration::days(7);

    // 清理 UA 每小时统计
    // 先收集需要删除的键，然后再删除，避免长时间持有锁
    if let Some(ua_hourly_map) = UA_HOURLY_COUNTS.get() {
        let keys_to_remove: Vec<_> = ua_hourly_map
            .iter()
            .filter_map(|entry| {
                let (user_agent, hour_timestamp) = entry.key();
                if *hour_timestamp < cutoff {
                    Some((user_agent.clone(), *hour_timestamp))
                } else {
                    None
                }
            })
            .collect();

        let removed_count = keys_to_remove.len();
        for key in keys_to_remove {
            ua_hourly_map.remove(&key);
        }

        if removed_count > 0 {
            event!(
                Level::INFO,
                removed_count = removed_count,
                "清理旧的 UA 每小时统计数据"
            );
        }
    }

    // 清理 IP 每小时统计
    // 先收集需要删除的键，然后再删除，避免长时间持有锁
    if let Some(ip_hourly_map) = IP_HOURLY_COUNTS.get() {
        let keys_to_remove: Vec<_> = ip_hourly_map
            .iter()
            .filter_map(|entry| {
                let (ip, hour_timestamp) = entry.key();
                if *hour_timestamp < cutoff {
                    Some((*ip, *hour_timestamp))
                } else {
                    None
                }
            })
            .collect();

        let removed_count = keys_to_remove.len();
        for key in keys_to_remove {
            ip_hourly_map.remove(&key);
        }

        if removed_count > 0 {
            event!(
                Level::INFO,
                removed_count = removed_count,
                "清理旧的 IP 每小时统计数据"
            );
        }
    }
}

/// 优雅关闭统计系统
///
/// 确保所有统计数据都已同步到数据库
pub async fn shutdown_statistics(db: &Database) -> anyhow::Result<()> {
    event!(Level::INFO, "关闭统计系统，正在发送关闭信号...");

    // 发送取消信号
    if let Some(token) = CANCELLATION_TOKEN.get() {
        token.cancel();
        event!(Level::INFO, "已发送关闭信号，等待后台任务完成...");

        // 给后台任务一些时间来完成同步
        tokio::time::sleep(std::time::Duration::from_secs(1)).await;
    }

    // 最后一次同步（确保数据完整）
    sync_statistics_to_db(db, &[]).await?;

    event!(Level::INFO, "统计系统已关闭");
    Ok(())
}

pub async fn middle_response(
    Extension(ClientIp(ip)): Extension<ClientIp>,
    req: Request<Body>,
    next: Next,
) -> impl IntoResponse {
    let now = Utc::now();
    let hour_timestamp = get_hour_timestamp(now);

    let user_agent = req
        .headers()
        .get("user-agent")
        .and_then(|h| h.to_str().ok())
        .map(|s| s.to_string())
        .unwrap_or_else(|| "unknown".to_string());

    let request_method = req.method().to_string();
    let request_path = req.uri().path().to_string();

    // 更新 UA 统计
    let ua_map = UA_STATS.get_or_init(DashMap::new);
    let max_ua = MAX_UA_ENTRIES.get().copied().unwrap_or(10000);

    // 使用更安全的并发控制方法
    // 先尝试更新现有条目
    if let Some(mut entry) = ua_map.get_mut(&user_agent) {
        entry.count += 1;
        entry.delta_since_last_sync += 1; // 同时更新增量
        entry.last_seen_at = now;
    } else {
        // 如果是新条目，检查是否超过上限
        if ua_map.len() < max_ua {
            ua_map.insert(
                user_agent.clone(),
                StatisticEntry {
                    count: 1,
                    delta_since_last_sync: 1, // 新条目的delta为1
                    first_seen_at: now,
                    last_seen_at: now,
                },
            );
            println!("{}", format!("new user-agent: {}", user_agent).green());
        }
        // 如果超过上限，不插入新条目
    }

    // 更新 IP 统计
    let ip_map = IP_STATS.get_or_init(DashMap::new);
    let max_ip = MAX_IP_ENTRIES.get().copied().unwrap_or(100000);

    // 使用更安全的并发控制方法
    // 先尝试更新现有条目
    if let Some(mut entry) = ip_map.get_mut(&ip) {
        entry.count += 1;
        entry.delta_since_last_sync += 1; // 同时更新增量
        entry.last_seen_at = now;
    } else {
        // 如果是新条目，检查是否超过上限
        if ip_map.len() < max_ip {
            ip_map.insert(
                ip,
                StatisticEntry {
                    count: 1,
                    delta_since_last_sync: 1, // 新条目的delta为1
                    first_seen_at: now,
                    last_seen_at: now,
                },
            );
            println!("{}", format!("new ip: {}", ip).green());
        }
        // 如果超过上限，不插入新条目
    }

    // 更新 UA 每小时统计
    let ua_hourly_map = UA_HOURLY_COUNTS.get_or_init(DashMap::new);
    ua_hourly_map
        .entry((user_agent.clone(), hour_timestamp))
        .and_modify(|entry| {
            entry.count += 1;
            entry.delta_since_last_sync += 1;
        })
        .or_insert(HourlyEntry {
            count: 1,
            delta_since_last_sync: 1,
        });

    // 更新 IP 每小时统计
    let ip_hourly_map = IP_HOURLY_COUNTS.get_or_init(DashMap::new);
    ip_hourly_map
        .entry((ip, hour_timestamp))
        .and_modify(|entry| {
            entry.count += 1;
            entry.delta_since_last_sync += 1;
        })
        .or_insert(HourlyEntry {
            count: 1,
            delta_since_last_sync: 1,
        });

    // 记录详细访问日志（如果启用）
    let enable_logs = ENABLE_DETAILED_LOGS.get().copied().unwrap_or(true);
    if enable_logs {
        let access_log = AccessLog {
            timestamp: now,
            ip_address: ip,
            user_agent,
            request_method,
            request_path,
        };

        if let Some(sender) = ACCESS_LOG_SENDER.get()
            && let Err(e) = sender.send(access_log)
        {
            event!(Level::WARN, error = ?e, "发送访问日志到队列失败");
        }
    }

    next.run(req).await
}
