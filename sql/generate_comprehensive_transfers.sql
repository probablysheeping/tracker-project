-- Comprehensive transfer edge generation script
-- Generates transfers between stations based on proximity and route type compatibility

-- First, delete all existing transfer edges
DELETE FROM edges_v2 WHERE edge_type = 'transfer';

-- Create temporary table for transfer rules based on route type combinations
CREATE TEMP TABLE transfer_rules (
    from_route_type INT,
    to_route_type INT,
    max_distance_km NUMERIC(5,3),
    base_penalty_minutes NUMERIC(5,2),
    per_meter_penalty NUMERIC(8,6),
    description TEXT
);

-- Define transfer rules for each route type combination
-- Route types: 0=Train, 1=Tram, 2=Bus, 3=V/Line, 4=Night Bus

INSERT INTO transfer_rules VALUES
-- Same-mode transfers (cross-platform at same station or very close)
(0, 0, 0.100, 2.5, 0.00, 'Train to Train (cross-platform)'),
(1, 1, 0.050, 2.0, 0.00, 'Tram to Tram (cross-platform)'),
(2, 2, 0.050, 1.5, 0.00, 'Bus to Bus (same stop)'),
(3, 3, 0.100, 3.0, 0.00, 'V/Line to V/Line (cross-platform)'),
(4, 4, 0.050, 1.5, 0.00, 'Night Bus to Night Bus (same stop)'),

-- Train ↔ Other modes
(0, 1, 0.200, 4.0, 0.020, 'Train to Tram (200m walk)'),
(1, 0, 0.200, 4.0, 0.020, 'Tram to Train (200m walk)'),
(0, 2, 0.300, 5.0, 0.015, 'Train to Bus (300m walk)'),
(2, 0, 0.300, 5.0, 0.015, 'Bus to Train (300m walk)'),
(0, 3, 0.500, 3.0, 0.010, 'Train to V/Line (500m walk)'),
(3, 0, 0.500, 3.0, 0.010, 'V/Line to Train (500m walk)'),
(0, 4, 0.300, 5.0, 0.015, 'Train to Night Bus (300m walk)'),
(4, 0, 0.300, 5.0, 0.015, 'Night Bus to Train (300m walk)'),

-- Tram ↔ Other modes (excluding Train)
(1, 2, 0.100, 3.0, 0.025, 'Tram to Bus (100m walk)'),
(2, 1, 0.100, 3.0, 0.025, 'Bus to Tram (100m walk)'),
(1, 3, 0.200, 5.0, 0.020, 'Tram to V/Line (200m walk)'),
(3, 1, 0.200, 5.0, 0.020, 'V/Line to Tram (200m walk)'),
(1, 4, 0.100, 3.0, 0.025, 'Tram to Night Bus (100m walk)'),
(4, 1, 0.100, 3.0, 0.025, 'Night Bus to Tram (100m walk)'),

-- Bus ↔ Other modes (excluding Train and Tram)
(2, 3, 0.300, 5.0, 0.015, 'Bus to V/Line (300m walk)'),
(3, 2, 0.300, 5.0, 0.015, 'V/Line to Bus (300m walk)'),
(2, 4, 0.050, 1.5, 0.00, 'Bus to Night Bus (same stop)'),
(4, 2, 0.050, 1.5, 0.00, 'Night Bus to Bus (same stop)'),

-- V/Line ↔ Night Bus
(3, 4, 0.300, 5.0, 0.015, 'V/Line to Night Bus (300m walk)'),
(4, 3, 0.300, 5.0, 0.015, 'Night Bus to V/Line (300m walk)');

