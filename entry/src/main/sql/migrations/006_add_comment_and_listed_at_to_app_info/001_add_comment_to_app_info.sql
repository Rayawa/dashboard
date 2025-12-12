-- 迁移脚本：为 app_info 表添加 comment 字段和 listed_at 字段
-- 执行顺序：006_add_comment_and_listed_at_to_app_info/001_add_comment_to_app_info.sql

-- 为 app_info 表添加 comment 列，类型为 JSONB，允许为 NULL
ALTER TABLE app_info
ADD COLUMN comment JSONB;

-- 为 app_info 表添加 listed_at 列，类型为 TIMESTAMPTZ，暂时允许为 NULL
ALTER TABLE app_info
ADD COLUMN listed_at TIMESTAMPTZ;

-- 为新字段添加注释
COMMENT ON COLUMN app_info.listed_at IS '应用上架时间';

-- 使用 created_at 数据填充 listed_at 字段
UPDATE app_info SET listed_at = created_at WHERE listed_at IS NULL;

-- 修改 listed_at 字段为 NOT NULL
ALTER TABLE app_info
ALTER COLUMN listed_at SET NOT NULL;

-- 为 listed_at 字段创建索引以提高查询性能
CREATE INDEX idx_app_info_listed_at ON app_info(listed_at);
CREATE INDEX idx_app_info_pkg_name ON app_info(pkg_name);
CREATE INDEX idx_app_info_name ON app_info(name);
CREATE INDEX idx_app_info_developer_name ON app_info(developer_name);

-- 删除现有视图
DROP VIEW IF EXISTS app_latest_info;

-- 重新创建 app_latest_info 视图，包含新增的 comment 字段和 listed_at 字段
CREATE VIEW app_latest_info AS
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
   ai.comment,      -- 新增字段：comment
   ai.listed_at,    -- 新增字段：上架时间
   ai.created_at,   -- 创建时间
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
    RAISE NOTICE '迁移完成：成功为 app_info 表添加 comment 和 listed_at 字段';
    RAISE NOTICE '- 添加了 comment 字段 (类型: JSONB, 允许为 NULL)';
    RAISE NOTICE '- 添加了 listed_at 字段 (类型: TIMESTAMPTZ, NOT NULL)';
    RAISE NOTICE '- 使用 created_at 数据填充了 listed_at 字段';
    RAISE NOTICE '- 重新创建了 app_latest_info 视图以包含 comment 和 listed_at 字段';
END $$;
