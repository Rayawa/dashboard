-- 理论上是个一次性脚本
-- 主要是用来在迁移之后跑

UPDATE app_info ai
SET
    -- 更新 app_info 表中的 release_countries 字段
    release_countries = COALESCE(
        -- 子查询用于获取最新的 app_raw 记录中的 releaseCountries 数据
        (SELECT
             CASE
                 -- 检查 jsonb_path_query_array 是否返回 NULL (即路径不存在)
                 WHEN jsonb_path_query_array(ar.raw_json_data, '$.releaseCountries[*]') IS NULL THEN '{}'::TEXT[]
                 -- 检查 jsonb_path_query_array 是否返回空的 JSONB 数组 (即路径存在但数组为空)
                 WHEN jsonb_path_query_array(ar.raw_json_data, '$.releaseCountries[*]') = '[]'::jsonb THEN '{}'::TEXT[]
                 -- 如果路径存在且数组不为空，则提取并聚合为 TEXT[] 数组
                 ELSE (SELECT array_agg(elem)
                       FROM jsonb_array_elements_text( -- 将 JSONB 数组中的文本元素展开为行
                                jsonb_path_query_array(ar.raw_json_data, '$.releaseCountries[*]') -- 从 raw_json_data 中提取 releaseCountries 数组
                            ) AS x(elem)) -- 为展开的元素设置别名
             END
         FROM app_raw ar
         WHERE ar.app_id = ai.app_id -- 关联 app_info 的 app_id 和 app_raw 的 app_id
         ORDER BY ar.created_at DESC -- 按照创建时间降序排列，确保获取最新记录
         LIMIT 1), -- 只获取最新的一条记录
        ai.release_countries -- 如果子查询的结果是 NULL（即没有找到匹配的 app_raw 记录），则保留原值
    ),
    -- 更新 app_info 表中的 main_device_codes 字段
    main_device_codes = COALESCE(
        -- 子查询用于获取最新的 app_raw 记录中的 mainDeviceCodes 数据
        (SELECT
             CASE
                 -- 检查 jsonb_path_query_array 是否返回 NULL (即路径不存在)
                 WHEN jsonb_path_query_array(ar.raw_json_data, '$.mainDeviceCodes[*]') IS NULL THEN '{}'::TEXT[]
                 -- 检查 jsonb_path_query_array 是否返回空的 JSONB 数组 (即路径存在但数组为空)
                 WHEN jsonb_path_query_array(ar.raw_json_data, '$.mainDeviceCodes[*]') = '[]'::jsonb THEN '{}'::TEXT[]
                 -- 如果路径存在且数组不为空，则提取并聚合为 TEXT[] 数组
                 ELSE (SELECT array_agg(elem)
                       FROM jsonb_array_elements_text( -- 将 JSONB 数组中的文本元素展开为行
                                jsonb_path_query_array(ar.raw_json_data, '$.mainDeviceCodes[*]') -- 从 raw_json_data 中提取 mainDeviceCodes 数组
                            ) AS x(elem)) -- 为展开的元素设置别名
             END
         FROM app_raw ar
         WHERE ar.app_id = ai.app_id -- 关联 app_info 的 app_id 和 app_raw 的 app_id
         ORDER BY ar.created_at DESC -- 按照创建时间降序排列，确保获取最新记录
         LIMIT 1), -- 只获取最新的一条记录
        ai.main_device_codes -- 如果子查询的结果是 NULL，则保留原值
    )
WHERE
    -- 仅更新那些 release_countries 或 main_device_codes 字段当前为空数组的记录
    ai.release_countries = '{}' OR ai.main_device_codes = '{}';
