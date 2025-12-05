-- select * from app_info where listed_at > '2025-08-01'
-- and pkg_name not like 'com.atomicservice%'
-- and developer_name not like '%公司%'
-- and length(developer_name) < 4
-- order by developer_name;

SELECT
    CASE
        WHEN LENGTH(developer_name) = 2 THEN SUBSTR(developer_name, 1, 1) || '*'
        WHEN LENGTH(developer_name) = 3 THEN SUBSTR(developer_name, 1, 1) || '**'
        WHEN LENGTH(developer_name) = 4 THEN SUBSTR(developer_name, 1, 1) || '***'
        ELSE developer_name
    END AS developer_name,
    COUNT(app_id) AS app_count
FROM
    app_info
WHERE
    listed_at > '2025-08-01'
    AND pkg_name NOT LIKE 'com.atomicservice%'
    AND developer_name NOT LIKE '%公司%'
    AND LENGTH(developer_name) <= 4

GROUP BY
    developer_name
ORDER BY
    app_count DESC;

SELECT
    CASE
        WHEN LENGTH(developer_name) = 2 THEN SUBSTR(developer_name, 1, 1) || '*'
        WHEN LENGTH(developer_name) = 3 THEN SUBSTR(developer_name, 1, 1) || '**'
        WHEN LENGTH(developer_name) = 4 THEN SUBSTR(developer_name, 1, 1) || '***'
        ELSE developer_name
    END AS developer_name,
    COUNT(app_id) AS app_count
FROM
    app_info
WHERE
    listed_at > '2025-08-01'
    AND pkg_name NOT LIKE 'com.atomicservice%'
GROUP BY
    developer_name
ORDER BY
    app_count DESC;
