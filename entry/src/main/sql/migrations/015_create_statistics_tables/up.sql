-- 统计系统数据库表创建脚本
-- 版本: 1.0
-- 创建时间: 2024

-- ============================================================
-- 1. UA 总体统计表
-- ============================================================
CREATE TABLE IF NOT EXISTS ua_statistics (
    user_agent TEXT PRIMARY KEY,
    access_count BIGINT NOT NULL DEFAULT 0,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- UA 统计表索引
CREATE INDEX IF NOT EXISTS idx_ua_statistics_access_count ON ua_statistics(access_count DESC);
CREATE INDEX IF NOT EXISTS idx_ua_statistics_last_seen ON ua_statistics(last_seen_at DESC);

-- UA 统计表注释
COMMENT ON TABLE ua_statistics IS 'User-Agent 总体访问统计表';
COMMENT ON COLUMN ua_statistics.user_agent IS 'User-Agent 字符串，作为主键';
COMMENT ON COLUMN ua_statistics.access_count IS '累计访问次数';
COMMENT ON COLUMN ua_statistics.first_seen_at IS '首次访问时间';
COMMENT ON COLUMN ua_statistics.last_seen_at IS '最后访问时间';
COMMENT ON COLUMN ua_statistics.created_at IS '记录创建时间';
COMMENT ON COLUMN ua_statistics.updated_at IS '记录更新时间';

-- ============================================================
-- 2. IP 总体统计表
-- ============================================================
CREATE TABLE IF NOT EXISTS ip_statistics (
    ip_address INET PRIMARY KEY,
    access_count BIGINT NOT NULL DEFAULT 0,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- IP 统计表索引
CREATE INDEX IF NOT EXISTS idx_ip_statistics_access_count ON ip_statistics(access_count DESC);
CREATE INDEX IF NOT EXISTS idx_ip_statistics_last_seen ON ip_statistics(last_seen_at DESC);

-- IP 统计表注释
COMMENT ON TABLE ip_statistics IS 'IP 地址总体访问统计表';
COMMENT ON COLUMN ip_statistics.ip_address IS 'IP 地址，作为主键';
COMMENT ON COLUMN ip_statistics.access_count IS '累计访问次数';
COMMENT ON COLUMN ip_statistics.first_seen_at IS '首次访问时间';
COMMENT ON COLUMN ip_statistics.last_seen_at IS '最后访问时间';
COMMENT ON COLUMN ip_statistics.created_at IS '记录创建时间';
COMMENT ON COLUMN ip_statistics.updated_at IS '记录更新时间';

-- ============================================================
-- 3. UA 每小时统计表
-- ============================================================
CREATE TABLE IF NOT EXISTS ua_hourly_statistics (
    user_agent TEXT NOT NULL,
    hour_timestamp TIMESTAMPTZ NOT NULL,
    access_count BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_agent, hour_timestamp)
);

-- UA 每小时统计表索引
CREATE INDEX IF NOT EXISTS idx_ua_hourly_timestamp ON ua_hourly_statistics(hour_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ua_hourly_user_agent ON ua_hourly_statistics(user_agent);
CREATE INDEX IF NOT EXISTS idx_ua_hourly_access_count ON ua_hourly_statistics(access_count DESC);

-- UA 每小时统计表注释
COMMENT ON TABLE ua_hourly_statistics IS 'User-Agent 每小时访问统计表';
COMMENT ON COLUMN ua_hourly_statistics.user_agent IS 'User-Agent 字符串';
COMMENT ON COLUMN ua_hourly_statistics.hour_timestamp IS '小时时间戳（整点时间）';
COMMENT ON COLUMN ua_hourly_statistics.access_count IS '该小时内的访问次数';
COMMENT ON COLUMN ua_hourly_statistics.created_at IS '记录创建时间';
COMMENT ON COLUMN ua_hourly_statistics.updated_at IS '记录更新时间';

-- ============================================================
-- 4. IP 每小时统计表
-- ============================================================
CREATE TABLE IF NOT EXISTS ip_hourly_statistics (
    ip_address INET NOT NULL,
    hour_timestamp TIMESTAMPTZ NOT NULL,
    access_count BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (ip_address, hour_timestamp)
);

-- IP 每小时统计表索引
CREATE INDEX IF NOT EXISTS idx_ip_hourly_timestamp ON ip_hourly_statistics(hour_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ip_hourly_ip_address ON ip_hourly_statistics(ip_address);
CREATE INDEX IF NOT EXISTS idx_ip_hourly_access_count ON ip_hourly_statistics(access_count DESC);

-- IP 每小时统计表注释
COMMENT ON TABLE ip_hourly_statistics IS 'IP 地址每小时访问统计表';
COMMENT ON COLUMN ip_hourly_statistics.ip_address IS 'IP 地址';
COMMENT ON COLUMN ip_hourly_statistics.hour_timestamp IS '小时时间戳（整点时间）';
COMMENT ON COLUMN ip_hourly_statistics.access_count IS '该小时内的访问次数';
COMMENT ON COLUMN ip_hourly_statistics.created_at IS '记录创建时间';
COMMENT ON COLUMN ip_hourly_statistics.updated_at IS '记录更新时间';

-- ============================================================
-- 5. 访问详细日志表
-- ============================================================
CREATE TABLE IF NOT EXISTS access_logs (
    id BIGSERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address INET NOT NULL,
    user_agent TEXT NOT NULL,
    request_method TEXT NOT NULL,
    request_path TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 访问日志表索引
CREATE INDEX IF NOT EXISTS idx_access_logs_timestamp ON access_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_access_logs_ip_address ON access_logs(ip_address);
CREATE INDEX IF NOT EXISTS idx_access_logs_user_agent ON access_logs(user_agent);
CREATE INDEX IF NOT EXISTS idx_access_logs_request_path ON access_logs(request_path);

-- 访问日志表注释
COMMENT ON TABLE access_logs IS '访问详细日志表';
COMMENT ON COLUMN access_logs.id IS '日志记录唯一ID';
COMMENT ON COLUMN access_logs.timestamp IS '访问时间戳';
COMMENT ON COLUMN access_logs.ip_address IS '访问者IP地址';
COMMENT ON COLUMN access_logs.user_agent IS 'User-Agent 字符串';
COMMENT ON COLUMN access_logs.request_method IS 'HTTP 请求方法';
COMMENT ON COLUMN access_logs.request_path IS '请求路径';
COMMENT ON COLUMN access_logs.created_at IS '记录创建时间';

-- ============================================================
-- 6. 创建更新时间自动触发器
-- ============================================================

-- 通用的更新 updated_at 字段的函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为 UA 统计表创建触发器
DROP TRIGGER IF EXISTS trigger_ua_statistics_updated_at ON ua_statistics;
CREATE TRIGGER trigger_ua_statistics_updated_at
    BEFORE UPDATE ON ua_statistics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 为 IP 统计表创建触发器
DROP TRIGGER IF EXISTS trigger_ip_statistics_updated_at ON ip_statistics;
CREATE TRIGGER trigger_ip_statistics_updated_at
    BEFORE UPDATE ON ip_statistics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 为 UA 每小时统计表创建触发器
DROP TRIGGER IF EXISTS trigger_ua_hourly_statistics_updated_at ON ua_hourly_statistics;
CREATE TRIGGER trigger_ua_hourly_statistics_updated_at
    BEFORE UPDATE ON ua_hourly_statistics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 为 IP 每小时统计表创建触发器
DROP TRIGGER IF EXISTS trigger_ip_hourly_statistics_updated_at ON ip_hourly_statistics;
CREATE TRIGGER trigger_ip_hourly_statistics_updated_at
    BEFORE UPDATE ON ip_hourly_statistics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 7. 创建数据清理函数（可选）
-- ============================================================

-- 清理旧的访问日志（保留最近 N 天）
CREATE OR REPLACE FUNCTION cleanup_old_access_logs(days_to_keep INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM access_logs
    WHERE timestamp < NOW() - INTERVAL '1 day' * days_to_keep;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_access_logs IS '清理超过指定天数的访问日志，默认保留90天';

-- 清理旧的每小时统计数据（保留最近 N 天）
CREATE OR REPLACE FUNCTION cleanup_old_hourly_statistics(days_to_keep INTEGER DEFAULT 180)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
    total_deleted INTEGER := 0;
BEGIN
    -- 清理 UA 每小时统计
    DELETE FROM ua_hourly_statistics
    WHERE hour_timestamp < NOW() - INTERVAL '1 day' * days_to_keep;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    total_deleted := total_deleted + deleted_count;

    -- 清理 IP 每小时统计
    DELETE FROM ip_hourly_statistics
    WHERE hour_timestamp < NOW() - INTERVAL '1 day' * days_to_keep;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    total_deleted := total_deleted + deleted_count;

    RETURN total_deleted;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_hourly_statistics IS '清理超过指定天数的每小时统计数据，默认保留180天';

-- ============================================================
-- 完成提示
-- ============================================================
DO $$
BEGIN
    RAISE NOTICE '统计系统数据库表创建完成';
    RAISE NOTICE '已创建表：';
    RAISE NOTICE '  - ua_statistics (UA 总体统计)';
    RAISE NOTICE '  - ip_statistics (IP 总体统计)';
    RAISE NOTICE '  - ua_hourly_statistics (UA 每小时统计)';
    RAISE NOTICE '  - ip_hourly_statistics (IP 每小时统计)';
    RAISE NOTICE '  - access_logs (访问详细日志)';
    RAISE NOTICE '已创建清理函数：';
    RAISE NOTICE '  - cleanup_old_access_logs(days) 清理旧访问日志';
    RAISE NOTICE '  - cleanup_old_hourly_statistics(days) 清理旧统计数据';
END $$;