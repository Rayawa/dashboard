-- ----------------------------------------------------------------------
-- 005_sync_existing_records.sql
-- 同步现有的 app_record 数据到 app_full_info 表
-- ----------------------------------------------------------------------
-- 执行时间：预计 1-5 分钟（取决于数据量）
-- 依赖：004_create_record_trigger.sql
-- 描述：将 app_record 表中已有的数据同步到 app_full_info 表
-- ----------------------------------------------------------------------

BEGIN;

-- 同步现有的 app_record 数据到 app_full_info
-- 对于每个应用，只取最新的 record 记录
UPDATE app_full_info afi
SET
    title = ar.title,
    app_recordal_info = ar.app_recordal_info,
    recordal_entity_title = ar.recordal_entity_title,
    recordal_entity_name = ar.recordal_entity_name,
    updated_at = now()
FROM (
    SELECT DISTINCT ON (app_id)
        app_id,
        title,
        app_recordal_info,
        recordal_entity_title,
        recordal_entity_name
    FROM app_record
    ORDER BY app_id, created_at DESC NULLS LAST
) ar
WHERE afi.app_id = ar.app_id;

-- 显示同步结果统计
DO $$
DECLARE
    total_records_count INT;
    synced_count INT;
BEGIN
    -- 统计 app_record 总数
    SELECT COUNT(DISTINCT app_id) INTO total_records_count FROM app_record;
    
    -- 统计 app_full_info 中有备案信息的应用数量
    SELECT COUNT(*) INTO synced_count 
    FROM app_full_info 
    WHERE app_recordal_info IS NOT NULL;
    
    RAISE NOTICE '总共 % 个应用有备案记录', total_records_count;
    RAISE NOTICE '成功同步 % 条记录到 app_full_info', synced_count;
END $$;

COMMIT;

-- 验证脚本执行结果
DO $$
DECLARE
    record_count INT;
    synced_count INT;
BEGIN
    -- 统计 app_record 中不同应用的数量
    SELECT COUNT(DISTINCT app_id) INTO record_count FROM app_record;
    
    -- 统计 app_full_info 中有备案信息的数量
    SELECT COUNT(*) INTO synced_count 
    FROM app_full_info 
    WHERE app_recordal_info IS NOT NULL;
    
    IF record_count > 0 AND synced_count = record_count THEN
        RAISE NOTICE '✓ 所有 app_record 数据同步成功 (% 条)', synced_count;
    ELSIF record_count = 0 THEN
        RAISE NOTICE '✓ app_record 表为空，无需同步';
    ELSE
        RAISE WARNING '⚠ 部分数据可能未同步: record 表有 % 条，app_full_info 同步了 % 条', 
            record_count, synced_count;
    END IF;
END $$;