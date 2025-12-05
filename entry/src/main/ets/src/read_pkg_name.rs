pub mod config;
pub mod db;
pub mod model;
pub mod server;
pub mod sync;
pub mod utils;

use std::io::BufRead;

use anyhow::Context;
use tracing::{Level, event};

use crate::sync::code::GLOBAL_CODE_MANAGER;

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
    event!(Level::INFO, "connecting to db");
    let db = db::Database::new(config.database_url(), config.db_max_connect()).await?;
    event!(Level::INFO, "connected to db");
    let client = reqwest::ClientBuilder::new()
        .build()
        .with_context(|| "无法创建 Reqwest 客户端")?;
    let _token = GLOBAL_CODE_MANAGER.update_token().await;

    let cli_file = {
        std::env::args()
            .nth(1)
            .ok_or_else(|| anyhow::anyhow!("No file path provided as CLI argument"))?
    };

    let pkg_names: Vec<String> = {
        let file =
            std::fs::File::open(&cli_file).with_context(|| format!("无法读取 {cli_file} 文件"))?;
        let mut reader = std::io::BufReader::new(file);
        let mut pkg_names = Vec::new();
        let mut line = String::new();
        while reader.read_line(&mut line)? > 0 {
            pkg_names.push(line.trim().to_string());
            line.clear();
        }
        pkg_names
            .into_iter()
            .map(|l| l.trim_matches('\"').to_string())
            .collect()
    };

    let mut cfg = config.clone();
    cfg.app.packages = pkg_names;

    sync::sync_all(&client, &db, &cfg).await?;

    Ok(())
}
