DROP VIEW IF EXISTS app_latest_info;

-- 更新 app_latest_info 视图以包含新增的 release_countries 和 main_device_codes 字段
CREATE OR REPLACE VIEW app_latest_info AS
SELECT ai.app_id,
   ai.alliance_app_id,
   ai.name,
   ai.pkg_name,                    -- 应用包名
   ai.dev_id,                      -- 开发者ID
   ai.developer_name,              -- 开发者名称
   ai.dev_en_name,                 -- 开发者英文名称
   ai.supplier,                    -- 供应商名称
   ai.kind_id,                     -- 应用分类ID
   ai.kind_name,                   -- 应用分类名称
   ai.tag_name,                    -- 标签名称
   ai.kind_type_id,                -- 类型ID
   ai.kind_type_name,              -- 类型名称
   ai.icon_url,                    -- 应用图标URL
   ai.brief_desc,                  -- 简短描述
   ai.description,                 -- 应用详细描述
   ai.privacy_url,                 -- 隐私政策链接
   ai.ctype,                       -- 客户端类型
   ai.detail_id,                   -- 详情页ID
   ai.app_level,                   -- 应用等级
   ai.jocat_id,                    -- 分类ID
   ai.iap,                         -- 是否含应用内购买
   ai.hms,                         -- 是否依赖HMS
   ai.tariff_type,                 -- 资费类型
   ai.packing_type,                -- 打包类型
   ai.order_app,                   -- 是否预装应用
   ai.denpend_gms,                 -- 是否依赖GMS
   ai.denpend_hms,                 -- 是否依赖HMS
   ai.force_update,                -- 是否强制更新
   ai.img_tag,                     -- 图片标签
   ai.is_pay,                      -- 是否付费
   ai.is_disciplined,              -- 是否合规
   ai.is_shelves,                  -- 是否上架
   ai.submit_type,                 -- 提交类型
   ai.delete_archive,              -- 是否删除归档
   ai.charging,                    -- 是否收费
   ai.button_grey,                 -- 按钮是否置灰
   ai.app_gift,                    -- 是否有礼包
   ai.free_days,                   -- 免费天数
   ai.pay_install_type,            -- 付费安装类型
   ai.comment,                     -- 评论或注释数据
   ai.listed_at,                   -- 上架时间
   ai.created_at,                  -- 创建时间
   ai.release_countries,           -- 新增：发布的国家/地区列表
   ai.main_device_codes,           -- 新增：支持的主要设备类型
   am.version,                     -- 版本号
   am.version_code,                -- 版本代码
   am.size_bytes,                  -- 应用大小（字节）
   am.sha256,                      -- 安装包SHA256校验值
   am.info_score,                  -- 信息评分
   am.info_rate_count,             -- 信息评分人数
   am.download_count,              -- 下载次数
   am.price,                       -- 价格
   am.release_date,                -- 发布时间
   am.new_features,                -- 新功能描述
   am.upgrade_msg,                 -- 升级提示
   am.target_sdk,
   am.minsdk,
   am.compile_sdk_version,
   am.min_hmos_api_level,
   am.api_release_type,
   ar.average_rating,
   ar.star_1_rating_count,
   ar.star_2_rating_count,
   ar.star_3_rating_count,
   ar.star_4_rating_count,
   ar.star_5_rating_count,
   ar.my_star_rating,
   ar.total_star_rating_count,
   ar.only_star_count,
   ar.full_average_rating,
   ar.source_type,
   am.created_at AS metrics_created_at,
   ar.created_at AS rating_created_at
  FROM app_info ai
    LEFT JOIN ( SELECT DISTINCT ON (app_metrics.app_id) app_metrics.id,
           app_metrics.app_id,
           app_metrics.version,
           app_metrics.version_code,
           app_metrics.size_bytes,
           app_metrics.sha256,
           app_metrics.download_count,
           app_metrics.price,
           app_metrics.release_date,
           app_metrics.new_features,
           app_metrics.upgrade_msg,
           app_metrics.target_sdk,
           app_metrics.minsdk,
           app_metrics.compile_sdk_version,
           app_metrics.min_hmos_api_level,
           app_metrics.api_release_type,
           app_metrics.created_at,
           app_metrics.info_score,
           app_metrics.info_rate_count
          FROM app_metrics
         ORDER BY app_metrics.app_id, app_metrics.created_at DESC NULLS LAST) am ON ai.app_id = am.app_id
    LEFT JOIN ( SELECT DISTINCT ON (app_rating.app_id) app_rating.id,
           app_rating.app_id,
           app_rating.average_rating,
           app_rating.star_1_rating_count,
           app_rating.star_2_rating_count,
           app_rating.star_3_rating_count,
           app_rating.star_4_rating_count,
           app_rating.star_5_rating_count,
           app_rating.my_star_rating,
           app_rating.total_star_rating_count,
           app_rating.only_star_count,
           app_rating.full_average_rating,
           app_rating.source_type,
           app_rating.created_at
          FROM app_rating
         ORDER BY app_rating.app_id, app_rating.created_at DESC NULLS LAST) ar ON ai.app_id = ar.app_id;
