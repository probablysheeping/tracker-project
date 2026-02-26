-- Pre-compute route geopaths for all train, tram, and V/Line routes.
-- Stores simplified geometry in the 'geopath' table so the API can serve
-- route shapes without needing the large shapes/stop_trip_sequence tables.
--
-- Run this BEFORE running slim_database.sql.
-- Expected runtime: 5-15 minutes depending on hardware.

SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;

-- Remove existing pre-computed geopaths (keep coach routes 20001+)
DELETE FROM geopath WHERE route_id < 20000;

-- Step 1: Count actual shape points per shape_id (separate from trip counts)
-- Step 2: Find the best shape per route (most shape points = most detailed path)
-- Step 3: Decimate to ~1000 points per route for lightweight storage
WITH shape_point_counts AS (
    -- Count actual GPS points per shape_id
    SELECT shape_id, COUNT(*) AS pt_count
    FROM shapes
    GROUP BY shape_id
),
route_shapes AS (
    -- Get all (route_id, shape_id) pairs with actual point counts
    SELECT DISTINCT
        r.route_id,
        t.shape_id,
        spc.pt_count
    FROM routes r
    JOIN gtfs_routes gr ON (
        -- Trains: aus:vic:vic-02-{code}:
        (r.route_type = 0 AND gr.route_id = 'aus:vic:vic-02-' || REPLACE(r.route_gtfs_id, ':', '') || ':')
        -- Trams: aus:vic:vic-03-{code}:
        OR (r.route_type = 1 AND gr.route_id = 'aus:vic:vic-03-' || REPLACE(REPLACE(r.route_gtfs_id, '3-', ''), ':', '') || ':')
        -- V/Line: aus:vic:vic-01-{code}:
        OR (r.route_type = 3 AND gr.route_id = 'aus:vic:vic-01-' || REPLACE(REPLACE(r.route_gtfs_id, '1-', ''), ':', '') || ':')
    )
    JOIN gtfs_trips t ON t.route_id = gr.route_id
    JOIN shape_point_counts spc ON spc.shape_id = t.shape_id
    WHERE r.route_type IN (0, 1, 3)
      AND gr.route_id NOT LIKE '%-R:%'
),
best_shapes AS (
    -- Pick the shape with the most GPS points per route
    SELECT DISTINCT ON (route_id) route_id, shape_id, pt_count
    FROM route_shapes
    ORDER BY route_id, pt_count DESC
),
decimated AS (
    -- Decimate each shape to ~1000 points (preserving first and last)
    SELECT
        bs.route_id,
        s.shape_pt_lat,
        s.shape_pt_lon,
        s.shape_pt_sequence,
        ROW_NUMBER() OVER (PARTITION BY bs.route_id ORDER BY s.shape_pt_sequence) AS rn,
        bs.pt_count AS total_pts
    FROM best_shapes bs
    JOIN shapes s ON s.shape_id = bs.shape_id
)
INSERT INTO geopath (route_id, latitude, longitude)
SELECT route_id, shape_pt_lat, shape_pt_lon
FROM decimated
WHERE
    rn = 1                                         -- always keep first point
    OR rn = total_pts                              -- always keep last point
    OR rn % GREATEST(1, total_pts / 1000) = 0     -- ~1000 points per route
ORDER BY route_id, shape_pt_sequence;

-- Report what was inserted
SELECT
    r.route_name,
    r.route_type,
    COUNT(g.id) AS stored_points
FROM routes r
JOIN geopath g ON g.route_id = r.route_id
WHERE r.route_id < 20000
GROUP BY r.route_name, r.route_type
ORDER BY r.route_type, r.route_name;
