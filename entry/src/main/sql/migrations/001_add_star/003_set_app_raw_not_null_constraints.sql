-- 迁移脚本：为app_raw表设置NOT NULL约束和默认值
-- 执行顺序：此脚本应在002_modify_app_raw_table.sql之后执行
-- 注意：此脚本用于处理现有数据的NOT NULL约束和默认值设置

-- 1. 设置app_id列为NOT NULL并处理现有NULL值
UPDATE app_raw 
SET app_id = 'unknown'
WHERE app_id IS NULL;

ALTER TABLE app_raw 
ALTER COLUMN app_id SET NOT NULL;

-- 2. 设置raw_json_data列为NOT NULL并添加默认值
UPDATE app_raw 
SET raw_json_data = '{}'::JSONB
WHERE raw_json_data IS NULL;

ALTER TABLE app_raw 
ALTER COLUMN raw_json_data SET NOT NULL,
ALTER COLUMN raw_json_data SET DEFAULT '{}'::JSONB;

-- 3. 设置raw_json_star列为NOT NULL并添加默认值
UPDATE app_raw 
SET raw_json_star = '{}'::JSONB
WHERE raw_json_star IS NULL;

ALTER TABLE app_raw 
ALTER COLUMN raw_json_star SET NOT NULL,
ALTER COLUMN raw_json_star SET DEFAULT '{}'::JSONB;

-- 4. 设置created_at列为NOT NULL并处理现有NULL值
UPDATE app_raw 
SET created_at = now()
WHERE created_at IS NULL;

ALTER TABLE app_raw 
ALTER COLUMN created_at SET NOT NULL;

-- 5. 验证所有约束都已正确设置
-- 查询确认没有NULL值存在
SELECT 
    COUNT(*) FILTER (WHERE app_id IS NULL) as null_app_id,
    COUNT(*) FILTER (WHERE raw_json_data IS NULL) as null_raw_json_data,
    COUNT(*) FILTER (WHERE raw_json_star IS NULL) as null_raw_json_star,
    COUNT(*) FILTER (WHERE created_at IS NULL) as null_created_at
FROM app_raw;

-- 6. 重新创建索引以确保性能
DROP INDEX IF EXISTS idx_app_raw_app_id;
CREATE INDEX idx_app_raw_app_id ON app_raw(app_id);