-- Generate proximity-based transfers
-- Uses Haversine formula approximation for distance calculation
WITH proximity_transfers AS (
    SELECT DISTINCT
        s1.stop_id as from_stop,
        s1.route_type as from_route_type,
        s2.stop_id as to_stop,
        s2.route_type as to_route_type,
        -- Haversine distance approximation in km
        6371 * 2 * ASIN(SQRT(
            POWER(SIN((s2.stop_latitude - s1.stop_latitude) * PI() / 180 / 2), 2) +
            COS(s1.stop_latitude * PI() / 180) * COS(s2.stop_latitude * PI() / 180) *
            POWER(SIN((s2.stop_longitude - s1.stop_longitude) * PI() / 180 / 2), 2)
        )) as distance_km,
        tr.base_penalty_minutes,
        tr.per_meter_penalty
    FROM stops s1
    CROSS JOIN stops s2
    JOIN transfer_rules tr
        ON tr.from_route_type = s1.route_type
        AND tr.to_route_type = s2.route_type
    WHERE s1.stop_id != s2.stop_id  -- Don't create self-transfers
        AND s1.stop_latitude IS NOT NULL AND s1.stop_longitude IS NOT NULL
        AND s2.stop_latitude IS NOT NULL AND s2.stop_longitude IS NOT NULL
        -- Only create transfers within the maximum distance for this combination
        AND 6371 * 2 * ASIN(SQRT(
                POWER(SIN((s2.stop_latitude - s1.stop_latitude) * PI() / 180 / 2), 2) +
                COS(s1.stop_latitude * PI() / 180) * COS(s2.stop_latitude * PI() / 180) *
                POWER(SIN((s2.stop_longitude - s1.stop_longitude) * PI() / 180 / 2), 2)
            )) <= tr.max_distance_km
)
INSERT INTO edges_v2 (
    source_stop,
    source_route,
    target_stop,
    target_route,
    source_node,
    target_node,
    cost,
    distance_km,
    edge_type
)
SELECT
    pt.from_stop,
    0 as source_route,  -- Hub node
    pt.to_stop,
    0 as target_route,  -- Hub node
    (pt.from_stop::bigint * 1000000000) as source_node,
    (pt.to_stop::bigint * 1000000000) as target_node,
    -- Calculate transfer time: base penalty + (distance in meters * per-meter penalty)
    GREATEST(
        1.0,  -- Minimum 1 minute transfer
        pt.base_penalty_minutes + (pt.distance_km * 1000 * pt.per_meter_penalty)
    ) as cost,
    pt.distance_km,
    'transfer' as edge_type
FROM proximity_transfers pt;

-- Create indexes for faster pathfinding
CREATE INDEX IF NOT EXISTS idx_edges_v2_transfer_nodes
ON edges_v2(source_node, target_node)
WHERE edge_type = 'transfer';

CREATE INDEX IF NOT EXISTS idx_edges_v2_transfer_stops
ON edges_v2(source_stop, target_stop)
WHERE edge_type = 'transfer';

-- Display summary statistics
SELECT
    s1.route_type as from_route_type,
    s2.route_type as to_route_type,
    COUNT(*) as transfer_count,
    ROUND(AVG(e.cost)::numeric, 2) as avg_time_min,
    ROUND(MIN(e.cost)::numeric, 2) as min_time_min,
    ROUND(MAX(e.cost)::numeric, 2) as max_time_min,
    ROUND(AVG(e.distance_km * 1000)::numeric, 0) as avg_distance_m,
    CASE s1.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
    END || ' → ' ||
    CASE s2.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
    END as transfer_description
FROM edges_v2 e
JOIN stops s1 ON e.source_stop = s1.stop_id
JOIN stops s2 ON e.target_stop = s2.stop_id
WHERE e.edge_type = 'transfer'
GROUP BY s1.route_type, s2.route_type
ORDER BY s1.route_type, s2.route_type;

-- Display overall statistics
SELECT
    COUNT(*) as total_transfers,
    ROUND(AVG(cost)::numeric, 2) as avg_time_min,
    ROUND(MIN(cost)::numeric, 2) as min_time_min,
    ROUND(MAX(cost)::numeric, 2) as max_time_min,
    COUNT(DISTINCT source_stop) as stations_with_transfers
FROM edges_v2
WHERE edge_type = 'transfer';

-- Display route type names
SELECT
    'Route Type Mapping:' as info,
    '0=Train, 1=Tram, 2=Bus, 3=V/Line, 4=Night Bus' as types;

-- Cleanup
DROP TABLE transfer_rules;

SELECT 'Comprehensive transfer edges generated successfully!' as status;
