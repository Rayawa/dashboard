-- 1. 向 app_info 表添加 release_countries 字段
-- 这个字段存储应用发布的国家/地区列表，是一个文本数组。
ALTER TABLE app_info ADD COLUMN release_countries TEXT[] NOT NULL DEFAULT '{}';
COMMENT ON COLUMN app_info.release_countries IS '应用发布的国家/地区列表';

-- 2. 向 app_info 表添加 main_device_codes 字段
-- 这个字段存储应用支持的主要设备类型，是一个文本数组。
ALTER TABLE app_info ADD COLUMN main_device_codes TEXT[] NOT NULL DEFAULT '{}';
COMMENT ON COLUMN app_info.main_device_codes IS '应用支持的主要设备类型';