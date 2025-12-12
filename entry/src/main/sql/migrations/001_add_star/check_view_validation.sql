-- 视图验证脚本：检查 app_latest_info 视图的正确性
-- 执行此脚本验证视图是否正常工作

-- 1. 检查视图是否存在
SELECT 
    EXISTS (
        SELECT 1 
        FROM information_schema.views 
        WHERE table_name = 'app_latest_info'
    ) AS view_exists;

-- 2. 检查视图定义是否完整
SELECT 
    COUNT(*) AS total_columns,
    COUNT(CASE WHEN column_name LIKE '%info_score%' THEN 1 END) AS has_info_score,
    COUNT(CASE WHEN column_name LIKE '%info_rate_count%' THEN 1 END) AS has_info_rate_count,
    COUNT(CASE WHEN column_name LIKE '%page_%' THEN 1 END) AS has_page_columns
FROM information_schema.columns 
WHERE table_name = 'app_latest_info';

-- 3. 检查视图是否可以正常查询（限制返回5行）
SELECT 
    app_id,
    name,
    version,
    info_score,
    info_rate_count,
    download_count,
    page_average_rating,
    page_total_star_rating_count
FROM app_latest_info 
LIMIT 5;

-- 4. 检查是否有NULL值问题
SELECT 
    COUNT(*) AS total_records,
    COUNT(CASE WHEN info_score IS NULL THEN 1 END) AS null_info_score,
    COUNT(CASE WHEN info_rate_count IS NULL THEN 1 END) AS null_info_rate_count,
    COUNT(CASE WHEN page_average_rating IS NULL THEN 1 END) AS null_page_avg_rating,
    COUNT(CASE WHEN page_total_star_rating_count IS NULL THEN 1 END) AS null_page_total_rating
FROM app_latest_info;

-- 5. 检查子查询字段映射
-- 验证SELECT列表和子查询中的字段是否匹配
SELECT 
    'SELECT列表字段' AS check_type,
    COUNT(*) AS field_count
FROM (
    SELECT unnest(ARRAY[
        'app_id', 'alliance_app_id', 'name', 'pkg_name', 'dev_id', 'developer_name', 
        'dev_en_name', 'supplier', 'kind_id', 'kind_name', 'tag_name', 'kind_type_id', 
        'kind_type_name', 'icon_url', 'brief_desc', 'description', 'privacy_url', 'ctype', 
        'detail_id', 'app_level', 'jocat_id', 'iap', 'hms', 'tariff_type', 'packing_type', 
        'order_app', 'denpend_gms', 'denpend_hms', 'force_update', 'img_tag', 'is_pay', 
        'is_disciplined', 'is_shelves', 'submit_type', 'delete_archive', 'charging', 
        'button_grey', 'app_gift', 'free_days', 'pay_install_type', 'version', 'version_code', 
        'size_bytes', 'sha256', 'info_score', 'info_rate_count', 'download_count', 'price', 
        'release_date', 'new_features', 'upgrade_msg', 'target_sdk', 'minsdk', 
        'compile_sdk_version', 'min_hmos_api_level', 'api_release_type', 'page_average_rating', 
        'page_star_1_rating_count', 'page_star_2_rating_count', 'page_star_3_rating_count', 
        'page_star_4_rating_count', 'page_star_5_rating_count', 'page_my_star_rating', 
        'page_total_star_rating_count', 'page_only_star_count', 'page_full_average_rating', 
        'page_source_type', 'metrics_created_at'
    ]) AS field_name
) AS select_fields

UNION ALL

SELECT 
    '子查询字段' AS check_type,
    COUNT(*) AS field_count
FROM (
    SELECT unnest(ARRAY[
        'id', 'app_id', 'version', 'version_code', 'size_bytes', 'sha256', 'download_count', 
        'price', 'release_date', 'new_features', 'upgrade_msg', 'target_sdk', 'minsdk', 
        'compile_sdk_version', 'min_hmos_api_level', 'api_release_type', 'created_at', 
        'info_score', 'info_rate_count', 'page_average_rating', 'page_star_1_rating_count', 
        'page_star_2_rating_count', 'page_star_3_rating_count', 'page_star_4_rating_count', 
        'page_star_5_rating_count', 'page_my_star_rating', 'page_total_star_rating_count', 
        'page_only_star_count', 'page_full_average_rating', 'page_source_type'
    ]) AS field_name
) AS subquery_fields;

-- 6. 检查视图性能（执行时间）
EXPLAIN ANALYZE 
SELECT COUNT(*) 
FROM app_latest_info 
WHERE info_score IS NOT NULL;

-- 7. 验证数据完整性
SELECT 
    '应用数量' AS metric,
    COUNT(DISTINCT app_id) AS value
FROM app_latest_info

UNION ALL

SELECT 
    '有评分数据的应用',
    COUNT(DISTINCT app_id) 
FROM app_latest_info 
WHERE info_score IS NOT NULL

UNION ALL

SELECT 
    '有页面评分数据的应用',
    COUNT(DISTINCT app_id) 
FROM app_latest_info 
WHERE page_average_rating IS NOT NULL;

-- 8. 最终验证结果
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM app_latest_info LIMIT 1) THEN '视图可正常查询'
        ELSE '视图查询失败'
    END AS validation_result,
    
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'app_latest_info') >= 60 
        THEN '字段数量正常'
        ELSE '字段数量异常'
    END AS field_count_check,
    
    CASE 
        WHEN (SELECT COUNT(CASE WHEN info_score IS NOT NULL THEN 1 END) FROM app_latest_info) > 0
        THEN 'info_score数据正常'
        ELSE 'info_score数据异常'
    END AS info_score_check;