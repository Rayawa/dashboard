-- ----------------------------------------------------------------------
-- 根据优化建议更新后的索引定义
-- ----------------------------------------------------------------------

-- app_info 表索引
-- 主键 app_id 已有隐式唯一索引。
CREATE INDEX IF NOT EXISTS idx_app_info_pkg_name ON app_info(pkg_name); -- pkg_name 上的 UNIQUE 约束也会创建隐式唯一索引。
CREATE INDEX IF NOT EXISTS idx_app_info_name ON app_info(name);
CREATE INDEX IF NOT EXISTS idx_app_info_developer_name ON app_info(developer_name);
CREATE INDEX IF NOT EXISTS idx_app_info_listed_at ON app_info(listed_at);

-- 013迁移添加的性能优化索引 - 冗余字段查询优化
-- 这些索引用于优化013迁移后新增的冗余字段查询，提升get_top_downloads等查询性能
-- 下载量降序索引（最重要的性能优化）
CREATE INDEX IF NOT EXISTS idx_app_full_info_download_count_desc 
ON app_full_info(download_count DESC NULLS LAST)
WHERE download_count IS NOT NULL;

-- 评分降序索引（用于评分排行查询）
CREATE INDEX IF NOT EXISTS idx_app_full_info_average_rating_desc 
ON app_full_info(average_rating DESC NULLS LAST)
WHERE average_rating IS NOT NULL;

-- 版本相关索引
CREATE INDEX IF NOT EXISTS idx_app_full_info_version ON app_full_info(version)
WHERE version IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_app_full_info_version_code ON app_full_info(version_code)
WHERE version_code IS NOT NULL;

-- 发布时间索引
CREATE INDEX IF NOT EXISTS idx_app_full_info_release_date ON app_full_info(release_date DESC)
WHERE release_date IS NOT NULL;

-- 评分数量索引
CREATE INDEX IF NOT EXISTS idx_app_full_info_total_star_rating_count_desc 
ON app_full_info(total_star_rating_count DESC NULLS LAST)
WHERE total_star_rating_count IS NOT NULL;

-- 信息评分索引
CREATE INDEX IF NOT EXISTS idx_app_full_info_info_score_desc 
ON app_full_info(info_score DESC NULLS LAST)
WHERE info_score IS NOT NULL;

-- 复合索引用于综合排序查询
-- 例如：按下载量和评分综合排序
CREATE INDEX IF NOT EXISTS idx_app_full_info_download_rating_composite 
ON app_full_info(download_count DESC NULLS LAST, average_rating DESC NULLS LAST)
WHERE download_count IS NOT NULL AND average_rating IS NOT NULL;



-- 为开发者相关的评分和下载量创建索引
CREATE INDEX IF NOT EXISTS idx_app_full_info_dev_download_rating 
ON app_full_info(dev_id, download_count DESC NULLS LAST, average_rating DESC NULLS LAST)
WHERE download_count IS NOT NULL AND average_rating IS NOT NULL;

-- 为分类相关的下载量创建索引
CREATE INDEX IF NOT EXISTS idx_app_full_info_kind_download 
ON app_full_info(kind_id, download_count DESC NULLS LAST)
WHERE download_count IS NOT NULL;

