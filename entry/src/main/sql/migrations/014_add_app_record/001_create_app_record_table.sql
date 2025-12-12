-- ----------------------------------------------------------------------
-- 001_create_app_record_table.sql
-- 创建 app_record 表
-- ----------------------------------------------------------------------
-- 执行时间：预计 1-2 分钟
-- 依赖：无
-- 描述：创建 app_record 表，存储应用的备案信息
-- ----------------------------------------------------------------------

BEGIN;

-- 创建 app_record 表
CREATE TABLE IF NOT EXISTS app_record (
    id                      BIGSERIAL PRIMARY KEY,                      -- 主键ID
    app_id                  TEXT NOT NULL UNIQUE REFERENCES app_info(app_id) ON DELETE CASCADE, -- 对应 app_info 的 app_id
    title                   TEXT NOT NULL,                               -- 标题，例如 "服务备案号"
    app_recordal_info       TEXT NOT NULL,                               -- 备案号文本
    recordal_entity_title   TEXT NOT NULL,                               -- 主办单位标题
    recordal_entity_name    TEXT NOT NULL,                               -- 主办单位名称
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()          -- 创建时间
);

-- 添加表注释
COMMENT ON TABLE app_record IS '应用备案信息表 - 存储应用的备案相关信息';

-- 添加字段注释
COMMENT ON COLUMN app_record.id IS '主键ID';
COMMENT ON COLUMN app_record.app_id IS '应用唯一ID，对应 app_info 表';
COMMENT ON COLUMN app_record.title IS '标题，例如 "服务备案号"';
COMMENT ON COLUMN app_record.app_recordal_info IS '备案号文本';
COMMENT ON COLUMN app_record.recordal_entity_title IS '主办单位标题';
COMMENT ON COLUMN app_record.recordal_entity_name IS '主办单位名称';
COMMENT ON COLUMN app_record.created_at IS '数据创建时间';

-- 验证表是否创建成功
SELECT
    table_name,
    table_type
FROM information_schema.tables
WHERE table_name = 'app_record';

COMMIT;

-- 验证脚本执行结果
DO $$
BEGIN
    -- 检查表是否存在
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'app_record'
    ) THEN
        RAISE NOTICE '✓ app_record 表创建成功';
    ELSE
        RAISE EXCEPTION '✗ app_record 表创建失败';
    END IF;
END $$;
