CREATE TABLE app_info (
    app_id                  TEXT PRIMARY KEY,     -- 应用唯一ID（如 C1164531384803416384）
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

    created_at              TIMESTAMPTZ NOT NULL DEFAULT now() -- 创建时间 (爬取时间)
);

CREATE TABLE app_full_info (
    app_id                  TEXT PRIMARY KEY REFERENCES app_info(app_id) ON DELETE CASCADE,   -- 应用唯一ID（如 C1164531384803416384
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

    -- latest metrics
    version                 TEXT,                             -- 来自 app_metrics 表的版本号
    version_code            BIGINT,                           -- 来自 app_metrics 表的版本代码
    size_bytes              BIGINT,                           -- 来自 app_metrics 表的应用大小
    sha256                  TEXT,                             -- 来自 app_metrics 表的SHA256校验值
    info_score              NUMERIC(3,1),                     -- 来自 app_metrics 表的信息评分
    info_rate_count         BIGINT,                           -- 来自 app_metrics 表的信息评分人数
    download_count          BIGINT,                           -- 来自 app_metrics 表的下载次数
    price                   NUMERIC(10,2),                    -- 来自 app_metrics 表的价格
    release_date            BIGINT,                           -- 来自 app_metrics 表的发布时间
    new_features            TEXT,                             -- 来自 app_metrics 表的新功能描述
    upgrade_msg             TEXT,                             -- 来自 app_metrics 表的升级提示
    target_sdk              INTEGER,                          -- 来自 app_metrics 表的目标SDK版本
    minsdk                  INTEGER,                          -- 来自 app_metrics 表的最低SDK版本
    compile_sdk_version     INTEGER,                          -- 来自 app_metrics 表的编译SDK版本
    min_hmos_api_level      INTEGER,                          -- 来自 app_metrics 表的最低鸿蒙API等级
    api_release_type        TEXT,                             -- 来自 app_metrics 表的API发布类型
    metrics_created_at      TIMESTAMPTZ,                      -- 来自 app_metrics 表的创建时间

    -- latest rating
    average_rating          NUMERIC(3,1),                     -- 来自 app_rating 表的平均评分
    star_1_rating_count     INTEGER,                          -- 来自 app_rating 表的1星评分数量
    star_2_rating_count     INTEGER,                          -- 来自 app_rating 表的2星评分数量
    star_3_rating_count     INTEGER,                          -- 来自 app_rating 表的3星评分数量
    star_4_rating_count     INTEGER,                          -- 来自 app_rating 表的4星评分数量
    star_5_rating_count     INTEGER,                          -- 来自 app_rating 表的5星评分数量
    my_star_rating          INTEGER,                          -- 来自 app_rating 表的我的评分
    total_star_rating_count INTEGER,                          -- 来自 app_rating 表的总评分数量
    only_star_count         INTEGER,                          -- 来自 app_rating 表的仅评分数量
    full_average_rating     NUMERIC(3,1),                     -- 来自 app_rating 表的完整平均评分
    source_type             TEXT,                             -- 来自 app_rating 表的评分来源类型
    rating_created_at       TIMESTAMPTZ,                      -- 来自 app_rating 表的创建时间

    -- app_record (备案信息)
    title                   TEXT,                             -- 来自 app_record 表的标题，例如 "服务备案号"
    app_recordal_info       TEXT,                             -- 来自 app_record 表的备案号文本
    recordal_entity_title   TEXT,                             -- 来自 app_record 表的主办单位标题
    recordal_entity_name    TEXT,                             -- 来自 app_record 表的主办单位名称

    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(), -- 创建时间 (爬取时间)
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()  -- 最后更新时间，用于监控数据同步
);

