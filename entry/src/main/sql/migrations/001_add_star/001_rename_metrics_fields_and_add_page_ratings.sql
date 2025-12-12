-- 迁移脚本：重命名app_metrics表中的字段并添加页面评分相关字段
-- 执行顺序：先添加新字段，然后迁移数据，最后删除旧字段
-- 注意：此脚本应在002_modify_app_raw_table.sql之前执行

-- 1. 首先添加新的info_score和info_rate_count字段
ALTER TABLE app_metrics
ADD COLUMN info_score NUMERIC(3,1),
ADD COLUMN info_rate_count BIGINT;

-- 2. 将hot_score和rate_num的数据迁移到新字段
UPDATE app_metrics
SET info_score = hot_score::numeric,
    info_rate_count = rate_num::bigint;

-- 3. 添加页面评分相关的新字段
ALTER TABLE app_metrics
ADD COLUMN page_average_rating NUMERIC(3,1),
ADD COLUMN page_star_1_rating_count INTEGER,
ADD COLUMN page_star_2_rating_count INTEGER,
ADD COLUMN page_star_3_rating_count INTEGER,
ADD COLUMN page_star_4_rating_count INTEGER,
ADD COLUMN page_star_5_rating_count INTEGER,
ADD COLUMN page_my_star_rating INTEGER,
ADD COLUMN page_total_star_rating_count INTEGER,
ADD COLUMN page_only_star_count INTEGER,
ADD COLUMN page_full_average_rating NUMERIC(3,1),
ADD COLUMN page_source_type TEXT;

-- 4. 修改app_raw表结构，添加raw_json_star字段
ALTER TABLE app_raw
ADD COLUMN raw_json_star JSONB;

-- 5. 将现有的raw_json数据复制到raw_json_data字段（如果需要）
-- 注意：这一步需要根据现有数据的结构来决定是否需要
-- 如果现有raw_json字段包含的是应用数据，可以执行：
-- UPDATE app_raw SET raw_json_data = raw_json;

-- 7. 更新视图以反映字段名称更改
DROP VIEW IF EXISTS app_latest_info;

-- 6. 删除旧的hot_score和rate_num字段
ALTER TABLE app_metrics
DROP COLUMN hot_score,
DROP COLUMN rate_num;


CREATE OR REPLACE VIEW app_latest_info AS
SELECT
    ai.*,
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
    am.page_average_rating,
    am.page_star_1_rating_count,
    am.page_star_2_rating_count,
    am.page_star_3_rating_count,
    am.page_star_4_rating_count,
    am.page_star_5_rating_count,
    am.page_my_star_rating,
    am.page_total_star_rating_count,
    am.page_only_star_count,
    am.page_full_average_rating,
    am.page_source_type,
    am.created_at as metrics_created_at
FROM app_info ai
LEFT JOIN (
    SELECT DISTINCT ON (app_id) *
    FROM app_metrics
    ORDER BY app_id, release_date DESC NULLS LAST
) am ON ai.app_id = am.app_id;

-- 8. 重新创建索引
CREATE INDEX IF NOT EXISTS idx_app_info_app_id ON app_info(app_id);
CREATE INDEX IF NOT EXISTS idx_app_raw_app_id ON app_raw(app_id);
CREATE INDEX IF NOT EXISTS idx_app_metrics_app_id ON app_metrics(app_id);
CREATE INDEX IF NOT EXISTS idx_app_metrics_version ON app_metrics(version);
CREATE INDEX IF NOT EXISTS idx_app_metrics_download_count ON app_metrics(download_count);

-- 9. 迁移完成提示
COMMENT ON TABLE app_metrics IS '应用指标表，包含版本、评分、下载量等信息';
