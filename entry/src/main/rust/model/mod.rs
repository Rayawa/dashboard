pub mod query;
pub mod raw;

use chrono::{DateTime, Local};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;

use crate::{model::raw::RawAppData, utils::sanitize_utf8_string};

pub use query::AppQuery;
pub use raw::{RawJsonData, RawRatingData, RawRecordalInfo};

/// 简化版评分排行结构体
#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, ToSchema)]
pub struct ShortAppRating {
    pub app_id: String,
    pub name: String,
    pub pkg_name: String,
    pub developer_name: String,
    pub icon_url: String,
    pub average_rating: Decimal,
    pub total_star_rating_count: i32,
}

/// 专题完整信息
#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, ToSchema)]
pub struct FullSubstanceInfo {
    pub substance_id: String,
    pub title: String,
    pub subtitle: Option<String>,
    pub name: Option<String>,
    pub comment: Option<serde_json::Value>,
    pub created_at: DateTime<Local>,
    /// 专题包含的应用列表
    pub apps: Vec<ShortAppInfo>,
}

/// 专题简略信息
#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, ToSchema, FromRow)]
pub struct ShortSubstanceInfo {
    pub substance_id: String,
    pub title: String,
    pub subtitle: Option<String>,
    pub created_at: DateTime<Local>,
}

/// 2. app_full_info 表
#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, ToSchema)]
pub struct FullAppInfo {
    pub app_id: String,
    pub alliance_app_id: String,
    pub name: String,
    pub pkg_name: String,
    pub dev_id: String,
    pub developer_name: String,
    pub dev_en_name: String,
    pub supplier: String,
    pub kind_id: i32,
    pub kind_name: String,
    pub tag_name: Option<String>,
    pub kind_type_id: i32,
    pub kind_type_name: String,
    pub icon_url: String,
    pub brief_desc: String,
    pub description: String,
    pub privacy_url: String,
    pub ctype: i32,
    pub detail_id: String,
    pub app_level: i32,
    pub jocat_id: i32,
    pub iap: bool,
    pub hms: bool,
    pub tariff_type: String,
    pub packing_type: i32,
    pub order_app: bool,
    pub denpend_gms: bool,
    pub denpend_hms: bool,
    pub force_update: bool,
    pub img_tag: String,
    pub is_pay: bool,
    pub is_disciplined: bool,
    pub is_shelves: bool,
    pub submit_type: i32,
    pub delete_archive: bool,
    pub charging: bool,
    pub button_grey: bool,
    pub app_gift: bool,
    pub free_days: i32,
    pub pay_install_type: i32,
    pub created_at: DateTime<Local>,
    pub listed_at: DateTime<Local>,
    pub comment: Option<serde_json::Value>,
    pub release_countries: Vec<String>,
    pub main_device_codes: Vec<String>,
    // app_metrics
    pub version: String,
    pub version_code: i64,
    pub size_bytes: i64,
    pub sha256: String,
    pub info_score: Decimal,
    pub info_rate_count: i64,
    pub download_count: i64,
    pub price: Decimal,
    pub release_date: i64,
    pub new_features: String,
    pub upgrade_msg: String,
    pub target_sdk: i32,
    pub minsdk: i32,
    pub compile_sdk_version: i32,
    pub min_hmos_api_level: i32,
    pub api_release_type: String,
    pub metrics_created_at: DateTime<Local>,
    // app_rating
    pub average_rating: Option<Decimal>,
    pub star_1_rating_count: Option<i32>,
    pub star_2_rating_count: Option<i32>,
    pub star_3_rating_count: Option<i32>,
    pub star_4_rating_count: Option<i32>,
    pub star_5_rating_count: Option<i32>,
    pub my_star_rating: Option<i32>,
    pub total_star_rating_count: Option<i32>,
    pub only_star_count: Option<i32>,
    pub full_average_rating: Option<Decimal>,
    pub source_type: Option<String>,
    pub rating_created_at: Option<DateTime<Local>>,
    // app_record (备案信息)
    pub title: Option<String>,
    pub app_recordal_info: Option<String>,
    pub recordal_entity_title: Option<String>,
    pub recordal_entity_name: Option<String>,
    pub updated_at: DateTime<Local>,
}

