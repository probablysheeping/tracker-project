-- Create hub edges for transfers between different route types at the same stop
-- Hub nodes have route_id = 0 and connect all routes at a station

-- Transfer penalty: 2.5 minutes each way (5 minutes total for a round trip through hub)
DO $$
DECLARE
    transfer_penalty CONSTANT int := 3; -- 3 minutes transfer time
    max_edge_id int;
BEGIN
    -- Get current max edge ID
    SELECT COALESCE(MAX(id), 0) INTO max_edge_id FROM edges_v2;

    -- Create bidirectional hub edges for each stop
    -- From route-specific node to hub node (route_id = 0)
    -- And from hub node back to route-specific nodes

    INSERT INTO edges_v2 (id, source_stop, target_stop, source_node, target_node, source_route, target_route, cost, distance_km, edge_type)
    SELECT
        ROW_NUMBER() OVER () + max_edge_id as id,
        source_stop,
        target_stop,
        source_node,
        target_node,
        source_route,
        target_route,
        transfer_penalty as cost,
        0 as distance_km,
        'transfer' as edge_type
    FROM (
        -- From each route-specific node to hub (route 0)
        SELECT DISTINCT
            s.stop_id as source_stop,
            s.stop_id as target_stop,
            (s.stop_id::bigint * 1000000000) + r.route_id as source_node,
            (s.stop_id::bigint * 1000000000) as target_node,
            r.route_id as source_route,
            0 as target_route
        FROM stops s
        CROSS JOIN (SELECT DISTINCT source_route as route_id FROM edges_v2 WHERE source_route > 0) r

        UNION ALL

        -- From hub to each route-specific node
        SELECT DISTINCT
            s.stop_id as source_stop,
            s.stop_id as target_stop,
            (s.stop_id::bigint * 1000000000) as source_node,
            (s.stop_id::bigint * 1000000000) + r.route_id as target_node,
            0 as source_route,
            r.route_id as target_route
        FROM stops s
        CROSS JOIN (SELECT DISTINCT source_route as route_id FROM edges_v2 WHERE source_route > 0) r
    ) hub_edges;

    RAISE NOTICE 'Created % hub edges', (SELECT COUNT(*) FROM edges_v2 WHERE source_route = 0 OR target_route = 0);
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_edges_v2_source_route ON edges_v2(source_route);
CREATE INDEX IF NOT EXISTS idx_edges_v2_target_route ON edges_v2(target_route);
CREATE INDEX IF NOT EXISTS idx_edges_v2_nodes ON edges_v2(source_node, target_node);
