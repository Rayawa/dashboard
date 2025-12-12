-- 迁移脚本：为数据库表设置 NOT NULL 约束
-- 执行顺序：005_set_not_null_constraints/001_set_not_null_constraints.sql

-- 1. 为 app_info 表设置 NOT NULL 约束
ALTER TABLE app_info 
ALTER COLUMN name SET NOT NULL,
ALTER COLUMN pkg_name SET NOT NULL,
ALTER COLUMN dev_id SET NOT NULL,
ALTER COLUMN developer_name SET NOT NULL,
ALTER COLUMN kind_id SET NOT NULL,
ALTER COLUMN kind_name SET NOT NULL,
ALTER COLUMN kind_type_id SET NOT NULL,
ALTER COLUMN kind_type_name SET NOT NULL,
ALTER COLUMN icon_url SET NOT NULL,
ALTER COLUMN brief_desc SET NOT NULL,
ALTER COLUMN description SET NOT NULL,
ALTER COLUMN privacy_url SET NOT NULL,
ALTER COLUMN ctype SET NOT NULL,
ALTER COLUMN detail_id SET NOT NULL,
ALTER COLUMN app_level SET NOT NULL,
ALTER COLUMN jocat_id SET NOT NULL,
ALTER COLUMN iap SET NOT NULL,
ALTER COLUMN hms SET NOT NULL,
ALTER COLUMN tariff_type SET NOT NULL,
ALTER COLUMN packing_type SET NOT NULL,
ALTER COLUMN order_app SET NOT NULL,
ALTER COLUMN denpend_gms SET NOT NULL,
ALTER COLUMN denpend_hms SET NOT NULL,
ALTER COLUMN force_update SET NOT NULL,
ALTER COLUMN img_tag SET NOT NULL,
ALTER COLUMN is_pay SET NOT NULL,
ALTER COLUMN is_disciplined SET NOT NULL,
ALTER COLUMN is_shelves SET NOT NULL,
ALTER COLUMN submit_type SET NOT NULL,
ALTER COLUMN delete_archive SET NOT NULL,
ALTER COLUMN charging SET NOT NULL,
ALTER COLUMN button_grey SET NOT NULL,
ALTER COLUMN app_gift SET NOT NULL,
ALTER COLUMN free_days SET NOT NULL,
ALTER COLUMN pay_install_type SET NOT NULL;

-- 2. 为 app_metrics 表设置 NOT NULL 约束
ALTER TABLE app_metrics 
ALTER COLUMN version SET NOT NULL,
ALTER COLUMN version_code SET NOT NULL,
ALTER COLUMN size_bytes SET NOT NULL,
ALTER COLUMN sha256 SET NOT NULL,
ALTER COLUMN info_score SET NOT NULL,
ALTER COLUMN info_rate_count SET NOT NULL,
ALTER COLUMN download_count SET NOT NULL,
ALTER COLUMN price SET NOT NULL,
ALTER COLUMN release_date SET NOT NULL,
ALTER COLUMN new_features SET NOT NULL,
ALTER COLUMN upgrade_msg SET NOT NULL,
ALTER COLUMN target_sdk SET NOT NULL,
ALTER COLUMN minsdk SET NOT NULL,
ALTER COLUMN compile_sdk_version SET NOT NULL,
ALTER COLUMN min_hmos_api_level SET NOT NULL,
ALTER COLUMN api_release_type SET NOT NULL;

-- 3. 为 app_rating 表设置 NOT NULL 约束
ALTER TABLE app_rating 
ALTER COLUMN average_rating SET NOT NULL,
ALTER COLUMN star_1_rating_count SET NOT NULL,
ALTER COLUMN star_2_rating_count SET NOT NULL,
ALTER COLUMN star_3_rating_count SET NOT NULL,
ALTER COLUMN star_4_rating_count SET NOT NULL,
ALTER COLUMN star_5_rating_count SET NOT NULL,
ALTER COLUMN my_star_rating SET NOT NULL,
ALTER COLUMN total_star_rating_count SET NOT NULL,
ALTER COLUMN only_star_count SET NOT NULL,
ALTER COLUMN full_average_rating SET NOT NULL,
ALTER COLUMN source_type SET NOT NULL;

-- 迁移完成提示
DO $$
BEGIN
    RAISE NOTICE '迁移完成：成功为数据库表设置 NOT NULL 约束';
    RAISE NOTICE '- app_info 表：为 32 个字段添加了 NOT NULL 约束';
    RAISE NOTICE '- app_metrics 表：为 16 个字段添加了 NOT NULL 约束';
    RAISE NOTICE '- app_rating 表：为 11 个字段添加了 NOT NULL 约束';
END $$;