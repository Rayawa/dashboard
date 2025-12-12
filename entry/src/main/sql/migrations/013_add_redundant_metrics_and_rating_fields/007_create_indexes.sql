-- ----------------------------------------------------------------------
-- 007_create_indexes.sql
-- 针对 app_full_info 创建索引
-- ----------------------------------------------------------------------
-- 执行时间：预计 3-8 分钟（取决于数据量）
-- 依赖：06_initialize_app_full_info_data.sql
-- 描述：为 app_full_info 表创建必要的索引，优化下载排行、评分排行及常用查询性能
-- ----------------------------------------------------------------------

BEGIN;

-- 1) 下载量降序索引（用于 get_top_downloads 等下载排行查询）
CREATE INDEX IF NOT EXISTS idx_app_full_info_download_count_desc
ON app_full_info (download_count DESC NULLS LAST)
WHERE download_count IS NOT NULL;

-- 2) 平均评分降序索引（用于评分排行、评分筛选）
CREATE INDEX IF NOT EXISTS idx_app_full_info_average_rating_desc
ON app_full_info (average_rating DESC NULLS LAST)
WHERE average_rating IS NOT NULL;

-- 3) 复合排序索引：下载量 + 评分（综合排序/筛选）
CREATE INDEX IF NOT EXISTS idx_app_full_info_download_rating_composite
ON app_full_info (download_count DESC NULLS LAST, average_rating DESC NULLS LAST)
WHERE download_count IS NOT NULL AND average_rating IS NOT NULL;

-- 4) 发布时间索引（用于最近更新等维度）
CREATE INDEX IF NOT EXISTS idx_app_full_info_release_date
ON app_full_info (release_date DESC)
WHERE release_date IS NOT NULL;

-- 5) 开发者维度综合索引：开发者 + 下载量 + 评分（用于开发者下的热门/高分应用）
CREATE INDEX IF NOT EXISTS idx_app_full_info_dev_download_rating
ON app_full_info (dev_id, download_count DESC NULLS LAST, average_rating DESC NULLS LAST)
WHERE download_count IS NOT NULL AND average_rating IS NOT NULL;

-- 6) 分类维度下载索引：分类 + 下载量（用于分类热门榜）
CREATE INDEX IF NOT EXISTS idx_app_full_info_kind_download
ON app_full_info (kind_id, download_count DESC NULLS LAST)
WHERE download_count IS NOT NULL;

-- 7) 信息评分降序索引（辅助评分维度/筛选）
CREATE INDEX IF NOT EXISTS idx_app_full_info_info_score_desc
ON app_full_info (info_score DESC NULLS LAST)
WHERE info_score IS NOT NULL;

-- 8) 总评分数量降序索引（用于评分活跃度排序）
CREATE INDEX IF NOT EXISTS idx_app_full_info_total_star_rating_count_desc
ON app_full_info (total_star_rating_count DESC NULLS LAST)
WHERE total_star_rating_count IS NOT NULL;

-- 9) 版本/版本码索引（用于版本聚合/筛选、详情）
CREATE INDEX IF NOT EXISTS idx_app_full_info_version
ON app_full_info (version)
WHERE version IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_app_full_info_version_code
ON app_full_info (version_code)
WHERE version_code IS NOT NULL;

-- 列出已创建的索引（供人工确认）
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'app_full_info'
  AND indexname LIKE 'idx_app_full_info_%'
ORDER BY indexname;

COMMIT;

-- 结果校验与提示
DO $$
DECLARE
    index_count INTEGER;
    expected_count INTEGER := 9;  -- 预期创建的索引数量（按本脚本计划）
BEGIN
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE tablename = 'app_full_info'
      AND indexname LIKE 'idx_app_full_info_%';

    RAISE NOTICE 'app_full_info 已创建或存在 % 个业务索引（前缀：idx_app_full_info_）', index_count;

    IF index_count < expected_count THEN
        RAISE WARNING '业务索引数量少于预期（已创建：%，预期：%），请检查迁移日志与表结构', index_count, expected_count;
    END IF;

    RAISE NOTICE '重点索引包括：';
    RAISE NOTICE '  - idx_app_full_info_download_count_desc：优化下载排名';
    RAISE NOTICE '  - idx_app_full_info_average_rating_desc：优化评分排名';
    RAISE NOTICE '  - idx_app_full_info_download_rating_composite：优化综合排序';

    RAISE NOTICE '建议执行 ANALYZE app_full_info 以更新统计信息';
END $$;

-- 性能测试建议（仅输出提示）
DO $$
BEGIN
    RAISE NOTICE '示例性能测试：';
    RAISE NOTICE 'EXPLAIN ANALYZE';
    RAISE NOTICE 'SELECT app_id, name, download_count, average_rating';
    RAISE NOTICE 'FROM app_full_info';
    RAISE NOTICE 'WHERE download_count IS NOT NULL';
    RAISE NOTICE 'ORDER BY download_count DESC';
    RAISE NOTICE 'LIMIT 10;';
END $$;
