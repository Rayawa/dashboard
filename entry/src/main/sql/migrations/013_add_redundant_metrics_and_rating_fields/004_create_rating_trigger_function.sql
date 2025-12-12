-- ----------------------------------------------------------------------
-- 004_create_rating_trigger_function.sql
-- 创建 rating 触发器函数（更新 app_full_info 表）
-- ----------------------------------------------------------------------
-- 执行时间：预计 1-2 分钟
-- 依赖：001_create_app_full_info_table.sql
-- 描述：创建触发器函数，在 app_rating 表插入、更新或删除时自动更新 app_full_info 表中的评分数据
-- 职责：只更新 rating 相关字段，不触及 app_info 基本字段
-- 前提：app_full_info 记录必须已存在（由 app_info 触发器创建）
-- ----------------------------------------------------------------------

BEGIN;

-- 创建更新 app_full_info 表中 rating 字段的触发器函数
-- 支持 INSERT、UPDATE、DELETE 三种操作
CREATE OR REPLACE FUNCTION update_app_full_info_from_rating()
RETURNS TRIGGER AS $$
DECLARE
    target_app_id TEXT;
    latest_rating_id BIGINT;
BEGIN
    -- 确定要处理的应用 ID
    IF TG_OP = 'DELETE' THEN
        target_app_id := OLD.app_id;
    ELSE
        target_app_id := NEW.app_id;
    END IF;

    -- 获取该应用最新的 rating 记录（排除被删除的记录）
    SELECT id
    INTO latest_rating_id
    FROM app_rating
    WHERE app_id = target_app_id
      AND (TG_OP != 'DELETE' OR id != OLD.id)  -- 排除刚删除的记录
    ORDER BY created_at DESC NULLS LAST
    LIMIT 1;

    IF latest_rating_id IS NOT NULL THEN
        -- 有最新记录，更新 rating 字段
        UPDATE app_full_info
        SET
            average_rating = ar.average_rating,
            star_1_rating_count = ar.star_1_rating_count,
            star_2_rating_count = ar.star_2_rating_count,
            star_3_rating_count = ar.star_3_rating_count,
            star_4_rating_count = ar.star_4_rating_count,
            star_5_rating_count = ar.star_5_rating_count,
            my_star_rating = ar.my_star_rating,
            total_star_rating_count = ar.total_star_rating_count,
            only_star_count = ar.only_star_count,
            full_average_rating = ar.full_average_rating,
            source_type = ar.source_type,
            rating_created_at = ar.created_at,
            updated_at = now()
        FROM app_rating ar
        WHERE app_full_info.app_id = ar.app_id
          AND ar.id = latest_rating_id;
    ELSE
        -- 没有记录，清空 rating 字段
        UPDATE app_full_info
        SET
            average_rating = NULL,
            star_1_rating_count = NULL,
            star_2_rating_count = NULL,
            star_3_rating_count = NULL,
            star_4_rating_count = NULL,
            star_5_rating_count = NULL,
            my_star_rating = NULL,
            total_star_rating_count = NULL,
            only_star_count = NULL,
            full_average_rating = NULL,
            source_type = NULL,
            rating_created_at = NULL,
            updated_at = now()
        WHERE app_id = target_app_id;
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
WHERE proname = 'update_app_full_info_from_rating';

COMMIT;

-- 验证脚本执行结果
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc
        WHERE proname = 'update_app_full_info_from_rating'
    ) THEN
        RAISE NOTICE '✓ Rating 触发器函数 update_app_full_info_from_rating 创建成功';
    ELSE
        RAISE EXCEPTION '✗ Rating 触发器函数创建失败';
    END IF;
END $$;