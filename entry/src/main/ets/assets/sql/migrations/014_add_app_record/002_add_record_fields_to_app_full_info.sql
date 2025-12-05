-- ----------------------------------------------------------------------
-- 002_add_record_fields_to_app_full_info.sql
-- 添加 app_record 字段到 app_full_info 表
-- ----------------------------------------------------------------------
-- 执行时间：预计 1-2 分钟
-- 依赖：001_create_app_record_table.sql
-- 描述：在 app_full_info 表中添加 app_record 相关字段
-- ----------------------------------------------------------------------

BEGIN;

-- 添加 app_record 相关字段到 app_full_info 表
ALTER TABLE app_full_info
    ADD COLUMN IF NOT EXISTS title TEXT,
    ADD COLUMN IF NOT EXISTS app_recordal_info TEXT,
    ADD COLUMN IF NOT EXISTS recordal_entity_title TEXT,
    ADD COLUMN IF NOT EXISTS recordal_entity_name TEXT;

-- 添加字段注释
COMMENT ON COLUMN app_full_info.title IS '来自 app_record 表的标题，例如 "服务备案号"';
COMMENT ON COLUMN app_full_info.app_recordal_info IS '来自 app_record 表的备案号文本';
COMMENT ON COLUMN app_full_info.recordal_entity_title IS '来自 app_record 表的主办单位标题';
COMMENT ON COLUMN app_full_info.recordal_entity_name IS '来自 app_record 表的主办单位名称';

-- 验证字段是否添加成功
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'app_full_info' 
  AND column_name IN ('title', 'app_recordal_info', 'recordal_entity_title', 'recordal_entity_name')
ORDER BY column_name;

COMMIT;

-- -- 验证脚本执行结果
-- DO $$
-- DECLARE
--     missing_columns TEXT[];
--     col TEXT;
-- BEGIN
--     -- 检查所有必需字段是否存在
--     SELECT ARRAY_AGG(col)
--     INTO missing_columns
--     FROM unnest(ARRAY['title', 'app_recordal_info', 'recordal_entity_title', 'recordal_entity_name']) AS col
--     WHERE NOT EXISTS (
--         SELECT 1
--         FROM information_schema.columns
--         WHERE table_name = 'app_full_info'
--           AND column_name = col
--     );
--
--     IF missing_columns IS NULL OR array_length(missing_columns, 1) IS NULL THEN
--         RAISE NOTICE '✓ app_full_info 表的 app_record 字段添加成功';
--     ELSE
--         RAISE EXCEPTION '✗ 以下字段添加失败: %', array_to_string(missing_columns, ', ');
--     END IF;
-- END $$;