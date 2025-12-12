-- 迁移脚本：修改app_raw表结构以支持两个JSON字段
-- 执行顺序：先添加新字段，然后迁移数据，最后删除旧字段
-- 注意：此脚本应在001_rename_metrics_fields_and_add_page_ratings.sql之后执行

-- 1. 首先添加raw_json_data和raw_json_star字段
ALTER TABLE app_raw 
ADD COLUMN raw_json_data JSONB,
ADD COLUMN raw_json_star JSONB;

-- 2. 将现有的raw_json数据迁移到raw_json_data字段
-- 注意：这里假设现有的raw_json字段包含的是应用数据
UPDATE app_raw 
SET raw_json_data = COALESCE(raw_json, '{}'::JSONB),
    raw_json_star = '{}'::JSONB;

-- 3. 删除旧的raw_json字段
ALTER TABLE app_raw 
DROP COLUMN raw_json;

-- 4. 设置所有列为NOT NULL并添加默认值
ALTER TABLE app_raw 
ALTER COLUMN app_id SET NOT NULL,
ALTER COLUMN raw_json_data SET NOT NULL,
ALTER COLUMN raw_json_data SET DEFAULT '{}'::JSONB,
ALTER COLUMN raw_json_star SET NOT NULL,
ALTER COLUMN raw_json_star SET DEFAULT '{}'::JSONB,
ALTER COLUMN created_at SET NOT NULL;

-- 5. 处理可能存在的NULL值（确保数据完整性）
UPDATE app_raw 
SET app_id = COALESCE(app_id, 'unknown')
WHERE app_id IS NULL;

UPDATE app_raw 
SET created_at = COALESCE(created_at, now())
WHERE created_at IS NULL;

-- 6. 重新创建索引
DROP INDEX IF EXISTS idx_app_raw_app_id;
CREATE INDEX idx_app_raw_app_id ON app_raw(app_id);