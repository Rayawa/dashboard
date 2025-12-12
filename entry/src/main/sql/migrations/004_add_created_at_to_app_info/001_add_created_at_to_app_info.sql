-- 迁移脚本：为 app_info 表添加 created_at 列
-- 执行顺序：004_add_created_at_to_app_info/001_add_created_at_to_app_info.sql

-- 1. 为 app_info 表添加 created_at 列，默认值为当前时间戳
ALTER TABLE app_info 
ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- 2. 为现有数据设置创建时间：使用 app_metrics 表中最老的记录时间
UPDATE app_info ai
SET created_at = (
    SELECT MIN(am.created_at) 
    FROM app_metrics am 
    WHERE am.app_id = ai.app_id
)
WHERE EXISTS (
    SELECT 1 
    FROM app_metrics am 
    WHERE am.app_id = ai.app_id
);

-- 3. 为没有 app_metrics 记录的应用设置默认创建时间（当前时间）
-- 这种情况应该很少，通常是新添加但还没有指标数据的应用
UPDATE app_info 
SET created_at = now() 
WHERE created_at = now() 
AND NOT EXISTS (
    SELECT 1 
    FROM app_metrics 
    WHERE app_metrics.app_id = app_info.app_id
);

-- 4. 为 created_at 列创建索引以提高查询性能
CREATE INDEX idx_app_info_created_at ON app_info(created_at);

-- 5. 更新视图以包含新的 created_at 列
DROP VIEW IF EXISTS app_latest_info;
CREATE OR REPLACE VIEW app_latest_info AS
SELECT ai.app_id,
   ai.alliance_app_id,
   ai.name,
   ai.pkg_name,
   ai.dev_id,
   ai.developer_name,
   ai.dev_en_name,
   ai.supplier,
   ai.kind_id,
   ai.kind_name,
   ai.tag_name,
   ai.kind_type_id,
   ai.kind_type_name,
   ai.icon_url,
   ai.brief_desc,
   ai.description,
   ai.privacy_url,
   ai.ctype,
   ai.detail_id,
   ai.app_level,
   ai.jocat_id,
   ai.iap,
   ai.hms,
   ai.tariff_type,
   ai.packing_type,
   ai.order_app,
   ai.denpend_gms,
   ai.denpend_hms,
   ai.force_update,
   ai.img_tag,
   ai.is_pay,
   ai.is_disciplined,
   ai.is_shelves,
   ai.submit_type,
   ai.delete_archive,
   ai.charging,
   ai.button_grey,
   ai.app_gift,
   ai.free_days,
   ai.pay_install_type,
   ai.created_at,  -- 新增的 created_at 列
   am.version,
   am.version_code,
   am.size_bytes,
   am.sha256,
   am.info_score,
   am.info_rate_count,
   am.download_count,
   am.price,
   am.release_date,
   am.new_features,
   am.upgrade_msg,
   am.target_sdk,
   am.minsdk,
   am.compile_sdk_version,
   am.min_hmos_api_level,
   am.api_release_type,
   ar.average_rating,
   ar.star_1_rating_count,
   ar.star_2_rating_count,
   ar.star_3_rating_count,
   ar.star_4_rating_count,
   ar.star_5_rating_count,
   ar.my_star_rating,
   ar.total_star_rating_count,
   ar.only_star_count,
   ar.full_average_rating,
   ar.source_type,
   am.created_at AS metrics_created_at,
   ar.created_at AS rating_created_at
  FROM app_info ai
    LEFT JOIN ( SELECT DISTINCT ON (app_metrics.app_id) app_metrics.id,
           app_metrics.app_id,
           app_metrics.version,
           app_metrics.version_code,
           app_metrics.size_bytes,
           app_metrics.sha256,
           app_metrics.download_count,
           app_metrics.price,
           app_metrics.release_date,
           app_metrics.new_features,
           app_metrics.upgrade_msg,
           app_metrics.target_sdk,
           app_metrics.minsdk,
           app_metrics.compile_sdk_version,
           app_metrics.min_hmos_api_level,
           app_metrics.api_release_type,
           app_metrics.created_at,
           app_metrics.info_score,
           app_metrics.info_rate_count
          FROM app_metrics
         ORDER BY app_metrics.app_id, app_metrics.created_at DESC NULLS LAST) am ON ai.app_id = am.app_id
    LEFT JOIN ( SELECT DISTINCT ON (app_rating.app_id) app_rating.id,
           app_rating.app_id,
           app_rating.average_rating,
           app_rating.star_1_rating_count,
           app_rating.star_2_rating_count,
           app_rating.star_3_rating_count,
           app_rating.star_4_rating_count,
           app_rating.star_5_rating_count,
           app_rating.my_star_rating,
           app_rating.total_star_rating_count,
           app_rating.only_star_count,
           app_rating.full_average_rating,
           app_rating.source_type,
           app_rating.created_at
          FROM app_rating
         ORDER BY app_rating.app_id, app_rating.created_at DESC NULLS LAST) ar ON ai.app_id = ar.app_id;

-- 迁移完成提示
DO $$
BEGIN
    RAISE NOTICE '迁移完成：成功为 app_info 表添加 created_at 列';
    RAISE NOTICE '已为 % 条记录设置了创建时间', (SELECT COUNT(*) FROM app_info);
    RAISE NOTICE '其中 % 条记录使用了 app_metrics 的最早记录时间', 
        (SELECT COUNT(*) FROM app_info WHERE created_at != now());
    RAISE NOTICE '% 条记录使用了默认当前时间', 
        (SELECT COUNT(*) FROM app_info WHERE created_at = now());
END $$;