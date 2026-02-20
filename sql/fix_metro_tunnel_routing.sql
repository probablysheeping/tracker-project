-- Fix Metro Tunnel Routing
-- This script generates routing edges for Metro Tunnel pattern routes
-- so trip planning can find routes via Metro Tunnel in addition to City Loop

-- Step 1: Identify all Metro Tunnel pattern routes
-- These are routes that include "Metro Tunnel" in their name
DROP TABLE IF EXISTS metro_tunnel_routes;
CREATE TEMP TABLE metro_tunnel_routes AS
SELECT DISTINCT route_id, route_name
FROM routes
WHERE route_name ILIKE '%Metro Tunnel%'
ORDER BY route_id;

-- Step 2: Identify base routes that have Metro Tunnel variants
-- Extract the base route ID from the pattern route ID (e.g., 14173 -> 14)
DROP TABLE IF EXISTS base_to_pattern_mapping;
CREATE TEMP TABLE base_to_pattern_mapping AS
SELECT DISTINCT
    CASE
        WHEN route_id >= 14000 AND route_id < 15000 THEN 14  -- Sunbury
        WHEN route_id >= 11000 AND route_id < 12000 THEN 11  -- Pakenham
        WHEN route_id >= 6100 AND route_id < 7000 THEN 6     -- Frankston (cross-line)
        WHEN route_id >= 16000 AND route_id < 17000 THEN 16  -- Werribee (cross-line)
        WHEN route_id >= 17000 AND route_id < 18000 THEN 17  -- Williamstown (cross-line)
        WHEN route_id >= 1000 AND route_id < 2000 THEN 1     -- Alamein
        WHEN route_id >= 2000 AND route_id < 3000 THEN 2     -- Belgrave
        WHEN route_id >= 3000 AND route_id < 4000 THEN 3     -- Craigieburn
        WHEN route_id >= 4000 AND route_id < 5000 THEN 4     -- Cranbourne
        WHEN route_id >= 7000 AND route_id < 8000 THEN 7     -- Glen Waverley
        WHEN route_id >= 8000 AND route_id < 9000 THEN 8     -- Hurstbridge
        WHEN route_id >= 9000 AND route_id < 10000 THEN 9    -- Lilydale
        WHEN route_id >= 12000 AND route_id < 13000 THEN 12  -- Sandringham
        WHEN route_id >= 15000 AND route_id < 16000 THEN 15  -- Upfield
        ELSE NULL
    END AS base_route_id,
    route_id AS pattern_route_id,
    route_name
FROM metro_tunnel_routes
WHERE route_id >= 1000;

-- Step 3: Generate route edges for Metro Tunnel patterns
-- Copy edges from base routes and assign them to pattern route IDs
INSERT INTO edges_v2 (
    source_stop, source_route, target_stop, target_route,
    cost, distance_km, edge_type, source_node, target_node
)
SELECT DISTINCT
    e.source_stop,
    m.pattern_route_id AS source_route,
    e.target_stop,
    m.pattern_route_id AS target_route,
    e.cost,
    e.distance_km,
    'route' AS edge_type,
    (e.source_stop::bigint * 1000000000) + m.pattern_route_id AS source_node,
    (e.target_stop::bigint * 1000000000) + m.pattern_route_id AS target_node
FROM edges_v2 e
JOIN base_to_pattern_mapping m ON e.source_route = m.base_route_id
WHERE e.edge_type = 'route'
  AND m.pattern_route_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- Step 4: Generate hub edges for Metro Tunnel routes
-- These allow transfers between routes at the same station
INSERT INTO edges_v2 (
    source_stop, source_route, target_stop, target_route,
    cost, distance_km, edge_type, source_node, target_node
)
SELECT DISTINCT
    source_stop,
    0 AS source_route,  -- Hub indicator
    target_stop,
    pattern_route_id AS target_route,
    2.5 AS cost,  -- Transfer penalty
    0.0 AS distance_km,
    'hub' AS edge_type,
    (source_stop::bigint * 1000000000) AS source_node,
    (target_stop::bigint * 1000000000) + pattern_route_id AS target_node
FROM (
    SELECT DISTINCT e.source_stop, e.source_stop AS target_stop, e.source_route AS pattern_route_id
    FROM edges_v2 e
    WHERE e.source_route IN (SELECT pattern_route_id FROM base_to_pattern_mapping)
      AND e.edge_type = 'route'
    UNION
    SELECT DISTINCT e.target_stop AS source_stop, e.target_stop AS target_stop, e.target_route AS pattern_route_id
    FROM edges_v2 e
    WHERE e.target_route IN (SELECT pattern_route_id FROM base_to_pattern_mapping)
      AND e.edge_type = 'route'
) stops_with_patterns
ON CONFLICT DO NOTHING;

-- Bidirectional hub edges
INSERT INTO edges_v2 (
    source_stop, source_route, target_stop, target_route,
    cost, distance_km, edge_type, source_node, target_node
)
SELECT DISTINCT
    target_stop AS source_stop,
    target_route AS source_route,
    source_stop AS target_stop,
    0 AS target_route,
    cost,
    distance_km,
    edge_type,
    target_node AS source_node,
    (source_stop::bigint * 1000000000) AS target_node
FROM edges_v2
WHERE edge_type = 'hub'
  AND source_route = 0
  AND target_route IN (SELECT pattern_route_id FROM base_to_pattern_mapping)
  AND NOT EXISTS (
      SELECT 1 FROM edges_v2 e2
      WHERE e2.source_stop = edges_v2.target_stop
        AND e2.source_route = edges_v2.target_route
        AND e2.target_stop = edges_v2.source_stop
        AND e2.target_route = 0
  )
ON CONFLICT DO NOTHING;

-- Step 5: Analyze results
SELECT
    'Metro Tunnel patterns identified' AS metric,
    COUNT(*) AS value
FROM metro_tunnel_routes
UNION ALL
SELECT
    'Base route mappings created',
    COUNT(DISTINCT base_route_id)
FROM base_to_pattern_mapping
WHERE base_route_id IS NOT NULL
UNION ALL
SELECT
    'Route edges created for patterns',
    COUNT(*)
FROM edges_v2
WHERE edge_type = 'route'
  AND source_route IN (SELECT pattern_route_id FROM base_to_pattern_mapping)
UNION ALL
SELECT
    'Hub edges created for patterns',
    COUNT(*)
FROM edges_v2
WHERE edge_type = 'hub'
  AND (source_route IN (SELECT pattern_route_id FROM base_to_pattern_mapping)
       OR target_route IN (SELECT pattern_route_id FROM base_to_pattern_mapping));

-- Verify specific Metro Tunnel routes have edges
SELECT
    r.route_id,
    r.route_name,
    COUNT(e.id) AS edge_count
FROM metro_tunnel_routes r
LEFT JOIN edges_v2 e ON (e.source_route = r.route_id OR e.target_route = r.route_id)
WHERE e.edge_type = 'route'
GROUP BY r.route_id, r.route_name
ORDER BY r.route_id
LIMIT 20;
