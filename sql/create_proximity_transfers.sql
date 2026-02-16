-- Create proximity-based transfer edges between nearby stops
-- This allows pathfinding to work across all transport modes

-- Delete old transfer edges
DELETE FROM edges_v2 WHERE edge_type = 'transfer';

-- Create bidirectional transfer edges between stops within proximity threshold
-- Uses different thresholds based on route type:
-- - Train/V/Line: 500m (stations are spread out)
-- - Tram/Bus: 200m (stops are closer together)

DO $$
DECLARE
    inserted_count int := 0;
    max_edge_id int;
BEGIN
    -- Get current max edge ID
    SELECT COALESCE(MAX(id), 0) INTO max_edge_id FROM edges_v2;

    RAISE NOTICE 'Starting proximity transfer edge generation...';
    RAISE NOTICE 'Current max edge ID: %', max_edge_id;

    -- Insert proximity-based transfers
    -- For each pair of stops within distance threshold, create edges in both directions
    -- between all route combinations that serve those stops
    INSERT INTO edges_v2 (id, source_stop, target_stop, source_node, target_node, source_route, target_route, cost, distance_km, edge_type)
    SELECT
        ROW_NUMBER() OVER () + max_edge_id as id,
        source_stop,
        target_stop,
        source_node,
        target_node,
        source_route,
        target_route,
        cost,
        distance_km,
        'transfer' as edge_type
    FROM (
        -- Create transfers from stop A (with route) to stop B (with route)
        SELECT DISTINCT
            s1.stop_id as source_stop,
            s2.stop_id as target_stop,
            (s1.stop_id::bigint * 1000000000) + r1.route_id as source_node,
            (s2.stop_id::bigint * 1000000000) + r2.route_id as target_node,
            r1.route_id as source_route,
            r2.route_id as target_route,
            CASE
                -- Longer transfer for bus/tram (more walking)
                WHEN s1.route_type IN (1, 2) OR s2.route_type IN (1, 2) THEN 4
                ELSE 3
            END as cost,
            6371 * 2 * ASIN(SQRT(
                POWER(SIN((RADIANS(s2.stop_latitude) - RADIANS(s1.stop_latitude)) / 2), 2) +
                COS(RADIANS(s1.stop_latitude)) * COS(RADIANS(s2.stop_latitude)) *
                POWER(SIN((RADIANS(s2.stop_longitude) - RADIANS(s1.stop_longitude)) / 2), 2)
            )) as distance_km
        FROM stops s1
        JOIN stops s2 ON s1.stop_id != s2.stop_id
        -- Get all routes that serve each stop (from existing edges)
        CROSS JOIN LATERAL (
            SELECT DISTINCT source_route as route_id
            FROM edges_v2
            WHERE (source_stop = s1.stop_id OR target_stop = s1.stop_id)
            AND edge_type = 'route'
        ) r1
        CROSS JOIN LATERAL (
            SELECT DISTINCT source_route as route_id
            FROM edges_v2
            WHERE (source_stop = s2.stop_id OR target_stop = s2.stop_id)
            AND edge_type = 'route'
        ) r2
        WHERE r1.route_id != r2.route_id  -- Only transfers between different routes
        AND (
            -- Train/V/Line to Train/V/Line: 500m
            (s1.route_type IN (0, 3) AND s2.route_type IN (0, 3) AND
             6371 * 2 * ASIN(SQRT(
                POWER(SIN((RADIANS(s2.stop_latitude) - RADIANS(s1.stop_latitude)) / 2), 2) +
                COS(RADIANS(s1.stop_latitude)) * COS(RADIANS(s2.stop_latitude)) *
                POWER(SIN((RADIANS(s2.stop_longitude) - RADIANS(s1.stop_longitude)) / 2), 2)
             )) <= 0.5)
            OR
            -- Any tram/bus involved: 200m
            ((s1.route_type IN (1, 2) OR s2.route_type IN (1, 2)) AND
             6371 * 2 * ASIN(SQRT(
                POWER(SIN((RADIANS(s2.stop_latitude) - RADIANS(s1.stop_latitude)) / 2), 2) +
                COS(RADIANS(s1.stop_latitude)) * COS(RADIANS(s2.stop_latitude)) *
                POWER(SIN((RADIANS(s2.stop_longitude) - RADIANS(s1.stop_longitude)) / 2), 2)
             )) <= 0.2)
        )
    ) transfers;

    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    RAISE NOTICE 'Inserted % proximity transfer edges', inserted_count;
END $$;

-- Show statistics
SELECT
    edge_type,
    COUNT(*) as edge_count,
    ROUND(AVG(cost)::numeric, 2) as avg_cost_minutes,
    ROUND(AVG(distance_km)::numeric, 3) as avg_distance_km
FROM edges_v2
GROUP BY edge_type
ORDER BY edge_type;

-- Show sample transfers
SELECT
    s1.stop_name as from_stop,
    s2.stop_name as to_stop,
    e.source_route,
    e.target_route,
    ROUND(e.distance_km::numeric, 3) as distance_km,
    e.cost as transfer_time_min
FROM edges_v2 e
JOIN stops s1 ON s1.stop_id = e.source_stop
JOIN stops s2 ON s2.stop_id = e.target_stop
WHERE e.edge_type = 'transfer'
ORDER BY e.distance_km
LIMIT 20;
