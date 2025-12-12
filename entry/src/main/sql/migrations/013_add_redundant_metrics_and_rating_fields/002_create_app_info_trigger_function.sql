-- ----------------------------------------------------------------------
-- 002_create_app_info_trigger_function.sql
-- 创建 app_info 触发器函数
-- ----------------------------------------------------------------------
-- 执行时间：预计 1-2 分钟
-- 依赖：001_create_app_full_info_table.sql
-- 描述：创建触发器函数，在 app_info 表插入或更新时自动更新 app_full_info 表
-- ----------------------------------------------------------------------

BEGIN;

-- 创建更新 app_full_info 表中 app_info 基本信息的触发器函数
-- 支持 INSERT、UPDATE 操作
CREATE OR REPLACE FUNCTION update_app_full_info_from_app_info()
RETURNS TRIGGER AS $$
BEGIN
    -- 使用 INSERT ... ON CONFLICT ... DO UPDATE 语法
    -- 只同步基本信息，不包含冗余字段
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

-- 验证触发器函数是否创建成功
SELECT 
    proname AS function_name,
    pronargs AS argument_count,
    prorettype::regtype AS return_type
FROM pg_proc 
WHERE proname = 'update_app_full_info_from_app_info';

COMMIT;

-- 验证脚本执行结果
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'update_app_full_info_from_app_info'
    ) THEN
        RAISE NOTICE '✓ App Info 触发器函数 update_app_full_info_from_app_info 创建成功';
    ELSE
        RAISE EXCEPTION '✗ App Info 触发器函数创建失败';
    END IF;
END $$;