use anyhow::Result;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::Value as JsonValue;
use tracing::{Level, event};

use crate::{
    model::AppQuery,
    sync::{USER_AGENT, code},
};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubstanceData {
    pub id: String,
    pub title: String,
    pub sub_title: Option<String>,
    pub name: Option<String>,
    pub data: Vec<AppQuery>,
}

impl SubstanceData {
    pub fn say_my_name(&self) -> String {
        format!(
            "{}{}{}",
            self.title,
            self.sub_title
                .as_ref()
                .map(|s| format!(" - {}", s))
                .unwrap_or_default(),
            self.name
                .as_ref()
                .map(|s| format!(" ({})", s))
                .unwrap_or_default()
        )
    }
}

async fn get_more_substance(
    client: &reqwest::Client,
    api_url: &str,
    card_id: impl ToString,
) -> Result<Vec<AppQuery>> {
    let mut has_more = true;
    // 从 2 开始
    let mut page_num = 2;
    let mut apps = Vec::new();
    let target_url = format!("{api_url}/harmony/card-list");
    while has_more {
        let body = serde_json::json!({
            "dataId": card_id.to_string(),
            "locale": "zh",
            "pageNum": page_num,
            "pageSize": 25,
        });
        let token = code::GLOBAL_CODE_MANAGER.get_full_token().await;
        let response = client
            .post(&target_url)
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
                target_url,
                body
            ));
        }

        // 检查响应体是否为空
        let content_length = response.content_length().unwrap_or(0);
        if content_length == 0 {
            return Err(anyhow::anyhow!(
                "HTTP响应体为空 \nurl: {target_url} data: {body}"
            ));
        }

        let data = response.json::<serde_json::Value>().await?;
        has_more = data
            .get("hasMore")
            .and_then(|v| v.as_i64())
            .map(|v| v != 0)
            .unwrap_or(false);
        page_num += 1;
        let layout = data["layoutData"].as_array().expect("layoutData not array");
        for card in layout {
            let card_type = card["type"].as_str().unwrap_or_default();
            let card_data = card["data"].as_array().expect("card data not array");
            #[allow(clippy::single_match)]
            match card_type {
                "com.huawei.hmsapp.appgallery.verticallistcard" => {
                    for app in card_data {
                        let app_id = app.get("appId").and_then(|v| v.as_str());
                        if let Some(app_id) = app_id {
                            apps.push(AppQuery::app_id(app_id));
                        }
                    }
                }
                _ => {}
            }
        }
    }

    Ok(apps)
}

