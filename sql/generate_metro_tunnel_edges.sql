-- Generate routing edges for Metro Tunnel pattern routes
-- This adds edges for routes that go via Metro Tunnel stations
-- (Arden, Parkville, State Library, Town Hall, Anzac)

-- Metro Tunnel station IDs (approximate - adjust based on actual data)
-- These are the key differentiating stops between Metro Tunnel and City Loop

-- First, let's identify Metro Tunnel routes by checking which trips pass through
-- Parkville Station (stop_id 1233) - a key Metro Tunnel station

-- Insert edges for Metro Tunnel variants of Sunbury line
-- Route pattern: Sunbury (Westall via Metro Tunnel), (Dandenong via Metro Tunnel), etc.

INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    e.source_stop,
    mt_route.route_id AS source_route,  -- Metro Tunnel variant route ID
    e.target_stop,
    mt_route.route_id AS target_route,
    e.cost,
    e.distance_km,
    'route' AS edge_type,
    (e.source_stop::bigint * 1000000000) + mt_route.route_id AS source_node,
    (e.target_stop::bigint * 1000000000) + mt_route.route_id AS target_node
FROM edges_v2 e
-- Join with base Sunbury route edges
JOIN (SELECT route_id FROM (VALUES (14)) AS t(route_id)) base_route ON e.source_route = base_route.route_id
-- Cross join with Metro Tunnel variant route IDs
CROSS JOIN (
    SELECT route_id FROM routes
    WHERE route_name ILIKE '%Sunbury%'
      AND route_name ILIKE '%Metro Tunnel%'
      AND route_id >= 14000
    LIMIT 10  -- Limit to avoid duplicates, pick representative Metro Tunnel routes
) mt_route
WHERE e.edge_type = 'route'
ON CONFLICT DO NOTHING;

-- Do the same for Frankston line (route 6)
-- Find Frankston Metro Tunnel patterns
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    e.source_stop,
    mt_route.route_id AS source_route,
    e.target_stop,
    mt_route.route_id AS target_route,
    e.cost,
    e.distance_km,
    'route' AS edge_type,
    (e.source_stop::bigint * 1000000000) + mt_route.route_id AS source_node,
    (e.target_stop::bigint * 1000000000) + mt_route.route_id AS target_node
FROM edges_v2 e
JOIN (SELECT route_id FROM (VALUES (6)) AS t(route_id)) base_route ON e.source_route = base_route.route_id
CROSS JOIN (
    SELECT DISTINCT route_id FROM routes
    WHERE route_name ILIKE '%Frankston%'
      AND (route_name ILIKE '%Pakenham%' OR route_name ILIKE '%Cranbourne%' OR route_name ILIKE '%Sunbury%')
      AND route_id >= 6000
      AND route_id < 7000
    LIMIT 20  -- Get representative cross-line routes (Frankston-Pakenham, Frankston-Sunbury via Metro Tunnel)
) mt_route
WHERE e.edge_type = 'route'
ON CONFLICT DO NOTHING;

-- Add hub edges for these new routes (to allow transfers)
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    stop_id AS source_stop,
    0 AS source_route,  -- Hub node
    stop_id AS target_stop,
    new_route.route_id AS target_route,
    2.5 AS cost,  -- Transfer penalty
    0.0 AS distance_km,
    'hub' AS edge_type,
    (stop_id::bigint * 1000000000) AS source_node,
    (stop_id::bigint * 1000000000) + new_route.route_id AS target_node
FROM stops
CROSS JOIN (
    SELECT DISTINCT source_route AS route_id
    FROM edges_v2
    WHERE source_route >= 14000 AND edge_type = 'route'
    UNION
    SELECT DISTINCT source_route AS route_id
    FROM edges_v2
    WHERE source_route >= 6100 AND source_route < 7000 AND edge_type = 'route'
) new_route
WHERE EXISTS (
    SELECT 1 FROM edges_v2
    WHERE (source_stop = stops.stop_id OR target_stop = stops.stop_id)
      AND source_route = new_route.route_id
)
ON CONFLICT DO NOTHING;

-- Bidirectional hub edges
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT
    target_stop AS source_stop,
    target_route AS source_route,
    source_stop AS target_stop,
    source_route AS target_route,
    cost,
    distance_km,
    edge_type,
    target_node AS source_node,
    source_node AS target_node
FROM edges_v2
WHERE edge_type = 'hub'
  AND (source_route >= 14000 OR (source_route >= 6100 AND source_route < 7000))
  AND NOT EXISTS (
      SELECT 1 FROM edges_v2 e2
      WHERE e2.source_node = edges_v2.target_node
        AND e2.target_node = edges_v2.source_node
  )
ON CONFLICT DO NOTHING;

-- Analysis
SELECT
    'Route edges added' AS description,
    COUNT(*) AS count
FROM edges_v2
WHERE edge_type = 'route'
  AND (source_route >= 14000 OR (source_route >= 6100 AND source_route < 7000))
UNION ALL
SELECT
    'Hub edges added',
    COUNT(*)
FROM edges_v2
WHERE edge_type = 'hub'
  AND (source_route >= 14000 OR target_route >= 14000 OR (source_route >= 6100 AND source_route < 7000));
