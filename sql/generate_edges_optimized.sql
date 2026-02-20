-- Optimized edge generation for all transport modes
-- Uses explicit GTFS route ID matching to avoid slow cartesian products

-- Helper function
CREATE OR REPLACE FUNCTION gtfs_time_to_seconds(t text) RETURNS integer AS $$
DECLARE
    parts text[];
    h int; m int; s int;
BEGIN
    IF t IS NULL THEN RETURN NULL; END IF;
    parts := string_to_array(t, ':');
    h := parts[1]::int;
    m := parts[2]::int;
    s := parts[3]::int;
    RETURN h * 3600 + m * 60 + s;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Clear old edges
TRUNCATE edges_v2 RESTART IDENTITY CASCADE;

-- Generate route edges using pre-computed stops and gtfs route mapping
-- This approach is much faster because we join on exact route matches
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT ON (r.route_id, s1.stop_id, s2.stop_id)
    s1.stop_id AS source_stop,
    r.route_id AS source_route,
    s2.stop_id AS target_stop,
    r.route_id AS target_route,
    GREATEST(1, ABS(gtfs_time_to_seconds(st2.arrival_time) - gtfs_time_to_seconds(st1.arrival_time)) / 60.0) AS cost,
    COALESCE(ABS(st2.shape_dist_traveled - st1.shape_dist_traveled) / 1000, 0) AS distance_km,
    'route' AS edge_type,
    (s1.stop_id::bigint * 1000000000 + r.route_id::bigint) AS source_node,
    (s2.stop_id::bigint * 1000000000 + r.route_id::bigint) AS target_node
FROM routes r
-- Match to GTFS routes using exact format matching
JOIN gtfs_routes gr ON (
    gr.route_id = 'aus:vic:vic-0' || r.route_gtfs_id || ':'
    AND gr.route_id NOT LIKE '%-R:%'  -- Exclude replacement buses
)
JOIN gtfs_trips t ON t.route_id = gr.route_id
-- Get consecutive stop pairs from each trip
JOIN gtfs_stop_times st1 ON st1.trip_id = t.trip_id
JOIN gtfs_stop_times st2 ON st2.trip_id = t.trip_id AND st2.stop_sequence = st1.stop_sequence + 1
-- Match GTFS stops to our stops
JOIN gtfs_stops gs1 ON gs1.gtfs_stop_id = st1.stop_id
JOIN gtfs_stops gs2 ON gs2.gtfs_stop_id = st2.stop_id
JOIN stops s1 ON s1.gtfs_parent_station = COALESCE(gs1.parent_station, gs1.gtfs_stop_id)
JOIN stops s2 ON s2.gtfs_parent_station = COALESCE(gs2.parent_station, gs2.gtfs_stop_id)
WHERE st1.arrival_time IS NOT NULL
  AND st2.arrival_time IS NOT NULL
  AND s1.route_type = r.route_type  -- Ensure stop types match
  AND s2.route_type = r.route_type
ORDER BY r.route_id, s1.stop_id, s2.stop_id, cost;

-- Show route edge counts by type
SELECT
    r.route_type,
    CASE r.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
    END as type_name,
    COUNT(DISTINCT r.route_id) as route_count,
    COUNT(*) as edge_count
FROM edges_v2 e
JOIN routes r ON r.route_id = e.source_route
WHERE e.edge_type = 'route'
GROUP BY r.route_type
ORDER BY r.route_type;

-- Create hub edges for same-stop transfers between different routes
-- Direction 1: Hub → Route
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    s.stop_id,
    0,
    s.stop_id,
    r.route_id,
    2.5,
    0,
    'hub',
    (s.stop_id::bigint * 1000000000),
    (s.stop_id::bigint * 1000000000 + r.route_id::bigint)
FROM stops s
CROSS JOIN routes r
WHERE EXISTS (
    SELECT 1 FROM edges_v2 e
    WHERE (e.source_stop = s.stop_id OR e.target_stop = s.stop_id)
    AND e.source_route = r.route_id
    AND e.edge_type = 'route'
);

-- Direction 2: Route → Hub
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    s.stop_id,
    r.route_id,
    s.stop_id,
    0,
    2.5,
    0,
    'hub',
    (s.stop_id::bigint * 1000000000 + r.route_id::bigint),
    (s.stop_id::bigint * 1000000000)
FROM stops s
CROSS JOIN routes r
WHERE EXISTS (
    SELECT 1 FROM edges_v2 e
    WHERE (e.source_stop = s.stop_id OR e.target_stop = s.stop_id)
    AND e.source_route = r.route_id
    AND e.edge_type = 'route'
);

-- Final statistics
SELECT
    edge_type,
    COUNT(*) as edge_count,
    ROUND(AVG(cost)::numeric, 2) as avg_cost_minutes
FROM edges_v2
GROUP BY edge_type
ORDER BY edge_type;