impl FullAppInfo {
    pub fn from_raw(raw: &RawAppData) -> Self {
        let value = &raw.app_info;
        let rating = raw.app_rating.as_ref();
        let record = raw.app_record.as_ref();
        Self {
            app_id: sanitize_utf8_string(&value.app_id).into_owned(),
            alliance_app_id: sanitize_utf8_string(&value.alliance_app_id).into_owned(),
            name: sanitize_utf8_string(&value.name).into_owned(),
            pkg_name: sanitize_utf8_string(&value.pkg_name).into_owned(),
            dev_id: sanitize_utf8_string(&value.dev_id).into_owned(),
            developer_name: sanitize_utf8_string(&value.developer_name).into_owned(),
            dev_en_name: sanitize_utf8_string(&value.dev_en_name).into_owned(),
            supplier: sanitize_utf8_string(&value.supplier).into_owned(),
            kind_id: value.kind_id.parse().unwrap_or(0),
            kind_name: sanitize_utf8_string(&value.kind_name).into_owned(),
            tag_name: value
                .tag_name
                .as_ref()
                .map(|s| sanitize_utf8_string(s).into_owned()),
            kind_type_id: value.kind_type_id.parse().unwrap_or(0),
            kind_type_name: sanitize_utf8_string(&value.kind_type_name).into_owned(),
            icon_url: sanitize_utf8_string(&value.icon_url).into_owned(),
            brief_desc: sanitize_utf8_string(&value.brief_desc).into_owned(),
            description: sanitize_utf8_string(&value.description).into_owned(),
            privacy_url: sanitize_utf8_string(&value.privacy_url).into_owned(),
            ctype: value.ctype,
            detail_id: sanitize_utf8_string(&value.detail_id).into_owned(),
            app_level: value.app_level,
            jocat_id: value.jocat_id,
            iap: value.iap != 0,
            hms: value.hms != 0,
            tariff_type: sanitize_utf8_string(&value.tariff_type).into_owned(),
            packing_type: value.packing_type,
            order_app: value.order_app,
            denpend_gms: value.denpend_gms != 0,
            denpend_hms: value.denpend_hms != 0,
            force_update: value.force_update != 0,
            img_tag: sanitize_utf8_string(&value.img_tag).into_owned(),
            is_pay: value.is_pay == "1",
            is_disciplined: value.is_disciplined != 0,
            is_shelves: value.is_shelves != 0,
            submit_type: value.submit_type,
            delete_archive: value.delete_archive != 0,
            charging: value.charging != 0,
            button_grey: value.button_grey != 0,
            app_gift: value.app_gift != 0,
            free_days: value.free_days,
            pay_install_type: value.pay_install_type,
            created_at: Local::now(),
            listed_at: Local::now(),
            comment: None,
            release_countries: value.release_countries.clone(),
            main_device_codes: value.main_device_codes.clone(),
            // app_metrics 冗余字段从 raw json data 获取
            version: sanitize_utf8_string(&value.version).into_owned(),
            version_code: value.version_code,
            size_bytes: value.size_bytes,
            sha256: sanitize_utf8_string(&value.sha256).into_owned(),
            info_score: value.hot_score.parse().unwrap_or(Decimal::ZERO),
            info_rate_count: value.rate_num.parse().unwrap_or(0),
            download_count: value.download_count.parse().unwrap_or(0),
            price: value.price.parse().unwrap_or(Decimal::ZERO),
            release_date: value.release_date,
            new_features: sanitize_utf8_string(&value.new_features).into_owned(),
            upgrade_msg: sanitize_utf8_string(&value.upgrade_msg).into_owned(),
            target_sdk: value.target_sdk.parse().unwrap_or(0),
            minsdk: value.min_sdk.parse().unwrap_or(0),
            compile_sdk_version: value.compile_sdk_version,
            min_hmos_api_level: value.min_hmos_api_level,
            api_release_type: sanitize_utf8_string(&value.api_release_type).into_owned(),
            metrics_created_at: Local::now(),
            // app_rating
            average_rating: rating.map(|r| r.average_rating.parse().unwrap_or(Decimal::ZERO)),
            star_1_rating_count: rating.map(|r| r.star_1_rating_count),
            star_2_rating_count: rating.map(|r| r.star_2_rating_count),
            star_3_rating_count: rating.map(|r| r.star_3_rating_count),
            star_4_rating_count: rating.map(|r| r.star_4_rating_count),
            star_5_rating_count: rating.map(|r| r.star_5_rating_count),
            my_star_rating: rating.map(|r| r.my_star_rating),
            total_star_rating_count: rating.map(|r| r.total_star_rating_count),
            only_star_count: rating.map(|r| r.only_star_count),
            full_average_rating: rating
                .map(|r| r.full_average_rating.parse().unwrap_or(Decimal::ZERO)),
            source_type: rating.map(|r| sanitize_utf8_string(&r.source_type).to_string()),
            rating_created_at: rating.map(|_| Local::now()),
            // app_record
            title: record.map(|r| sanitize_utf8_string(&r.title).to_string()),
            app_recordal_info: record
                .map(|r| sanitize_utf8_string(&r.app_recordal_info).to_string()),
            recordal_entity_title: record
                .map(|r| sanitize_utf8_string(&r.recordal_entity_title).to_string()),
            recordal_entity_name: record
                .map(|r| sanitize_utf8_string(&r.recordal_entity_name).to_string()),
            updated_at: Local::now(),
        }
    }
}

