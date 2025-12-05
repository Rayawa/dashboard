
-- 检查有哪些 app_raw 重复了
SELECT
    id,
    app_id,
    raw_json_data,
    raw_json_star,
    created_at,
    rn
FROM (
    SELECT
        id,
        app_id,
        raw_json_data,
        raw_json_star,
        created_at,
        -- 使用 ROW_NUMBER() 来识别重复项
        ROW_NUMBER() OVER(PARTITION BY app_id, raw_json_data, raw_json_star ORDER BY created_at DESC, id DESC) as rn
    FROM app_raw
) AS subquery
WHERE rn > 1 -- 筛选出所有在分区内不是第一条的记录，即重复项
ORDER BY app_id, raw_json_data, raw_json_star, created_at DESC, id DESC;


-- BEGIN; -- 开启一个事务，以便可以在必要时回滚

-- 使用CTE来识别并删除重复项
WITH app_raw_duplicates AS (
    SELECT
        id,
        -- 使用 ROW_NUMBER() 来识别重复项。
        -- PARTITION BY app_id, raw_json_data, raw_json_star：
        -- 这定义了“重复”的条件，即 app_id, raw_json_data, raw_json_star 都完全相同。
        -- ORDER BY created_at DESC, id DESC：
        -- 在每个重复组中，我们希望保留 created_at 最新（如果相同则 id 最大）的那个。
        -- 因此，rn=1 的将是被保留的，rn>1 的将被删除。
        ROW_NUMBER() OVER(PARTITION BY app_id, raw_json_data, raw_json_star ORDER BY created_at DESC, id DESC) as rn
    FROM app_raw
)
-- 删除所有 rn 大于 1 的记录，这些就是我们定义的重复项
DELETE FROM app_raw
WHERE id IN (
    SELECT id
    FROM app_raw_duplicates
    WHERE rn > 1
);

-- 在这里，您可以运行一个 SELECT COUNT(*) FROM app_raw; 来检查剩余的行数，
-- 或者再次运行之前的 SELECT 重复项的SQL来确认没有重复项了。

-- 如果您对删除结果满意，请提交事务
-- COMMIT;

-- 如果您不满意结果，或者发现删除了不该删除的数据，可以回滚事务
-- ROLLBACK;
