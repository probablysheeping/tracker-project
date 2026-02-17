-- Add Metro Tunnel Cross-Line Routes
-- This creates specific route patterns for Metro Tunnel services
-- and generates routing edges so trip planning can find them

-- Step 1: Insert Metro Tunnel route patterns into the routes table
-- Using IDs in the 50000 range to avoid conflicts

-- Frankston-Pakenham via Metro Tunnel (route 50001)
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour)
VALUES
    (50001, 'Frankston-Pakenham via Metro Tunnel', NULL, 0, '6',
     '{"RGB": [0, 155, 119]}'::jsonb)
ON CONFLICT (route_id) DO UPDATE SET route_name = EXCLUDED.route_name;

-- Frankston-Sunbury via Metro Tunnel (route 50002)
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour)
VALUES
    (50002, 'Frankston-Sunbury via Metro Tunnel', NULL, 0, '6',
     '{"RGB": [0, 155, 119]}'::jsonb)
ON CONFLICT (route_id) DO UPDATE SET route_name = EXCLUDED.route_name;

-- Cranbourne-Sunbury via Metro Tunnel (route 50003)
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour)
VALUES
    (50003, 'Cranbourne-Sunbury via Metro Tunnel', NULL, 0, '4',
     '{"RGB": [33, 174, 220]}'::jsonb)
ON CONFLICT (route_id) DO UPDATE SET route_name = EXCLUDED.route_name;

-- Pakenham-Sunbury via Metro Tunnel (route 50004)
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour)
VALUES
    (50004, 'Pakenham-Sunbury via Metro Tunnel', NULL, 0, '11',
     '{"RGB": [0, 155, 119]}'::jsonb)
ON CONFLICT (route_id) DO UPDATE SET route_name = EXCLUDED.route_name;

-- Step 2: Generate edges for these Metro Tunnel routes
-- For Frankston-Pakenham via Metro Tunnel, we use Frankston line edges south of city,
-- and Pakenham line edges north/east of city

-- Metro Tunnel station IDs
-- Arden: 1232, Parkville: 1233, State Library: 1234, Town Hall: 1235, Anzac: 1236

-- Frankston line edges (southern section, stops south of Flinders St)
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    source_stop,
    50001 AS source_route,  -- Frankston-Pakenham via Metro Tunnel
    target_stop,
    50001 AS target_route,
    cost,
    distance_km,
    'route' AS edge_type,
    (source_stop::bigint * 1000000000) + 50001 AS source_node,
    (target_stop::bigint * 1000000000) + 50001 AS target_node
FROM edges_v2
WHERE source_route = 6  -- Frankston line
  AND edge_type = 'route'
  AND source_stop NOT IN (1071, 1120, 1155, 1175, 1181)  -- Exclude City Loop stations
ON CONFLICT DO NOTHING;

-- Pakenham line edges (eastern section) for Frankston-Pakenham cross-line
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    source_stop,
    50001 AS source_route,
    target_stop,
    50001 AS target_route,
    cost,
    distance_km,
    'route' AS edge_type,
    (source_stop::bigint * 1000000000) + 50001 AS source_node,
    (target_stop::bigint * 1000000000) + 50001 AS target_node
FROM edges_v2
WHERE source_route = 11  -- Pakenham line
  AND edge_type = 'route'
  AND source_stop NOT IN (1071, 1120, 1155, 1175, 1181)  -- Exclude City Loop stations
ON CONFLICT DO NOTHING;

-- Add Metro Tunnel station connections for route 50001
-- Connect to Arden, Parkville, State Library, Town Hall, Anzac in sequence
-- Using approximate travel times between Metro Tunnel stations

-- South to Metro Tunnel: Richmond to Anzac
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT 1151, 50001, 1236, 50001, 2, 1.5, 'route',
       (1151::bigint * 1000000000) + 50001,
       (1236::bigint * 1000000000) + 50001
WHERE NOT EXISTS (SELECT 1 FROM edges_v2 WHERE source_node = (1151::bigint * 1000000000) + 50001 AND target_node = (1236::bigint * 1000000000) + 50001);

-- Anzac to Town Hall
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT 1236, 50001, 1235, 50001, 2, 0.8, 'route',
       (1236::bigint * 1000000000) + 50001,
       (1235::bigint * 1000000000) + 50001
WHERE NOT EXISTS (SELECT 1 FROM edges_v2 WHERE source_node = (1236::bigint * 1000000000) + 50001 AND target_node = (1235::bigint * 1000000000) + 50001);

