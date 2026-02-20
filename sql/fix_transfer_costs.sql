-- Fix transfer edge costs to use realistic walking time (5 km/h)
-- Current formula is ~42 min/km which is impossibly slow (1.4 km/h)
-- New formula: distance_km * 12 min/km (5 km/h walking) with 1.5 min minimum

-- Show current cost distribution
SELECT
    'Before fix' as state,
    COUNT(*) as count,
    ROUND(MIN(cost)::numeric, 2) as min_cost,
    ROUND(MAX(cost)::numeric, 2) as max_cost,
    ROUND(AVG(cost)::numeric, 2) as avg_cost
FROM edges_v2
WHERE edge_type = 'transfer';

-- Update transfer costs: use 5 km/h walking speed
-- cost_minutes = distance_km * 60_min_per_hour / 5_km_per_hour = distance_km * 12
-- with a minimum of 1.5 minutes (for short hops, lights, etc.)
UPDATE edges_v2
SET cost = GREATEST(1.5, distance_km * 12.0)
WHERE edge_type = 'transfer'
  AND distance_km > 0;  -- Only update edges with valid distance

-- Show updated cost distribution
SELECT
    'After fix' as state,
    COUNT(*) as count,
    ROUND(MIN(cost)::numeric, 2) as min_cost,
    ROUND(MAX(cost)::numeric, 2) as max_cost,
    ROUND(AVG(cost)::numeric, 2) as avg_cost
FROM edges_v2
WHERE edge_type = 'transfer';

-- Check the specific transfers we care about
SELECT
    s1.stop_name as from_stop,
    s2.stop_name as to_stop,
    ROUND(distance_km::numeric, 3) as distance_km,
    ROUND(cost::numeric, 2) as cost_minutes
FROM edges_v2 e
JOIN stops s1 ON s1.stop_id = e.source_stop
JOIN stops s2 ON s2.stop_id = e.target_stop
WHERE e.edge_type = 'transfer'
  AND e.source_stop IN (1371, 1372, 1375, 1360, 1233)
ORDER BY s1.stop_name, e.cost;
