-- 如果表已存在，先删除可能存在的重复数据
DELETE FROM app_raw
WHERE id IN (
    SELECT id
    FROM (
        SELECT
            id,
            ROW_NUMBER() OVER (
                PARTITION BY raw_json_data, raw_json_star
                ORDER BY created_at
            ) AS rn
        FROM app_raw
    ) t
    WHERE rn > 1
);
