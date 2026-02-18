-- Check if tram route 725 has proper edges from stop 1371

-- 1. Check route edges for tram route 725 from Royal Melbourne Hospital (stop 1371)
SELECT
    'Route edges from stop 1371 on route 725',
    COUNT(*) as edge_count
FROM edges_v2
WHERE source_stop = 1371
  AND source_route = 725
  AND edge_type = 'route';

-- 2. Show sample edges from this stop on this route
SELECT
    s1.stop_name as from_stop,
    s2.stop_name as to_stop,
    e.source_route,
    e.cost,
    e.distance_km
FROM edges_v2 e
JOIN stops s1 ON s1.stop_id = e.source_stop
JOIN stops s2 ON s2.stop_id = e.target_stop
WHERE e.source_stop = 1371
  AND e.source_route = 725
  AND e.edge_type = 'route'
LIMIT 10;

-- 3. Check if tram route 725 connects to Parkville Station area
-- Find edges from route 725 that get close to Parkville Station (stop 1233)
SELECT
    s1.stop_name as tram_stop,
    s1.stop_id as tram_stop_id,
    s2.stop_name as next_tram_stop,
    s2.stop_id as next_stop_id,
    ROUND(
        (6371 * 2 * ASIN(SQRT(
            POWER(SIN((RADIANS(parkville.stop_latitude) - RADIANS(s1.stop_latitude)) / 2), 2) +
            COS(RADIANS(s1.stop_latitude)) * COS(RADIANS(parkville.stop_latitude)) *
            POWER(SIN((RADIANS(parkville.stop_longitude) - RADIANS(s1.stop_longitude)) / 2), 2)
        )))::numeric,
        3
    ) as distance_to_parkville_km
FROM edges_v2 e
JOIN stops s1 ON s1.stop_id = e.source_stop
JOIN stops s2 ON s2.stop_id = e.target_stop
CROSS JOIN (SELECT stop_latitude, stop_longitude FROM stops WHERE stop_id = 1233) AS parkville
WHERE e.source_route = 725
  AND e.edge_type = 'route'
  AND 6371 * 2 * ASIN(SQRT(
        POWER(SIN((RADIANS(parkville.stop_latitude) - RADIANS(s1.stop_latitude)) / 2), 2) +
        COS(RADIANS(s1.stop_latitude)) * COS(RADIANS(parkville.stop_latitude)) *
        POWER(SIN((RADIANS(parkville.stop_longitude) - RADIANS(s1.stop_longitude)) / 2), 2)
    )) <= 0.3  -- Within 300m of Parkville Station
ORDER BY distance_to_parkville_km
LIMIT 10;

-- 4. Check hub-to-hub transfers from vicinity of stop 1371 to vicinity of Parkville
SELECT
    s1.stop_name as from_hub_stop,
    s2.stop_name as to_hub_stop,
    e.cost,
    ROUND(e.distance_km::numeric, 3) as distance_km
FROM edges_v2 e
JOIN stops s1 ON s1.stop_id = e.source_stop
JOIN stops s2 ON s2.stop_id = e.target_stop
WHERE e.edge_type = 'transfer'
  AND e.source_stop = 1371
  AND e.target_stop = 1233
LIMIT 5;

-- 5. Check if there's a direct hub transfer from tram stop to Parkville Station
SELECT
    'Hub-to-hub transfer from 1371 to 1233 exists',
    COUNT(*) as transfer_count
FROM edges_v2
WHERE edge_type = 'transfer'
  AND source_stop = 1371
  AND target_stop = 1233;

-- 6. List all edges involving stop 1371 (Royal Melbourne Hospital)
SELECT
    edge_type,
    source_stop,
    target_stop,
    source_route,
    target_route,
    cost,
    ROUND(distance_km::numeric, 3) as distance_km
FROM edges_v2
WHERE source_stop = 1371 OR target_stop = 1371
ORDER BY edge_type, source_route, target_route;
