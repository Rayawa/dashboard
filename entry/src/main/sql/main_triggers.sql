-- =============================================================================
-- main_triggers.sql
-- 主触发器和函数文件
-- =============================================================================
-- 描述：整合主库中与 app_full_info 冗余字段同步相关的触发器与函数
-- 组成：触发器函数（app_info、metrics、rating、record、listed_at）与对应触发器
-- 依赖：先执行表结构与冗余字段定义（参见 main.sql 与相关迁移）
-- 设计理念：
--   1. app_info 触发器负责创建和更新 app_full_info 的基本信息字段
--   2. metrics 触发器只更新 metrics 相关的冗余字段
--   3. rating 触发器只更新 rating 相关的冗余字段
--   4. record 触发器只更新 record 相关的冗余字段
--   5. listed_at 触发器维护应用的历史最早上架时间
-- =============================================================================

-- ============================================================================
-- 触发器函数：update_app_full_info_from_app_info
-- 功能：在 app_info 插入/更新时同步 app_full_info 中的基本信息字段
-- 职责：负责创建 app_full_info 记录并维护所有来自 app_info 的字段
-- ============================================================================
CREATE OR REPLACE FUNCTION update_app_full_info_from_app_info()
RETURNS TRIGGER AS $$
BEGIN
    -- 使用 INSERT ... ON CONFLICT ... DO UPDATE 语法
    -- 只同步基本信息，不包含冗余字段（metrics、rating）
    INSERT INTO app_full_info (
        app_id, alliance_app_id, name, pkg_name,
        dev_id, developer_name, dev_en_name,
        supplier, kind_id, kind_name,
        tag_name, kind_type_id, kind_type_name, icon_url,
        brief_desc, description, privacy_url, ctype,
        detail_id, app_level, jocat_id, iap, hms,
        tariff_type, packing_type, order_app, denpend_gms,
        denpend_hms, force_update, img_tag, is_pay,
        is_disciplined, is_shelves, submit_type, delete_archive,
        charging, button_grey, app_gift, free_days,
        pay_install_type, comment, listed_at, release_countries,
        main_device_codes, created_at, updated_at
    ) VALUES (
        NEW.app_id, NEW.alliance_app_id, NEW.name, NEW.pkg_name,
        NEW.dev_id, NEW.developer_name, NEW.dev_en_name,
        NEW.supplier, NEW.kind_id, NEW.kind_name,
        NEW.tag_name, NEW.kind_type_id, NEW.kind_type_name, NEW.icon_url,
        NEW.brief_desc, NEW.description, NEW.privacy_url, NEW.ctype,
        NEW.detail_id, NEW.app_level, NEW.jocat_id, NEW.iap, NEW.hms,
        NEW.tariff_type, NEW.packing_type, NEW.order_app, NEW.denpend_gms,
        NEW.denpend_hms, NEW.force_update, NEW.img_tag, NEW.is_pay,
        NEW.is_disciplined, NEW.is_shelves, NEW.submit_type, NEW.delete_archive,
        NEW.charging, NEW.button_grey, NEW.app_gift, NEW.free_days,
        NEW.pay_install_type, NEW.comment, NEW.listed_at, NEW.release_countries,
        NEW.main_device_codes, NEW.created_at, now()
    )
    ON CONFLICT (app_id) DO UPDATE SET
        alliance_app_id = EXCLUDED.alliance_app_id,
        name = EXCLUDED.name,
        pkg_name = EXCLUDED.pkg_name,
        dev_id = EXCLUDED.dev_id,
        developer_name = EXCLUDED.developer_name,
        dev_en_name = EXCLUDED.dev_en_name,
        supplier = EXCLUDED.supplier,
        kind_id = EXCLUDED.kind_id,
        kind_name = EXCLUDED.kind_name,
        tag_name = EXCLUDED.tag_name,
        kind_type_id = EXCLUDED.kind_type_id,
        kind_type_name = EXCLUDED.kind_type_name,
        icon_url = EXCLUDED.icon_url,
        brief_desc = EXCLUDED.brief_desc,
        description = EXCLUDED.description,
        privacy_url = EXCLUDED.privacy_url,
        ctype = EXCLUDED.ctype,
        detail_id = EXCLUDED.detail_id,
        app_level = EXCLUDED.app_level,
        jocat_id = EXCLUDED.jocat_id,
        iap = EXCLUDED.iap,
        hms = EXCLUDED.hms,
        tariff_type = EXCLUDED.tariff_type,
        packing_type = EXCLUDED.packing_type,
        order_app = EXCLUDED.order_app,
        denpend_gms = EXCLUDED.denpend_gms,
        denpend_hms = EXCLUDED.denpend_hms,
        force_update = EXCLUDED.force_update,
        img_tag = EXCLUDED.img_tag,
        is_pay = EXCLUDED.is_pay,
        is_disciplined = EXCLUDED.is_disciplined,
        is_shelves = EXCLUDED.is_shelves,
        submit_type = EXCLUDED.submit_type,
        delete_archive = EXCLUDED.delete_archive,
        charging = EXCLUDED.charging,
        button_grey = EXCLUDED.button_grey,
        app_gift = EXCLUDED.app_gift,
        free_days = EXCLUDED.free_days,
        pay_install_type = EXCLUDED.pay_install_type,
        comment = EXCLUDED.comment,
        listed_at = EXCLUDED.listed_at,
        release_countries = EXCLUDED.release_countries,
        main_device_codes = EXCLUDED.main_device_codes,
        created_at = EXCLUDED.created_at,
        updated_at = now();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 触发器函数：update_app_full_info_from_metrics
