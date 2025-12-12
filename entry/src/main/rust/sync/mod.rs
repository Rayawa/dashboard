use std::{sync::LazyLock, time::Duration};

use anyhow::{Context, Result};
use chrono::{DateTime, Local};
use colored::Colorize;
use reqwest::Client;
use serde_json::Value as JsonValue;
use tracing::{Level, event};

use crate::{
    db::Database,
    model::{
        AppQuery, FullAppInfo, RawJsonData, RawRatingData,
        raw::{RawAppData, RawRecordalInfo},
    },
};

/// token 更新间隔
pub const TOKEN_UPDATE_INTERVAL: Duration = Duration::from_secs(600);

pub mod code;
pub mod status;
pub mod substance;

pub use substance::{SubstanceData, get_app_from_substance};

// 重新导出状态管理相关的公共接口
pub use status::{
    SyncStatusInfo, end_sync_all, get_sync_status, reset_sync_status, start_sync_all,
    update_sync_progress,
};

/// UA
pub static USER_AGENT: LazyLock<String> = LazyLock::new(|| {
    format!(
        "get_huawei_market/{}-{}",
        env!("CARGO_PKG_VERSION"),
        env!("CARGO_PKG_NAME")
    )
});

/// 批量同步所有应用数据
///
/// # 参数
/// - `client`: HTTP客户端
/// - `db`: 数据库连接
/// - `config`: 配置信息
///
/// # 返回值
/// - `anyhow::Result<()>`: 同步结果
///
/// # 功能
/// 1. 获取配置中的包名列表
/// 2. 合并数据库中已存在的包名
/// 3. 随机打乱顺序
/// 4. 逐个同步每个包的数据
/// 5. 统计并输出结果
pub async fn sync_all(
    client: &Client,
    db: &crate::db::Database,
    config: &crate::config::Config,
) -> Result<()> {
    let mut packages = config.packages().to_vec();

    #[cfg(not(feature = "no_db_sync"))]
    for pkg in db.get_all_pkg_names().await?.iter() {
        if !packages.contains(pkg) {
            packages.push(pkg.to_string());
        }
    }

    packages.sort();
    packages.dedup();

    // 随机打乱顺序
    {
        let seed = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos() as u64;
        let mut state = seed;
        let n = packages.len();
        for i in 0..n {
            state = state
                .wrapping_mul(6364136223846793005u64)
                .wrapping_add(1442695040888963407u64);
            let j = i + ((state % (n - i) as u64) as usize);
            packages.swap(i, j);
        }
    }

    event!(Level::INFO, "开始同步 {} 个 包", packages.len());

    // 初始化全局同步状态
    start_sync_all(packages.len());

    // 统计变量
    let start_time = std::time::Instant::now();
    let mut total_processed = 0;
    let mut total_inserted = 0;
    let mut total_skipped = 0;
    let mut total_failed = 0;

    // 获取批次大小配置
    let batch_size = config.sync_batch_size();
    let wait_time = std::time::Duration::from_millis(25);
    let mut batch_count = 0;
    let total_batches = packages.len().div_ceil(batch_size); // 向上取整

    // 按批次处理包
    for chunk in packages.chunks(batch_size) {
        batch_count += 1;
        let mut join_set = tokio::task::JoinSet::new();

        // 为批次中的每个包创建异步任务
        for package in chunk {
            let client = client.clone();
            let db = db.clone();
            let api_url = config.api_url().to_string();
            let package = package.clone();

            join_set.spawn(async move {
                match sync_app(
                    &client,
                    &db,
                    &api_url,
                    &AppQuery::pkg_name(&package),
                    None,
                    None,
                )
                .await
                {
                    Ok(inserted) => Ok((package, inserted)),
                    Err(e) => Err((package, e)),
                }
            });
        }

        // 等待批次中的所有任务完成
        let mut batch_processed = 0;
        let mut batch_inserted = 0;
        let mut batch_skipped = 0;
        let mut batch_failed = 0;

        while let Some(result) = join_set.join_next().await {
            match result {
                Ok(Ok((package, inserted))) => {
                    batch_processed += 1;
                    if inserted.0 || inserted.1 {
                        if inserted.0 {
                            event!(Level::DEBUG, "已将 {package} 的数据插入数据库");
                        }
                        if inserted.1 {
                            event!(Level::DEBUG, "已将 {package} 的评分数据插入数据库");
                        }
                        batch_inserted += 1;
                        event!(Level::DEBUG, "包 {} 处理完成 (新数据已插入)", package);
                    } else {
                        batch_skipped += 1;
                        event!(Level::DEBUG, "包 {} 处理完成 (数据相同，已跳过)", package);
                    }
                }
                Ok(Err((package, e))) => {
                    batch_processed += 1;
                    batch_failed += 1;
                    event!(Level::WARN, "包 {} 同步失败: {:#}", package, e);
                }
                Err(e) => {
                    batch_processed += 1;
                    batch_failed += 1;
                    event!(Level::WARN, "任务执行失败: {:#}", e);
                }
            }
        }

        // 更新全局统计
        total_processed += batch_processed;
        total_inserted += batch_inserted;
        total_skipped += batch_skipped;
        total_failed += batch_failed;

        // 更新全局状态
        update_sync_progress(
            total_processed,
            total_processed,
            total_inserted,
            total_skipped,
            total_failed,
        );

        // 打印批次进度
        let total_elapsed = start_time.elapsed();
        let avg_time_per_batch = total_elapsed / batch_count;
        let estimated_total_time = avg_time_per_batch * total_batches as u32;
        let remaining_time = estimated_total_time.saturating_sub(total_elapsed);

        print!(
            "\r[批次 {}/{}] 已处理 {} 个包，总耗时 {:?}，预计剩余 {:?}",
            batch_count, total_batches, total_processed, total_elapsed, remaining_time
        );
        std::io::Write::flush(&mut std::io::stdout()).unwrap();

        // 批次间等待
        tokio::time::sleep(wait_time).await;
    }

    // 结束全局同步状态
    end_sync_all();

    println!("{}", "所有包处理完成！".green());

    let cost_time = start_time.elapsed();
    // 打印统计信息
    println!();
    println!("{}", "=".repeat(50).cyan());
    println!("{}", "处理统计信息:".cyan().bold());
    println!("{}", "=".repeat(50).cyan());
    println!("总处理包数: {}", total_processed.to_string().cyan());
    println!("新插入数据包数: {}", total_inserted.to_string().green());
    println!(
        "跳过相同数据包数: {}",
        total_skipped.to_string().bright_black()
    );
    println!("处理失败包数: {}", total_failed.to_string().red());
    println!("处理耗时: {:?}", cost_time);
    println!("{}", "=".repeat(50).cyan());

    Ok(())
}

