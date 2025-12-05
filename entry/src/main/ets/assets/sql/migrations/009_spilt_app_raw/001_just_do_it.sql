-- 1. 创建新的 app_data_history 表 (移除原始的 UNIQUE 约束，避免索引过大问题)
CREATE TABLE app_data_history (
    id              BIGSERIAL PRIMARY KEY,
    app_id          TEXT NOT NULL REFERENCES app_info(app_id),
    pkg_name        TEXT NOT NULL REFERENCES app_info(pkg_name) ON DELETE CASCADE,
    raw_json_data   JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
    -- 不再添加 UNIQUE (app_id, pkg_name, raw_json_data, created_at)
);

-- 2. 创建新的 app_rating_history 表 (注意：star 已改名为 rating，移除原始的 UNIQUE 约束)
CREATE TABLE app_rating_history (
    id              BIGSERIAL PRIMARY KEY,
    app_id          TEXT NOT NULL REFERENCES app_info(app_id),
    pkg_name        TEXT NOT NULL REFERENCES app_info(pkg_name) ON DELETE CASCADE,
    raw_json_rating JSONB NOT NULL DEFAULT '{}'::JSONB, -- star 改名为 rating
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
    -- 不再添加 UNIQUE (app_id, pkg_name, raw_json_rating, created_at)
);

-- 3. 将 app_raw 表的数据迁移到 app_data_history，并在迁移前进行去重
INSERT INTO app_data_history (app_id, pkg_name, raw_json_data, created_at)
SELECT
    app_id,
    pkg_name,
    raw_json_data,
    created_at
FROM (
    SELECT
        app_id,
        pkg_name,
        raw_json_data,
        created_at,
        ROW_NUMBER() OVER (PARTITION BY app_id, pkg_name, raw_json_data ORDER BY created_at DESC) as rn
    FROM app_raw
) AS de_duped_app_data
WHERE rn = 1; -- 只选择每个 (app_id, pkg_name, raw_json_data) 组合的最新记录

-- 4. 将 app_raw 表的数据迁移到 app_rating_history，并在迁移前进行去重
INSERT INTO app_rating_history (app_id, pkg_name, raw_json_rating, created_at)
SELECT
    app_id,
    pkg_name,
    raw_json_star, -- 这里依然从 app_raw 的 raw_json_star 列读取
    created_at
FROM (
    SELECT
        app_id,
        pkg_name,
        raw_json_star,
        created_at,
        ROW_NUMBER() OVER (PARTITION BY app_id, pkg_name, raw_json_star ORDER BY created_at DESC) as rn
    FROM app_raw
) AS de_duped_app_rating
WHERE rn = 1; -- 只选择每个 (app_id, pkg_name, raw_json_star) 组合的最新记录

-- 5. 确认数据迁移和去重无误后，删除旧的 app_raw 表
-- 在生产环境中执行此步骤前，请务必备份数据并仔细检查新表数据
DROP TABLE app_raw;

-- 6. (可选) 添加索引以提高查询性能
-- 注意：这些索引不再包含整个 JSONB 列，只包含常用的查询列
CREATE INDEX idx_app_data_history_app_pkg ON app_data_history (app_id, pkg_name);
CREATE INDEX idx_app_data_history_created_at ON app_data_history (created_at);
-- 如果你经常需要基于 raw_json_data 的某个特定字段进行查询，可以考虑创建 Gin 索引：
-- CREATE INDEX idx_app_data_history_jsonb_data_gin ON app_data_history USING GIN (raw_json_data);


CREATE INDEX idx_app_rating_history_app_pkg ON app_rating_history (app_id, pkg_name);
CREATE INDEX idx_app_rating_history_created_at ON app_rating_history (created_at);
-- 同理，如果需要基于 raw_json_rating 的字段查询，考虑 Gin 索引：
-- CREATE INDEX idx_app_rating_history_jsonb_rating_gin ON app_rating_history USING GIN (raw_json_rating);