/// 获取主题的内容
pub async fn get_app_from_substance(
    client: &reqwest::Client,
    api_url: &str,
    substance_id: impl ToString,
) -> Result<(SubstanceData, JsonValue)> {
    let body = serde_json::json!({
        "pageId": format!("webAgSubstanceDetail|{}", substance_id.to_string()),
        "pageNum": 1,
        "pageSize": 100,
        "zone": "",
        "businessParam": { "animation": 0 }
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
    let data = {
        let raw = response.json::<serde_json::Value>().await?;
        let pages = &raw["pages"].as_array().expect("pages not array")[0];

        let card_list = &pages["data"]["cardlist"]
            .as_object()
            .expect("cardlist not object");

        let mut apps = Vec::new();

        if card_list["hasMore"].as_i64().unwrap_or(0) != 0 {
            let card_id = card_list["dataId"]
                .as_str()
                .expect("dataId not str")
                .to_string();
            let more_apps = get_more_substance(client, api_url, card_id).await?;
            apps.extend(more_apps);
        }
        let layouts = &card_list["layoutData"];
        let layouts = layouts.as_array().expect("layoutData not array");

        let mut title = None;
        let mut sub_title = None;
        let mut name = None;
        for card in layouts {
            let data_cards = card.as_object().expect("card not object")["data"]
                .as_array()
                .expect("data not array");
            match card["type"].as_str().unwrap_or("") {
                "com.huawei.hmsapp.appgallery.verticallistcard" => {
                    // 竖向列表卡片
                    for card in data_cards {
                        if let Some(app_id) = card.get("appId") {
                            apps.push(AppQuery::app_id(app_id.as_str().expect("appId not str")));
                        }
                    }
                }
                "com.huawei.hmos.appgallery.scenariolistcard.landing"
                | "com.huawei.hmos.appgallery.whiteverticalslidercard.landing"
                | "com.huawei.hmsapp.appgallery.appiconrollingcard.landing" => {
                    // 这玩意是肯定有第一个的
                    let first = &data_cards[0].as_object().expect("first not object");
                    // 考虑到有概率他就是个title, 先把 title 拿了
                    if let Some(title_obj) = first.get("title") {
                        title = title_obj.as_str().map(|s| s.to_string());
                    }
                    if let Some(sub_title_obj) = first.get("subTitle") {
                        sub_title = sub_title_obj.as_str().map(|s| s.to_string());
                    }
                    if let Some(name_obj) = first.get("name") {
                        name = name_obj.as_str().map(|s| s.to_string());
                    }

                    if !first.contains_key("refsList_app") {
                        // 有 verticallistcard 的, landing 里面就没有 app 了
                        continue;
                    }
                    // 里面有可能有个 refsList_app 是个数组，里面是 appId
                    let app_list = first["refsList_app"]
                        .as_array()
                        .expect("refsList_app not array");
                    for app in app_list {
                        if let Some(app_id) = app.get("appId") {
                            apps.push(AppQuery::app_id(app_id.as_str().expect("appId not str")));
                        }
                    }
                }
                "com.huawei.hmsapp.appgallery.subjectappbigcard.landing" => {
                    // 大卡片, 只是用来获取标题, 吗?
                    for card in data_cards {
                        if let Some(title_obj) = card.get("title") {
                            title = title_obj.as_str().map(|s| s.to_string());
                        }
                        if let Some(sub_title_obj) = card.get("subTitle") {
                            sub_title = sub_title_obj.as_str().map(|s| s.to_string());
                        }
                        if let Some(name_obj) = card.get("name") {
                            name = name_obj.as_str().map(|s| s.to_string());
                        }
                        if let Some(app_list) = card.get("refsList_app_short") {
                            // 想不到吧! 我还能复用! (华为我谢谢你)
                            let app_list =
                                app_list.as_array().expect("refsList_app_short not array");
                            for app in app_list {
                                if let Some(app_id) = app.get("appId") {
                                    apps.push(AppQuery::app_id(
                                        app_id.as_str().expect("appId not str"),
                                    ));
                                }
                            }
                        }
                    }
                }
                _ => {}
            }
        }
        apps.sort();
        apps.dedup();

        (
            SubstanceData {
                id: substance_id.to_string(),
                title: title.unwrap_or_default(),
                sub_title,
                name,
                data: apps,
            },
            pages.clone(),
        )
    };

    Ok(data)
}

/// 同步专题
pub async fn sync_substance(
    client: &Client,
    db: &crate::db::Database,
    config: &crate::config::Config,
) -> anyhow::Result<()> {
    let substances = db.get_all_substance_id().await?;

    let mut query_apps = Vec::with_capacity(substances.len() * 3);
    let mut raw_datas = Vec::with_capacity(substances.len());

    for substance_id in substances {
        let apps = get_app_from_substance(client, config.api_url(), substance_id).await?;
        query_apps.extend(apps.0.data.clone());
        raw_datas.push(apps);
    }

    query_apps.sort();
    query_apps.dedup();

    // 使用 sync_all
    for app in query_apps.iter() {
        if let Err(e) = crate::sync::sync_app(client, db, config.api_url(), app, None, None).await {
            event!(Level::WARN, "保存 app 时错误 {e}")
        }
    }

    for (substance, raw_substance) in raw_datas {
        if let Err(e) = db.save_substance(&substance, &raw_substance, None).await {
            event!(Level::WARN, "保存 substance 时错误 {e}")
        }
    }
    Ok(())
}
