-- ----------------------------------------------------------------------
-- 003_create_record_trigger_function.sql
-- 创建 record 触发器函数（更新 app_full_info 表）
-- ----------------------------------------------------------------------
-- 执行时间：预计 1-2 分钟
-- 依赖：002_add_record_fields_to_app_full_info.sql
-- 描述：创建触发器函数，在 app_record 表插入、更新或删除时自动更新 app_full_info 表中的备案数据
-- 职责：只更新 record 相关字段，不触及 app_info 基本字段
-- 前提：app_full_info 记录必须已存在（由 app_info 触发器创建）
-- ----------------------------------------------------------------------

BEGIN;

-- 创建更新 app_full_info 表中 record 字段的触发器函数
-- 支持 INSERT、UPDATE、DELETE 三种操作
CREATE OR REPLACE FUNCTION update_app_full_info_from_record()
RETURNS TRIGGER AS $$
DECLARE
    target_app_id TEXT;
    latest_record_id BIGINT;
BEGIN
    -- 确定要处理的应用 ID
    IF TG_OP = 'DELETE' THEN
        target_app_id := OLD.app_id;
    ELSE
        target_app_id := NEW.app_id;
    END IF;

    -- 获取该应用最新的 record 记录（排除被删除的记录）
    SELECT id
    INTO latest_record_id
    FROM app_record
    WHERE app_id = target_app_id
      AND (TG_OP != 'DELETE' OR id != OLD.id)  -- 排除刚删除的记录
    ORDER BY created_at DESC NULLS LAST
    LIMIT 1;

    IF latest_record_id IS NOT NULL THEN
        -- 有最新记录，更新 record 字段
        UPDATE app_full_info
        SET
            title = ar.title,
            app_recordal_info = ar.app_recordal_info,
            recordal_entity_title = ar.recordal_entity_title,
            recordal_entity_name = ar.recordal_entity_name,
            updated_at = now()
        FROM app_record ar
        WHERE app_full_info.app_id = ar.app_id
          AND ar.id = latest_record_id;
    ELSE
        -- 没有记录，清空 record 字段
        UPDATE app_full_info
        SET
            title = NULL,
            app_recordal_info = NULL,
            recordal_entity_title = NULL,
            recordal_entity_name = NULL,
            updated_at = now()
        WHERE app_id = target_app_id;
    END IF;

    -- 返回适当的记录
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 验证触发器函数是否创建成功
SELECT
    proname AS function_name,
    pronargs AS argument_count,
    prorettype::regtype AS return_type
FROM pg_proc
WHERE proname = 'update_app_full_info_from_record';

COMMIT;

-- 验证脚本执行结果
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc
        WHERE proname = 'update_app_full_info_from_record'
    ) THEN
        RAISE NOTICE '✓ Record 触发器函数 update_app_full_info_from_record 创建成功';
    ELSE
        RAISE EXCEPTION '✗ Record 触发器函数创建失败';
    END IF;
END $$;