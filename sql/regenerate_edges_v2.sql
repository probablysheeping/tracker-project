-- Regenerate edges_v2 table with all routes serving each stop
-- This fixes the issue where stops served by multiple routes only have edges for one route

BEGIN;

-- Clear existing edges
TRUNCATE TABLE edges_v2 RESTART IDENTITY CASCADE;

-- Step 1: Create route edges
-- For each route, create edges between consecutive stops
-- Helper function to convert GTFS time to seconds (handles times > 24:00:00)
CREATE OR REPLACE FUNCTION gtfs_time_to_seconds(t text) RETURNS integer AS $$
DECLARE
    parts text[];
    h int;
    m int;
    s int;
BEGIN
    parts := string_to_array(t, ':');
    h := parts[1]::int;
    m := parts[2]::int;
    s := parts[3]::int;
    RETURN h * 3600 + m * 60 + s;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Use ALL trips (not just one) to capture all route patterns (e.g., City Loop vs Metro Tunnel)
WITH trip_edges AS (
    SELECT
        r2.route_id,
        s1.stop_id AS source_stop,
        s2.stop_id AS target_stop,
        ABS(gtfs_time_to_seconds(arrival2) - gtfs_time_to_seconds(arrival1)) / 60.0 AS cost,
        ABS(dist2 - dist1) / 1000 AS distance_km,
        (s1.stop_id::bigint * 1000000000 + r2.route_id::bigint) AS source_node,
        (s2.stop_id::bigint * 1000000000 + r2.route_id::bigint) AS target_node
    FROM gtfs_routes gr
    JOIN gtfs_trips t ON t.route_id = gr.route_id
    JOIN routes r2 ON gr.route_id = 'aus:vic:vic-0' || r2.route_gtfs_id || ':'
    JOIN (
        SELECT
            st.trip_id,
            gs.parent_station,
            st.arrival_time as arrival1,
            st.shape_dist_traveled as dist1,
            LEAD(gs.parent_station) OVER (PARTITION BY st.trip_id ORDER BY st.stop_sequence) as next_parent_station,
            LEAD(st.arrival_time) OVER (PARTITION BY st.trip_id ORDER BY st.stop_sequence) as arrival2,
            LEAD(st.shape_dist_traveled) OVER (PARTITION BY st.trip_id ORDER BY st.stop_sequence) as dist2
        FROM gtfs_stop_times st
        JOIN gtfs_stops gs ON gs.gtfs_stop_id = st.stop_id
        WHERE st.arrival_time IS NOT NULL
          AND st.shape_dist_traveled IS NOT NULL
    ) st_with_next ON st_with_next.trip_id = t.trip_id
    JOIN stops s1 ON s1.gtfs_parent_station = st_with_next.parent_station
    JOIN stops s2 ON s2.gtfs_parent_station = st_with_next.next_parent_station
    WHERE gr.route_id NOT LIKE '%-R:%'  -- Exclude replacement buses
      AND st_with_next.next_parent_station IS NOT NULL
      AND st_with_next.arrival2 IS NOT NULL
      AND st_with_next.dist2 IS NOT NULL
      AND ABS(st_with_next.dist2 - st_with_next.dist1) / 1000 < 15
)
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT ON (route_id, source_stop, target_stop)
    source_stop,
    route_id AS source_route,
    target_stop,
    route_id AS target_route,
    cost,
    distance_km,
    'route' AS edge_type,
    source_node,
    target_node
FROM trip_edges
ORDER BY route_id, source_stop, target_stop;

-- Step 2: Create hub edges (for transfers)
-- For each stop, create hub node (route_id = 0) that connects to all routes serving that stop
-- Hub edges must be BI-DIRECTIONAL to allow transfers
-- Transfer penalty: 2.5 minutes each way

-- Direction 1: Hub → Route (getting onto a route after transfer)
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    s.stop_id AS source_stop,
    0 AS source_route,  -- Hub node has route_id = 0
    s.stop_id AS target_stop,
    r2.route_id AS target_route,
    2.5 AS cost,  -- Transfer penalty: 2.5 minutes
    0 AS distance_km,
    'hub' AS edge_type,
    (s.stop_id::bigint * 1000000000) AS source_node,  -- Hub node
    (s.stop_id::bigint * 1000000000 + r2.route_id::bigint) AS target_node  -- Route-specific node
FROM stops s
JOIN gtfs_stops gs ON gs.parent_station = s.gtfs_parent_station
JOIN gtfs_stop_times st ON st.stop_id = gs.gtfs_stop_id
JOIN gtfs_trips t ON t.trip_id = st.trip_id
JOIN gtfs_routes gr ON gr.route_id = t.route_id
JOIN routes r2 ON (
    gr.route_id = 'aus:vic:vic-0' || r2.route_gtfs_id || ':'
)
WHERE gr.route_id NOT LIKE '%-R:%';  -- Exclude replacement bus routes

-- Direction 2: Route → Hub (leaving a route to transfer)
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    s.stop_id AS source_stop,
    r2.route_id AS source_route,  -- Route-specific node
    s.stop_id AS target_stop,
    0 AS target_route,  -- Hub node has route_id = 0
    2.5 AS cost,  -- Transfer penalty: 2.5 minutes
    0 AS distance_km,
    'hub' AS edge_type,
    (s.stop_id::bigint * 1000000000 + r2.route_id::bigint) AS source_node,  -- Route-specific node
    (s.stop_id::bigint * 1000000000) AS target_node  -- Hub node
FROM stops s
JOIN gtfs_stops gs ON gs.parent_station = s.gtfs_parent_station
JOIN gtfs_stop_times st ON st.stop_id = gs.gtfs_stop_id
JOIN gtfs_trips t ON t.trip_id = st.trip_id
JOIN gtfs_routes gr ON gr.route_id = t.route_id
JOIN routes r2 ON (
    gr.route_id = 'aus:vic:vic-0' || r2.route_gtfs_id || ':'
)
WHERE gr.route_id NOT LIKE '%-R:%';  -- Exclude replacement bus routes

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_edges_v2_source_node ON edges_v2(source_node);
CREATE INDEX IF NOT EXISTS idx_edges_v2_target_node ON edges_v2(target_node);
CREATE INDEX IF NOT EXISTS idx_edges_v2_source_target ON edges_v2(source_node, target_node);
CREATE INDEX IF NOT EXISTS idx_edges_v2_stops ON edges_v2(source_stop, target_stop);

COMMIT;

-- Verify the results
SELECT
    edge_type,
    COUNT(*) as edge_count,
    COUNT(DISTINCT source_route) as distinct_source_routes,
    COUNT(DISTINCT target_route) as distinct_target_routes
FROM edges_v2
GROUP BY edge_type;

-- Check that Malvern now has edges for multiple routes
SELECT DISTINCT
    CASE WHEN e.edge_type = 'hub' THEN 'hub' ELSE r.route_name END as route_name,
    e.edge_type,
    COUNT(*) as edge_count
FROM edges_v2 e
LEFT JOIN routes r ON r.route_id = e.source_route OR r.route_id = e.target_route
WHERE (e.source_stop = 1118 OR e.target_stop = 1118)
GROUP BY
    CASE WHEN e.edge_type = 'hub' THEN 'hub' ELSE r.route_name END,
    e.edge_type
ORDER BY e.edge_type, route_name;
