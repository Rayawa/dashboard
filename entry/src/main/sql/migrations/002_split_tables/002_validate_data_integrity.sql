-- 数据完整性验证脚本
-- 执行顺序：在 001_create_app_rating_and_migrate_data.sql 之后执行
-- 目的：验证迁移后的数据完整性和约束有效性

-- 1. 检查 app_rating 表的 NOT NULL 约束
DO $$
DECLARE
    null_count INTEGER;
BEGIN
    -- 检查每个字段的 NULL 值
    SELECT COUNT(*) INTO null_count FROM app_rating WHERE app_id IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 app_id 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE average_rating IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 average_rating 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE star_1_rating_count IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 star_1_rating_count 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE star_2_rating_count IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 star_2_rating_count 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE star_3_rating_count IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 star_3_rating_count 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE star_4_rating_count IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 star_4_rating_count 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE star_5_rating_count IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 star_5_rating_count 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE my_star_rating IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 my_star_rating 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE total_star_rating_count IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 total_star_rating_count 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE only_star_count IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 only_star_count 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE full_average_rating IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 full_average_rating 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE source_type IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 source_type 为 NULL 的记录', null_count;
    END IF;

    SELECT COUNT(*) INTO null_count FROM app_rating WHERE created_at IS NULL;
    IF null_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条 created_at 为 NULL 的记录', null_count;
    END IF;

    RAISE NOTICE '✅ app_rating 表所有 NOT NULL 约束验证通过';
END $$;

-- 2. 检查外键约束
DO $$
DECLARE
    orphan_count INTEGER;
BEGIN
    -- 检查 app_rating 表中是否有 app_id 在 app_info 中不存在
    SELECT COUNT(*) INTO orphan_count 
    FROM app_rating ar 
    WHERE NOT EXISTS (SELECT 1 FROM app_info ai WHERE ai.app_id = ar.app_id);
    
    IF orphan_count > 0 THEN
        RAISE EXCEPTION 'app_rating 表存在 % 条孤儿记录（app_id 在 app_info 中不存在）', orphan_count;
    END IF;

    RAISE NOTICE '✅ 外键约束验证通过';
END $$;

-- 3. 检查数据一致性
DO $$
DECLARE
    total_rating_count INTEGER;
    sum_star_counts INTEGER;
    consistency_check BOOLEAN;
BEGIN
    -- 检查总评分数量是否等于各星级评分数量之和
    SELECT COUNT(*) INTO total_rating_count FROM app_rating;
    
    SELECT COUNT(*) INTO sum_star_counts FROM app_rating 
    WHERE total_star_rating_count = (
        star_1_rating_count + star_2_rating_count + star_3_rating_count + 
        star_4_rating_count + star_5_rating_count
    );
    
    consistency_check := (total_rating_count = sum_star_counts);
    
    IF NOT consistency_check THEN
        RAISE EXCEPTION '数据一致性检查失败：有 % 条记录的 total_star_rating_count 不等于各星级评分数量之和', 
                        (total_rating_count - sum_star_counts);
    END IF;

    RAISE NOTICE '✅ 数据一致性验证通过';
END $$;

-- 4. 检查索引创建情况
DO $$
DECLARE
    index_count INTEGER;
BEGIN
    -- 检查 app_rating 表索引
    SELECT COUNT(*) INTO index_count 
    FROM pg_indexes 
    WHERE tablename = 'app_rating' AND indexname = 'idx_app_rating_app_id';
    
    IF index_count = 0 THEN
        RAISE EXCEPTION 'app_rating 表缺少 idx_app_rating_app_id 索引';
    END IF;

    SELECT COUNT(*) INTO index_count 
    FROM pg_indexes 
    WHERE tablename = 'app_rating' AND indexname = 'idx_app_rating_created_at';
    
    IF index_count = 0 THEN
        RAISE EXCEPTION 'app_rating 表缺少 idx_app_rating_created_at 索引';
    END IF;

    RAISE NOTICE '✅ 索引验证通过';
END $$;

-- 5. 检查视图是否正常工作
DO $$
DECLARE
    view_count INTEGER;
BEGIN
    -- 检查 app_latest_info 视图是否存在且可查询
    SELECT COUNT(*) INTO view_count FROM app_latest_info LIMIT 1;
    
    IF view_count IS NULL THEN
        RAISE EXCEPTION 'app_latest_info 视图查询失败';
    END IF;

    RAISE NOTICE '✅ 视图验证通过';
END $$;

-- 6. 最终验证总结
DO $$
DECLARE
    rating_count BIGINT;
    metrics_count BIGINT;
    info_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO rating_count FROM app_rating;
    SELECT COUNT(*) INTO metrics_count FROM app_metrics;
    SELECT COUNT(*) INTO info_count FROM app_info;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ 数据完整性验证完成';
    RAISE NOTICE '========================================';
    RAISE NOTICE '表记录统计:';
    RAISE NOTICE '- app_info 表记录数: %', info_count;
    RAISE NOTICE '- app_metrics 表记录数: %', metrics_count;
    RAISE NOTICE '- app_rating 表记录数: %', rating_count;
    RAISE NOTICE '========================================';
    RAISE NOTICE '所有验证项目均已通过 ✅';
    RAISE NOTICE '迁移成功完成！';
    RAISE NOTICE '========================================';
END $$;