-- app_metrics 表索引
-- 主键 id 已有隐式唯一索引。
-- app_id 和 pkg_name 的外键约束如果不存在也会隐式创建索引。
-- 新的复合索引 idx_app_metrics_app_id_created_at 替代了原有的简单 app_id 索引，用于高效获取每个应用的最新 metrics 记录（支撑冗余字段同步）。
CREATE INDEX IF NOT EXISTS idx_app_metrics_app_id_created_at ON app_metrics(app_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_app_metrics_version ON app_metrics(version);
-- 新的复合索引 idx_app_metrics_download_count_app_id_created_at 替代了原有的简单 download_count 索引，
-- 更好地支持慢查询中的 ORDER BY 排序并在冗余数据初始化与报表查询中保持性能。
CREATE INDEX IF NOT EXISTS idx_app_metrics_download_count_app_id_created_at ON app_metrics(download_count DESC, app_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_app_metrics_pkg_name ON app_metrics (pkg_name);

-- app_rating 表索引
-- 主键 id 已有隐式唯一索引。
-- 新的复合索引 idx_app_rating_app_id_created_at 替代了原有的简单 app_id 索引，用于快速获取最新 rating 记录（支撑冗余字段同步）。
CREATE INDEX IF NOT EXISTS idx_app_rating_app_id_created_at ON app_rating(app_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_app_rating_pkg_name ON app_rating (pkg_name);


-- app_data_history 表索引
CREATE INDEX IF NOT EXISTS idx_app_data_history_app_pkg_data ON app_data_history (app_id, pkg_name, raw_json_data);
CREATE INDEX IF NOT EXISTS idx_app_data_history_created_at ON app_data_history (created_at);

-- app_record 表索引
-- 主键 id 已有隐式唯一索引
CREATE INDEX IF NOT EXISTS idx_app_record_app_id ON app_record(app_id);
CREATE INDEX IF NOT EXISTS idx_app_record_title ON app_record(title);
CREATE INDEX IF NOT EXISTS idx_app_record_app_recordal_info ON app_record(app_recordal_info);
CREATE INDEX IF NOT EXISTS idx_app_record_entity_name ON app_record(recordal_entity_name);
CREATE INDEX IF NOT EXISTS idx_app_record_created_at ON app_record(created_at);

-- 1) substance_info 表索引
-- 主键 id 已有隐式唯一索引；补充常用查询字段索引：
CREATE INDEX IF NOT EXISTS idx_substance_info_name ON substance_info (name);
CREATE INDEX IF NOT EXISTS idx_substance_info_title ON substance_info (title);
CREATE INDEX IF NOT EXISTS idx_substance_info_created_at ON substance_info (created_at);

-- 2) substance_history 表索引
-- 针对 substance_id 和时间范围查询进行了优化。
CREATE INDEX IF NOT EXISTS idx_substance_history_substance_id ON substance_history (substance_id);
CREATE INDEX IF NOT EXISTS idx_substance_history_created_at ON substance_history (created_at);
-- 如果需要基于 JSONB 内容查询（例如 raw_json_substance ->> 'field'），则建立 GIN 索引。
CREATE INDEX IF NOT EXISTS idx_substance_history_raw_json_gin ON substance_history USING GIN (raw_json_substance);

-- 3) substance_app_map 表索引
-- 主键 (substance_id, app_id) 已存在；补充索引：
CREATE INDEX IF NOT EXISTS idx_substance_app_map_app_id ON substance_app_map (app_id);
-- 如果需要按 app_id 排序/筛选，可以考虑复合索引（例如：按 app_id 再按 substance_id）
CREATE INDEX IF NOT EXISTS idx_substance_app_map_appid_substanceid ON substance_app_map (app_id, substance_id);

-- ----------------------------------------------------------------------
-- 015迁移添加的统计系统表索引
-- ----------------------------------------------------------------------

-- ua_statistics 表索引
CREATE INDEX IF NOT EXISTS idx_ua_statistics_access_count ON ua_statistics(access_count DESC);
CREATE INDEX IF NOT EXISTS idx_ua_statistics_last_seen ON ua_statistics(last_seen_at DESC);

-- ip_statistics 表索引
CREATE INDEX IF NOT EXISTS idx_ip_statistics_access_count ON ip_statistics(access_count DESC);
CREATE INDEX IF NOT EXISTS idx_ip_statistics_last_seen ON ip_statistics(last_seen_at DESC);

-- ua_hourly_statistics 表索引
CREATE INDEX IF NOT EXISTS idx_ua_hourly_timestamp ON ua_hourly_statistics(hour_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ua_hourly_user_agent ON ua_hourly_statistics(user_agent);
CREATE INDEX IF NOT EXISTS idx_ua_hourly_access_count ON ua_hourly_statistics(access_count DESC);

-- ip_hourly_statistics 表索引
CREATE INDEX IF NOT EXISTS idx_ip_hourly_timestamp ON ip_hourly_statistics(hour_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ip_hourly_ip_address ON ip_hourly_statistics(ip_address);
CREATE INDEX IF NOT EXISTS idx_ip_hourly_access_count ON ip_hourly_statistics(access_count DESC);

-- access_logs 表索引
CREATE INDEX IF NOT EXISTS idx_access_logs_timestamp ON access_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_access_logs_ip_address ON access_logs(ip_address);
CREATE INDEX IF NOT EXISTS idx_access_logs_user_agent ON access_logs(user_agent);
CREATE INDEX IF NOT EXISTS idx_access_logs_request_path ON access_logs(request_path);