/// 同步单个应用数据
///
/// # 参数
/// - `client`: HTTP客户端
/// - `db`: 数据库连接
/// - `api_url`: API地址
/// - `app_query`: 应用查询条件（包名或应用ID）
/// - `listed_at`: 上架时间（可选）
///
/// # 功能
/// 1. 获取应用基本信息
/// 2. 获取应用评分信息（如果是普通应用）
/// 3. 保存数据到数据库
/// 4. 返回插入状态
pub async fn sync_app(
    client: &reqwest::Client,
    db: &Database,
    api_url: &str,
    app_query: &AppQuery,
    listed_at: Option<DateTime<Local>>,
    comment: Option<serde_json::Value>,
) -> Result<(bool, bool, bool, FullAppInfo)> {
    let app_data = query_app(client, api_url, app_query).await?;

    // event!(
    //     Level::DEBUG,
    //     app_id = app_data.0.0.app_id,
    //     "获取到包 {app_query} 的数据, 应用名称: {}",
    //     app_data.0.0.name
    // );

    // 保存数据到数据库（包含重复检查）
    let inserted = db
        .save_app_data(app_data, listed_at, comment)
        .await
        .map_err(|e| anyhow::anyhow!("保存包 {} 的数据失败: {:#}", app_query, e))?;

    Ok(inserted)
}

/// 查询单个应用的完整数据
///
/// # 参数
/// - `client`: HTTP客户端
/// - `api_url`: API地址
/// - `app_query`: 应用查询条件（包名或应用ID）
///
/// # 功能
/// 1. 获取应用基本信息
/// 2. 获取应用评分信息
/// 3. 返回完整数据但不保存到数据库
async fn query_app(
    client: &reqwest::Client,
    api_url: &str,
    app_query: &AppQuery,
) -> Result<RawAppData> {
    let data = get_app_data(client, api_url, app_query)
        .await
        .map_err(|e| anyhow::anyhow!("获取包 {} 的数据失败: {:#}", app_query, e))?;

    let (raw_data, data) = (
        data.clone(),
        serde_json::from_value::<RawJsonData>(data)
            .with_context(|| format!("不是，怎么又解析失败了 {app_query}"))?,
    );

    let mut raw_data = RawAppData::part_new(data, raw_data);

    if !raw_data.pkg_name().starts_with("com.atomicservice") {
        match get_app_page_detail(client, api_url, &raw_data.app_id()).await {
            Ok((rating, record)) => {
                if let Some(raw) = rating {
                    raw_data.with_rating(raw);
                }
                if let Some(raw) = record {
                    raw_data.with_record(raw);
                }
            }
            Err(e) => {
                event!(Level::WARN, "获取包 {} 的页面数据失败: {}", app_query, e);
            }
        }
    }

    // event!(
    //     Level::DEBUG,
    //     app_id = data.app_id,
    //     "获取到包 {app_query} 的数据,应用ID: {}，应用名称: {}",
    //     data.app_id,
    //     data.name
    // );

    Ok(raw_data)
}

