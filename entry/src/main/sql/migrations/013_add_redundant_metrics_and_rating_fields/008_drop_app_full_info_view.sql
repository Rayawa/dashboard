
BEGIN;

DO $$
DECLARE
    view_existed BOOLEAN := FALSE;
BEGIN
    -- 目标视图名已改为 app_latest_info（与迁移说明一致）
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.views
        WHERE table_schema = current_schema()
          AND table_name = 'app_latest_info'
    ) INTO view_existed;

    IF view_existed THEN
        EXECUTE 'DROP VIEW IF EXISTS app_latest_info';
        RAISE NOTICE '成功删除 app_latest_info 视图';
    ELSE
        RAISE NOTICE 'app_latest_info 视图不存在，无需删除';
    END IF;
END $$;

COMMIT;