-- 功能：在 app_metrics 插入/更新/删除时同步 app_full_info 中的冗余指标字段
-- 职责：更新 metrics 相关字段，并在 INSERT 时维护 listed_at 最早时间
-- 前提：app_full_info 记录必须已存在（由 app_info 触发器创建）
-- ============================================================================
CREATE OR REPLACE FUNCTION update_app_full_info_from_metrics()
RETURNS TRIGGER AS $$
DECLARE
    target_app_id TEXT;
    latest_metric_id BIGINT;
    current_listed_at TIMESTAMPTZ;
    new_release_date TIMESTAMPTZ;
BEGIN
    IF TG_OP = 'DELETE' THEN
        target_app_id := OLD.app_id;
    ELSE
        target_app_id := NEW.app_id;
    END IF;

    SELECT id
    INTO latest_metric_id
    FROM app_metrics
    WHERE app_id = target_app_id
      AND (TG_OP != 'DELETE' OR id != OLD.id)
    ORDER BY created_at DESC NULLS LAST
    LIMIT 1;

    IF latest_metric_id IS NOT NULL THEN
        -- 有最新记录，更新 metrics 字段
        UPDATE app_full_info
        SET
            version = am.version,
            version_code = am.version_code,
            size_bytes = am.size_bytes,
            sha256 = am.sha256,
            info_score = am.info_score,
            info_rate_count = am.info_rate_count,
            download_count = am.download_count,
            price = am.price,
            release_date = am.release_date,
            new_features = am.new_features,
            upgrade_msg = am.upgrade_msg,
            target_sdk = am.target_sdk,
            minsdk = am.minsdk,
            compile_sdk_version = am.compile_sdk_version,
            min_hmos_api_level = am.min_hmos_api_level,
            api_release_type = am.api_release_type,
            metrics_created_at = am.created_at,
            updated_at = now()
        FROM app_metrics am
        WHERE app_full_info.app_id = am.app_id
          AND am.id = latest_metric_id;
    ELSE
        -- 没有记录，清空 metrics 字段
        UPDATE app_full_info
        SET
            version = NULL,
            version_code = NULL,
            size_bytes = NULL,
            sha256 = NULL,
            info_score = NULL,
            info_rate_count = NULL,
            download_count = NULL,
            price = NULL,
            release_date = NULL,
            new_features = NULL,
            upgrade_msg = NULL,
            target_sdk = NULL,
            minsdk = NULL,
            compile_sdk_version = NULL,
            min_hmos_api_level = NULL,
            api_release_type = NULL,
            metrics_created_at = NULL,
            updated_at = now()
        WHERE app_id = target_app_id;
    END IF;

    -- 在 INSERT 时，更新 listed_at 为历史最早时间
    IF TG_OP = 'INSERT' THEN
        SELECT listed_at
        INTO current_listed_at
        FROM app_full_info
        WHERE app_id = NEW.app_id;

        new_release_date := TO_TIMESTAMP(NEW.release_date / 1000);

        IF current_listed_at IS NULL OR new_release_date < current_listed_at THEN
            UPDATE app_full_info
            SET listed_at = new_release_date,
                updated_at = now()
            WHERE app_id = NEW.app_id;
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 触发器函数：update_app_full_info_from_rating
-- 功能：在 app_rating 插入/更新/删除时同步 app_full_info 中的冗余评分字段
-- 职责：只更新 rating 相关字段，不触及 app_info 基本字段
-- 前提：app_full_info 记录必须已存在（由 app_info 触发器创建）
-- ============================================================================
CREATE OR REPLACE FUNCTION update_app_full_info_from_rating()
RETURNS TRIGGER AS $$
DECLARE
    target_app_id TEXT;
    latest_rating_id BIGINT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        target_app_id := OLD.app_id;
    ELSE
        target_app_id := NEW.app_id;
    END IF;

    SELECT id
    INTO latest_rating_id
    FROM app_rating
    WHERE app_id = target_app_id
      AND (TG_OP != 'DELETE' OR id != OLD.id)
    ORDER BY created_at DESC NULLS LAST
    LIMIT 1;

    IF latest_rating_id IS NOT NULL THEN
        -- 有最新记录，更新 rating 字段
        UPDATE app_full_info
        SET
            average_rating = ar.average_rating,
            star_1_rating_count = ar.star_1_rating_count,
            star_2_rating_count = ar.star_2_rating_count,
            star_3_rating_count = ar.star_3_rating_count,
            star_4_rating_count = ar.star_4_rating_count,
            star_5_rating_count = ar.star_5_rating_count,
            my_star_rating = ar.my_star_rating,
            total_star_rating_count = ar.total_star_rating_count,
            only_star_count = ar.only_star_count,
            full_average_rating = ar.full_average_rating,
            source_type = ar.source_type,
            rating_created_at = ar.created_at,
            updated_at = now()
        FROM app_rating ar
        WHERE app_full_info.app_id = ar.app_id
          AND ar.id = latest_rating_id;
    ELSE
        -- 没有记录，清空 rating 字段
        UPDATE app_full_info
        SET
            average_rating = NULL,
            star_1_rating_count = NULL,
            star_2_rating_count = NULL,
            star_3_rating_count = NULL,
            star_4_rating_count = NULL,
            star_5_rating_count = NULL,
            my_star_rating = NULL,
            total_star_rating_count = NULL,
            only_star_count = NULL,
            full_average_rating = NULL,
            source_type = NULL,
            rating_created_at = NULL,
            updated_at = now()
        WHERE app_id = target_app_id;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 触发器：绑定触发器函数到对应的表
