-- Check current edge status in database
-- This will show if we have edges for different transport modes

-- 1. Count edges by type
SELECT
    edge_type,
    COUNT(*) as count
FROM edges_v2
GROUP BY edge_type
ORDER BY edge_type;

-- 2. Count route edges by route type
SELECT
    r.route_type,
    CASE r.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        ELSE 'Other'
    END as mode,
    COUNT(DISTINCT r.route_id) as num_routes,
    COUNT(e.id) as num_edges
FROM routes r
LEFT JOIN edges_v2 e ON e.source_route = r.route_id AND e.edge_type = 'route'
GROUP BY r.route_type
ORDER BY r.route_type;

-- 3. Check for tram-specific edges (route_type = 1)
SELECT
    COUNT(DISTINCT e.source_route) as tram_routes_with_edges,
    COUNT(*) as total_tram_edges
FROM edges_v2 e
JOIN routes r ON r.route_id = e.source_route
WHERE r.route_type = 1
  AND e.edge_type = 'route';

-- 4. Check for cross-modal transfer edges (tram to train)
SELECT
    CASE
        WHEN r1.route_type = 1 AND r2.route_type = 0 THEN 'Tram -> Train'
        WHEN r1.route_type = 0 AND r2.route_type = 1 THEN 'Train -> Tram'
        WHEN r1.route_type = 1 AND r2.route_type = 3 THEN 'Tram -> V/Line'
        WHEN r1.route_type = 3 AND r2.route_type = 1 THEN 'V/Line -> Tram'
        WHEN r1.route_type = 0 AND r2.route_type = 3 THEN 'Train -> V/Line'
        WHEN r1.route_type = 3 AND r2.route_type = 0 THEN 'V/Line -> Train'
        ELSE 'Other'
    END as transfer_type,
    COUNT(*) as count
FROM edges_v2 e
LEFT JOIN routes r1 ON r1.route_id = e.source_route
LEFT JOIN routes r2 ON r2.route_id = e.target_route
WHERE e.edge_type IN ('transfer', 'hub')
  AND r1.route_id IS NOT NULL
  AND r2.route_id IS NOT NULL
  AND r1.route_type != r2.route_type
GROUP BY transfer_type
ORDER BY count DESC;

-- 5. Find Royal Melbourne Hospital stop and check its edges
SELECT
    s.stop_id,
    s.stop_name,
    s.route_type,
    COUNT(DISTINCT e.source_route) as routes_serving
FROM stops s
LEFT JOIN edges_v2 e ON (e.source_stop = s.stop_id OR e.target_stop = s.stop_id)
WHERE s.stop_name ILIKE '%Royal Melbourne Hospital%'
GROUP BY s.stop_id, s.stop_name, s.route_type
ORDER BY s.stop_name;

-- 6. Find Ashburton stop
SELECT
    s.stop_id,
    s.stop_name,
    s.route_type,
    COUNT(DISTINCT e.source_route) as routes_serving
FROM stops s
LEFT JOIN edges_v2 e ON (e.source_stop = s.stop_id OR e.target_stop = s.stop_id)
WHERE s.stop_name ILIKE '%Ashburton%'
GROUP BY s.stop_id, s.stop_name, s.route_type
ORDER BY s.stop_name;
