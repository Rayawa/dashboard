-- 迁移脚本：拆分 app_metrics 表，创建 app_rating 表并迁移数据
-- 执行顺序：此脚本应在停机维护期间执行
-- 注意：此迁移是单向的，不包含回滚逻辑

-- 1. 首先创建新的 app_rating 表，所有字段设置为 NOT NULL
CREATE TABLE app_rating (
    id                          BIGSERIAL PRIMARY KEY,
    app_id                      TEXT NOT NULL REFERENCES app_info(app_id),
    average_rating              NUMERIC(3,1) NOT NULL,
    star_1_rating_count         INTEGER NOT NULL,
    star_2_rating_count         INTEGER NOT NULL,
    star_3_rating_count         INTEGER NOT NULL,
    star_4_rating_count         INTEGER NOT NULL,
    star_5_rating_count         INTEGER NOT NULL,
    my_star_rating              INTEGER NOT NULL,
    total_star_rating_count     INTEGER NOT NULL,
    only_star_count             INTEGER NOT NULL,
    full_average_rating         NUMERIC(3,1) NOT NULL,
    source_type                 TEXT NOT NULL,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. 从 app_metrics 迁移有效的评分数据到 app_rating 表
-- 判断标准：所有评分字段都不为 NULL 的数据才进行迁移
INSERT INTO app_rating (
    app_id,
    average_rating,
    star_1_rating_count,
    star_2_rating_count,
    star_3_rating_count,
    star_4_rating_count,
    star_5_rating_count,
    my_star_rating,
    total_star_rating_count,
    only_star_count,
    full_average_rating,
    source_type,
    created_at
)
SELECT 
    app_id,
    page_average_rating,
    page_star_1_rating_count,
    page_star_2_rating_count,
    page_star_3_rating_count,
    page_star_4_rating_count,
    page_star_5_rating_count,
    page_my_star_rating,
    page_total_star_rating_count,
    page_only_star_count,
    page_full_average_rating,
    page_source_type,
    created_at
FROM app_metrics
WHERE 
    page_average_rating IS NOT NULL AND
    page_star_1_rating_count IS NOT NULL AND
    page_star_2_rating_count IS NOT NULL AND
    page_star_3_rating_count IS NOT NULL AND
    page_star_4_rating_count IS NOT NULL AND
    page_star_5_rating_count IS NOT NULL AND
    page_my_star_rating IS NOT NULL AND
    page_total_star_rating_count IS NOT NULL AND
    page_only_star_count IS NOT NULL AND
    page_full_average_rating IS NOT NULL AND
    page_source_type IS NOT NULL;

-- 3. 首先删除依赖这些字段的视图
DROP VIEW IF EXISTS app_latest_info;

-- 4. 检查是否有其他对象依赖这些字段（安全措施）
DO $$
DECLARE
    dependent_objects TEXT;
BEGIN
    -- 检查是否有其他对象依赖这些字段
    SELECT string_agg(dependent_obj::TEXT, ', ') INTO dependent_objects
    FROM (
        SELECT DISTINCT 
            '函数: ' || p.proname AS dependent_obj
        FROM pg_depend d
        JOIN pg_class c ON d.refobjid = c.oid
        JOIN pg_attribute a ON (a.attrelid = c.oid AND a.attnum = d.refobjsubid)
        JOIN pg_proc p ON d.objid = p.oid
        WHERE c.relname = 'app_metrics'
        AND a.attname LIKE 'page_%'
        
        UNION ALL
        
        SELECT DISTINCT 
            '触发器: ' || tgname AS dependent_obj
        FROM pg_depend d
        JOIN pg_class c ON d.refobjid = c.oid
        JOIN pg_attribute a ON (a.attrelid = c.oid AND a.attnum = d.refobjsubid)
        JOIN pg_trigger t ON d.objid = t.oid
        WHERE c.relname = 'app_metrics'
        AND a.attname LIKE 'page_%'
        
        UNION ALL
        
        SELECT DISTINCT 
            '视图: ' || v.viewname AS dependent_obj
        FROM pg_depend d
        JOIN pg_class c ON d.refobjid = c.oid
        JOIN pg_attribute a ON (a.attrelid = c.oid AND a.attnum = d.refobjsubid)
        JOIN pg_views v ON d.objid = (SELECT oid FROM pg_class WHERE relname = v.viewname)
        WHERE c.relname = 'app_metrics'
        AND a.attname LIKE 'page_%'
        AND v.viewname != 'app_latest_info'
    ) deps;
    
    IF dependent_objects IS NOT NULL THEN
        RAISE EXCEPTION '发现依赖对象，无法删除字段。依赖对象: %', dependent_objects;
    END IF;
END $$;

-- 5. 从 app_metrics 表中删除评分相关字段
ALTER TABLE app_metrics
DROP COLUMN page_average_rating,
DROP COLUMN page_star_1_rating_count,
DROP COLUMN page_star_2_rating_count,
DROP COLUMN page_star_3_rating_count,
DROP COLUMN page_star_4_rating_count,
DROP COLUMN page_star_5_rating_count,
DROP COLUMN page_my_star_rating,
DROP COLUMN page_total_star_rating_count,
DROP COLUMN page_only_star_count,
DROP COLUMN page_full_average_rating,
DROP COLUMN page_source_type;

-- 6. 重新创建 app_latest_info 视图以反映表结构变化

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
    am.created_at as metrics_created_at,
    ar.created_at as rating_created_at
FROM app_info ai
LEFT JOIN (
    SELECT DISTINCT ON (app_id) *
    FROM app_metrics
    ORDER BY app_id, release_date DESC NULLS LAST
) am ON ai.app_id = am.app_id
LEFT JOIN (
    SELECT DISTINCT ON (app_id) *
    FROM app_rating
    ORDER BY app_id, created_at DESC NULLS LAST
) ar ON ai.app_id = ar.app_id;

-- 7. 为 app_rating 表创建索引
CREATE INDEX idx_app_rating_app_id ON app_rating(app_id);
CREATE INDEX idx_app_rating_created_at ON app_rating(created_at);

-- 8. 迁移完成提示
COMMENT ON TABLE app_rating IS '应用评分表，包含用户评分相关信息';
COMMENT ON TABLE app_metrics IS '应用指标表，包含版本、下载量等信息（已移除评分相关字段）';

-- 9. 输出迁移统计信息
DO $$
DECLARE
    total_metrics_records BIGINT;
    migrated_records BIGINT;
    skipped_records BIGINT;
BEGIN
    -- 获取统计信息
    SELECT COUNT(*) INTO total_metrics_records FROM app_metrics;
    SELECT COUNT(*) INTO migrated_records FROM app_rating;
    skipped_records := total_metrics_records - migrated_records;
    
    -- 输出统计信息
    RAISE NOTICE '迁移完成统计:';
    RAISE NOTICE '- app_metrics 表总记录数: %', total_metrics_records;
    RAISE NOTICE '- 迁移到 app_rating 表的记录数: %', migrated_records;
    RAISE NOTICE '- 跳过迁移的记录数（包含NULL数据）: %', skipped_records;
END $$;