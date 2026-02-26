-- Slim the database for cloud deployment by dropping tables only needed
-- for GTFS data processing (not needed at runtime).
--
-- IMPORTANT: Run pre_compute_geopaths.sql FIRST before running this script!
-- After running this, the database will be ~55MB instead of ~5.6GB.
--
-- Tables kept:   routes, stops, edges_v2, geopath, disruptions,
--                route_types, disruption_modes
-- Tables dropped: gtfs_* (raw source data), shapes, stop_trip_sequence,
--                 shape_lines (no longer used by API)

-- Verify geopath table has data before proceeding
DO $$
DECLARE
    geopath_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO geopath_count FROM geopath WHERE route_id < 20000;
    IF geopath_count < 10 THEN
        RAISE EXCEPTION 'ERROR: Only % rows in geopath table. Run pre_compute_geopaths.sql first!', geopath_count;
    END IF;
    RAISE NOTICE 'OK: geopath table has % pre-computed rows. Proceeding with slim.', geopath_count;
END $$;

-- Drop foreign key from geopath referencing routes before we touch routes
-- (geopath FK is kept, just noting it exists)

-- Drop raw GTFS tables (source data, no longer needed at runtime)
DROP TABLE IF EXISTS gtfs_stop_times CASCADE;   -- 2.6 GB
DROP TABLE IF EXISTS stop_trip_sequence CASCADE; -- 1.6 GB
DROP TABLE IF EXISTS gtfs_shapes CASCADE;        -- 696 MB
DROP TABLE IF EXISTS shapes CASCADE;             -- 655 MB
DROP TABLE IF EXISTS gtfs_trips CASCADE;         -- 75 MB
DROP TABLE IF EXISTS shape_lines CASCADE;        -- 26 MB (not used by API)
DROP TABLE IF EXISTS gtfs_stops CASCADE;         -- small
DROP TABLE IF EXISTS gtfs_routes CASCADE;        -- small

-- Drop PostGIS generated column from stops if needed for non-PostGIS deployments.
-- Supabase has PostGIS so this is optional there. Uncomment if deploying to a
-- service without PostGIS:
-- ALTER TABLE stops DROP COLUMN IF EXISTS geom;

-- Show final table sizes
SELECT
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) AS size
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC;