/// 获取应用基本信息
///
/// # 参数
/// - `client`: HTTP客户端
/// - `api_url`: API地址
/// - `app_query`: 应用查询条件（包名或应用ID）
///
/// # 返回值
/// - `anyhow::Result<RawJsonData>`: 应用基本信息
///
/// # 功能
/// 1. 构建请求体
/// 2. 发送HTTP请求
/// 3. 解析响应数据
/// 4. 返回应用基本信息
pub async fn get_app_data(
    client: &reqwest::Client,
    api_url: &str,
    app_query: &AppQuery,
) -> Result<JsonValue> {
    let body = serde_json::json!({
        app_query.app_info_type(): app_query.name(),
        "locale": "zh_CN",
        "countryCode": "CN",
        "orderApp": 1
    });

    let token = code::GLOBAL_CODE_MANAGER.get_full_token().await;
    let response = client
        .post(format!("{api_url}/webedge/appinfo"))
        .header("Content-Type", "application/json")
        .header("User-Agent", USER_AGENT.to_string())
        .header("interface-code", token.interface_code)
        .header("identity-id", token.identity_id)
        .json(&body)
        .send()
        .await?;

    // 检查响应状态码
    if !response.status().is_success() {
        return Err(anyhow::anyhow!(
            "HTTP请求失败,状态码: {}",
            response.status()
        ));
    }

    // 检查响应体是否为空
    let content_length = response.content_length().unwrap_or(0);
    if content_length == 0 {
        return Err(anyhow::anyhow!("HTTP响应体为空"));
    }
    let mut raw = response.json::<serde_json::Value>().await?;
    let raw_obj = raw.as_object_mut().unwrap();
    if raw_obj.contains_key("AG-TraceId") {
        raw_obj.remove("AG-TraceId");
    };
    // 拜 cn.com.wind.wft_pc 所赐
    // 我们需要去掉可能的 \0
    // 拜 C5765880207856097575 所赐
    // 我决定直接遍历
    let keys_to_fix: Vec<String> = raw_obj
        .iter()
        .filter_map(|(key, value)| {
            if let Some(v) = value.as_str() {
                if v.contains('\0') {
                    Some(key.clone())
                } else {
                    None
                }
            } else {
                None
            }
        })
        .collect();

    for key in keys_to_fix {
        if let Some(value) = raw_obj.get(&key).and_then(|v| v.as_str()) {
            raw_obj.insert(key, serde_json::Value::String(value.replace('\0', "")));
        }
    }
    // 感谢 轩辕小波 提醒我得做安卓应用过滤
    // 我的方案是: 报错所有 appid len < 15 的
    if raw["appId"]
        .as_str()
        .with_context(|| " 要么没 app_id, 要么 app_id不是str")?
        .len()
        < 15
    {
        return Err(anyhow::anyhow!(
            "appid长度小于15, 你怕不是投了一个安卓应用上来"
        ));
    }
    Ok(raw)
}

/// 获取应用评分数据
///
/// # 参数
/// - `client`: HTTP客户端
/// - `api_url`: API地址
/// - `app_id`: 应用ID
///
async fn get_app_page_detail(
    client: &reqwest::Client,
    api_url: &str,
    app_id: impl ToString,
) -> Result<(Option<RawRatingData>, Option<RawRecordalInfo>)> {
    let body = serde_json::json!({
        "pageId": format!("webAgAppDetail|{}", app_id.to_string()),
        "pageNum": 1,
        "pageSize": 100,
        "zone": ""
    });

    let token = code::GLOBAL_CODE_MANAGER.get_full_token().await;
    let response = client
        .post(format!("{api_url}/harmony/page-detail"))
        .header("Content-Type", "application/json")
        .header("User-Agent", USER_AGENT.to_string())
        .header("Interface-Code", token.interface_code)
        .header("identity-id", token.identity_id)
        .json(&body)
        .send()
        .await?;

    // 检查响应状态码
    if !response.status().is_success() {
        return Err(anyhow::anyhow!(
            "HTTP请求失败,状态码: {}\nurl: {} body: {}",
            response.status(),
            api_url,
            body
        ));
    }

    // 检查响应体是否为空
    let content_length = response.content_length().unwrap_or(0);
    if content_length == 0 {
        return Err(anyhow::anyhow!(
            "HTTP响应体为空 \nurl: {api_url} data: {body}"
        ));
    }

    // 华为我谢谢你
    let raw_value = response.json::<serde_json::Value>().await?;
    let layouts = raw_value["pages"][0]["data"]["cardlist"]["layoutData"]
        .as_array()
        .expect("faild to parse page info");
    let mut comment = None;
    let mut record = None;
    for layout in layouts.iter() {
        let card_type = layout["type"].as_str().expect("type not str");
        let card_data = layout["data"]
            .as_array()
            .expect("data not array")
            .first()
            .expect("data not found");
        match card_type {
            "fl.card.comment" => {
                comment = card_data
                    .get("starInfo")
                    .and_then(|info| info.as_str())
                    .and_then(|info_str| serde_json::from_str::<'_, RawRatingData>(info_str).ok());
            }
            "com.huawei.hmos.appgallery.appdetailaboutcard" => {
                record = card_data
                    .get("list")
                    .and_then(|m| m.as_array())
                    .and_then(|l| l.first())
                    .and_then(|list_data| list_data.get("appRecordalInfo"))
                    .and_then(|d| serde_json::from_value(d.clone()).ok())
            }
            _ => {}
        }
    }

    Ok((comment, record))
}