-- Town Hall to State Library
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT 1235, 50001, 1234, 50001, 1, 0.5, 'route',
       (1235::bigint * 1000000000) + 50001,
       (1234::bigint * 1000000000) + 50001
WHERE NOT EXISTS (SELECT 1 FROM edges_v2 WHERE source_node = (1235::bigint * 1000000000) + 50001 AND target_node = (1234::bigint * 1000000000) + 50001);

-- State Library to Parkville
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT 1234, 50001, 1233, 50001, 2, 1.2, 'route',
       (1234::bigint * 1000000000) + 50001,
       (1233::bigint * 1000000000) + 50001
WHERE NOT EXISTS (SELECT 1 FROM edges_v2 WHERE source_node = (1234::bigint * 1000000000) + 50001 AND target_node = (1233::bigint * 1000000000) + 50001);

-- Parkville to Arden
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT 1233, 50001, 1232, 50001, 2, 1.0, 'route',
       (1233::bigint * 1000000000) + 50001,
       (1232::bigint * 1000000000) + 50001
WHERE NOT EXISTS (SELECT 1 FROM edges_v2 WHERE source_node = (1233::bigint * 1000000000) + 50001 AND target_node = (1232::bigint * 1000000000) + 50001);

-- Arden to North Melbourne (connection to Pakenham line)
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT 1232, 50001, 1104, 50001, 2, 1.5, 'route',
       (1232::bigint * 1000000000) + 50001,
       (1104::bigint * 1000000000) + 50001
WHERE NOT EXISTS (SELECT 1 FROM edges_v2 WHERE source_node = (1232::bigint * 1000000000) + 50001 AND target_node = (1104::bigint * 1000000000) + 50001);

-- Bidirectional edges for Metro Tunnel
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT target_stop, target_route, source_stop, source_route, cost, distance_km, edge_type, target_node, source_node
FROM edges_v2
WHERE source_route = 50001
  AND edge_type = 'route'
  AND NOT EXISTS (
      SELECT 1 FROM edges_v2 e2
      WHERE e2.source_node = edges_v2.target_node
        AND e2.target_node = edges_v2.source_node
  )
ON CONFLICT DO NOTHING;

-- Step 3: Add hub edges for Metro Tunnel routes
-- Allow transfers to/from Metro Tunnel routes at all stops

INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT DISTINCT
    source_stop,
    0 AS source_route,  -- Hub
    source_stop AS target_stop,
    50001 AS target_route,
    2.5 AS cost,
    0.0 AS distance_km,
    'hub' AS edge_type,
    (source_stop::bigint * 1000000000) AS source_node,
    (source_stop::bigint * 1000000000) + 50001 AS target_node
FROM edges_v2
WHERE source_route = 50001 AND edge_type = 'route'
ON CONFLICT DO NOTHING;

-- Bidirectional hub edges
INSERT INTO edges_v2 (source_stop, source_route, target_stop, target_route, cost, distance_km, edge_type, source_node, target_node)
SELECT target_stop, target_route, source_stop, source_route, cost, distance_km, edge_type, target_node, source_node
FROM edges_v2
WHERE target_route = 50001 AND edge_type = 'hub'
  AND NOT EXISTS (
      SELECT 1 FROM edges_v2 e2
      WHERE e2.source_node = edges_v2.target_node
        AND e2.target_node = edges_v2.source_node
  )
ON CONFLICT DO NOTHING;

-- Step 4: Verify results
SELECT
    'Metro Tunnel routes added' AS description,
    COUNT(*) AS count
FROM routes
WHERE route_id >= 50001 AND route_id <= 50004
UNION ALL
SELECT
    'Route edges for Metro Tunnel cross-lines',
    COUNT(*)
FROM edges_v2
WHERE source_route IN (50001, 50002, 50003, 50004) AND edge_type = 'route'
UNION ALL
SELECT
    'Hub edges for Metro Tunnel cross-lines',
    COUNT(*)
FROM edges_v2
WHERE (source_route IN (50001, 50002, 50003, 50004) OR target_route IN (50001, 50002, 50003, 50004))
  AND edge_type = 'hub';

-- Show sample edges
SELECT 'Sample Metro Tunnel edges:' AS info;
SELECT
    s1.stop_name AS from_stop,
    s2.stop_name AS to_stop,
    e.cost,
    e.edge_type
FROM edges_v2 e
JOIN stops s1 ON e.source_stop = s1.stop_id
JOIN stops s2 ON e.target_stop = s2.stop_id
WHERE e.source_route = 50001
ORDER BY e.id
LIMIT 15;
