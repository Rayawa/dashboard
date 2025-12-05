-- 视图修复脚本：修正 app_latest_info 视图中的字段顺序问题
-- 执行此脚本修复视图字段映射错误

-- 1. 首先删除现有视图
DROP VIEW IF EXISTS app_latest_info;

-- 2. 重新创建视图，确保字段顺序正确
CREATE OR REPLACE VIEW app_latest_info AS
SELECT
    ai.app_id,
    ai.alliance_app_id,
    ai.name,
    ai.pkg_name,
    ai.dev_id,
    ai.developer_name,
    ai.dev_en_name,
    ai.supplier,
    ai.kind_id,
    ai.kind_name,
    ai.tag_name,
    ai.kind_type_id,
    ai.kind_type_name,
    ai.icon_url,
    ai.brief_desc,
    ai.description,
    ai.privacy_url,
    ai.ctype,
    ai.detail_id,
    ai.app_level,
    ai.jocat_id,
    ai.iap,
    ai.hms,
    ai.tariff_type,
    ai.packing_type,
    ai.order_app,
    ai.denpend_gms,
    ai.denpend_hms,
    ai.force_update,
    ai.img_tag,
    ai.is_pay,
    ai.is_disciplined,
    ai.is_shelves,
    ai.submit_type,
    ai.delete_archive,
    ai.charging,
    ai.button_grey,
    ai.app_gift,
    ai.free_days,
    ai.pay_install_type,
    am.version,
    am.version_code,
    am.size_bytes,
    am.sha256,
    am.info_score,
    am.info_rate_count,
    am.download_count,
    am.price,
    am.release_date,
    am.new_features,
    am.upgrade_msg,
    am.target_sdk,
    am.minsdk,
    am.compile_sdk_version,
    am.min_hmos_api_level,
    am.api_release_type,
    am.page_average_rating,
    am.page_star_1_rating_count,
    am.page_star_2_rating_count,
    am.page_star_3_rating_count,
    am.page_star_4_rating_count,
    am.page_star_5_rating_count,
    am.page_my_star_rating,
    am.page_total_star_rating_count,
    am.page_only_star_count,
    am.page_full_average_rating,
    am.page_source_type,
    am.created_at AS metrics_created_at
FROM app_info ai
LEFT JOIN (
    SELECT DISTINCT ON (app_id) 
        id,
        app_id,
        version,
        version_code,
        size_bytes,
        sha256,
        info_score,
        info_rate_count,
        download_count,
        price,
        release_date,
        new_features,
        upgrade_msg,
        target_sdk,
        minsdk,
        compile_sdk_version,
        min_hmos_api_level,
        api_release_type,
        page_average_rating,
        page_star_1_rating_count,
        page_star_2_rating_count,
        page_star_3_rating_count,
        page_star_4_rating_count,
        page_star_5_rating_count,
        page_my_star_rating,
        page_total_star_rating_count,
        page_only_star_count,
        page_full_average_rating,
        page_source_type,
        created_at
    FROM app_metrics
    ORDER BY app_id, release_date DESC NULLS LAST
) am ON ai.app_id = am.app_id;

-- 3. 设置视图所有者
ALTER VIEW app_latest_info OWNER TO srdown;

-- 4. 验证修复结果
COMMENT ON VIEW app_latest_info IS '修复后的应用最新信息视图，字段顺序已正确对齐';

-- 5. 验证脚本
DO $$
BEGIN
    -- 检查视图是否存在
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'app_latest_info') THEN
        RAISE NOTICE '✅ 视图创建成功';
    ELSE
        RAISE EXCEPTION '❌ 视图创建失败';
    END IF;

    -- 检查字段数量
    IF (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'app_latest_info') >= 60 THEN
        RAISE NOTICE '✅ 字段数量正常';
    ELSE
        RAISE WARNING '⚠️ 字段数量可能异常';
    END IF;
END $$;

-- 6. 执行简单查询测试
SELECT 
    '视图修复完成，测试查询中...' AS status,
    COUNT(*) AS record_count
FROM app_latest_info 
WHERE info_score IS NOT NULL 
LIMIT 1;