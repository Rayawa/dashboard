-- ----------------------------------------------------------------------
-- 006_initialize_app_full_info_data.sql
-- 合并初始化脚本 - 直接从 app_full_info view 选择数据
-- ----------------------------------------------------------------------
-- 执行时间：预计 3-5 分钟（取决于数据量）
-- 依赖：
--   - 001_create_app_full_info_table.sql
--   - 002_create_app_info_trigger_function.sql
--   - 003_create_metrics_trigger_function.sql
--   - 004_create_rating_trigger_function.sql
--   - 005_create_triggers.sql
-- 描述：
--   直接从 app_latest_info 选择数据并插入到 app_full_info 表
-- 注意：
--   - 仅插入在 app_metrics 中存在最新记录的应用（保证 NOT NULL 字段不违约）
--   - 若某些应用仅存在 app_info，但暂未有 metrics 数据，将不会插入该行，待后续 metrics 到来由触发器补全
--   - 【修改】price 字段已转换为 NUMERIC(10, 2) NOT NULL，转换失败默认 0.0
-- ----------------------------------------------------------------------


BEGIN;

-- 统计信息（初始化前）
DO $$
DECLARE
    before_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO before_count FROM app_full_info;
    RAISE NOTICE '初始化前 app_full_info 行数： %', before_count;
END $$;

-- 直接从 app_latest_info 选择数据并插入到 app_full_info
INSERT INTO app_full_info (
    -- 基础信息（来自 app_info）
    app_id, alliance_app_id, name, pkg_name,
    dev_id, developer_name, dev_en_name,
    supplier, kind_id, kind_name,
    tag_name, kind_type_id, kind_type_name, icon_url,
    brief_desc, description, privacy_url, ctype,
    detail_id, app_level, jocat_id, iap, hms,
    tariff_type, packing_type, order_app, denpend_gms,
    denpend_hms, force_update, img_tag, is_pay,
    is_disciplined, is_shelves, submit_type, delete_archive,
    charging, button_grey, app_gift, free_days,
    pay_install_type, comment, listed_at, release_countries,
    main_device_codes, created_at,

    -- 指标信息（来自 app_metrics，NOT NULL）
    version, version_code, size_bytes, sha256,
    info_score, info_rate_count, download_count, price, -- <--- price 字段
    release_date, new_features, upgrade_msg,
    target_sdk, minsdk, compile_sdk_version,
    min_hmos_api_level, api_release_type, metrics_created_at,

    -- 评分信息（来自 app_rating，NULLABLE）
    average_rating, star_1_rating_count, star_2_rating_count,
    star_3_rating_count, star_4_rating_count, star_5_rating_count,
    my_star_rating, total_star_rating_count, only_star_count,
    full_average_rating, source_type, rating_created_at,

    -- 更新时间
    updated_at
)
SELECT
    -- 基础信息
    app_id, alliance_app_id, name, pkg_name,
    dev_id, developer_name, dev_en_name,
    supplier, kind_id, kind_name,
    tag_name, kind_type_id, kind_type_name, icon_url,
    brief_desc, description, privacy_url, ctype,
    detail_id, app_level, jocat_id, iap, hms,
    tariff_type, packing_type, order_app, denpend_gms,
    denpend_hms, force_update, img_tag, is_pay,
    is_disciplined, is_shelves, submit_type, delete_archive,
    charging, button_grey, app_gift, free_days,
    pay_install_type, comment, listed_at, release_countries,
    main_device_codes, created_at,

    -- 指标信息（NOT NULL）
    version, version_code, size_bytes, sha256,
    info_score, info_rate_count, download_count,

    -- 【新增逻辑】价格转换：去除所有非数字和小数点的字符，失败则设为 0.0，转换为 NUMERIC(10, 2)
    COALESCE(
        NULLIF(regexp_replace(price, '[^\d.]', '', 'g'), ''),
        '0.0'
    )::NUMERIC(10, 2) AS price,

    release_date, new_features, upgrade_msg,
    target_sdk, minsdk, compile_sdk_version,
    min_hmos_api_level, api_release_type, metrics_created_at,

    -- 评分信息（NULLABLE）
    average_rating, star_1_rating_count, star_2_rating_count,
    star_3_rating_count, star_4_rating_count, star_5_rating_count,
    my_star_rating, total_star_rating_count, only_star_count,
    full_average_rating, source_type, rating_created_at,

    -- 更新时间
    now() AS updated_at
