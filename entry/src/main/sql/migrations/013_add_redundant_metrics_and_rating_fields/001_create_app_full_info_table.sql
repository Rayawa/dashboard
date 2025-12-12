-- ----------------------------------------------------------------------
-- 001_create_app_full_info_table.sql
-- 创建 app_full_info 表
-- ----------------------------------------------------------------------
-- 执行时间：预计 1-2 分钟
-- 依赖：无
-- 描述：创建 app_full_info 表，包含 app_info、app_metrics、app_rating 三个表的所有字段
-- ----------------------------------------------------------------------

BEGIN;

-- 创建 app_full_info 表
CREATE TABLE IF NOT EXISTS app_full_info (
    -- 来自 app_info 表的基本信息字段
    app_id                  TEXT PRIMARY KEY REFERENCES app_info(app_id) ON DELETE CASCADE,     -- 应用唯一ID（如 C1164531384803416384）
    alliance_app_id         TEXT NOT NULL,        -- 联盟应用ID（如 1164531384803416384）
    name                    TEXT NOT NULL,        -- 应用名称（如 应用市场）
    pkg_name                TEXT NOT NULL UNIQUE, -- 应用包名（如 com.huawei.hmsapp.appgallery），添加了UNIQUE约束
    dev_id                  TEXT NOT NULL,        -- 开发者ID（如 260086000000068459）
    developer_name          TEXT NOT NULL,        -- 开发者名称（如 华为软件技术有限公司）
    dev_en_name             TEXT,                 -- 开发者英文名称（如 Huawei Software Technologies Co., Ltd.）
    supplier                TEXT,                 -- 供应商名称（如 华为软件技术有限公司）
    kind_id                 INTEGER NOT NULL,     -- 应用分类ID（如 10000000）
    kind_name               TEXT NOT NULL,        -- 应用分类名称（如 工具）
    tag_name                TEXT,                 -- 标签名称（如 工具）
    kind_type_id            INTEGER NOT NULL,     -- 类型ID（如 13）
    kind_type_name          TEXT NOT NULL,        -- 类型名称（如 应用）
    icon_url                TEXT NOT NULL,        -- 应用图标URL
    brief_desc              TEXT NOT NULL,        -- 简短描述（如 应用市场，点亮精彩生活）
    description             TEXT NOT NULL,        -- 应用详细描述
    privacy_url             TEXT NOT NULL,        -- 隐私政策链接
    ctype                   INTEGER NOT NULL,     -- 客户端类型（如 17）
    detail_id               TEXT NOT NULL,        -- 详情页ID（如 app|C1164531384803416384）
    app_level               INTEGER NOT NULL,     -- 应用等级（如 2）
    jocat_id                INTEGER NOT NULL,     -- 分类ID（如 10000000）
    iap                     BOOLEAN NOT NULL,     -- 是否含应用内购买（false=否）
    hms                     BOOLEAN NOT NULL,     -- 是否依赖HMS（false=否）
    tariff_type             TEXT NOT NULL,        -- 资费类型（如 免费/付费）
    packing_type            INTEGER NOT NULL,     -- 打包类型（如 4）
    order_app               BOOLEAN NOT NULL,     -- 是否预装应用（false）
    denpend_gms             BOOLEAN NOT NULL,     -- 是否依赖GMS（false=否）
    denpend_hms             BOOLEAN NOT NULL,     -- 是否依赖HMS（false=否）
    force_update            BOOLEAN NOT NULL,     -- 是否强制更新（false=否）
    img_tag                 TEXT NOT NULL,        -- 图片标签（如 1）
    is_pay                  BOOLEAN NOT NULL,     -- 是否付费（false=否）
    is_disciplined          BOOLEAN NOT NULL,     -- 是否合规（false=否）
    is_shelves              BOOLEAN NOT NULL,     -- 是否上架（true=是）
    submit_type             INTEGER NOT NULL,     -- 提交类型（0）
    delete_archive          BOOLEAN NOT NULL,     -- 是否删除归档（false=否）
    charging                BOOLEAN NOT NULL,     -- 是否收费（false=否）
    button_grey             BOOLEAN NOT NULL,     -- 按钮是否置灰（false=否）
    app_gift                BOOLEAN NOT NULL,     -- 是否有礼包（false=否）
    free_days               INTEGER NOT NULL,     -- 免费天数（0）
    pay_install_type        INTEGER NOT NULL,     -- 付费安装类型（0）
    comment                 JSONB,                -- 评论或注释数据（JSON格式）
    listed_at               TIMESTAMPTZ NOT NULL, -- 应用上架时间
    release_countries       TEXT[] NOT NULL DEFAULT '{}', -- 应用发布的国家/地区列表
    main_device_codes       TEXT[] NOT NULL DEFAULT '{}', -- 应用支持的主要设备类型
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(), -- 创建时间

    -- 来自 app_metrics 表的字段
    version                 TEXT,                             -- 版本号
    version_code            BIGINT,                           -- 版本代码
    size_bytes              BIGINT,                           -- 应用大小
    sha256                  TEXT,                             -- SHA256校验值
    info_score              NUMERIC(3,1),                     -- 信息评分
    info_rate_count         BIGINT,                           -- 信息评分人数
    download_count          BIGINT,                           -- 下载次数
    price                   NUMERIC(10,2),                    -- 价格
    release_date            BIGINT,                           -- 发布时间
    new_features            TEXT,                             -- 新功能描述
    upgrade_msg             TEXT,                             -- 升级提示
    target_sdk              INTEGER,                          -- 目标SDK版本
    minsdk                  INTEGER,                          -- 最低SDK版本
    compile_sdk_version     INTEGER,                          -- 编译SDK版本
    min_hmos_api_level      INTEGER,                          -- 最低鸿蒙API等级
    api_release_type        TEXT,                             -- API发布类型
    metrics_created_at      TIMESTAMPTZ,                      -- 指标数据创建时间

    -- 来自 app_rating 表的字段
    average_rating          NUMERIC(3,1),                     -- 平均评分
    star_1_rating_count     INTEGER,                          -- 1星评分数量
    star_2_rating_count     INTEGER,                          -- 2星评分数量
    star_3_rating_count     INTEGER,                          -- 3星评分数量
    star_4_rating_count     INTEGER,                          -- 4星评分数量
    star_5_rating_count     INTEGER,                          -- 5星评分数量
    my_star_rating          INTEGER,                          -- 我的评分
    total_star_rating_count INTEGER,                          -- 总评分数量
    only_star_count         INTEGER,                          -- 仅评分数量
    full_average_rating     NUMERIC(3,1),                     -- 完整平均评分
    source_type             TEXT,                             -- 评分来源类型
    rating_created_at       TIMESTAMPTZ,                      -- 评分数据创建时间

    -- app_record (备案信息) 字段将在 014 迁移中添加
    -- title                   TEXT,
    -- app_recordal_info       TEXT,
    -- recordal_entity_title   TEXT,
    -- recordal_entity_name    TEXT,

    -- 记录更新时间
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now() -- 最后更新时间
);
-- 添加表注释
COMMENT ON TABLE app_full_info IS '应用最新信息表 - 存储应用的基本信息、最新指标数据和最新评分数据的汇总';

