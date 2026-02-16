-- Remove replacement bus shapes from the shapes table
-- Replacement bus routes have distorted/bad geometry data

BEGIN;

-- Delete shapes that belong to replacement bus routes
DELETE FROM shapes
WHERE shape_id IN (
    SELECT DISTINCT t.shape_id
    FROM gtfs_trips t
    JOIN gtfs_routes gr ON gr.route_id = t.route_id
    WHERE gr.route_id LIKE '%-R:%'  -- Replacement bus routes
);

-- Also clean stop_trip_sequence table
DELETE FROM stop_trip_sequence
WHERE trip_id IN (
    SELECT trip_id
    FROM gtfs_trips t
    WHERE t.route_id LIKE '%-R:%'
);

COMMIT;

-- Verify results
SELECT COUNT(*) as remaining_shapes FROM shapes;
SELECT COUNT(*) as remaining_sequences FROM stop_trip_sequence;
