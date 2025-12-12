-- ----------------------------------------------------------------------
-- 004b_create_listed_at_trigger_function.sql
-- 创建 listed_at 触发器函数
-- ----------------------------------------------------------------------
-- 执行时间：预计 1-2 分钟
-- 依赖：001_create_app_full_info_table.sql
-- 描述：创建触发器函数，在 app_metrics 表插入时更新 app_full_info.listed_at 字段
--       保证记录应用的历史最早上架时间
-- ----------------------------------------------------------------------

BEGIN;

-- 创建更新 app_full_info.listed_at 的触发器函数
-- 只在 INSERT 时触发，取当前 listed_at 与新记录 release_date 的最小值
CREATE OR REPLACE FUNCTION update_app_full_info_listed_at_on_metric_insert()
RETURNS TRIGGER AS $$
DECLARE
    current_listed_at TIMESTAMPTZ;
    new_release_date TIMESTAMPTZ;
BEGIN
    SELECT listed_at
    INTO current_listed_at
    FROM app_full_info
    WHERE app_id = NEW.app_id;

    new_release_date := TO_TIMESTAMP(NEW.release_date / 1000);

    IF current_listed_at IS NULL OR new_release_date < current_listed_at THEN
        UPDATE app_full_info
        SET listed_at = new_release_date,
            updated_at = now()
        WHERE app_id = NEW.app_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 验证触发器函数是否创建成功
SELECT 
    proname AS function_name,
    pronargs AS argument_count,
    prorettype::regtype AS return_type
FROM pg_proc 
WHERE proname = 'update_app_full_info_listed_at_on_metric_insert';

COMMIT;

-- 验证脚本执行结果
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'update_app_full_info_listed_at_on_metric_insert'
    ) THEN
        RAISE NOTICE '✓ Listed At 触发器函数 update_app_full_info_listed_at_on_metric_insert 创建成功';
    ELSE
        RAISE EXCEPTION '✗ Listed At 触发器函数创建失败';
    END IF;
END $$;