FROM app_latest_info
WHERE version IS NOT NULL  -- 确保有 metrics 数据（满足 NOT NULL 约束）
ON CONFLICT (app_id) DO UPDATE SET
    -- 覆盖基础信息
    alliance_app_id = EXCLUDED.alliance_app_id,
    name = EXCLUDED.name,
    pkg_name = EXCLUDED.pkg_name,
    dev_id = EXCLUDED.dev_id,
    developer_name = EXCLUDED.developer_name,
    dev_en_name = EXCLUDED.dev_en_name,
    supplier = EXCLUDED.supplier,
    kind_id = EXCLUDED.kind_id,
    kind_name = EXCLUDED.kind_name,
    tag_name = EXCLUDED.tag_name,
    kind_type_id = EXCLUDED.kind_type_id,
    kind_type_name = EXCLUDED.kind_type_name,
    icon_url = EXCLUDED.icon_url,
    brief_desc = EXCLUDED.brief_desc,
    description = EXCLUDED.description,
    privacy_url = EXCLUDED.privacy_url,
    ctype = EXCLUDED.ctype,
    detail_id = EXCLUDED.detail_id,
    app_level = EXCLUDED.app_level,
    jocat_id = EXCLUDED.jocat_id,
    iap = EXCLUDED.iap,
    hms = EXCLUDED.hms,
    tariff_type = EXCLUDED.tariff_type,
    packing_type = EXCLUDED.packing_type,
    order_app = EXCLUDED.order_app,
    denpend_gms = EXCLUDED.denpend_gms,
    denpend_hms = EXCLUDED.denpend_hms,
    force_update = EXCLUDED.force_update,
    img_tag = EXCLUDED.img_tag,
    is_pay = EXCLUDED.is_pay,
    is_disciplined = EXCLUDED.is_disciplined,
    is_shelves = EXCLUDED.is_shelves,
    submit_type = EXCLUDED.submit_type,
    delete_archive = EXCLUDED.delete_archive,
    charging = EXCLUDED.charging,
    button_grey = EXCLUDED.button_grey,
    app_gift = EXCLUDED.app_gift,
    free_days = EXCLUDED.free_days,
    pay_install_type = EXCLUDED.pay_install_type,
    comment = EXCLUDED.comment,
    listed_at = EXCLUDED.listed_at,
    release_countries = EXCLUDED.release_countries,
    main_device_codes = EXCLUDED.main_device_codes,
    created_at = EXCLUDED.created_at,

    -- 覆盖指标信息（NOT NULL）
    version = EXCLUDED.version,
    version_code = EXCLUDED.version_code,
    size_bytes = EXCLUDED.size_bytes,
    sha256 = EXCLUDED.sha256,
    info_score = EXCLUDED.info_score,
    info_rate_count = EXCLUDED.info_rate_count,
    download_count = EXCLUDED.download_count,
    price = EXCLUDED.price,  -- 此处 EXCLUDED.price 已经是 SELECT 语句转换后的 NUMERIC 值
    release_date = EXCLUDED.release_date,
    new_features = EXCLUDED.new_features,
    upgrade_msg = EXCLUDED.upgrade_msg,
    target_sdk = EXCLUDED.target_sdk,
    minsdk = EXCLUDED.minsdk,
    compile_sdk_version = EXCLUDED.compile_sdk_version,
    min_hmos_api_level = EXCLUDED.min_hmos_api_level,
    api_release_type = EXCLUDED.api_release_type,
    metrics_created_at = EXCLUDED.metrics_created_at,

    -- 覆盖评分信息（允许为 NULL）
    average_rating = EXCLUDED.average_rating,
    star_1_rating_count = EXCLUDED.star_1_rating_count,
    star_2_rating_count = EXCLUDED.star_2_rating_count,
    star_3_rating_count = EXCLUDED.star_3_rating_count,
    star_4_rating_count = EXCLUDED.star_4_rating_count,
    star_5_rating_count = EXCLUDED.star_5_rating_count,
    my_star_rating = EXCLUDED.my_star_rating,
    total_star_rating_count = EXCLUDED.total_star_rating_count,
    only_star_count = EXCLUDED.only_star_count,
    full_average_rating = EXCLUDED.full_average_rating,
    source_type = EXCLUDED.source_type,
    rating_created_at = EXCLUDED.rating_created_at,

    -- 更新时间
    updated_at = now()
;

-- 统计信息（初始化后）
DO $$
DECLARE
    after_count BIGINT;
    with_rating BIGINT;
    without_rating BIGINT;
    total_apps_with_metrics BIGINT;
BEGIN
    SELECT COUNT(*) INTO after_count FROM app_full_info;
    SELECT COUNT(*) INTO with_rating FROM app_full_info WHERE average_rating IS NOT NULL;
    SELECT COUNT(*) INTO without_rating FROM app_full_info WHERE average_rating IS NULL;
    SELECT COUNT(*) INTO total_apps_with_metrics FROM app_latest_info WHERE version IS NOT NULL;

    RAISE NOTICE '初始化后 app_full_info 行数： %', after_count;
    RAISE NOTICE '其中有评分行数： %，无评分行数： %', with_rating, without_rating;
    RAISE NOTICE 'app_latest_info 中有 metrics 数据的应用数： %', total_apps_with_metrics;
END $$;

-- 验证数据完整性
DO $$
DECLARE
    view_count BIGINT;
    table_count BIGINT;
    mismatch_count BIGINT;
BEGIN
    -- 统计 view 与 table 中的记录数
    SELECT COUNT(*) INTO view_count FROM app_latest_info WHERE version IS NOT NULL;
    SELECT COUNT(*) INTO table_count FROM app_full_info;

    -- 检查数据一致性
    SELECT COUNT(*) INTO mismatch_count
    FROM (
        SELECT app_id FROM app_latest_info WHERE version IS NOT NULL
        EXCEPT
        SELECT app_id FROM app_full_info
    ) AS missing_apps;

    RAISE NOTICE '数据完整性验证：';
    RAISE NOTICE '  - app_latest_info 中有 metrics 数据的应用数： %', view_count;
    RAISE NOTICE '  - app_full_info 表中的应用数： %', table_count;
    RAISE NOTICE '  - 数据不一致的应用数： %', mismatch_count;

    IF mismatch_count = 0 AND view_count = table_count THEN
        RAISE NOTICE '数据完整性验证通过';
    ELSE
        RAISE WARNING '数据完整性验证失败：存在 % 个应用数据不一致', mismatch_count;
    END IF;
END $$;

-- 可选：更新统计信息，优化后续查询
ANALYZE app_full_info;

COMMIT;

-- 完成提示
DO $$
BEGIN
    RAISE NOTICE 'app_full_info 初始化完成（使用 app_latest_info 数据源）';
    RAISE NOTICE '说明：仅插入存在最新 metrics 记录的应用，以满足 NOT NULL 约束；rating 字段允许为空';
    RAISE NOTICE '数据源：直接从 app_latest_info 选择数据，简化了复杂的 JOIN 逻辑';
END $$;