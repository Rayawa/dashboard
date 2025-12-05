-- 确保没有 json null
UPDATE app_info
SET comment = null
WHERE comment = '{}'

UPDATE app_raw
SET raw_json_data = raw_json_data - 'AG-TraceId'
WHERE raw_json_data ? 'AG-TraceId';
