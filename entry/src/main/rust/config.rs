use anyhow::Context;
use serde::Deserialize;
use std::{fs, sync::OnceLock};
use tracing::{Level, event};

pub static GLOBAL_CONFIG: OnceLock<Config> = OnceLock::new();

pub fn get_config() -> &'static Config {
    GLOBAL_CONFIG.get().unwrap()
}

fn default_db_max_limit() -> u32 {
    100
}

fn default_sync_batch_size() -> usize {
    100
}

fn default_max_ua_entries() -> usize {
    10000
}

fn default_max_ip_entries() -> usize {
    100000
}

fn default_statistics_sync_interval() -> u64 {
    300
}

fn default_statistics_enable_detailed_logs() -> bool {
    true
}

#[derive(Debug, Deserialize, Clone)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connect: u32,
    #[serde(default = "default_db_max_limit")]
    pub max_limit: u32,
}

#[derive(Debug, Deserialize, Clone)]
pub struct AppConfig {
    pub packages: Vec<String>,
    pub locale: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ApiConfig {
    /// 华为应用市场 API 基础 URL
    pub api_url: String,
    /// API 请求超时时间（秒）
    pub timeout_seconds: u64,
    /// 数据更新间隔 (秒)
    pub interval_seconds: u64,
    /// 批量同步的批次大小
    #[serde(default = "default_sync_batch_size")]
    pub sync_batch_size: usize,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ServeConfig {
    pub url: String,
    pub port: u16,
    /// UA 统计条目上限
    #[serde(default = "default_max_ua_entries")]
    pub max_ua_entries: usize,
    /// IP 统计条目上限
    #[serde(default = "default_max_ip_entries")]
    pub max_ip_entries: usize,
    /// 统计数据同步到数据库的间隔（秒）
    #[serde(default = "default_statistics_sync_interval")]
    pub statistics_sync_interval_seconds: u64,
    /// 是否启用详细访问日志
    #[serde(default = "default_statistics_enable_detailed_logs")]
    pub statistics_enable_detailed_logs: bool,
}

#[derive(Debug, Deserialize, Clone)]
pub struct Config {
    pub database: DatabaseConfig,
    pub app: AppConfig,
    pub api: ApiConfig,
    pub serve: ServeConfig,
}

impl Config {
    pub fn load() -> anyhow::Result<&'static Self> {
        let config_content =
            fs::read_to_string("config.toml").with_context(|| "无法读取 config.toml 配置文件")?;
        event!(Level::INFO, "config.toml loaded");
        let config: Config =
            toml::from_str(&config_content).with_context(|| "无法解析 config.toml 配置文件")?;
        event!(Level::INFO, "config.toml parsed");
        // 用配置文件初始化
        crate::db::query::SELECT_MAX_LIMIT.get_or_init(|| config.database.max_limit);
        crate::server::statistics::MAX_UA_ENTRIES.get_or_init(|| config.serve.max_ua_entries);
        crate::server::statistics::MAX_IP_ENTRIES.get_or_init(|| config.serve.max_ip_entries);
        Ok(GLOBAL_CONFIG.get_or_init(|| config))
    }

    pub fn database_url(&self) -> &str {
        &self.database.url
    }

    pub fn db_max_connect(&self) -> u32 {
        self.database.max_connect
    }

    pub fn packages(&self) -> &[String] {
        &self.app.packages
    }

    pub fn locale(&self) -> &str {
        &self.app.locale
    }

    pub fn api_url(&self) -> &str {
        &self.api.api_url
    }

    pub fn api_timeout_seconds(&self) -> u64 {
        self.api.timeout_seconds
    }

    pub fn api_interval(&self) -> u64 {
        self.api.interval_seconds
    }

    pub fn sync_batch_size(&self) -> usize {
        self.api.sync_batch_size
    }

    pub fn serve_url(&self) -> &str {
        &self.serve.url
    }

    pub fn serve_port(&self) -> u16 {
        self.serve.port
    }

    pub fn max_ua_entries(&self) -> usize {
        self.serve.max_ua_entries
    }

    pub fn max_ip_entries(&self) -> usize {
        self.serve.max_ip_entries
    }

    pub fn statistics_sync_interval(&self) -> u64 {
        self.serve.statistics_sync_interval_seconds
    }

    pub fn statistics_enable_detailed_logs(&self) -> bool {
        self.serve.statistics_enable_detailed_logs
    }
}
