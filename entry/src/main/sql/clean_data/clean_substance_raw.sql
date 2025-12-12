WITH duplicates AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY substance_id, raw_json_substance -- 按照 substance_id 和 json 内容分组
            ORDER BY id ASC                               -- 按照 ID 升序排列（小的在前）
        ) as rn
    FROM
        substance_history
)
DELETE FROM substance_history
WHERE id IN (
    SELECT id FROM duplicates WHERE rn > 1 -- 删除排序在第1名之后的所有行
);

SELECT
    substance_id,
    -- raw_json_substance, -- 如果 json 很大，建议注释掉这一行，只看统计
    count(*) as total_count,
    array_agg(id ORDER BY id ASC) as all_ids
FROM
    substance_history
GROUP BY
    substance_id,
    raw_json_substance
HAVING
    count(*) > 1; -- 只显示有重复的项

CREATE OR REPLACE FUNCTION normalize_json_by_value(data jsonb)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    _type text;
    _text_val text;
BEGIN
    -- 获取当前节点的类型
    _type := jsonb_typeof(data);

    -- 1. 如果是对象 (Object)，遍历每个键值对并递归处理 Value
    IF _type = 'object' THEN
        RETURN (
            SELECT COALESCE(
                jsonb_object_agg(
                    key,
                    normalize_json_by_value(value)
                ),
                '{}'::jsonb -- 处理空对象的情况
            )
            FROM jsonb_each(data)
        );

    -- 2. 如果是数组 (Array)，遍历每个元素并递归处理
    ELSIF _type = 'array' THEN
        RETURN (
            SELECT COALESCE(
                jsonb_agg(
                    normalize_json_by_value(elem)
                ),
                '[]'::jsonb -- 处理空数组的情况
            )
            FROM jsonb_array_elements(data) elem
        );

    -- 3. 如果是字符串 (String)，检查内容
    ELSIF _type = 'string' THEN
        _text_val := data #>> '{}'; -- 将 jsonb 字符串转为 text
        -- 如果值中包含 'trace' (ILIKE 不区分大小写)，则进行脱敏
        IF _text_val ILIKE '%trace%' THEN
            RETURN '"TRACE_MASKED"'::jsonb;
        ELSE
            RETURN data;
        END IF;

    -- 4. 其他类型 (数值、布尔、Null)，保持原样
    ELSE
        RETURN data;
    END IF;
END;
$$;

SELECT
    id,
    raw_json_substance as original,
    normalize_json_by_value(raw_json_substance) as cleaned
FROM substance_history
-- 找一条包含 trace 的数据测试一下
WHERE raw_json_substance::text ILIKE '%trace%'
LIMIT 5;

WITH duplicates AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY
                substance_id,
                normalize_json_by_value(raw_json_substance) -- 使用清洗后的 JSON 分组
            ORDER BY id ASC -- 确保 ID 小的排在第一位
        ) as rn
    FROM
        substance_history
)
DELETE FROM substance_history
WHERE id IN (
    SELECT id FROM duplicates WHERE rn > 1
);