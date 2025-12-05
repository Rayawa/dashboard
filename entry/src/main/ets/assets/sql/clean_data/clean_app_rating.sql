DELETE FROM app_rating t1
USING app_rating t2
WHERE t1.id > t2.id -- t1 是较新的，t2 是较老的
  -- 比较所有业务字段
  AND t1.app_id = t2.app_id
  AND t1.average_rating = t2.average_rating
  AND t1.star_1_rating_count = t2.star_1_rating_count
  AND t1.star_2_rating_count = t2.star_2_rating_count
  AND t1.star_3_rating_count = t2.star_3_rating_count
  AND t1.star_4_rating_count = t2.star_4_rating_count
  AND t1.star_5_rating_count = t2.star_5_rating_count
  AND t1.my_star_rating = t2.my_star_rating
  AND t1.total_star_rating_count = t2.total_star_rating_count
  AND t1.only_star_count = t2.only_star_count
  AND t1.full_average_rating = t2.full_average_rating
  AND t1.source_type = t2.source_type
  AND t1.pkg_name = t2.pkg_name;

CREATE INDEX CONCURRENTLY idx_app_rating_dupe_hash
ON app_rating (
    md5(
        app_id ||
        average_rating::text ||
        star_1_rating_count::text ||
        star_2_rating_count::text ||
        star_3_rating_count::text ||
        star_4_rating_count::text ||
        star_5_rating_count::text ||
        my_star_rating::text ||
        total_star_rating_count::text ||
        only_star_count::text ||
        full_average_rating::text ||
        source_type ||
        pkg_name
    )
);

DELETE FROM app_rating t1
USING app_rating t2
WHERE
    -- 1. 匹配 App ID (缩小范围)
    t1.app_id = t2.app_id
    -- 2. t1 是需要删除的较新数据 (ID 更大)
    AND t1.id > t2.id
    -- 3. 利用刚才创建的索引进行哈希比对
    AND md5(
        t1.app_id ||
        t1.average_rating::text ||
        t1.star_1_rating_count::text ||
        t1.star_2_rating_count::text ||
        t1.star_3_rating_count::text ||
        t1.star_4_rating_count::text ||
        t1.star_5_rating_count::text ||
        t1.my_star_rating::text ||
        t1.total_star_rating_count::text ||
        t1.only_star_count::text ||
        t1.full_average_rating::text ||
        t1.source_type ||
        t1.pkg_name
    )
    =
    md5(
        t2.app_id ||
        t2.average_rating::text ||
        t2.star_1_rating_count::text ||
        t2.star_2_rating_count::text ||
        t2.star_3_rating_count::text ||
        t2.star_4_rating_count::text ||
        t2.star_5_rating_count::text ||
        t2.my_star_rating::text ||
        t2.total_star_rating_count::text ||
        t2.only_star_count::text ||
        t2.full_average_rating::text ||
        t2.source_type ||
        t2.pkg_name
    );

DROP INDEX idx_app_rating_dupe_hash;
VACUUM ANALYZE app_rating;