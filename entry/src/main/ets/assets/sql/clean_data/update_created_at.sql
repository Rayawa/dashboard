UPDATE app_info ai
SET created_at = LEAST(ai.created_at, am_min.min_created_at)
FROM (
    SELECT
        app_id,
        MIN(created_at) AS min_created_at
    FROM app_metrics
    GROUP BY app_id
) AS am_min
WHERE ai.app_id = am_min.app_id AND ai.created_at > am_min.min_created_at;
