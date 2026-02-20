-- Generate route edges for ALL transport modes (trains, trams, buses, V/Line)
-- This adapts the train edge generation script to work for all route types

-- Helper function to convert GTFS time to seconds (handles times > 24:00:00)
CREATE OR REPLACE FUNCTION gtfs_time_to_seconds(t text) RETURNS integer AS $$
DECLARE
    parts text[];
    h int;
    m int;
    s int;
BEGIN
    IF t IS NULL THEN
        RETURN NULL;
    END IF;
    parts := string_to_array(t, ':');
    h := parts[1]::int;
    m := parts[2]::int;
    s := parts[3]::int;
    RETURN h * 3600 + m * 60 + s;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Clear existing route edges (keep transfers we just created)
DELETE FROM edges_v2 WHERE edge_type IN ('route', 'hub');

-- Generate route edges for ALL route types
-- This uses the same logic as trains but works for trams, buses, V/Line
WITH trip_edges AS (
    SELECT
        r2.route_id,
        s1.stop_id AS source_stop,
        s2.stop_id AS target_stop,
        GREATEST(1, ABS(gtfs_time_to_seconds(arrival2) - gtfs_time_to_seconds(arrival1)) / 60.0) AS cost,
        ABS(dist2 - dist1) / 1000 AS distance_km,
        (s1.stop_id::bigint * 1000000000 + r2.route_id::bigint) AS source_node,
        (s2.stop_id::bigint * 1000000000 + r2.route_id::bigint) AS target_node
    FROM gtfs_routes gr
    JOIN gtfs_trips t ON t.route_id = gr.route_id
    -- Match GTFS routes to our routes table
    -- Format varies: trains use 'aus:vic:vic-02-ALM:', trams use 'aus:vic:vic-03-1:', buses vary
    JOIN routes r2 ON (
        gr.route_id LIKE '%' || r2.route_gtfs_id || '%'
        OR gr.route_id = 'aus:vic:vic-0' || r2.route_gtfs_id || ':'
    )
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
    ) st_with_next ON st_with_next.trip_id = t.trip_id
    -- Match stops using gtfs_parent_station
    JOIN stops s1 ON (
        s1.gtfs_parent_station = st_with_next.parent_station
        OR (st_with_next.parent_station IS NULL AND s1.gtfs_parent_station = '')
    )
    JOIN stops s2 ON (
        s2.gtfs_parent_station = st_with_next.next_parent_station
        OR (st_with_next.next_parent_station IS NULL AND s2.gtfs_parent_station = '')
    )
    WHERE gr.route_id NOT LIKE '%-R:%'  -- Exclude replacement buses
      AND st_with_next.next_parent_station IS NOT NULL
      AND st_with_next.arrival2 IS NOT NULL
      -- Filter out unrealistic edges (>50km between consecutive stops)
      AND (st_with_next.dist2 IS NULL OR st_with_next.dist1 IS NULL
           OR ABS(st_with_next.dist2 - st_with_next.dist1) / 1000 < 50)
      -- Ensure stops are from the same route type
      AND s1.route_type = s2.route_type
)
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT ON (route_id, source_stop, target_stop)
    source_stop,
    route_id AS source_route,
    target_stop,
    route_id AS target_route,
    cost,
    COALESCE(distance_km, 0) as distance_km,
    'route' AS edge_type,
    source_node,
    target_node
FROM trip_edges
ORDER BY route_id, source_stop, target_stop, cost;

-- Get count of inserted edges
DO $$
DECLARE
    route_edge_count int;
BEGIN
    SELECT COUNT(*) INTO route_edge_count FROM edges_v2 WHERE edge_type = 'route';
    RAISE NOTICE 'Inserted % route edges', route_edge_count;
END $$;

-- Create hub edges for transfers at each stop
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
JOIN gtfs_stops gs ON gs.parent_station = s.gtfs_parent_station OR (gs.parent_station IS NULL AND s.gtfs_parent_station = '')
JOIN gtfs_stop_times st ON st.stop_id = gs.gtfs_stop_id
JOIN gtfs_trips t ON t.trip_id = st.trip_id
JOIN gtfs_routes gr ON gr.route_id = t.route_id
JOIN routes r2 ON (
    gr.route_id LIKE '%' || r2.route_gtfs_id || '%'
    OR gr.route_id = 'aus:vic:vic-0' || r2.route_gtfs_id || ':'
)
WHERE gr.route_id NOT LIKE '%-R:%'  -- Exclude replacement bus routes
  AND s.route_type = r2.route_type;  -- Ensure route type matches

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
JOIN gtfs_stops gs ON gs.parent_station = s.gtfs_parent_station OR (gs.parent_station IS NULL AND s.gtfs_parent_station = '')
JOIN gtfs_stop_times st ON st.stop_id = gs.gtfs_stop_id
JOIN gtfs_trips t ON t.trip_id = st.trip_id
JOIN gtfs_routes gr ON gr.route_id = t.route_id
JOIN routes r2 ON (
    gr.route_id LIKE '%' || r2.route_gtfs_id || '%'
    OR gr.route_id = 'aus:vic:vic-0' || r2.route_gtfs_id || ':'
)
WHERE gr.route_id NOT LIKE '%-R:%'  -- Exclude replacement bus routes
  AND s.route_type = r2.route_type;  -- Ensure route type matches

-- Get count of hub edges
DO $$
DECLARE
    hub_edge_count int;
BEGIN
    SELECT COUNT(*) INTO hub_edge_count FROM edges_v2 WHERE edge_type = 'hub';
    RAISE NOTICE 'Inserted % hub edges', hub_edge_count;
END $$;

-- Show statistics by route type
SELECT
    r.route_type,
    CASE r.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
    END as type_name,
    COUNT(DISTINCT e.source_route) as route_count,
    COUNT(*) as edge_count
FROM edges_v2 e
JOIN routes r ON r.route_id = e.source_route
WHERE e.edge_type = 'route'
GROUP BY r.route_type
ORDER BY r.route_type;

-- Show overall statistics
SELECT
    edge_type,
    COUNT(*) as edge_count,
    ROUND(AVG(cost)::numeric, 2) as avg_cost_minutes,
    ROUND(AVG(distance_km)::numeric, 3) as avg_distance_km
FROM edges_v2
GROUP BY edge_type
ORDER BY edge_type;
