use anyhow::Context;
use tracing::{Level, event};

use crate::sync::{USER_AGENT, code::GLOBAL_CODE_MANAGER};

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
    event!(Level::INFO, "async rt built");
    rt.block_on(async_main())
}

async fn async_main() -> anyhow::Result<()> {
    // 加载配置
    let config = config::Config::load().with_context(|| "无法加载配置文件")?;
    let token = GLOBAL_CODE_MANAGER.update_token().await;

    let client = reqwest::ClientBuilder::new()
        .timeout(std::time::Duration::from_secs(config.api_timeout_seconds()))
        .build()
        .with_context(|| "无法创建 Reqwest 客户端")?;

    // https://web-drcn.hispace.dbankcloud.com/edge/harmony/version
    // versionHistories|C1263153796607926656

    let body = serde_json::json!({
       "locale": "zh",
       "pageId": "versionHistories|C1263153796607926656",
       "pageNum": 1,
       "pageSize": 100
    });

    let response = client
        .post("https://web-drcn.hispace.dbankcloud.com/edge/harmony/version-history")
        .header("Content-Type", "application/json")
        .header("User-Agent", USER_AGENT.to_string())
        .header("interface-code", token.interface_code)
        .header("identity-id", token.identity_id)
        .json(&body)
        .send()
        .await
        .with_context(|| "无法发送请求")?;

    // 检查响应状态码
    if !response.status().is_success() {
        return Err(anyhow::anyhow!(
            "HTTP请求失败,状态码: {}",
            response.status()
        ));
    }

    // 处理响应内容
    let data = response
        .json::<serde_json::Value>()
        .await
        .with_context(|| "无法解析响应内容")?;
    println!("响应内容: {:?}", data);

    Ok(())
}