CREATE TABLE app_metrics (
    id                  BIGSERIAL PRIMARY KEY,                      -- 主键ID
    app_id              TEXT NOT NULL REFERENCES app_info(app_id) ON DELETE CASCADE,  -- 对应 app_info 的 app_id
    pkg_name            TEXT NOT NULL REFERENCES app_info(pkg_name) ON DELETE CASCADE, -- 新增：对应 app_info 的 pkg_name，并建立外键
    version             TEXT NOT NULL,                              -- 版本号（如 6.3.2.302）
    version_code        BIGINT NOT NULL,                            -- 版本代码（如 1460302302）
    size_bytes          BIGINT NOT NULL,                            -- 应用大小（字节）（如 76591487）
    sha256              TEXT NOT NULL,                              -- 安装包SHA256校验值
    info_score          NUMERIC(3,1) NOT NULL,                      -- 信息评分（重命名自 hot_score）
    info_rate_count     BIGINT NOT NULL,                            -- 信息评分人数（重命名自 rate_num）
    download_count      BIGINT NOT NULL,                            -- 下载次数（如 14443706）
    price               NUMERIC(10,2) NOT NULL,                     -- 价格（如 0 表示免费）
    release_date        BIGINT NOT NULL,                            -- 发布时间（时间戳毫秒）
    new_features        TEXT NOT NULL,                              -- 新功能描述
    upgrade_msg         TEXT NOT NULL,                              -- 升级提示
    target_sdk          INTEGER NOT NULL,                           -- 目标SDK版本（如 18）
    minsdk              INTEGER NOT NULL,                           -- 最低SDK版本（如 13）
    compile_sdk_version INTEGER NOT NULL,                           -- 编译SDK版本（如 50100）
    min_hmos_api_level  INTEGER NOT NULL,                           -- 最低鸿蒙API等级（如 50001）
    api_release_type    TEXT NOT NULL,                              -- API发布类型（如 Release）
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()          -- 创建时间
);

CREATE TABLE app_rating (
    id                          BIGSERIAL PRIMARY KEY,                      -- 主键ID
    app_id                      TEXT NOT NULL REFERENCES app_info(app_id) ON DELETE CASCADE,  -- 对应 app_info 的 app_id
    pkg_name                    TEXT NOT NULL REFERENCES app_info(pkg_name) ON DELETE CASCADE, -- 新增：对应 app_info 的 pkg_name，并建立外键
    average_rating              NUMERIC(3,1) NOT NULL,                      -- 平均评分
    star_1_rating_count         INTEGER NOT NULL,                           -- 1星评分数量
    star_2_rating_count         INTEGER NOT NULL,                           -- 2星评分数量
    star_3_rating_count         INTEGER NOT NULL,                           -- 3星评分数量
    star_4_rating_count         INTEGER NOT NULL,                           -- 4星评分数量
    star_5_rating_count         INTEGER NOT NULL,                           -- 5星评分数量
    my_star_rating              INTEGER NOT NULL,                           -- 我的评分
    total_star_rating_count     INTEGER NOT NULL,                           -- 总评分数量
    only_star_count             INTEGER NOT NULL,                           -- 仅评分数量
    full_average_rating         NUMERIC(3,1) NOT NULL,                      -- 完整平均评分
    source_type                 TEXT NOT NULL,                              -- 评分来源类型
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now()          -- 创建时间
);

CREATE TABLE app_data_history (
    id              BIGSERIAL PRIMARY KEY,                     -- 主键ID
    app_id          TEXT NOT NULL REFERENCES app_info(app_id) ON DELETE CASCADE, -- 对应 app_info 的 app_id
    pkg_name        TEXT NOT NULL REFERENCES app_info(pkg_name) ON DELETE CASCADE, -- 对应 app_info 的 pkg_name
    raw_json_data   JSONB NOT NULL DEFAULT '{}'::JSONB,        -- 原始应用数据JSON
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()         -- 数据创建或记录时间
);

CREATE TABLE app_record (
    id                      BIGSERIAL PRIMARY KEY,                                       -- 主键ID
    app_id                  TEXT NOT NULL UNIQUE REFERENCES app_info(app_id) ON DELETE CASCADE, -- 对应 app_info 的 app_id
    title                   TEXT NOT NULL,                                               -- 标题，例如 "服务备案号"
    app_recordal_info       TEXT NOT NULL,                                               -- 备案号文本
    recordal_entity_title   TEXT NOT NULL,                                               -- 主办单位标题
    recordal_entity_name    TEXT NOT NULL,                                               -- 主办单位名称
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()                           -- 创建时间
);

CREATE TABLE substance_info (
    substance_id   TEXT PRIMARY KEY,
    title          TEXT NOT NULL,
    subtitle       TEXT,
    name           TEXT,
    comment        JSONB,                             -- 评论或注释数据（JSON格式）
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE substance_history (
    id                 BIGSERIAL PRIMARY KEY,
    substance_id       TEXT NOT NULL REFERENCES substance_info(substance_id) ON DELETE CASCADE,
    raw_json_substance JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE substance_app_map (
    substance_id   TEXT NOT NULL REFERENCES substance_info(substance_id) ON DELETE CASCADE,
    app_id         TEXT NOT NULL REFERENCES app_info(app_id) ON DELETE CASCADE,
    PRIMARY KEY (substance_id, app_id)
);
