-- Debug pathfinding from Royal Melbourne Hospital (1371) to Ashburton (1010)
-- This will show the full path including hub nodes

SELECT
    d.path_id,
    d.seq,
    d.node,
    (d.node / 1000000000)::int as stop_id,
    (d.node % 1000000000)::int as route_id,
    s.stop_name,
    d.cost,
    d.agg_cost,
    e.edge_type,
    e.source_stop,
    e.target_stop,
    e.source_route,
    e.target_route
FROM pgr_ksp(
    'SELECT id, source_node as source, target_node as target, cost FROM edges_v2',
    1371000000000::bigint,  -- Origin: Royal Melbourne Hospital tram stop (hub node)
    1010000000000::bigint,  -- Destination: Ashburton train station (hub node)
    3,  -- k paths
    directed := false
) d
LEFT JOIN stops s ON s.stop_id = (d.node / 1000000000)::int
LEFT JOIN edges_v2 e ON e.id = d.edge
ORDER BY d.path_id, d.seq
LIMIT 50;
