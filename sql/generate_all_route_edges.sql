-- Generate proximity-based transfer edges for pathfinding across all transport modes
-- Strategy:
-- 1. Keep existing route edges (trains, trams, etc.)
-- 2. Clear old hub transfer edges
-- 3. Create new proximity-based transfer edges between nearby stops

-- First, clear old hub transfer edges
DELETE FROM edges_v2 WHERE edge_type = 'transfer';

RAISE NOTICE 'Deleted old transfer edges';

-- Note: Route edges already exist from previous imports
-- We just need to create transfer edges between nearby stops

-- Create proximity-based transfer edges between stops of different route types
-- Stops within 500m can transfer between each other (3 minute transfer penalty)
-- For buses/trams which have many stops, use 200m threshold
INSERT INTO edges_v2 (source_stop, target_stop, source_node, target_node, source_route, target_route, cost, distance_km, edge_type)
SELECT DISTINCT
    s1.stop_id as source_stop,
    s2.stop_id as target_stop,
    (s1.stop_id::bigint * 1000000000) + r1.route_id as source_node,
    (s2.stop_id::bigint * 1000000000) + r2.route_id as target_node,
    r1.route_id as source_route,
    r2.route_id as target_route,
    CASE
        -- Longer transfer time for buses/trams (more walking between stops)
        WHEN s1.route_type IN (1, 2) OR s2.route_type IN (1, 2) THEN 4
        ELSE 3
    END as cost,
    6371 * 2 * ASIN(SQRT(
        POWER(SIN((RADIANS(s2.stop_latitude) - RADIANS(s1.stop_latitude)) / 2), 2) +
        COS(RADIANS(s1.stop_latitude)) * COS(RADIANS(s2.stop_latitude)) *
        POWER(SIN((RADIANS(s2.stop_longitude) - RADIANS(s1.stop_longitude)) / 2), 2)
    )) as distance_km,
    'transfer' as edge_type
FROM stops s1
CROSS JOIN stops s2
CROSS JOIN (SELECT DISTINCT source_route as route_id FROM edges_v2 WHERE edge_type = 'route') r1
CROSS JOIN (SELECT DISTINCT source_route as route_id FROM edges_v2 WHERE edge_type = 'route') r2
WHERE s1.stop_id < s2.stop_id  -- Avoid duplicates
AND (
    -- Train/V/Line to other modes: 500m
    (s1.route_type IN (0, 3) AND s2.route_type IN (0, 3) AND
     6371 * 2 * ASIN(SQRT(
        POWER(SIN((RADIANS(s2.stop_latitude) - RADIANS(s1.stop_latitude)) / 2), 2) +
        COS(RADIANS(s1.stop_latitude)) * COS(RADIANS(s2.stop_latitude)) *
        POWER(SIN((RADIANS(s2.stop_longitude) - RADIANS(s1.stop_longitude)) / 2), 2)
     )) <= 0.5)
    OR
    -- Tram/Bus to any mode: 200m (they have more stops, so closer transfers)
    ((s1.route_type IN (1, 2) OR s2.route_type IN (1, 2)) AND
     6371 * 2 * ASIN(SQRT(
        POWER(SIN((RADIANS(s2.stop_latitude) - RADIANS(s1.stop_latitude)) / 2), 2) +
        COS(RADIANS(s1.stop_latitude)) * COS(RADIANS(s2.stop_latitude)) *
        POWER(SIN((RADIANS(s2.stop_longitude) - RADIANS(s1.stop_longitude)) / 2), 2)
     )) <= 0.2)
)
ON CONFLICT DO NOTHING;

-- Show statistics
SELECT
    edge_type,
    COUNT(*) as edge_count
FROM edges_v2
GROUP BY edge_type
ORDER BY edge_type;

SELECT
    source_route,
    COUNT(*) as edge_count
FROM edges_v2
WHERE edge_type = 'route'
GROUP BY source_route
ORDER BY source_route
LIMIT 30;