/// 2. app_info 表
#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, FromRow, ToSchema)]
pub struct AppInfo {
    pub app_id: String,
    pub alliance_app_id: String,
    pub name: String,
    pub pkg_name: String,
    pub dev_id: String,
    pub developer_name: String,
    pub dev_en_name: String,
    pub supplier: String,
    pub kind_id: i32,
    pub kind_name: String,
    pub tag_name: Option<String>,
    pub kind_type_id: i32,
    pub kind_type_name: String,
    pub icon_url: String,
    pub brief_desc: String,
    pub description: String,
    pub privacy_url: String,
    pub ctype: i32,
    pub detail_id: String,
    pub app_level: i32,
    pub jocat_id: i32,
    pub iap: bool,
    pub hms: bool,
    pub tariff_type: String,
    pub packing_type: i32,
    pub order_app: bool,
    pub denpend_gms: bool,
    pub denpend_hms: bool,
    pub force_update: bool,
    pub img_tag: String,
    pub is_pay: bool,
    pub is_disciplined: bool,
    pub is_shelves: bool,
    pub submit_type: i32,
    pub delete_archive: bool,
    pub charging: bool,
    pub button_grey: bool,
    pub app_gift: bool,
    pub free_days: i32,
    pub pay_install_type: i32,
    pub created_at: DateTime<Local>,
    pub listed_at: DateTime<Local>,
    pub comment: Option<serde_json::Value>,
    pub release_countries: Vec<String>,
    pub main_device_codes: Vec<String>,
}

impl AppInfo {
    pub fn from_raw(raw: &RawAppData) -> Self {
        let value = &raw.app_info;
        Self {
            app_id: sanitize_utf8_string(&value.app_id).into_owned(),
            alliance_app_id: sanitize_utf8_string(&value.alliance_app_id).into_owned(),
            name: sanitize_utf8_string(&value.name).into_owned(),
            pkg_name: sanitize_utf8_string(&value.pkg_name).into_owned(),
            dev_id: sanitize_utf8_string(&value.dev_id).into_owned(),
            developer_name: sanitize_utf8_string(&value.developer_name).into_owned(),
            dev_en_name: sanitize_utf8_string(&value.dev_en_name).into_owned(),
            supplier: sanitize_utf8_string(&value.supplier).into_owned(),
            kind_id: value.kind_id.parse().unwrap_or(0),
            kind_name: sanitize_utf8_string(&value.kind_name).into_owned(),
            tag_name: value
                .tag_name
                .as_ref()
                .map(|s| sanitize_utf8_string(s).into_owned()),
            kind_type_id: value.kind_type_id.parse().unwrap_or(0),
            kind_type_name: sanitize_utf8_string(&value.kind_type_name).into_owned(),
            icon_url: sanitize_utf8_string(&value.icon_url).into_owned(),
            brief_desc: sanitize_utf8_string(&value.brief_desc).into_owned(),
            description: sanitize_utf8_string(&value.description).into_owned(),
            privacy_url: sanitize_utf8_string(&value.privacy_url).into_owned(),
            ctype: value.ctype,
            detail_id: sanitize_utf8_string(&value.detail_id).into_owned(),
            app_level: value.app_level,
            jocat_id: value.jocat_id,
            iap: value.iap != 0,
            hms: value.hms != 0,
            tariff_type: sanitize_utf8_string(&value.tariff_type).into_owned(),
            packing_type: value.packing_type,
            order_app: value.order_app,
            denpend_gms: value.denpend_gms != 0,
            denpend_hms: value.denpend_hms != 0,
            force_update: value.force_update != 0,
            img_tag: sanitize_utf8_string(&value.img_tag).into_owned(),
            is_pay: value.is_pay == "1",
            is_disciplined: value.is_disciplined != 0,
            is_shelves: value.is_shelves != 0,
            submit_type: value.submit_type,
            delete_archive: value.delete_archive != 0,
            charging: value.charging != 0,
            button_grey: value.button_grey != 0,
            app_gift: value.app_gift != 0,
            free_days: value.free_days,
            pay_install_type: value.pay_install_type,
            created_at: Local::now(),
            listed_at: Local::now(),
            comment: None,
            release_countries: value.release_countries.clone(),
            main_device_codes: value.main_device_codes.clone(),
        }
    }
}