-- 添加字段注释
COMMENT ON COLUMN app_full_info.app_id IS '应用唯一ID';
COMMENT ON COLUMN app_full_info.alliance_app_id IS '联盟应用ID';
COMMENT ON COLUMN app_full_info.name IS '应用名称';
COMMENT ON COLUMN app_full_info.pkg_name IS '应用包名，唯一约束';
COMMENT ON COLUMN app_full_info.dev_id IS '开发者ID';
COMMENT ON COLUMN app_full_info.developer_name IS '开发者名称';
COMMENT ON COLUMN app_full_info.dev_en_name IS '开发者英文名称';
COMMENT ON COLUMN app_full_info.supplier IS '供应商名称';
COMMENT ON COLUMN app_full_info.kind_id IS '应用分类ID';
COMMENT ON COLUMN app_full_info.kind_name IS '应用分类名称';
COMMENT ON COLUMN app_full_info.tag_name IS '标签名称';
COMMENT ON COLUMN app_full_info.kind_type_id IS '类型ID';
COMMENT ON COLUMN app_full_info.kind_type_name IS '类型名称';
COMMENT ON COLUMN app_full_info.icon_url IS '应用图标URL';
COMMENT ON COLUMN app_full_info.brief_desc IS '简短描述';
COMMENT ON COLUMN app_full_info.description IS '应用详细描述';
COMMENT ON COLUMN app_full_info.privacy_url IS '隐私政策链接';
COMMENT ON COLUMN app_full_info.ctype IS '客户端类型';
COMMENT ON COLUMN app_full_info.detail_id IS '详情页ID';
COMMENT ON COLUMN app_full_info.app_level IS '应用等级';
COMMENT ON COLUMN app_full_info.jocat_id IS '分类ID';
COMMENT ON COLUMN app_full_info.iap IS '是否含应用内购买';
COMMENT ON COLUMN app_full_info.hms IS '是否依赖HMS';
COMMENT ON COLUMN app_full_info.tariff_type IS '资费类型';
COMMENT ON COLUMN app_full_info.packing_type IS '打包类型';
COMMENT ON COLUMN app_full_info.order_app IS '是否预装应用';
COMMENT ON COLUMN app_full_info.denpend_gms IS '是否依赖GMS';
COMMENT ON COLUMN app_full_info.denpend_hms IS '是否依赖HMS';
COMMENT ON COLUMN app_full_info.force_update IS '是否强制更新';
COMMENT ON COLUMN app_full_info.img_tag IS '图片标签';
COMMENT ON COLUMN app_full_info.is_pay IS '是否付费';
COMMENT ON COLUMN app_full_info.is_disciplined IS '是否合规';
COMMENT ON COLUMN app_full_info.is_shelves IS '是否上架';
COMMENT ON COLUMN app_full_info.submit_type IS '提交类型';
COMMENT ON COLUMN app_full_info.delete_archive IS '是否删除归档';
COMMENT ON COLUMN app_full_info.charging IS '是否收费';
COMMENT ON COLUMN app_full_info.button_grey IS '按钮是否置灰';
COMMENT ON COLUMN app_full_info.app_gift IS '是否有礼包';
COMMENT ON COLUMN app_full_info.free_days IS '免费天数';
COMMENT ON COLUMN app_full_info.pay_install_type IS '付费安装类型';
COMMENT ON COLUMN app_full_info.comment IS '评论或注释数据（JSON格式）';
COMMENT ON COLUMN app_full_info.listed_at IS '应用上架时间';
COMMENT ON COLUMN app_full_info.release_countries IS '应用发布的国家/地区列表';
COMMENT ON COLUMN app_full_info.main_device_codes IS '应用支持的主要设备类型';
COMMENT ON COLUMN app_full_info.created_at IS '创建时间';
COMMENT ON COLUMN app_full_info.version IS '版本号';
COMMENT ON COLUMN app_full_info.version_code IS '版本代码';
COMMENT ON COLUMN app_full_info.size_bytes IS '应用大小';
COMMENT ON COLUMN app_full_info.sha256 IS 'SHA256校验值';
COMMENT ON COLUMN app_full_info.info_score IS '信息评分';
COMMENT ON COLUMN app_full_info.info_rate_count IS '信息评分人数';
COMMENT ON COLUMN app_full_info.download_count IS '下载次数';
COMMENT ON COLUMN app_full_info.price IS '价格';
COMMENT ON COLUMN app_full_info.release_date IS '发布时间';
COMMENT ON COLUMN app_full_info.new_features IS '新功能描述';
COMMENT ON COLUMN app_full_info.upgrade_msg IS '升级提示';
COMMENT ON COLUMN app_full_info.target_sdk IS '目标SDK版本';
COMMENT ON COLUMN app_full_info.minsdk IS '最低SDK版本';
COMMENT ON COLUMN app_full_info.compile_sdk_version IS '编译SDK版本';
COMMENT ON COLUMN app_full_info.min_hmos_api_level IS '最低鸿蒙API等级';
COMMENT ON COLUMN app_full_info.api_release_type IS 'API发布类型';
COMMENT ON COLUMN app_full_info.metrics_created_at IS '指标数据创建时间';
COMMENT ON COLUMN app_full_info.average_rating IS '平均评分';
COMMENT ON COLUMN app_full_info.star_1_rating_count IS '1星评分数量';
COMMENT ON COLUMN app_full_info.star_2_rating_count IS '2星评分数量';
COMMENT ON COLUMN app_full_info.star_3_rating_count IS '3星评分数量';
COMMENT ON COLUMN app_full_info.star_4_rating_count IS '4星评分数量';
COMMENT ON COLUMN app_full_info.star_5_rating_count IS '5星评分数量';
COMMENT ON COLUMN app_full_info.my_star_rating IS '我的评分';
COMMENT ON COLUMN app_full_info.total_star_rating_count IS '总评分数量';
COMMENT ON COLUMN app_full_info.only_star_count IS '仅评分数量';
COMMENT ON COLUMN app_full_info.full_average_rating IS '完整平均评分';
COMMENT ON COLUMN app_full_info.source_type IS '评分来源类型';
COMMENT ON COLUMN app_full_info.rating_created_at IS '评分数据创建时间';
COMMENT ON COLUMN app_full_info.updated_at IS '最后更新时间，用于监控数据同步';

-- 验证表是否创建成功
SELECT
    table_name,
    table_type
FROM information_schema.tables
WHERE table_name = 'app_full_info';

COMMIT;

-- 验证脚本执行结果
DO $$
BEGIN
    -- 检查表是否存在
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'app_full_info'
    ) THEN
        RAISE NOTICE '✓ app_full_info 表创建成功';
    ELSE
        RAISE EXCEPTION '✗ app_full_info 表创建失败';
    END IF;
END $$;
