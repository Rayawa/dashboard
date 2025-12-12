-- ----------------------------------------------------------------------
-- 009_merge_listed_at_trigger.sql
-- 合并 listed_at 触发器到 metrics 触发器
-- ----------------------------------------------------------------------
-- 执行时间：预计 1 分钟
-- 依赖：
--   - 003_create_metrics_trigger_function.sql (已更新)
--   - 004b_create_listed_at_trigger_function.sql (将被弃用)
--   - 005_create_triggers.sql (已更新)
-- 描述：
--   将 update_app_full_info_listed_at_on_metric_insert 函数的逻辑合并到
--   update_app_full_info_from_metrics 函数中，避免在同一表上有多个 AFTER INSERT 触发器。
--   这样可以：
--     1. 减少触发器执行次数（从 2 次减少到 1 次）
--     2. 避免 updated_at 被多次更新
--     3. 提高写入性能
-- 变更：
--   - 删除独立的 trg_update_app_full_info_listed_at 触发器
--   - 删除 update_app_full_info_listed_at_on_metric_insert 函数
--   - update_app_full_info_from_metrics 函数已包含 listed_at 更新逻辑
-- ----------------------------------------------------------------------

BEGIN;

-- 1. 删除旧的独立 listed_at 触发器
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_update_app_full_info_listed_at'
          AND NOT tgisinternal
    ) THEN
        DROP TRIGGER trg_update_app_full_info_listed_at ON app_metrics;
        RAISE NOTICE '✓ 已删除旧的 trg_update_app_full_info_listed_at 触发器';
    ELSE
        RAISE NOTICE '  trg_update_app_full_info_listed_at 触发器不存在，跳过删除';
    END IF;
END $$;

-- 2. 删除旧的独立 listed_at 触发器函数
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'update_app_full_info_listed_at_on_metric_insert'
    ) THEN
        DROP FUNCTION update_app_full_info_listed_at_on_metric_insert();
        RAISE NOTICE '✓ 已删除旧的 update_app_full_info_listed_at_on_metric_insert 函数';
    ELSE
        RAISE NOTICE '  update_app_full_info_listed_at_on_metric_insert 函数不存在，跳过删除';
    END IF;
END $$;

-- 3. 验证合并后的 metrics 触发器函数包含 listed_at 逻辑
-- 通过检查函数源码中是否包含 'listed_at' 关键字
DO $$
DECLARE
    func_source TEXT;
BEGIN
    SELECT prosrc INTO func_source
    FROM pg_proc 
    WHERE proname = 'update_app_full_info_from_metrics';
    
    IF func_source IS NULL THEN
        RAISE EXCEPTION '✗ update_app_full_info_from_metrics 函数不存在';
    END IF;
    
    IF func_source LIKE '%listed_at%' THEN
        RAISE NOTICE '✓ update_app_full_info_from_metrics 函数已包含 listed_at 更新逻辑';
    ELSE
        RAISE EXCEPTION '✗ update_app_full_info_from_metrics 函数缺少 listed_at 更新逻辑，请先执行更新后的 003_create_metrics_trigger_function.sql';
    END IF;
END $$;

-- 4. 验证只有一个 metrics 触发器在运行
SELECT 
    tgname AS trigger_name,
    tgrelid::regclass AS table_name,
    tgfoid::regproc AS function_name,
    CASE 
        WHEN tgtype & 2 = 2 THEN 'BEFORE'
        WHEN tgtype & 2 = 0 THEN 'AFTER'
    END AS timing,
    CASE 
        WHEN tgtype & 4 = 4 THEN 'INSERT'
        WHEN tgtype & 8 = 8 THEN 'DELETE'
        WHEN tgtype & 16 = 16 THEN 'UPDATE'
    END AS event
FROM pg_trigger 
WHERE tgrelid = 'app_metrics'::regclass
  AND NOT tgisinternal
ORDER BY tgname;

COMMIT;

-- 最终验证
DO $$
DECLARE
    metrics_trigger_count INT;
BEGIN
    SELECT COUNT(*) INTO metrics_trigger_count
    FROM pg_trigger 
    WHERE tgrelid = 'app_metrics'::regclass
      AND NOT tgisinternal
      AND tgname LIKE '%full_info%';
    
    IF metrics_trigger_count = 1 THEN
        RAISE NOTICE '✓ 迁移成功完成！';
        RAISE NOTICE '  app_metrics 表现在只有 1 个 app_full_info 相关触发器';
        RAISE NOTICE '  该触发器同时处理 metrics 字段同步和 listed_at 最早时间维护';
    ELSIF metrics_trigger_count > 1 THEN
        RAISE WARNING '⚠ app_metrics 表上仍有 % 个 app_full_info 相关触发器，可能需要手动清理', metrics_trigger_count;
    ELSE
        RAISE EXCEPTION '✗ app_metrics 表上没有 app_full_info 相关触发器，迁移失败';
    END IF;
END $$;