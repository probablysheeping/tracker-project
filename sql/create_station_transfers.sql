-- Script to generate realistic walking transfer edges between stations
-- This creates transfers for cross-platform changes and nearby stations

-- First, delete existing transfer edges to avoid duplicates
DELETE FROM edges_v2 WHERE edge_type = 'transfer';

-- Define station transfer pairs with realistic walking times (in minutes)
-- Format: (stop1_id, stop2_id, transfer_time_minutes, description)
CREATE TEMP TABLE station_transfers (
    stop1_id INT,
    stop2_id INT,
    transfer_time NUMERIC(5,2),
    description TEXT
);

-- City Loop Stations - Underground connections
INSERT INTO station_transfers VALUES
-- Flinders Street ↔ Parliament (via underground concourse)
(1071, 1155, 5.0, 'Flinders Street to Parliament'),
-- Parliament ↔ Melbourne Central (via underground concourse)
(1155, 1120, 3.0, 'Parliament to Melbourne Central'),
-- Melbourne Central ↔ Flagstaff (via underground concourse)
(1120, 1068, 3.0, 'Melbourne Central to Flagstaff'),
-- Flagstaff ↔ Southern Cross (via underground concourse)
(1068, 1181, 4.0, 'Flagstaff to Southern Cross'),

-- Metro Tunnel Stations - Underground connections
-- Town Hall ↔ Flinders Street (direct underground)
(1199, 1071, 5.0, 'Town Hall to Flinders Street'),
-- State Library ↔ Melbourne Central (direct underground)
(1188, 1120, 5.0, 'State Library to Melbourne Central'),
-- Arden ↔ North Melbourne (close proximity)
(1008, 1141, 6.0, 'Arden to North Melbourne'),
-- Parkville ↔ Royal Park (close proximity)
(1162, 1176, 8.0, 'Parkville to Royal Park'),
-- Anzac ↔ Richmond (close proximity)
(1009, 1170, 4.0, 'Anzac to Richmond'),

-- Major Interchanges
-- Southern Cross ↔ Spencer Street (same station different names)
(1181, 1181, 0.5, 'Southern Cross platforms'),
-- Flinders Street ↔ Federation Square (Elizabeth St exit)
(1071, 1071, 1.0, 'Flinders Street platforms'),
-- Richmond ↔ Richmond (cross-platform)
(1170, 1170, 2.0, 'Richmond cross-platform'),
-- Caulfield ↔ Caulfield (cross-platform)
(1024, 1024, 3.0, 'Caulfield cross-platform'),
-- Box Hill ↔ Box Hill (cross-platform)
(1017, 1017, 2.5, 'Box Hill cross-platform'),
-- Footscray ↔ Footscray (cross-platform)
(1073, 1073, 2.5, 'Footscray cross-platform'),
-- Sunshine ↔ Sunshine (cross-platform)
(1195, 1195, 3.0, 'Sunshine cross-platform'),
-- Dandenong ↔ Dandenong (cross-platform)
(1046, 1046, 3.0, 'Dandenong cross-platform'),
-- Werribee ↔ Werribee (cross-platform)
(1226, 1226, 2.5, 'Werribee cross-platform'),

-- CBD Street-Level Connections
-- Parliament ↔ Melbourne Central (street level)
(1155, 1120, 8.0, 'Parliament to Melbourne Central (street)'),
-- Melbourne Central ↔ Flagstaff (street level)
(1120, 1068, 10.0, 'Melbourne Central to Flagstaff (street)'),
-- Flagstaff ↔ Southern Cross (street level)
(1068, 1181, 12.0, 'Flagstaff to Southern Cross (street)'),

-- North Melbourne Area
-- North Melbourne ↔ Macaulay (adjacent stations)
(1141, 1105, 15.0, 'North Melbourne to Macaulay'),
-- Macaulay ↔ Flemington Bridge (adjacent stations)
(1105, 1072, 12.0, 'Macaulay to Flemington Bridge'),

-- Richmond Area Connections
-- Richmond ↔ East Richmond (adjacent stations)
(1170, 1058, 12.0, 'Richmond to East Richmond'),
-- Richmond ↔ Burnley (adjacent stations)
(1170, 1021, 10.0, 'Richmond to Burnley'),
-- Richmond ↔ Jolimont (adjacent stations)
(1170, 1091, 10.0, 'Richmond to Jolimont'),

-- South Yarra Area
-- South Yarra ↔ Hawksburn (adjacent stations)
(1184, 1085, 15.0, 'South Yarra to Hawksburn'),
-- South Yarra ↔ Prahran (tram connection)
(1184, 1167, 12.0, 'South Yarra to Prahran'),

-- Tram Interchange Stations
-- Bourke St ↔ Melbourne Central (Swanston St trams)
(1120, 1120, 2.0, 'Melb Central tram platforms'),
-- Flinders St ↔ Elizabeth St (tram interchange)
(1071, 1071, 3.0, 'Flinders St tram interchange');

-- Now generate bidirectional transfer edges
-- Create edges in both directions for all transfer pairs
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
    t.stop1_id as source_stop,
    0 as source_route,  -- Route 0 = hub node (allows any route transfer)
    t.stop2_id as target_stop,
    0 as target_route,
    (t.stop1_id::bigint * 1000000000) as source_node,  -- Convert to composite node ID
    (t.stop2_id::bigint * 1000000000) as target_node,
    t.transfer_time as cost,
    0.0 as distance_km,  -- Walking transfers don't count toward journey distance
    'transfer' as edge_type
FROM station_transfers t

UNION ALL

-- Reverse direction
SELECT
    t.stop2_id as source_stop,
    0 as source_route,
    t.stop1_id as target_stop,
    0 as target_route,
    (t.stop2_id::bigint * 1000000000) as source_node,
    (t.stop1_id::bigint * 1000000000) as target_node,
    t.transfer_time as cost,
    0.0 as distance_km,
    'transfer' as edge_type
FROM station_transfers t;

-- Create index for faster pathfinding
CREATE INDEX IF NOT EXISTS idx_edges_v2_transfer
ON edges_v2(source_node, target_node)
WHERE edge_type = 'transfer';

-- Display summary
SELECT
    edge_type,
    COUNT(*) as edge_count,
    AVG(cost) as avg_transfer_time_min,
    MIN(cost) as min_transfer_time_min,
    MAX(cost) as max_transfer_time_min
FROM edges_v2
WHERE edge_type = 'transfer'
GROUP BY edge_type;

-- Cleanup temp table
DROP TABLE station_transfers;

SELECT 'Transfer edges created successfully!' as status;
