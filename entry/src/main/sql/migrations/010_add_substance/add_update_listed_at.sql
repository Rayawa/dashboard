-- 1. 创建或替换一个函数，用于更新 app_info.listed_at
CREATE OR REPLACE FUNCTION update_app_listed_at_on_metric_insert()
RETURNS TRIGGER AS $$
DECLARE
    current_listed_at TIMESTAMPTZ;
    new_listed_at TIMESTAMPTZ;
BEGIN
    -- 获取当前 app_info.listed_at
    SELECT listed_at INTO current_listed_at
    FROM app_info
    WHERE app_id = NEW.app_id;

    -- 计算新的 listed_at
    -- 取 app_info 中已有的 listed_at 和 app_metrics 中最小的 release_date 的最小值
    SELECT LEAST(current_listed_at, MIN(TO_TIMESTAMP(am.release_date / 1000)))
    INTO new_listed_at
    FROM app_metrics am
    WHERE am.app_id = NEW.app_id;

    -- 如果计算出的新 listed_at 不同于当前的 listed_at，则进行更新
    IF new_listed_at IS NOT NULL AND current_listed_at IS DISTINCT FROM new_listed_at THEN
        UPDATE app_info
        SET listed_at = new_listed_at
        WHERE app_id = NEW.app_id;
    END IF;

    RETURN NEW; -- 触发器函数必须返回 NEW 或 OLD
END;
$$ LANGUAGE plpgsql;

-- 2. 创建一个触发器，在 app_metrics 插入后执行上述函数
CREATE OR REPLACE TRIGGER trg_update_app_listed_at
AFTER INSERT ON app_metrics
FOR EACH ROW
EXECUTE FUNCTION update_app_listed_at_on_metric_insert();
