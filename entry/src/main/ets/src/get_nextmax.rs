use anyhow::Context;
use tracing::{Level, event};

use crate::db::Database;

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

pub const SRC_URL: &str = "https://nextmax.cn";

async fn parse_and_check_app_name(db: &Database, raw_html: &str) -> anyhow::Result<Vec<String>> {
    // <img data-src="https://appimg-drcn.dbankcdn.com/application/icon144/ff24bbc8ef444929bf0188f621bdebba.png" alt="滴滴出行" src="dat
    let app_name_match = r#"<img data-src="https://appimg-drcn.dbankcdn.com/application/icon144/"#;

    let app_name_lst = raw_html
        .split("\n")
        .map(|l| l.trim())
        .filter(|l| l.starts_with(app_name_match))
        .map(|l| {
            // 取 alt="xxxxx" 里面的 xxxx
            l.trim_start_matches(app_name_match)
                .split_once(r#"alt=""#)
                .map(|(_, name)| name)
                .unwrap_or("")
                .split_once(r#"" src=""#)
                .map(|(name, _)| name)
                .unwrap_or("")
                .trim()
        });

    let mut not_exist_lst = Vec::new();
    let mut app_gather = Vec::new();
    for app_name in app_name_lst {
        let exists = db.have_app_by_name(app_name).await;
        if !exists {
            not_exist_lst.push(app_name);
        }
        app_gather.push(app_name.to_string());
    }
    event!(Level::INFO, "共有 {} 个应用未入库", not_exist_lst.len());
    println!("未入库应用: {:?}", not_exist_lst);
    Ok(app_gather)
}

async fn parse_get_pkg_name(client: &reqwest::Client, raw_html: &str) -> anyhow::Result<()> {
    let app_card_match = r#"<div class="app-card" onclick="window.location.href='/app/"#;
    let app_lst = raw_html
        .split("\n")
        .map(|l| l.trim())
        .filter(|l| l.starts_with(app_card_match))
        .map(|l| {
            l.trim_start_matches(app_card_match)
                .trim_end_matches("\'\">")
                .parse::<u32>()
        });

    let app_lst = {
        let mut app_ids = Vec::new();
        for stuff in app_lst {
            match stuff {
                Ok(id) => app_ids.push(id),
                Err(e) => {
                    event!(Level::ERROR, "Failed to parse app ID: {}", e);
                    continue;
                }
            }
        }
        app_ids.sort_unstable();
        app_ids.dedup();
        app_ids
    };
    // 输出统计信息
    event!(Level::INFO, "处理完成 - 共计 {} 个APP", app_lst.len());
    // println!("{:?}", app_lst);

    // https://appgallery.huawei.com/app/detail?id=com.tencent.hm.qqmusic&amp;channelId=SHARE
    // com.tencent.hm.qqmusic
    let app_gallery_match = "https://appgallery.huawei.com/app/detail?id=";

    let mut apps = Vec::new();
    for app in app_lst {
        let request = client
            .get(format!("{}/app/{}", SRC_URL, app))
            .send()
            .await?;
        let response = request.text().await?;
        if response.contains(app_gallery_match) {
            // 有信息
            let app_id = {
                let app_gallery_text = response
                    .split("\n")
                    .map(|l| l.trim())
                    .find(|l| l.contains(app_gallery_match))
                    .unwrap_or("");

                let temp = app_gallery_text
                    .replace(
                        r#"<a href="https://appgallery.huawei.com/app/detail?id="#,
                        "",
                    )
                    .replace(app_gallery_match, "")
                    .split("&amp;")
                    .next()
                    .unwrap_or("")
                    .trim()
                    .to_string();
                if temp.contains('"') {
                    // 去掉引号以及之后的内容
                    temp.split('"').next().unwrap_or("").to_string()
                } else {
                    temp.to_string()
                }
            };
            event!(Level::INFO, "页面 {} 找到了 appid {}", app, app_id);
            apps.push(app_id);
        } else {
            continue;
        }
    }

    // 写到json里
    let json =
        serde_json::to_string_pretty(&apps).with_context(|| "无法序列化 apps 数据到 JSON")?;
    std::fs::write("apps.json", json).with_context(|| "无法写入 apps.json 文件")?;
    Ok(())
}

pub async fn check_what_i_got(max: &[String], db: &Database) -> anyhow::Result<()> {
    let db_apps = db.get_all_app_name().await?;
    let mut not_in_db = Vec::new();
    for app in db_apps {
        if !max.contains(&app) {
            not_in_db.push(app.clone());
        }
    }
    event!(Level::INFO, "共有 {} 个应用未入库", not_in_db.len());
    println!("未入库应用: {:?}", not_in_db);
    Ok(())
}

async fn async_main() -> anyhow::Result<()> {
    let config = config::Config::load().with_context(|| "无法加载配置文件")?;
    let client = reqwest::ClientBuilder::new()
        .build()
        .with_context(|| "无法创建 Reqwest 客户端")?;

    let db = crate::db::Database::new(config.database_url(), config.db_max_connect()).await?;

    event!(Level::INFO, "Starting...");
    let start_time = std::time::Instant::now();
    let response = client.get(format!("{SRC_URL}/all_apps")).send().await?;
    let request_spent = start_time.elapsed();
    event!(Level::INFO, "HTTP请求已发送 - 耗时 {:.2?}", request_spent);
    let body = response.text().await?;
    let response_spent = start_time.elapsed();
    let body_spent = response_spent - request_spent;
    event!(
        Level::INFO,
        "HTTP响应已接收 - 总耗时 {:.2?}, 响应体接收耗时 {:.2?}",
        response_spent,
        body_spent
    );

    let app_names = parse_and_check_app_name(&db, &body).await?;
    check_what_i_got(&app_names, &db).await?;
    parse_get_pkg_name(&client, &body).await?;

    Ok(())
}
