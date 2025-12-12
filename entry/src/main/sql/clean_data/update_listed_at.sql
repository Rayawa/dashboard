UPDATE app_info ai
SET listed_at = calculated_values.new_listed_at
FROM (
    SELECT
        am.app_id,
        LEAST(ai_sub.listed_at, MIN(TO_TIMESTAMP(am.release_date / 1000))) AS new_listed_at,
        ai_sub.listed_at AS original_listed_at
    FROM app_metrics am
    JOIN app_info ai_sub ON am.app_id = ai_sub.app_id -- 再次连接 app_info 来获取原始 listed_at
    GROUP BY am.app_id, ai_sub.listed_at
) AS calculated_values
WHERE
    ai.app_id = calculated_values.app_id
    AND ai.listed_at IS DISTINCT FROM calculated_values.new_listed_at; -- 仅更新不同的行