impl AppInfo {
    pub fn update_from_db(&mut self, db_data: &Self) {
        self.created_at = db_data.created_at;
        self.listed_at = db_data.listed_at;
        self.comment = db_data.comment.clone();
    }
}

/// 简化过的 AppInfo
#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, ToSchema, FromRow)]
pub struct ShortAppInfo {
    pub app_id: String,
    pub name: String,
    pub pkg_name: String,
    pub icon_url: String,
    pub create_at: DateTime<Local>,
}

impl From<&AppInfo> for ShortAppInfo {
    fn from(app_info: &AppInfo) -> Self {
        ShortAppInfo {
            app_id: app_info.app_id.clone(),
            name: app_info.name.clone(),
            pkg_name: app_info.pkg_name.clone(),
            icon_url: app_info.icon_url.clone(),
            create_at: app_info.created_at,
        }
    }
}

impl From<&RawJsonData> for ShortAppInfo {
    fn from(raw_data: &RawJsonData) -> Self {
        ShortAppInfo {
            app_id: raw_data.app_id.clone(),
            name: raw_data.name.clone(),
            pkg_name: raw_data.pkg_name.clone(),
            icon_url: raw_data.icon_url.clone(),
            create_at: Local::now(),
        }
    }
}

impl From<&RawJsonData> for AppInfo {
    fn from(raw_data: &RawJsonData) -> Self {
        use crate::utils::sanitize_utf8_string;
        AppInfo {
            app_id: sanitize_utf8_string(&raw_data.app_id).into_owned(),
            alliance_app_id: sanitize_utf8_string(&raw_data.alliance_app_id).into_owned(),
            name: sanitize_utf8_string(&raw_data.name).into_owned(),
            pkg_name: sanitize_utf8_string(&raw_data.pkg_name).into_owned(),
            dev_id: sanitize_utf8_string(&raw_data.dev_id).into_owned(),
            developer_name: sanitize_utf8_string(&raw_data.developer_name).into_owned(),
            dev_en_name: sanitize_utf8_string(&raw_data.dev_en_name).into_owned(),
            supplier: sanitize_utf8_string(&raw_data.supplier).into_owned(),
            kind_id: raw_data.kind_id.parse().unwrap_or(0),
            kind_name: sanitize_utf8_string(&raw_data.kind_name).into_owned(),
            tag_name: raw_data
                .tag_name
                .as_ref()
                .map(|s| sanitize_utf8_string(s).into_owned()),
            kind_type_id: raw_data.kind_type_id.parse().unwrap_or(0),
            kind_type_name: sanitize_utf8_string(&raw_data.kind_type_name).into_owned(),
            icon_url: sanitize_utf8_string(&raw_data.icon_url).into_owned(),
            brief_desc: sanitize_utf8_string(&raw_data.brief_desc).into_owned(),
            description: sanitize_utf8_string(&raw_data.description).into_owned(),
            privacy_url: sanitize_utf8_string(&raw_data.privacy_url).into_owned(),
            ctype: raw_data.ctype,
            detail_id: sanitize_utf8_string(&raw_data.detail_id).into_owned(),
            app_level: raw_data.app_level,
            jocat_id: raw_data.jocat_id,
            iap: raw_data.iap != 0,
            hms: raw_data.hms != 0,
            tariff_type: sanitize_utf8_string(&raw_data.tariff_type).into_owned(),
            packing_type: raw_data.packing_type,
            order_app: raw_data.order_app,
            denpend_gms: raw_data.denpend_gms != 0,
            denpend_hms: raw_data.denpend_hms != 0,
            force_update: raw_data.force_update != 0,
            img_tag: sanitize_utf8_string(&raw_data.img_tag).into_owned(),
            is_pay: raw_data.is_pay.parse::<i32>().unwrap_or(0) != 0,
            is_disciplined: raw_data.is_disciplined != 0,
            is_shelves: raw_data.is_shelves != 0,
            submit_type: raw_data.submit_type,
            delete_archive: raw_data.delete_archive != 0,
            charging: raw_data.charging != 0,
            button_grey: raw_data.button_grey != 0,
            app_gift: raw_data.app_gift != 0,
            free_days: raw_data.free_days,
            pay_install_type: raw_data.pay_install_type,
            created_at: Local::now(),
            listed_at: Local::now(),
            comment: None,
            release_countries: raw_data.release_countries.clone(),
            main_device_codes: raw_data.main_device_codes.clone(),
        }
    }
}

