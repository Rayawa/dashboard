use anyhow::Context;
use colored::Colorize;

use crate::{model::AppQuery, sync::code::GLOBAL_CODE_MANAGER};

pub mod config;
pub mod db;
pub mod model;
pub mod server;
pub mod sync;
pub mod utils;

fn main() -> anyhow::Result<()> {
    utils::init_log();
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(8)
        .enable_all()
        .build()
        .with_context(|| "无法创建 tokio runtime")?;

    rt.block_on(async_main())
}

#[allow(unused)]
fn i32_to_letters(mut n: i32) -> String {
    // 假设 n >= 0
    let mut s = String::new();
    while n >= 0 {
        let c = (b'a' + (n % 26) as u8) as char;
        s.insert(0, c);
        n = n / 26 - 1;
    }
    s
}

async fn async_main() -> anyhow::Result<()> {
    // 加载配置
    let config = config::Config::load().with_context(|| "无法加载配置文件")?;

    // C576588020785 6374145
    // C576588020785 6366961
    // C576588020785 2915863
    // C576588020785 2866435

    // let range = 2915863..=6366961;
    // let range = 0..=6366961;
    let range = 2000000..=6390000;
    // let range = 0000000..=9999999;
    // let range = 0..=475254;
    let start = "C576588020785";

    let _token = GLOBAL_CODE_MANAGER.update_token().await;

    let db = crate::db::Database::new(config.database_url(), config.db_max_connect()).await?;

    let batch = 1000;
    let wait_time = std::time::Duration::from_millis(25);
    let mut batch_count = 0;
    let total_batches = ((*range.end() - *range.start()) / batch as u64) + 1;
    let total_batches_u32 = total_batches as u32;
    let start_time = std::time::Instant::now();

    let client = reqwest::ClientBuilder::new()
        .timeout(std::time::Duration::from_secs(config.api_timeout_seconds()))
        .build()
        .with_context(|| "无法创建 Reqwest 客户端")?;
    let range_vec: Vec<u64> = range.collect();
    for bunch_id in range_vec.chunks(batch) {
        let mut join_set = tokio::task::JoinSet::new();
        for id in bunch_id.iter() {
            let client = client.clone();
            let db = db.clone();
            let api_url = config.api_url().to_string();
            let _locale = config.locale().to_string();
            let app_id = format!("{start}{id:07}");
            let comment = serde_json::json!({"user": format!("guess_market-{}", env!("CARGO_PKG_VERSION")), "platform": "guess_market_bin"});
            // let app_id = format!("com.chinasoft.app.api12.{}", i32_to_letters(*id as i32));
            // let app_id = format!("com.fkccc.{}", i32_to_letters(*id as i32));
            // let app_id = format!("xkkj.uni.UNI{:X}", id);
            // let app_id = format!("com.fengyun.app{id}");
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
                                format!("已将 {app_id} 的基本插入数据库\n")
                                    .on_green()
                                    .to_string()
                            } else {
                                "".to_string()
                            },
                            if new_metric {
                                format!("已将 {app_id} metrics\n").on_green().to_string()
                            } else {
                                "".to_string()
                            },
                            if new_rating {
                                format!("已将 {app_id} 的评分数据插入数据库")
                                    .on_green()
                                    .to_string()
                            } else {
                                "".to_string()
                            }
                        );
                    }
                    Err(_err) => {
                        // println!(
                        //     "{}",
                        //     format!("同步 {app_id} 的数据时出错: {}", err).on_red()
                        // );
                    }
                }
            });
        }
        join_set.join_all().await;
        batch_count += 1;
        let total_elapsed = start_time.elapsed();
        let avg_time_per_batch = total_elapsed / batch_count;
        let estimated_total_time = avg_time_per_batch * total_batches_u32;
        let remaining_time = estimated_total_time.saturating_sub(total_elapsed);

        print!(
            "\r[批次 {}/{}] id {} - {} 处理完成，总耗时 {:?}，预计剩余 {:?}，等待 {:?}",
            batch_count,
            total_batches,
            bunch_id[0],
            bunch_id[bunch_id.len() - 1],
            total_elapsed,
            remaining_time,
            wait_time
        );
        std::io::Write::flush(&mut std::io::stdout()).unwrap();
        tokio::time::sleep(wait_time).await;
    }

    Ok(())
}
