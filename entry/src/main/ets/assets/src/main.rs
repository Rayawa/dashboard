use anyhow::Context;
use tracing::{Level, event, info};

pub mod config;
pub mod db;
pub mod model;
pub mod server;
pub mod sync;
pub mod utils;

fn main() -> anyhow::Result<()> {
    utils::init_log();
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(16)
        .enable_all()
        .build()
        .with_context(|| "无法创建 tokio runtime")?;
    event!(Level::INFO, "async rt built");
    rt.block_on(async_main())
}

async fn async_main() -> anyhow::Result<()> {
    // 加载配置
    let _config = config::Config::load().with_context(|| "无法加载配置文件")?;
    let (worker_send, worker_recv) = tokio::sync::oneshot::channel::<()>();

    let worker = tokio::spawn(server::worker(worker_recv));

    // 等待 ctrl + c
    tokio::signal::ctrl_c().await?;

    info!("收到退出信号，正在优雅关闭...");

    // 发送关闭信号
    let _ = worker_send.send(());

    // 等待 worker 完成清理
    match tokio::time::timeout(std::time::Duration::from_secs(10), worker).await {
        Ok(Ok(Ok(()))) => {
            info!("Worker 已优雅退出");
        }
        Ok(Ok(Err(e))) => {
            event!(Level::WARN, "Worker 退出时出错: {:?}", e);
        }
        Ok(Err(e)) => {
            event!(Level::WARN, "Worker 任务失败: {:?}", e);
        }
        Err(_) => {
            event!(Level::WARN, "Worker 退出超时，强制终止");
        }
    }

    Ok(())
}