// impl From<FullAppInfo> for AppInfo {
//     fn from(full_info: FullAppInfo) -> Self {
//         full_info.info
//     }
// }
// impl From<FullAppInfo> for AppMetric {
//     fn from(full_info: FullAppInfo) -> Self {
//         full_info.metric
//     }
// }

impl From<FullAppInfo> for ShortAppInfo {
    fn from(full_info: FullAppInfo) -> Self {
        ShortAppInfo {
            app_id: full_info.app_id,
            name: full_info.name,
            pkg_name: full_info.pkg_name,
            icon_url: full_info.icon_url,
            create_at: full_info.created_at,
        }
    }
}

// Old commented code:
// impl From<FullAppInfo> for ShortAppInfo {
//     fn from(full_info: FullAppInfo) -> Self {
//         let info = full_info.info;
//         ShortAppInfo {
//             app_id: info.app_id,
//             name: info.name,
//             pkg_name: info.pkg_name,
//             icon_url: info.icon_url,
//             create_at: info.created_at,
//         }
//     }
// }

/// 4. app_metrics 表
#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, FromRow)]
pub struct AppMetric {
    pub id: i64,
    pub app_id: String,
    pub version: String,
    pub version_code: i64,
    pub size_bytes: i64,
    pub sha256: String,
    pub info_score: Decimal,
    pub info_rate_count: i64,
    pub download_count: i64,
    pub price: Decimal,
    pub release_date: i64,
    pub new_features: String,
    pub upgrade_msg: String,
    pub target_sdk: i32,
    pub minsdk: i32,
    pub compile_sdk_version: i32,
    pub min_hmos_api_level: i32,
    pub api_release_type: String,
    pub created_at: DateTime<Local>,
}

impl AppMetric {
    pub fn from_raw_data(raw_data: &RawJsonData) -> Self {
        Self {
            id: 0,
            app_id: raw_data.app_id.clone(),
            version: sanitize_utf8_string(&raw_data.version).into_owned(),
            version_code: raw_data.version_code,
            size_bytes: raw_data.size_bytes,
            sha256: sanitize_utf8_string(&raw_data.sha256).into_owned(),
            info_score: raw_data.hot_score.parse().unwrap_or(Decimal::ZERO),
            info_rate_count: raw_data.rate_num.parse().unwrap_or(0),
            download_count: raw_data.download_count.parse().unwrap_or(0),
            price: raw_data.price.parse().unwrap_or(Decimal::ZERO),
            release_date: raw_data.release_date,
            new_features: sanitize_utf8_string(&raw_data.new_features).into_owned(),
            upgrade_msg: sanitize_utf8_string(&raw_data.upgrade_msg).into_owned(),
            target_sdk: raw_data.target_sdk.parse().unwrap_or(0),
            minsdk: raw_data.min_sdk.parse().unwrap_or(0),
            compile_sdk_version: raw_data.compile_sdk_version,
            min_hmos_api_level: raw_data.min_hmos_api_level,
            api_release_type: sanitize_utf8_string(&raw_data.api_release_type).into_owned(),
            created_at: Local::now(),
        }
    }

