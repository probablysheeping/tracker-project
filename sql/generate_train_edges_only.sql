-- Generate edges ONLY for trains first (fast test)
-- This is a simplified version to verify the approach works

SET work_mem = '2GB';
SET maintenance_work_mem = '8GB';
SET max_parallel_workers_per_gather = 8;

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

-- Generate route edges ONLY for trains (route_type = 0)
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
JOIN gtfs_routes gr ON gr.route_id = 'aus:vic:vic-0' || r.route_gtfs_id || ':'
JOIN gtfs_trips t ON t.route_id = gr.route_id
JOIN gtfs_stop_times st1 ON st1.trip_id = t.trip_id
JOIN gtfs_stop_times st2 ON st2.trip_id = t.trip_id AND st2.stop_sequence = st1.stop_sequence + 1
JOIN gtfs_stops gs1 ON gs1.gtfs_stop_id = st1.stop_id
JOIN gtfs_stops gs2 ON gs2.gtfs_stop_id = st2.stop_id
JOIN stops s1 ON s1.gtfs_parent_station = COALESCE(gs1.parent_station, gs1.gtfs_stop_id)
JOIN stops s2 ON s2.gtfs_parent_station = COALESCE(gs2.parent_station, gs2.gtfs_stop_id)
WHERE r.route_type = 0  -- ONLY TRAINS
  AND gr.route_id NOT LIKE '%-R:%'
  AND st1.arrival_time IS NOT NULL
  AND st2.arrival_time IS NOT NULL
  AND s1.route_type = 0
  AND s2.route_type = 0
ORDER BY r.route_id, s1.stop_id, s2.stop_id, cost;

-- Hub edges for trains
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    s.stop_id, 0, s.stop_id, r.route_id, 2.5, 0, 'hub',
    (s.stop_id::bigint * 1000000000),
    (s.stop_id::bigint * 1000000000 + r.route_id::bigint)
FROM stops s
CROSS JOIN routes r
WHERE s.route_type = 0 AND r.route_type = 0
  AND EXISTS (
    SELECT 1 FROM edges_v2 e
    WHERE (e.source_stop = s.stop_id OR e.target_stop = s.stop_id)
    AND e.source_route = r.route_id AND e.edge_type = 'route'
);

INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    s.stop_id, r.route_id, s.stop_id, 0, 2.5, 0, 'hub',
    (s.stop_id::bigint * 1000000000 + r.route_id::bigint),
    (s.stop_id::bigint * 1000000000)
FROM stops s
CROSS JOIN routes r
WHERE s.route_type = 0 AND r.route_type = 0
  AND EXISTS (
    SELECT 1 FROM edges_v2 e
    WHERE (e.source_stop = s.stop_id OR e.target_stop = s.stop_id)
    AND e.source_route = r.route_id AND e.edge_type = 'route'
);

-- Now add proximity transfers (existing script)
\i 'C:/Users/edw37/OneDrive/Documents/CS/create_proximity_transfers.sql'

-- Statistics
SELECT edge_type, COUNT(*) as count, ROUND(AVG(cost)::numeric, 2) as avg_cost
FROM edges_v2
GROUP BY edge_type ORDER BY edge_type;
