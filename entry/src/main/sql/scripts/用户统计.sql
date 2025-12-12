SELECT
    comment ->> 'user' AS username,
    COUNT(*) AS record_count
FROM
    app_info
WHERE
    comment IS NOT NULL
    AND (comment ->> 'user') IS NOT NULL
GROUP BY
    username
ORDER BY
    record_count DESC;