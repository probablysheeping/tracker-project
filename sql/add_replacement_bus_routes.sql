-- Add a boolean column to mark replacement bus routes
-- This allows the routing algorithm to distinguish between regular routes and replacement buses

BEGIN;

-- Add a column to identify replacement bus routes
ALTER TABLE routes ADD COLUMN IF NOT EXISTS is_replacement_bus BOOLEAN DEFAULT FALSE;

-- Mark routes that have replacement bus GTFS data (route_gtfs_id ending in -R)
-- by checking if corresponding -R route exists in GTFS
UPDATE routes r
SET is_replacement_bus = TRUE
WHERE EXISTS (
    SELECT 1 FROM gtfs_routes gr
    WHERE gr.route_id = 'aus:vic:vic-0' || r.route_gtfs_id || '-R:'
    AND gr.route_short_name = 'Replacement Bus'
);

COMMIT;

-- Verify the results
SELECT route_id, route_name, route_type, route_gtfs_id, is_replacement_bus
FROM routes
WHERE is_replacement_bus = TRUE
ORDER BY route_id;
