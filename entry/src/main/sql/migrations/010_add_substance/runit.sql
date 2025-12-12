
CREATE TABLE substance_info (
    substance_id   TEXT PRIMARY KEY,
    title          TEXT NOT NULL,
    subtitle       TEXT,
    name           TEXT,
    comment        JSONB,                             -- 评论或注释数据（JSON格式）
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE substance_history (
    id                 BIGSERIAL PRIMARY KEY,
    substance_id       TEXT NOT NULL REFERENCES substance_info(substance_id) ON DELETE CASCADE,
    raw_json_substance JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE substance_app_map (
    substance_id   TEXT NOT NULL REFERENCES substance_info(substance_id) ON DELETE CASCADE,
    app_id         TEXT NOT NULL REFERENCES app_info(app_id) ON DELETE CASCADE,
    PRIMARY KEY (substance_id, app_id)
);

-- 1) substance_info
-- 快速按主键已自然支持；补充常用查询字段索引
CREATE INDEX idx_substance_info_name ON substance_info (name);
CREATE INDEX idx_substance_info_title ON substance_info (title);
CREATE INDEX idx_substance_info_created_at ON substance_info (created_at);

-- 2) substance_history
-- 常按 substance_id 查历史记录（FK 上通常需要并发查询优化）
CREATE INDEX idx_substance_history_substance_id ON substance_history (substance_id);
-- 按时间范围查询历史记录
CREATE INDEX idx_substance_history_created_at ON substance_history (created_at);
-- 如果需要基于 JSONB 内容查询（例如 raw_json_substance ->> 'field'），建立 GIN 索引
CREATE INDEX idx_substance_history_raw_json_gin ON substance_history USING GIN (raw_json_substance);

-- 3) substance_app_map
-- 主键 (substance_id, app_id) 已存在，补充按 app_id 反向查找的索引
CREATE INDEX idx_substance_app_map_app_id ON substance_app_map (app_id);
-- 如需按 app_id 按时间或其它维度排序/筛选，可考虑复合索引（示例：按 app_id 再按 substance_id）
CREATE INDEX idx_substance_app_map_appid_substanceid ON substance_app_map (app_id, substance_id);
