-- ----------------------------------------------------------------------
-- 004_create_record_trigger.sql
-- 创建 app_record 触发器
-- ----------------------------------------------------------------------
-- 执行时间：预计 1 分钟
-- 依赖：003_create_record_trigger_function.sql
-- 描述：在 app_record 表上创建触发器，自动同步数据到 app_full_info 表
-- ----------------------------------------------------------------------

BEGIN;

-- 删除旧触发器（如果存在）
DROP TRIGGER IF EXISTS trigger_sync_record_to_app_full_info ON app_record;

-- 创建触发器：在 INSERT 或 UPDATE 后触发
CREATE TRIGGER trigger_sync_record_to_app_full_info
    AFTER INSERT OR UPDATE OR DELETE ON app_record
    FOR EACH ROW
    EXECUTE FUNCTION update_app_full_info_from_record();

-- 验证触发器是否创建成功
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trigger_sync_record_to_app_full_info';

COMMIT;

-- 验证脚本执行结果
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_sync_record_to_app_full_info'
          AND event_object_table = 'app_record'
    ) THEN
        RAISE NOTICE '✓ Record 触发器 trigger_sync_record_to_app_full_info 创建成功';
    ELSE
        RAISE EXCEPTION '✗ Record 触发器创建失败';
    END IF;
END $$;