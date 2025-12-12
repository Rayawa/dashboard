-- 统计系统数据库表回滚脚本
-- 版本: 1.0
-- 用途: 删除统计系统相关的所有表、函数和触发器

-- ============================================================
-- 1. 删除触发器
-- ============================================================
DROP TRIGGER IF EXISTS trigger_ua_statistics_updated_at ON ua_statistics;
DROP TRIGGER IF EXISTS trigger_ip_statistics_updated_at ON ip_statistics;
DROP TRIGGER IF EXISTS trigger_ua_hourly_statistics_updated_at ON ua_hourly_statistics;
DROP TRIGGER IF EXISTS trigger_ip_hourly_statistics_updated_at ON ip_hourly_statistics;

-- ============================================================
-- 2. 删除函数
-- ============================================================
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS cleanup_old_access_logs(INTEGER);
DROP FUNCTION IF EXISTS cleanup_old_hourly_statistics(INTEGER);

-- ============================================================
-- 3. 删除表（按依赖关系的逆序删除）
-- ============================================================
DROP TABLE IF EXISTS access_logs CASCADE;
DROP TABLE IF EXISTS ip_hourly_statistics CASCADE;
DROP TABLE IF EXISTS ua_hourly_statistics CASCADE;
DROP TABLE IF EXISTS ip_statistics CASCADE;
DROP TABLE IF EXISTS ua_statistics CASCADE;

-- ============================================================
-- 完成提示
-- ============================================================
DO $$
BEGIN
    RAISE NOTICE '统计系统数据库表已全部删除';
    RAISE NOTICE '已删除的表：';
    RAISE NOTICE '  - ua_statistics';
    RAISE NOTICE '  - ip_statistics';
    RAISE NOTICE '  - ua_hourly_statistics';
    RAISE NOTICE '  - ip_hourly_statistics';
    RAISE NOTICE '  - access_logs';
    RAISE NOTICE '已删除的函数：';
    RAISE NOTICE '  - update_updated_at_column';
    RAISE NOTICE '  - cleanup_old_access_logs';
    RAISE NOTICE '  - cleanup_old_hourly_statistics';
END $$;