-- ============================================================================

-- 1. app_info 表触发器：同步基本信息
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_app_info ON app_info;
CREATE TRIGGER trg_update_app_full_info_from_app_info
AFTER INSERT OR UPDATE ON app_info
FOR EACH ROW
EXECUTE FUNCTION update_app_full_info_from_app_info();

-- 2. app_metrics 表触发器：同步 metrics 字段并维护 listed_at
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_metrics ON app_metrics;
DROP TRIGGER IF EXISTS trg_update_app_full_info_listed_at ON app_metrics;  -- 删除旧的独立 listed_at 触发器
CREATE TRIGGER trg_update_app_full_info_from_metrics
AFTER INSERT OR UPDATE OR DELETE ON app_metrics
FOR EACH ROW
EXECUTE FUNCTION update_app_full_info_from_metrics();

-- 3. app_rating 表触发器：同步 rating 字段
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_rating ON app_rating;
CREATE TRIGGER trg_update_app_full_info_from_rating
AFTER INSERT OR UPDATE OR DELETE ON app_rating
FOR EACH ROW
EXECUTE FUNCTION update_app_full_info_from_rating();

-- ============================================================================
-- 触发器函数：update_app_full_info_from_record
-- 功能：在 app_record 插入/更新/删除时同步 app_full_info 中的冗余备案字段
-- 职责：只更新 record 相关字段，不触及 app_info 基本字段
-- 前提：app_full_info 记录必须已存在（由 app_info 触发器创建）
-- ============================================================================
CREATE OR REPLACE FUNCTION update_app_full_info_from_record()
RETURNS TRIGGER AS $$
DECLARE
    target_app_id TEXT;
    latest_record_id BIGINT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        target_app_id := OLD.app_id;
    ELSE
        target_app_id := NEW.app_id;
    END IF;

    SELECT id
    INTO latest_record_id
    FROM app_record
    WHERE app_id = target_app_id
      AND (TG_OP != 'DELETE' OR id != OLD.id)
    ORDER BY created_at DESC NULLS LAST
    LIMIT 1;

    IF latest_record_id IS NOT NULL THEN
        -- 有最新记录，更新 record 字段
        UPDATE app_full_info
        SET
            title = ar.title,
            app_recordal_info = ar.app_recordal_info,
            recordal_entity_title = ar.recordal_entity_title,
            recordal_entity_name = ar.recordal_entity_name,
            updated_at = now()
        FROM app_record ar
        WHERE app_full_info.app_id = ar.app_id
          AND ar.id = latest_record_id;
    ELSE
        -- 没有记录，清空 record 字段
        UPDATE app_full_info
        SET
            title = NULL,
            app_recordal_info = NULL,
            recordal_entity_title = NULL,
            recordal_entity_name = NULL,
            updated_at = now()
        WHERE app_id = target_app_id;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 4. app_record 表触发器：同步 record 字段
DROP TRIGGER IF EXISTS trg_update_app_full_info_from_record ON app_record;
CREATE TRIGGER trg_update_app_full_info_from_record
AFTER INSERT OR UPDATE OR DELETE ON app_record
FOR EACH ROW
EXECUTE FUNCTION update_app_full_info_from_record();