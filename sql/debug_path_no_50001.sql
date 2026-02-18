-- Debug pathfinding from Royal Melbourne Hospital (1371) to Ashburton (1010)
-- Without route 50001 - should show proper Alamein route

SELECT
    d.path_id,
    d.seq,
    (d.node / 1000000000)::int as stop_id,
    (d.node % 1000000000)::int as route_id,
    s.stop_name,
    d.cost,
    d.agg_cost,
    e.edge_type
FROM pgr_ksp(
    'SELECT id, source_node as source, target_node as target, cost FROM edges_v2 WHERE source_route != 50001 AND target_route != 50001',
    1371000000725::bigint,  -- Origin: Royal Melbourne Hospital on tram route 725
    1010000000000::bigint,  -- Destination: Ashburton hub
    2,  -- k paths
    directed := false
) d
LEFT JOIN stops s ON s.stop_id = (d.node / 1000000000)::int
LEFT JOIN edges_v2 e ON e.id = d.edge
WHERE (d.node % 1000000000)::int != 0  -- Skip hub nodes
ORDER BY d.path_id, d.seq
LIMIT 40;
