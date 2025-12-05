use anyhow::Result;
use serde_json::Value as JsonValue;

use crate::db::Database;
use crate::model::{AppInfo, AppMetric, AppRating, AppRecord};
use crate::sync::substance::SubstanceData;

impl Database {
    /// 插入应用信息到 app_info 表
    pub async fn insert_app_info(&self, app_info: &AppInfo) -> Result<()> {
        const QUERY: &str = r#"
            INSERT INTO app_info (
                app_id, alliance_app_id, name, pkg_name, dev_id, developer_name,
                dev_en_name, supplier, kind_id, kind_name, tag_name,
                kind_type_id, kind_type_name, icon_url, brief_desc, description,
                privacy_url, ctype, detail_id, app_level, jocat_id, iap, hms,
                tariff_type, packing_type, order_app, denpend_gms, denpend_hms,
                force_update, img_tag, is_pay, is_disciplined, is_shelves,
                submit_type, delete_archive, charging, button_grey, app_gift,
                free_days, pay_install_type, created_at, listed_at, comment,
                release_countries, main_device_codes
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
                $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28,
                $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41,
                $42, $43, $44, $45
            )
            ON CONFLICT (app_id) DO UPDATE SET
                alliance_app_id = EXCLUDED.alliance_app_id,
                name = EXCLUDED.name,
                pkg_name = EXCLUDED.pkg_name,
                dev_id = EXCLUDED.dev_id,
                developer_name = EXCLUDED.developer_name,
                dev_en_name = EXCLUDED.dev_en_name,
                supplier = EXCLUDED.supplier,
                kind_id = EXCLUDED.kind_id,
                kind_name = EXCLUDED.kind_name,
                tag_name = EXCLUDED.tag_name,
                kind_type_id = EXCLUDED.kind_type_id,
                kind_type_name = EXCLUDED.kind_type_name,
                icon_url = EXCLUDED.icon_url,
                brief_desc = EXCLUDED.brief_desc,
                description = EXCLUDED.description,
                privacy_url = EXCLUDED.privacy_url,
                ctype = EXCLUDED.ctype,
                detail_id = EXCLUDED.detail_id,
                app_level = EXCLUDED.app_level,
                jocat_id = EXCLUDED.jocat_id,
                iap = EXCLUDED.iap,
                hms = EXCLUDED.hms,
                tariff_type = EXCLUDED.tariff_type,
                packing_type = EXCLUDED.packing_type,
                order_app = EXCLUDED.order_app,
                denpend_gms = EXCLUDED.denpend_gms,
                denpend_hms = EXCLUDED.denpend_hms,
                force_update = EXCLUDED.force_update,
                img_tag = EXCLUDED.img_tag,
                is_pay = EXCLUDED.is_pay,
                is_disciplined = EXCLUDED.is_disciplined,
                is_shelves = EXCLUDED.is_shelves,
                submit_type = EXCLUDED.submit_type,
                delete_archive = EXCLUDED.delete_archive,
                charging = EXCLUDED.charging,
                button_grey = EXCLUDED.button_grey,
                app_gift = EXCLUDED.app_gift,
                free_days = EXCLUDED.free_days,
                pay_install_type = EXCLUDED.pay_install_type,
                listed_at = EXCLUDED.listed_at,
                release_countries = EXCLUDED.release_countries,
                main_device_codes = EXCLUDED.main_device_codes
        "#;

        sqlx::query(QUERY)
            .bind(&app_info.app_id)
            .bind(&app_info.alliance_app_id)
            .bind(&app_info.name)
            .bind(&app_info.pkg_name)
            .bind(&app_info.dev_id)
            .bind(&app_info.developer_name)
            .bind(&app_info.dev_en_name)
            .bind(&app_info.supplier)
            .bind(app_info.kind_id)
            .bind(&app_info.kind_name)
            .bind(&app_info.tag_name)
            .bind(app_info.kind_type_id)
            .bind(&app_info.kind_type_name)
            .bind(&app_info.icon_url)
            .bind(&app_info.brief_desc)
            .bind(&app_info.description)
            .bind(&app_info.privacy_url)
            .bind(app_info.ctype)
            .bind(&app_info.detail_id)
            .bind(app_info.app_level)
            .bind(app_info.jocat_id)
            .bind(app_info.iap)
            .bind(app_info.hms)
            .bind(&app_info.tariff_type)
            .bind(app_info.packing_type)
            .bind(app_info.order_app)
            .bind(app_info.denpend_gms)
            .bind(app_info.denpend_hms)
            .bind(app_info.force_update)
            .bind(&app_info.img_tag)
            .bind(app_info.is_pay)
            .bind(app_info.is_disciplined)
            .bind(app_info.is_shelves)
            .bind(app_info.submit_type)
            .bind(app_info.delete_archive)
            .bind(app_info.charging)
            .bind(app_info.button_grey)
            .bind(app_info.app_gift)
            .bind(app_info.free_days)
            .bind(app_info.pay_install_type)
            .bind(app_info.created_at)
            .bind(app_info.listed_at)
            .bind(&app_info.comment)
            .bind(&app_info.release_countries)
            .bind(&app_info.main_device_codes)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    /// 插入应用指标到 app_metrics 表
    pub async fn insert_app_metric(&self, app_metric: &AppMetric) -> Result<()> {
        const QUERY: &str = r#"
            INSERT INTO app_metrics (
                app_id, pkg_name, version, version_code, size_bytes, sha256, info_score,
                info_rate_count, download_count, price, release_date, new_features,
                upgrade_msg, target_sdk, minsdk, compile_sdk_version,
                min_hmos_api_level, api_release_type
            ) VALUES (
                $1,
                (SELECT pkg_name FROM app_info WHERE app_id = $1),
                $2, $3, $4, $5, $6::numeric, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17
            )
        "#;

        sqlx::query(QUERY)
            .bind(&app_metric.app_id)
            .bind(&app_metric.version)
            .bind(app_metric.version_code)
            .bind(app_metric.size_bytes)
            .bind(&app_metric.sha256)
            .bind(app_metric.info_score)
            .bind(app_metric.info_rate_count)
            .bind(app_metric.download_count)
            .bind(app_metric.price)
            .bind(app_metric.release_date)
            .bind(&app_metric.new_features)
            .bind(&app_metric.upgrade_msg)
            .bind(app_metric.target_sdk)
            .bind(app_metric.minsdk)
            .bind(app_metric.compile_sdk_version)
            .bind(app_metric.min_hmos_api_level)
            .bind(&app_metric.api_release_type)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    /// 插入应用评分到 app_rating 表
    pub async fn insert_app_rating(&self, app_rating: &AppRating) -> Result<()> {
        const QUERY: &str = r#"
            INSERT INTO app_rating (
                app_id, pkg_name, average_rating,
                star_1_rating_count, star_2_rating_count, star_3_rating_count,
                star_4_rating_count, star_5_rating_count, my_star_rating,
                total_star_rating_count, only_star_count, full_average_rating,
                source_type
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13
            )
        "#;

        sqlx::query(QUERY)
            .bind(&app_rating.app_id)
            .bind(&app_rating.pkg_name)
            .bind(app_rating.average_rating)
            .bind(app_rating.star_1_rating_count)
            .bind(app_rating.star_2_rating_count)
            .bind(app_rating.star_3_rating_count)
            .bind(app_rating.star_4_rating_count)
            .bind(app_rating.star_5_rating_count)
            .bind(app_rating.my_star_rating)
            .bind(app_rating.total_star_rating_count)
            .bind(app_rating.only_star_count)
            .bind(app_rating.full_average_rating)
            .bind(&app_rating.source_type)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    /// 插入应用备案信息到 app_record 表
    pub async fn insert_app_record(&self, app_record: &AppRecord) -> Result<()> {
        const QUERY: &str = r#"
            INSERT INTO app_record (
                app_id, title, app_recordal_info,
                recordal_entity_title, recordal_entity_name
            ) VALUES (
                $1, $2, $3, $4, $5
            )
            ON CONFLICT (app_id) DO UPDATE SET
                title = EXCLUDED.title,
                app_recordal_info = EXCLUDED.app_recordal_info,
                recordal_entity_title = EXCLUDED.recordal_entity_title,
                recordal_entity_name = EXCLUDED.recordal_entity_name
        "#;

        sqlx::query(QUERY)
            .bind(&app_record.app_id)
            .bind(&app_record.title)
            .bind(&app_record.app_recordal_info)
            .bind(&app_record.recordal_entity_title)
            .bind(&app_record.recordal_entity_name)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    /// 插入应用数据到 app_data_history 表
    pub async fn insert_data_history(&self, app_id: &str, data: &JsonValue) -> Result<()> {
        let query = r#"
            INSERT INTO app_data_history (app_id, pkg_name, raw_json_data)
            VALUES ($1,
            (SELECT pkg_name FROM app_info WHERE app_id = $1),
            $2::jsonb)
        "#;

        sqlx::query(query)
            .bind(app_id)
            .bind(data)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    /// 插入 substance 到 substance_info 表
    pub async fn insert_substance(
        &self,
        substance: &SubstanceData,
        comment: Option<JsonValue>,
    ) -> Result<()> {
        const QUERY: &str = r#"
            INSERT INTO substance_info (substance_id, title, subtitle, name, comment)
            VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT (substance_id) DO UPDATE SET
                title = EXCLUDED.title,
                subtitle = EXCLUDED.subtitle,
                name = EXCLUDED.name
        "#;

        sqlx::query(QUERY)
            .bind(&substance.id)
            .bind(&substance.title)
            .bind(&substance.sub_title)
            .bind(&substance.name)
            .bind(comment)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    /// 插入 substance history 到 substance_history 表
    pub async fn insert_substance_history(
        &self,
        substance_id: &str,
        substance: &JsonValue,
    ) -> Result<()> {
        const QUERY: &str = r#"
            INSERT INTO substance_history (substance_id, raw_json_substance)
            VALUES ($1, $2::jsonb)
        "#;

        sqlx::query(QUERY)
            .bind(substance_id)
            .bind(substance)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    /// 插入 substance 和 app 的映射关系到 substance_app_map 表
    pub async fn insert_substance_app_map(&self, substance_id: &str, app_id: &str) -> Result<()> {
        const QUERY: &str = r#"
            INSERT INTO substance_app_map (substance_id, app_id)
            VALUES ($1, $2)
            ON CONFLICT (substance_id, app_id) DO NOTHING
        "#;

        sqlx::query(QUERY)
            .bind(substance_id)
            .bind(app_id)
            .execute(&self.pool)
            .await?;

        Ok(())
    }
}
