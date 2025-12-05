-- 更新外键约束以支持级联删除
-- 当 app_info 表中的记录被删除时，相关的历史记录和指标数据也会被自动删除

-- 1. 更新 app_data_history 表的外键约束
ALTER TABLE app_data_history
DROP CONSTRAINT app_data_history_app_id_fkey,
ADD CONSTRAINT app_data_history_app_id_fkey
FOREIGN KEY (app_id) REFERENCES app_info(app_id) ON DELETE CASCADE;

-- 2. 更新 app_rating_history 表的外键约束
ALTER TABLE app_rating_history
DROP CONSTRAINT app_rating_history_app_id_fkey,
ADD CONSTRAINT app_rating_history_app_id_fkey
FOREIGN KEY (app_id) REFERENCES app_info(app_id) ON DELETE CASCADE;

-- 3. 更新 app_metrics 表的外键约束
ALTER TABLE app_metrics
DROP CONSTRAINT app_metrics_app_id_fkey,
ADD CONSTRAINT app_metrics_app_id_fkey
FOREIGN KEY (app_id) REFERENCES app_info(app_id) ON DELETE CASCADE;

-- 4. 更新 app_rating 表的外键约束
ALTER TABLE app_rating
DROP CONSTRAINT app_rating_app_id_fkey,
ADD CONSTRAINT app_rating_app_id_fkey
FOREIGN KEY (app_id) REFERENCES app_info(app_id) ON DELETE CASCADE;