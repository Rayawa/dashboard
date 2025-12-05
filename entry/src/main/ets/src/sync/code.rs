//! 用于全局共享 identity id 和 interface code

use std::{
    sync::LazyLock,
    time::{Duration, Instant, UNIX_EPOCH},
};

use colored::Colorize;
use reqwest::Client;
use tokio::sync::RwLock;

use crate::sync::{TOKEN_UPDATE_INTERVAL, USER_AGENT};

const URL: &str = "https://web-drcn.hispace.dbankcloud.com/edge/webedge/getInterfaceCode";
const MAX_RETRIES: usize = 5;

/// 格式化 UUID 为无连字符的小写十六进制字符串
fn format_uuid(uuid: &uuid::Uuid) -> String {
    format!("{:x}", uuid).replace("-", "")
}

pub static GLOBAL_CODE_MANAGER: LazyLock<CodeManager> = LazyLock::new(|| {
    let now = Instant::now();
    let client = reqwest::ClientBuilder::new()
        .build()
        .expect("failed to build client");

    CodeManager {
        identity_id: RwLock::new(uuid::Uuid::new_v4()),
        token: RwLock::new(None),
        last_update: RwLock::new(now),
        client,
    }
});

pub struct CodeManager {
    identity_id: RwLock<uuid::Uuid>,
    token: RwLock<Option<String>>,
    last_update: RwLock<Instant>,
    client: Client,
}

impl CodeManager {
    /// 获取统一的 token 信息，包含 identity_id 和 interface_code
    pub async fn get_token(&self) -> TokenInfo {
        let last_update = self.last_update.read().await;

        if last_update.elapsed() > TOKEN_UPDATE_INTERVAL {
            // 需要更新，释放读锁，获取写锁
            drop(last_update);

            // 更新 token
            self.update_token().await
        } else {
            // 不需要更新，直接返回当前 token
            let identity_id_guard = self.identity_id.read().await;
            let identity_id = format_uuid(&identity_id_guard);
            let token_guard = self.token.read().await;
            let interface_code = token_guard
                .as_ref()
                .map(|t| t.clone())
                .unwrap_or_else(|| "".to_string());

            TokenInfo {
                identity_id,
                interface_code,
            }
        }
    }

    /// 获取完整的 token（包含 unix time）
    pub async fn get_full_token(&self) -> TokenInfo {
        let mut token_info = self.get_token().await;
        let unix_time: u64 = UNIX_EPOCH.elapsed().expect("wtf").as_millis() as u64;
        token_info.interface_code = format!("{}_{unix_time}", token_info.interface_code);
        token_info
    }

    /// 更新 token（内部方法）
    pub async fn update_token(&self) -> TokenInfo {
        println!("{}", "正在刷新 token".on_blue());

        let mut last_update_guard = self.last_update.write().await;
        let mut identity_id_guard = self.identity_id.write().await;
        let mut token_guard = self.token.write().await;

        // 生成新的 identity_id
        let new_identity_id = uuid::Uuid::new_v4();
        let identity_id_str = format_uuid(&new_identity_id);

        // 更新 identity_id
        *identity_id_guard = new_identity_id;

        // 获取新的 interface_code
        let interface_code = self.fetch_interface_code(&identity_id_str).await;

        // 更新 token 和更新时间
        *token_guard = Some(interface_code.clone());
        *last_update_guard = Instant::now();

        println!(
            "{}\nidentity_id: {}\ninterface_code: {}",
            "token 刷新完成".on_green(),
            identity_id_str.bright_yellow(),
            interface_code.bright_yellow()
        );

        TokenInfo {
            identity_id: identity_id_str,
            interface_code,
        }
    }

    /// 从服务器获取 interface_code
    async fn fetch_interface_code(&self, identity_id: &str) -> String {
        let mut retry_count = 0;

        loop {
            if retry_count >= MAX_RETRIES {
                panic!("达到最大重试次数，无法获取 interface_code");
            }

            let unix_time: u64 = UNIX_EPOCH.elapsed().expect("wtf").as_millis() as u64;

            let response_result = self
                .client
                .post(URL)
                .header("Content-Type", "application/json")
                .header("User-Agent", USER_AGENT.to_string())
                .header("Interface-Code", format!("null_{unix_time}"))
                .header("identity-id", identity_id)
                .send()
                .await;

            match response_result {
                Ok(response) => {
                    if !response.status().is_success() {
                        println!(
                            "{}",
                            format!(
                                "请求失败，状态码: {}，正在重试 ({}/{})",
                                response.status(),
                                retry_count + 1,
                                MAX_RETRIES
                            )
                            .yellow()
                        );
                        retry_count += 1;
                        tokio::time::sleep(Duration::from_secs(1)).await;
                        continue;
                    }

                    match response.text().await {
                        Ok(text) => {
                            let token = text.trim_matches('\"').to_string();
                            return token;
                        }
                        Err(e) => {
                            println!(
                                "{}",
                                format!(
                                    "解析响应失败: {}，正在重试 ({}/{})",
                                    e,
                                    retry_count + 1,
                                    MAX_RETRIES
                                )
                                .yellow()
                            );
                            retry_count += 1;
                            tokio::time::sleep(Duration::from_secs(1)).await;
                            continue;
                        }
                    }
                }
                Err(e) => {
                    println!(
                        "{}",
                        format!(
                            "发送请求失败: {}，正在重试 ({}/{})",
                            e,
                            retry_count + 1,
                            MAX_RETRIES
                        )
                        .yellow()
                    );
                    retry_count += 1;
                    tokio::time::sleep(Duration::from_secs(1)).await;
                    continue;
                }
            }
        }
    }
}

/// Token 信息结构体
pub struct TokenInfo {
    pub identity_id: String,
    pub interface_code: String,
}
