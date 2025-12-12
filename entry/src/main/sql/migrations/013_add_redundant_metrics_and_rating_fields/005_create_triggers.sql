-- ----------------------------------------------------------------------
-- 005_create_triggers.sql
-- 创建触发器：将三张表的变更绑定到新的 app_full_info 同步函数
-- ----------------------------------------------------------------------
-- 执行时间：预计 1-2 分钟
-- 依赖：
--   - 001_create_app_full_info_table.sql
--   - 002_create_app_info_trigger_function.sql
--   - 003_create_metrics_trigger_function.sql
--   - 004_create_rating_trigger_function.sql
-- 描述：
--   为 app_info、app_metrics、app_rating 表创建触发器，分别绑定到：
--     - update_app_full_info_from_app_info() (app_info 基本信息同步)
--     - update_app_full_info_from_metrics() (metrics 字段同步 + listed_at 最早时间维护)
--     - update_app_full_info_from_rating() (rating 字段同步)
--   确保在相关表发生插入/更新（以及删除，针对 metrics/rating）时，app_full_info 能被自动同步最新数据。
-- ----------------------------------------------------------------------

BEGIN;

-- 先删除可能存在的旧触发器（兼容历史命名）
DROP TRIGGER IF EXISTS trg_update_app_info_metrics ON app_metrics;
DROP TRIGGER IF EXISTS trg_update_app_info_rating ON app_rating;

-- 删除当前将要创建的触发器（若已存在则重建）
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_app_info ON app_info;
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_metrics ON app_metrics;
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_rating ON app_rating;

-- 1) app_info -> app_full_info（基本信息同步）
-- 在 INSERT 或 UPDATE 后触发
CREATE TRIGGER trg_update_app_full_info_from_app_info
AFTER INSERT OR UPDATE ON app_info
FOR EACH ROW
EXECUTE FUNCTION update_app_full_info_from_app_info();

-- 2) app_metrics -> app_full_info（最新指标数据同步 + listed_at 维护）
-- 在 INSERT、UPDATE 或 DELETE 后触发
-- 注意：此触发器已整合了 listed_at 更新逻辑，因此不需要单独的 listed_at 触发器
DROP TRIGGER IF EXISTS trg_update_app_full_info_listed_at ON app_metrics;  -- 删除旧的独立 listed_at 触发器
CREATE TRIGGER trg_update_app_full_info_from_metrics
AFTER INSERT OR UPDATE OR DELETE ON app_metrics
FOR EACH ROW
EXECUTE FUNCTION update_app_full_info_from_metrics();

-- 3) app_rating -> app_full_info（最新评分数据同步）
-- 在 INSERT、UPDATE 或 DELETE 后触发
CREATE TRIGGER trg_update_app_full_info_from_rating
AFTER INSERT OR UPDATE OR DELETE ON app_rating
FOR EACH ROW
EXECUTE FUNCTION update_app_full_info_from_rating();

-- 列出刚创建的触发器信息用于人工确认
SELECT 
    tgname AS trigger_name,
    tgrelid::regclass AS table_name,
    tgfoid::regproc AS function_name,
    tgenabled AS is_enabled
FROM pg_trigger 
WHERE tgname IN (
    'trg_update_app_full_info_from_app_info',
    'trg_update_app_full_info_from_metrics',
    'trg_update_app_full_info_from_rating'
)
AND NOT tgisinternal
ORDER BY tgname;

COMMIT;

-- 验证脚本执行结果：逐一检查触发器是否存在
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_update_app_full_info_from_app_info'
          AND NOT tgisinternal
    ) THEN
        RAISE NOTICE '✓ 触发器 trg_update_app_full_info_from_app_info 创建成功（表：app_info）';
    ELSE
        RAISE EXCEPTION '✗ 触发器 trg_update_app_full_info_from_app_info 创建失败';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_update_app_full_info_from_metrics'
          AND NOT tgisinternal
    ) THEN
        RAISE NOTICE '✓ 触发器 trg_update_app_full_info_from_metrics 创建成功（表：app_metrics）';
    ELSE
        RAISE EXCEPTION '✗ 触发器 trg_update_app_full_info_from_metrics 创建失败';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_update_app_full_info_from_rating'
          AND NOT tgisinternal
    ) THEN
        RAISE NOTICE '✓ 触发器 trg_update_app_full_info_from_rating 创建成功（表：app_rating）';
    ELSE
        RAISE EXCEPTION '✗ 触发器 trg_update_app_full_info_from_rating 创建失败';
    END IF;

    RAISE NOTICE '✓ 所有触发器创建完成。app_full_info 将在相关表写入时自动同步最新数据';
    RAISE NOTICE '  （listed_at 更新逻辑已整合到 trg_update_app_full_info_from_metrics 触发器中）';
END $$;