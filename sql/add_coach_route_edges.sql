-- Add routing edges for V/Line coach services
-- Route IDs: 14937 (Apollo Bay - Geelong), 20001 (Warrnambool - Melbourne via Great Ocean Road)
-- Node ID formula: (stop_id × 1,000,000,000) + route_id

-- Stop IDs:
-- 90001: Apollo Bay
-- 90004: Lorne
-- 25929: Geelong Station
-- 25970: Warrnambool Station

-- ============================================
-- ROUTE 14937: Apollo Bay - Geelong (5-GVL)
-- ============================================

-- Geelong → Lorne (90 minutes, ~70km)
INSERT INTO edges_v2 (source_stop, target_stop, source_route, target_route, source_node, target_node, cost, distance_km, edge_type)
VALUES
(25929, 90004, 14937, 14937, 25929000014937, 90004000014937, 90, 70, 'route'),
(90004, 25929, 14937, 14937, 90004000014937, 25929000014937, 90, 70, 'route');

-- Lorne → Apollo Bay (60 minutes, ~45km)
INSERT INTO edges_v2 (source_stop, target_stop, source_route, target_route, source_node, target_node, cost, distance_km, edge_type)
VALUES
(90004, 90001, 14937, 14937, 90004000014937, 90001000014937, 60, 45, 'route'),
(90001, 90004, 14937, 14937, 90001000014937, 90004000014937, 60, 45, 'route');

-- ============================================
-- ROUTE 20001: Warrnambool - Melbourne via Great Ocean Road (coach-GOR)
-- This connects Warrnambool → Apollo Bay → Lorne → Geelong → Melbourne
-- ============================================

-- Warrnambool → Apollo Bay (120 minutes, ~100km)
INSERT INTO edges_v2 (source_stop, target_stop, source_route, target_route, source_node, target_node, cost, distance_km, edge_type)
VALUES
(25970, 90001, 20001, 20001, 25970000020001, 90001000020001, 120, 100, 'route'),
(90001, 25970, 20001, 20001, 90001000020001, 25970000020001, 120, 100, 'route');

-- Apollo Bay → Lorne (60 minutes, ~45km)
INSERT INTO edges_v2 (source_stop, target_stop, source_route, target_route, source_node, target_node, cost, distance_km, edge_type)
VALUES
(90001, 90004, 20001, 20001, 90001000020001, 90004000020001, 60, 45, 'route'),
(90004, 90001, 20001, 20001, 90004000020001, 90001000020001, 60, 45, 'route');

-- Lorne → Geelong (90 minutes, ~70km)
INSERT INTO edges_v2 (source_stop, target_stop, source_route, target_route, source_node, target_node, cost, distance_km, edge_type)
VALUES
(90004, 25929, 20001, 20001, 90004000020001, 25929000020001, 90, 70, 'route'),
(25929, 90004, 20001, 20001, 25929000020001, 90004000020001, 90, 70, 'route');

-- Geelong → Southern Cross (already exists from train routes, but add coach connection)
-- Note: We'll rely on hub edges at Geelong to transfer to trains for Melbourne

-- ============================================
-- HUB EDGES (for transfers between routes)
-- route_id = 0 means hub/transfer edge
-- ============================================

-- Apollo Bay hub (allows transfers at Apollo Bay)
INSERT INTO edges_v2 (source_stop, target_stop, source_route, target_route, source_node, target_node, cost, distance_km, edge_type)
VALUES
(90001, 90001, 0, 14937, 90001000000000, 90001000014937, 2.5, 0, 'hub'),
(90001, 90001, 14937, 0, 90001000014937, 90001000000000, 2.5, 0, 'hub'),
(90001, 90001, 0, 20001, 90001000000000, 90001000020001, 2.5, 0, 'hub'),
(90001, 90001, 20001, 0, 90001000020001, 90001000000000, 2.5, 0, 'hub');

-- Lorne hub
INSERT INTO edges_v2 (source_stop, target_stop, source_route, target_route, source_node, target_node, cost, distance_km, edge_type)
VALUES
(90004, 90004, 0, 14937, 90004000000000, 90004000014937, 2.5, 0, 'hub'),
(90004, 90004, 14937, 0, 90004000014937, 90004000000000, 2.5, 0, 'hub'),
(90004, 90004, 0, 20001, 90004000000000, 90004000020001, 2.5, 0, 'hub'),
(90004, 90004, 20001, 0, 90004000020001, 90004000000000, 2.5, 0, 'hub');

-- Geelong Station already has hub edges from train routes,
-- but we need to connect the coach routes to the hub
INSERT INTO edges_v2 (source_stop, target_stop, source_route, target_route, source_node, target_node, cost, distance_km, edge_type)
VALUES
(25929, 25929, 0, 14937, 25929000000000, 25929000014937, 2.5, 0, 'hub'),
(25929, 25929, 14937, 0, 25929000014937, 25929000000000, 2.5, 0, 'hub'),
(25929, 25929, 0, 20001, 25929000000000, 25929000020001, 2.5, 0, 'hub'),
(25929, 25929, 20001, 0, 25929000020001, 25929000000000, 2.5, 0, 'hub')
ON CONFLICT DO NOTHING;

-- Warrnambool Station hub
INSERT INTO edges_v2 (source_stop, target_stop, source_route, target_route, source_node, target_node, cost, distance_km, edge_type)
VALUES
(25970, 25970, 0, 20001, 25970000000000, 25970000020001, 2.5, 0, 'hub'),
(25970, 25970, 20001, 0, 25970000020001, 25970000000000, 2.5, 0, 'hub')
ON CONFLICT DO NOTHING;

-- ============================================
-- SUMMARY
-- ============================================
-- Added routes:
-- 1. Apollo Bay ↔ Lorne ↔ Geelong (route 14937)
-- 2. Warrnambool ↔ Apollo Bay ↔ Lorne ↔ Geelong (route 20001)
-- Total new edges: 28 (12 route edges + 16 hub edges)
