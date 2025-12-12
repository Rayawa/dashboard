pub mod frontend_handlers;
pub mod handlers;
pub mod middle;
pub mod routes;
pub mod state;
pub mod statistics;
pub mod statistics_handlers;

use std::{net::SocketAddr, sync::Arc};

use anyhow::Context;
use colored::Colorize;
use tracing::{Level, event};

use crate::{
    config::{Config, get_config},
    db::Database,
    sync::code::GLOBAL_CODE_MANAGER,
};

use self::state::AppState;

pub use routes::create_router;

/// Web服务器工作线程
pub async fn worker(mut waiter: tokio::sync::oneshot::Receiver<()>) -> anyhow::Result<()> {
    let config = get_config();
    event!(Level::INFO, "connecting to db");
    let db = crate::db::Database::new(config.database_url(), config.db_max_connect()).await?;
    event!(Level::INFO, "connected to db");

    #[cfg(not(feature = "no_sync"))]
    let client = reqwest::ClientBuilder::new()
        .timeout(std::time::Duration::from_secs(config.api_timeout_seconds()))
        .build()
        .with_context(|| "创建 http 客户端失败")?;

    let _ = GLOBAL_CODE_MANAGER.update_token().await;

    let interval = config.api_interval();
    let web_part = tokio::spawn(web_main(config.clone(), db.clone()));

    loop {
        // no_sync 的时候就不同步了
        #[cfg(not(feature = "no_sync"))]
        crate::sync::sync_all(&client, &db, config).await?;
        #[cfg(not(feature = "no_sync"))]
        #[cfg(not(feature = "no_db_sync"))]
        crate::sync::substance::sync_substance(&client, &db, config).await?;

        // 通过 select 同时等待/接受结束事件
        let wait_time = std::time::Duration::from_secs(interval);
        println!("{}", format!("等待 {:?} 后再同步", wait_time).green());
        tokio::select! {
            _ = tokio::time::sleep(wait_time) => {
            }
            _ = &mut waiter => {
                break;
            }
        }
    }

    event!(Level::INFO, "正在关闭 Web 服务器...");
    web_part.abort();

    // 优雅关闭统计系统
    event!(Level::INFO, "正在关闭统计系统...");
    if let Err(e) = statistics::shutdown_statistics(&db).await {
        event!(Level::WARN, "关闭统计系统时出错: {:?}", e);
    }

    Ok(())
}

/// Web服务器主函数
pub async fn web_main(config: Config, db: Database) -> anyhow::Result<()> {
    // 初始化统计系统
    let enable_logs = config.statistics_enable_detailed_logs();
    statistics::initialize_statistics(&db, enable_logs).await?;

    // 启动统计同步任务
    let sync_interval = config.statistics_sync_interval();
    let _sync_handle = statistics::start_statistics_sync_task(db.clone(), sync_interval);

    let client = reqwest::ClientBuilder::new()
        .timeout(std::time::Duration::from_secs(config.api_timeout_seconds()))
        .build()
        .with_context(|| "创建 Web http 客户端失败")?;

    let app_state = Arc::new(AppState {
        db,
        client,
        cfg: config.clone(),
    });

    let router = routes::create_router(app_state);

    let listener = tokio::net::TcpListener::bind((config.serve_url(), config.serve_port())).await?;
    event!(
        Level::INFO,
        "开始监听 {}:{}",
        config.serve_url(),
        config.serve_port()
    );

    axum::serve(
        listener,
        router.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await?;
    Ok(())
}