    pub fn update_from_db(&mut self, db_data: &Self) {
        self.id = db_data.id;
        self.created_at = db_data.created_at;
    }
}

/// 5. app_rating 表
#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, FromRow, ToSchema)]
pub struct AppRating {
    pub id: i64,
    pub app_id: String,
    pub pkg_name: String,
    pub average_rating: Decimal,
    pub star_1_rating_count: i32,
    pub star_2_rating_count: i32,
    pub star_3_rating_count: i32,
    pub star_4_rating_count: i32,
    pub star_5_rating_count: i32,
    pub my_star_rating: i32,
    pub total_star_rating_count: i32,
    pub only_star_count: i32,
    pub full_average_rating: Decimal,
    pub source_type: String,
    pub created_at: DateTime<Local>,
}

impl AppRating {
    pub fn from_raw_star(raw_data: &RawJsonData, raw_star: &RawRatingData) -> Self {
        Self {
            id: 0,
            app_id: raw_data.app_id.clone(),
            pkg_name: raw_data.pkg_name.clone(),
            average_rating: raw_star.average_rating.parse().unwrap_or(Decimal::ZERO),
            star_1_rating_count: raw_star.star_1_rating_count,
            star_2_rating_count: raw_star.star_2_rating_count,
            star_3_rating_count: raw_star.star_3_rating_count,
            star_4_rating_count: raw_star.star_4_rating_count,
            star_5_rating_count: raw_star.star_5_rating_count,
            my_star_rating: raw_star.my_star_rating,
            total_star_rating_count: raw_star.total_star_rating_count,
            only_star_count: raw_star.only_star_count,
            full_average_rating: raw_star
                .full_average_rating
                .parse()
                .unwrap_or(Decimal::ZERO),
            source_type: sanitize_utf8_string(&raw_star.source_type).into_owned(),
            created_at: Local::now(),
        }
    }
    pub fn update_from_db(&mut self, db_data: &Self) {
        self.id = db_data.id;
        self.created_at = db_data.created_at;
    }
}

#[derive(Debug, Clone, Deserialize, Serialize, FromRow, ToSchema)]
pub struct AppRecord {
    pub id: i64,
    pub app_id: String,
    /// 标题，例如 "服务备案号"
    pub title: String,
    /// 备案号文本
    pub app_recordal_info: String,
    /// 主办单位标题
    pub recordal_entity_title: String,
    /// 主办单位名称
    pub recordal_entity_name: String,
}

impl AppRecord {
    pub fn from_raw_record(app_id: &str, raw_record: &RawRecordalInfo) -> Self {
        Self {
            id: 0,
            app_id: app_id.to_string(),
            title: sanitize_utf8_string(&raw_record.title).into_owned(),
            app_recordal_info: sanitize_utf8_string(&raw_record.app_recordal_info).into_owned(),
            recordal_entity_title: sanitize_utf8_string(&raw_record.recordal_entity_title)
                .into_owned(),
            recordal_entity_name: sanitize_utf8_string(&raw_record.recordal_entity_name)
                .into_owned(),
        }
    }

    pub fn update_from_db(&mut self, db_data: &Self) {
        self.id = db_data.id;
    }
}

/// 6. 应用数据历史记录表 (app_data_history)
#[derive(Debug, Clone, Deserialize, Serialize, FromRow, ToSchema)]
pub struct AppDataHistory {
    pub id: i64,
    pub app_id: String,
    pub pkg_name: String,
    pub raw_json_data: serde_json::Value,
    pub created_at: DateTime<Local>,
}

impl AppDataHistory {
    pub fn from_raw_data(app_id: &str, pkg_name: &str, data: &serde_json::Value) -> Self {
        Self {
            id: 0,
            app_id: app_id.to_string(),
            pkg_name: pkg_name.to_string(),
            raw_json_data: data.clone(),
            created_at: Local::now(),
        }
    }
}
