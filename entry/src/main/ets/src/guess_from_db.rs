pub mod config;
pub mod db;
pub mod model;
pub mod server;
pub mod sync;
pub mod utils;

use std::collections::BTreeSet;

use anyhow::Context;
use colored::Colorize;

use model::query::AppQuery;

use crate::sync::code::GLOBAL_CODE_MANAGER;

fn main() -> anyhow::Result<()> {
    utils::init_log();
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(8)
        .enable_all()
        .build()
        .with_context(|| "无法创建 tokio runtime")?;

    rt.block_on(async_main())
}

async fn async_main() -> anyhow::Result<()> {
    // 加载配置
    let config = config::Config::load().with_context(|| "无法加载配置文件")?;

    // 连接数据库
    let db = crate::db::Database::new(config.database_url(), config.db_max_connect()).await?;

    let _token = GLOBAL_CODE_MANAGER.update_token().await;

    // 获取数据库中所有的 app_id
    println!("正在从数据库获取所有 app_id...");
    let existing_app_ids = db.get_all_app_ids().await?;
    let existing_app_ids = existing_app_ids
        .iter()
        .filter(|i| i.starts_with("C69175"))
        .cloned()
        .collect::<Vec<_>>();
    println!("从数据库获取到 {} 个 app_id", existing_app_ids.len());

    if existing_app_ids.is_empty() {
        println!("数据库中没有找到任何 app_id, 无法进行猜测");
        return Ok(());
    }

    // 解析 app_id 格式并生成需要猜测的范围
    let mut all_ranges: BTreeSet<(String, u64, u64)> = BTreeSet::new();

    for app_id in existing_app_ids {
        if let Some((prefix, numeric_part)) = parse_app_id(&app_id) {
            let start_range = numeric_part.saturating_sub(1000);
            let end_range = numeric_part.saturating_add(1000);
            all_ranges.insert((prefix, start_range, end_range));
        }
    }

    println!("生成了 {} 个唯一的前缀范围", all_ranges.len());

    // 按前缀分组并合并范围
    let mut ranges_by_prefix = std::collections::HashMap::new();

    for (prefix, start, end) in all_ranges {
        ranges_by_prefix
            .entry(prefix)
            .or_insert_with(Vec::new)
            .push((start, end));
    }

    // 合并每个前缀的重叠范围
    let mut merged_ranges = Vec::new();

    for (prefix, mut ranges) in ranges_by_prefix {
        // 按起始位置排序
        ranges.sort_by_key(|&(start, _)| start);

        let mut merged = Vec::new();
        let mut current_range = ranges[0];

        for &range in &ranges[1..] {
            if range.0 <= current_range.1 + 1 {
                // 范围重叠或相邻，合并
                current_range.1 = current_range.1.max(range.1);
            } else {
                // 不重叠，保存当前范围并开始新的范围
                merged.push(current_range);
                current_range = range;
            }
        }
        merged.push(current_range);

        for (start, end) in merged {
            merged_ranges.push((prefix.clone(), start, end));
        }
    }

    println!("合并后得到 {} 个范围", merged_ranges.len());

    let client = reqwest::ClientBuilder::new()
        .timeout(std::time::Duration::from_secs(config.api_timeout_seconds()))
        .build()
        .with_context(|| "无法创建 Reqwest 客户端")?;

    let batch = 1000;
    let wait_time = std::time::Duration::from_millis(50);

    // 处理每个合并后的范围
    for (prefix, start_range, end_range) in merged_ranges {
        println!(
            "开始处理前缀 {} 的范围 {}..{}",
            prefix, start_range, end_range
        );

        let total_ids = end_range - start_range + 1;
        println!("需要处理 {} 个 ID", total_ids);

        for chunk_start in (start_range..=end_range).step_by(batch) {
            let chunk_end = (chunk_start + batch as u64 - 1).min(end_range);
            let chunk_size = chunk_end - chunk_start + 1;

            println!(
                "处理批次: {} - {} ({} 个 ID)",
                chunk_start, chunk_end, chunk_size
            );

            let mut join_set = tokio::task::JoinSet::new();

            for id in chunk_start..=chunk_end {
                let client = client.clone();
                let db = db.clone();
                let api_url = config.api_url().to_string();
                let app_id = format!("{}{}", prefix, id);
                let comment = serde_json::json!({"user": format!("guess_from_db-{}", env!("CARGO_PKG_VERSION"))});

                join_set.spawn(async move {
                    match crate::sync::sync_app(
                        &client,
                        &db,
                        &api_url,
                        &AppQuery::app_id(&app_id),
                        None,
                        Some(comment),
                    )
                    .await
                    {
                        Ok((new_info, new_metric, new_rating, _full_info)) => {
                            println!(
                                "{}{}{}",
                                if new_info {
                                    format!("已将 {app_id} 的基本信息插入数据库\n")
                                        .on_green()
                                        .to_string()
                                } else {
                                    "".to_string()
                                },
                                if new_metric {
                                    format!("已将 {app_id} 的 metric 信息插入数据库\n")
                                        .on_green()
                                        .to_string()
                                } else {
                                    "".to_string()
                                },
                                if new_rating {
                                    format!("已将 {app_id} 的 rating 信息插入数据库\n")
                                        .on_green()
                                        .to_string()
                                } else {
                                    "".to_string()
                                }
                            );
                        }
                        Err(e) => {
                            eprintln!("{}", format!("同步 {app_id} 失败: {e}").on_red());
                        }
                    }
                });
            }

            join_set.join_all().await;
            println!(
                "批次 {} - {} 处理完成，等待 {:?}",
                chunk_start, chunk_end, wait_time
            );
            tokio::time::sleep(wait_time).await;
        }
    }

    println!("所有范围处理完成!");
    Ok(())
}

/// 解析 app_id，返回前缀和数字部分
fn parse_app_id(app_id: &str) -> Option<(String, u64)> {
    // app_id 格式通常是 "C5765880207856366961"
    // 我们需要分离前缀和数字部分

    // 找到第一个数字的位置
    let first_digit_pos = app_id.find(|c: char| c.is_ascii_digit())?;

    // 找到最后一个数字的位置
    let last_digit_pos = app_id.rfind(|c: char| c.is_ascii_digit())?;

    let prefix = app_id[..first_digit_pos].to_string();
    let numeric_str = &app_id[first_digit_pos..=last_digit_pos];

    numeric_str.parse().ok().map(|num| (prefix, num))
}
