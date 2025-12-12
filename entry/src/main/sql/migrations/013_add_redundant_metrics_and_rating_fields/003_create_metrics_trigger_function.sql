-- ----------------------------------------------------------------------
-- 003_create_metrics_trigger_function.sql
-- 创建 metrics 触发器函数
-- ----------------------------------------------------------------------
-- 执行时间：预计 1-2 分钟
-- 依赖：001_create_app_full_info_table.sql
-- 描述：创建触发器函数，在 app_metrics 表插入、更新或删除时自动更新 app_full_info 表中的指标数据
-- 职责：更新 metrics 相关字段，并在 INSERT 时维护 listed_at 最早时间
-- 前提：app_full_info 记录必须已存在（由 app_info 触发器创建）
-- ----------------------------------------------------------------------

BEGIN;

-- 创建更新 app_full_info 表中 metrics 数据的触发器函数
-- 支持 INSERT、UPDATE、DELETE 三种操作
CREATE OR REPLACE FUNCTION update_app_full_info_from_metrics()
RETURNS TRIGGER AS $$
DECLARE
    target_app_id TEXT;
    latest_metric_id BIGINT;
    current_listed_at TIMESTAMPTZ;
    new_release_date TIMESTAMPTZ;
BEGIN
    -- 确定要处理的应用 ID
    IF TG_OP = 'DELETE' THEN
        target_app_id := OLD.app_id;
    ELSE
        target_app_id := NEW.app_id;
    END IF;
    
    -- 获取该应用最新的 metrics 记录（排除被删除的记录）
    SELECT id INTO latest_metric_id
    FROM app_metrics
    WHERE app_id = target_app_id
        AND (TG_OP != 'DELETE' OR id != OLD.id)  -- 排除刚删除的记录
    ORDER BY created_at DESC NULLS LAST
    LIMIT 1;
    
    IF latest_metric_id IS NOT NULL THEN
        -- 有最新记录，更新 metrics 字段
        UPDATE app_full_info
        SET
            version = am.version,
            version_code = am.version_code,
            size_bytes = am.size_bytes,
            sha256 = am.sha256,
            info_score = am.info_score,
            info_rate_count = am.info_rate_count,
            download_count = am.download_count,
            price = am.price,
            release_date = am.release_date,
            new_features = am.new_features,
            upgrade_msg = am.upgrade_msg,
            target_sdk = am.target_sdk,
            minsdk = am.minsdk,
            compile_sdk_version = am.compile_sdk_version,
            min_hmos_api_level = am.min_hmos_api_level,
            api_release_type = am.api_release_type,
            metrics_created_at = am.created_at,
            updated_at = now()
        FROM app_metrics am
        WHERE app_full_info.app_id = am.app_id
          AND am.id = latest_metric_id;
    ELSE
        -- 没有记录，清空 metrics 字段
        UPDATE app_full_info
        SET
            version = NULL,
            version_code = NULL,
            size_bytes = NULL,
            sha256 = NULL,
            info_score = NULL,
            info_rate_count = NULL,
            download_count = NULL,
            price = NULL,
            release_date = NULL,
            new_features = NULL,
            upgrade_msg = NULL,
            target_sdk = NULL,
            minsdk = NULL,
            compile_sdk_version = NULL,
            min_hmos_api_level = NULL,
            api_release_type = NULL,
            metrics_created_at = NULL,
            updated_at = now()
        WHERE app_id = target_app_id;
    END IF;
    
    -- 在 INSERT 时，更新 listed_at 为历史最早时间
    IF TG_OP = 'INSERT' THEN
        SELECT listed_at
        INTO current_listed_at
        FROM app_full_info
        WHERE app_id = NEW.app_id;

        new_release_date := TO_TIMESTAMP(NEW.release_date / 1000);

        IF current_listed_at IS NULL OR new_release_date < current_listed_at THEN
            UPDATE app_full_info
            SET listed_at = new_release_date,
                updated_at = now()
            WHERE app_id = NEW.app_id;
        END IF;
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
WHERE proname = 'update_app_full_info_from_metrics';

COMMIT;

-- 验证脚本执行结果
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'update_app_full_info_from_metrics'
    ) THEN
        RAISE NOTICE '✓ Metrics 触发器函数 update_app_full_info_from_metrics 创建成功';
    ELSE
        RAISE EXCEPTION '✗ Metrics 触发器函数创建失败';
    END IF;
END $$;