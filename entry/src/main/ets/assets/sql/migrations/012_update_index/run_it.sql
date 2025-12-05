-- Migration SQL Script to drop old indexes and create new, optimized ones

-- Start a transaction for atomicity
BEGIN;

-- ----------------------------------------------------------------------
-- 1. Dropping existing indexes that will be replaced or are less optimal
-- ----------------------------------------------------------------------

-- Drop existing single-column indexes on app_metrics.app_id and app_metrics.created_at
-- if they exist and are not part of other essential composite indexes
-- Note: 'idx_app_metrics_app_id' is on app_metrics(app_id)
-- Note: 'idx_app_metrics_download_count' is on app_metrics(download_count)
-- The new composite indexes will supersede these for relevant queries.

-- If you have a separate index just on app_metrics(app_id), consider dropping it
DROP INDEX IF EXISTS idx_app_metrics_app_id;

-- If you have a separate index just on app_rating(app_id), consider dropping it
DROP INDEX IF EXISTS idx_app_rating_app_id;

-- Drop the single-column download_count index as a more comprehensive one will be created
DROP INDEX IF EXISTS idx_app_metrics_download_count;

-- ----------------------------------------------------------------------
-- 2. Creating new, optimized composite indexes
-- ----------------------------------------------------------------------

-- Optimized index for app_metrics to support app_latest_info view's DISTINCT ON (app_id)
-- and common lookups by app_id ordered by creation time.
-- This helps in efficiently finding the latest metric for each app_id.
CREATE INDEX IF NOT EXISTS idx_app_metrics_app_id_created_at ON app_metrics (app_id, created_at DESC);

-- Optimized index for app_rating to support app_latest_info view's DISTINCT ON (app_id)
-- and common lookups by app_id ordered by creation time.
-- This helps in efficiently finding the latest rating for each app_id.
CREATE INDEX IF NOT EXISTS idx_app_rating_app_id_created_at ON app_rating (app_id, created_at DESC);

-- Optimized index for app_metrics to directly support the slow query's
-- ORDER BY download_count DESC, and also the app_id/created_at lookups within the view.
-- This index covers filtering by download_count, ordering by download_count,
-- and the unique latest record selection for app_id.
CREATE INDEX IF NOT EXISTS idx_app_metrics_download_count_app_id_created_at ON app_metrics (download_count DESC, app_id, created_at DESC);

-- ----------------------------------------------------------------------
-- 3. (Optional) Materialized View and its Index
-- ----------------------------------------------------------------------
-- If you decide to use a materialized view, you would replace your existing
-- app_latest_info VIEW with a MATERIALIZED VIEW.
-- This part is commented out as it requires more changes to your application code
-- (to query the MV instead of the VIEW) and a refresh strategy.

-- DROP VIEW IF EXISTS app_latest_info;
--
-- CREATE MATERIALIZED VIEW IF NOT EXISTS app_latest_info_mv AS
-- SELECT ai.app_id,
--    ai.alliance_app_id,
--    -- ... (all columns from your original view definition) ...
--    ar.full_average_rating,
--    ar.source_type,
--    am.created_at AS metrics_created_at,
--    ar.created_at AS rating_created_at
--   FROM app_info ai
--     LEFT JOIN ( SELECT DISTINCT ON (app_metrics.app_id) app_metrics.id,
--            app_metrics.app_id,
--            app_metrics.version,
--            -- ... (all app_metrics columns) ...
--            app_metrics.created_at,
--            app_metrics.info_score,
--            app_metrics.info_rate_count
--           FROM app_metrics
--          ORDER BY app_metrics.app_id, app_metrics.created_at DESC NULLS LAST) am ON ai.app_id = am.app_id
--     LEFT JOIN ( SELECT DISTINCT ON (app_rating.app_id) app_rating.id,
--            app_rating.app_id,
--            app_rating.average_rating,
--            -- ... (all app_rating columns) ...
--            app_rating.created_at
--           FROM app_rating
--          ORDER BY app_rating.app_id, app_rating.created_at DESC NULLS LAST) ar ON ai.app_id = ar.app_id;
--
-- -- Create an index on the materialized view for download_count ordering
-- CREATE INDEX IF NOT EXISTS idx_app_latest_info_mv_download_count ON app_latest_info_mv (download_count DESC);
--
-- -- You would then need to query app_latest_info_mv in your application
-- -- And set up a cron job or similar to run: REFRESH MATERIALIZED VIEW app_latest_info_mv;

-- Commit the transaction if all operations are successful
COMMIT;

ANALYZE;

-- Informational message
SELECT 'Migration script completed. Please check your database for new indexes and consider refreshing statistics.';
