-- 迁移开始

-- 1. 在 app_info 表中为 pkg_name 列添加唯一约束
--    在添加外键之前，被引用的列（pkg_name）必须是唯一的。
--    如果 pkg_name 已经有唯一索引或主键，可以跳过此步骤。
ALTER TABLE app_info
ADD CONSTRAINT uq_app_info_pkg_name UNIQUE (pkg_name);

-- 2. 修改 app_raw 表
--    添加 pkg_name 列，暂时允许 NULL，方便数据填充
ALTER TABLE app_raw
ADD COLUMN pkg_name TEXT;

-- 3. 修改 app_metrics 表
--    添加 pkg_name 列，暂时允许 NULL，方便数据填充
ALTER TABLE app_metrics
ADD COLUMN pkg_name TEXT;

-- 4. 修改 app_rating 表
--    添加 pkg_name 列，暂时允许 NULL，方便数据填充
ALTER TABLE app_rating
ADD COLUMN pkg_name TEXT;

-- 5. 填充 app_raw 表中的 pkg_name
UPDATE app_raw ar
SET pkg_name = (SELECT ai.pkg_name FROM app_info ai WHERE ai.app_id = ar.app_id)
WHERE ar.app_id IS NOT NULL;

-- 6. 填充 app_metrics 表中的 pkg_name
UPDATE app_metrics am
SET pkg_name = (SELECT ai.pkg_name FROM app_info ai WHERE ai.app_id = am.app_id)
WHERE am.app_id IS NOT NULL;

-- 7. 填充 app_rating 表中的 pkg_name
UPDATE app_rating arat
SET pkg_name = (SELECT ai.pkg_name FROM app_info ai WHERE ai.app_id = arat.app_id)
WHERE arat.app_id IS NOT NULL;

-- 8. 将 pkg_name 列设置为 NOT NULL，并添加外键约束
--    请确保在执行此步骤之前，所有 app_id 对应的 pkg_name 都已正确填充。
--    如果存在 app_raw 记录的 app_id 在 app_info 中不存在，
--    或者 app_info 中 app_id 对应的 pkg_name 为 NULL，此步骤会失败。
ALTER TABLE app_raw
ALTER COLUMN pkg_name SET NOT NULL;

ALTER TABLE app_raw
ADD CONSTRAINT fk_app_raw_pkg_name
FOREIGN KEY (pkg_name) REFERENCES app_info (pkg_name) ON DELETE CASCADE; -- 根据业务需求选择 ON DELETE 策略

ALTER TABLE app_metrics
ALTER COLUMN pkg_name SET NOT NULL;

ALTER TABLE app_metrics
ADD CONSTRAINT fk_app_metrics_pkg_name
FOREIGN KEY (pkg_name) REFERENCES app_info (pkg_name) ON DELETE CASCADE; -- 根据业务需求选择 ON DELETE 策略

ALTER TABLE app_rating
ALTER COLUMN pkg_name SET NOT NULL;

ALTER TABLE app_rating
ADD CONSTRAINT fk_app_rating_pkg_name
FOREIGN KEY (pkg_name) REFERENCES app_info (pkg_name) ON DELETE CASCADE; -- 根据业务需求选择 ON DELETE 策略

CREATE INDEX idx_app_raw_pkg_name ON app_raw (pkg_name);
CREATE INDEX idx_app_metrics_pkg_name ON app_metrics (pkg_name);
CREATE INDEX idx_app_rating_pkg_name ON app_rating (pkg_name);

-- 迁移结束
