-- Check if hub edges can facilitate tram-to-train transfers

-- 1. Check hub edges structure
SELECT
    'Hub edges with route_id = 0' as description,
    COUNT(*) as count
FROM edges_v2
WHERE source_route = 0 OR target_route = 0;

-- 2. Check if Royal Melbourne Hospital (tram stop 1371) has hub connections
SELECT
    'Hub edges for Royal Melbourne Hospital stop 1371',
    COUNT(*) as hub_edge_count
FROM edges_v2
WHERE (source_stop = 1371 OR target_stop = 1371)
  AND (source_route = 0 OR target_route = 0);

-- 3. Check if there's a route serving stop 1371
SELECT
    r.route_id,
    r.route_name,
    r.route_type
FROM edges_v2 e
JOIN routes r ON r.route_id = e.source_route
WHERE e.source_stop = 1371
  AND e.edge_type = 'route'
LIMIT 10;

-- 4. Check edges for Ashburton (train stop 1010)
SELECT
    'Hub edges for Ashburton stop 1010',
    COUNT(*) as hub_edge_count
FROM edges_v2
WHERE (source_stop = 1010 OR target_stop = 1010)
  AND (source_route = 0 OR target_route = 0);

-- 5. Show sample path from tram stop to hub
SELECT
    s1.stop_name as from_stop,
    s2.stop_name as to_stop,
    e.source_route,
    e.target_route,
    e.edge_type,
    e.cost
FROM edges_v2 e
JOIN stops s1 ON s1.stop_id = e.source_stop
JOIN stops s2 ON s2.stop_id = e.target_stop
WHERE e.source_stop = 1371
  AND e.target_stop = 1371
  AND e.target_route = 0
LIMIT 5;

-- 6. Check if transfer edges exist at all
SELECT
    edge_type,
    source_route,
    target_route,
    COUNT(*) as count
FROM edges_v2
WHERE edge_type = 'transfer'
GROUP BY edge_type, source_route, target_route
ORDER BY count DESC
LIMIT 20;

-- 7. Check nearby stops to Royal Melbourne Hospital
-- Find train stations within 500m of stop 1371
SELECT
    s1.stop_name as tram_stop,
    s2.stop_name as train_stop,
    s2.stop_id as train_stop_id,
    s2.route_type,
    ROUND(
        (6371 * 2 * ASIN(SQRT(
            POWER(SIN((RADIANS(s2.stop_latitude) - RADIANS(s1.stop_latitude)) / 2), 2) +
            COS(RADIANS(s1.stop_latitude)) * COS(RADIANS(s2.stop_latitude)) *
            POWER(SIN((RADIANS(s2.stop_longitude) - RADIANS(s1.stop_longitude)) / 2), 2)
        )))::numeric,
        3
    ) as distance_km
FROM stops s1
CROSS JOIN stops s2
WHERE s1.stop_id = 1371
  AND s2.route_type = 0  -- Train stations
  AND 6371 * 2 * ASIN(SQRT(
        POWER(SIN((RADIANS(s2.stop_latitude) - RADIANS(s1.stop_latitude)) / 2), 2) +
        COS(RADIANS(s1.stop_latitude)) * COS(RADIANS(s2.stop_latitude)) *
        POWER(SIN((RADIANS(s2.stop_longitude) - RADIANS(s1.stop_longitude)) / 2), 2)
    )) <= 0.5  -- Within 500m
ORDER BY distance_km
LIMIT 10;
