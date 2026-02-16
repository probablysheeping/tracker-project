-- Add major V/Line coach stops that are missing from GTFS data
-- These are coach-only destinations not served by train

-- Apollo Bay (Great Ocean Road coach service)
INSERT INTO stops (stop_id, stop_name, stop_latitude, stop_longitude, route_type, stop_suburb)
VALUES
(90001, 'Apollo Bay', -38.7578, 143.6712, 3, 'Apollo Bay')
ON CONFLICT (stop_id) DO NOTHING;

-- Bright (Alpine coach service)
INSERT INTO stops (stop_id, stop_name, stop_latitude, stop_longitude, route_type, stop_suburb)
VALUES
(90002, 'Bright', -36.7294, 146.9594, 3, 'Bright')
ON CONFLICT (stop_id) DO NOTHING;

-- Mildura (already exists as a station, but adding for completeness)
INSERT INTO stops (stop_id, stop_name, stop_latitude, stop_longitude, route_type, stop_suburb)
VALUES
(90003, 'Mildura', -34.1889, 142.1583, 3, 'Mildura')
ON CONFLICT (stop_id) DO NOTHING;

-- Lorne (Great Ocean Road intermediate stop)
INSERT INTO stops (stop_id, stop_name, stop_latitude, stop_longitude, route_type, stop_suburb)
VALUES
(90004, 'Lorne', -38.5414, 143.9787, 3, 'Lorne')
ON CONFLICT (stop_id) DO NOTHING;

-- Cowes (Phillip Island)
INSERT INTO stops (stop_id, stop_name, stop_latitude, stop_longitude, route_type, stop_suburb)
VALUES
(90005, 'Cowes', -38.4592, 145.2372, 3, 'Cowes')
ON CONFLICT (stop_id) DO NOTHING;

-- Inverloch
INSERT INTO stops (stop_id, stop_name, stop_latitude, stop_longitude, route_type, stop_suburb)
VALUES
(90006, 'Inverloch', -38.6294, 145.6731, 3, 'Inverloch')
ON CONFLICT (stop_id) DO NOTHING;

-- Add these stops to the GTFS stops table for compatibility
INSERT INTO gtfs_stops (gtfs_stop_id, stop_name, stop_lat, stop_lon, location_type, parent_station)
VALUES
('coach-apollo-bay', 'Apollo Bay', -38.7578, 143.6712, '1', NULL),
('coach-bright', 'Bright', -36.7294, 146.9594, '1', NULL),
('coach-mildura', 'Mildura', -34.1889, 142.1583, '1', NULL),
('coach-lorne', 'Lorne', -38.5414, 143.9787, '1', NULL),
('coach-cowes', 'Cowes', -38.4592, 145.2372, '1', NULL),
('coach-inverloch', 'Inverloch', -38.6294, 145.6731, '1', NULL)
ON CONFLICT (gtfs_stop_id) DO NOTHING;

-- Update stops table to link with GTFS
UPDATE stops SET gtfs_parent_station = 'coach-apollo-bay' WHERE stop_id = 90001;
UPDATE stops SET gtfs_parent_station = 'coach-bright' WHERE stop_id = 90002;
UPDATE stops SET gtfs_parent_station = 'coach-mildura' WHERE stop_id = 90003;
UPDATE stops SET gtfs_parent_station = 'coach-lorne' WHERE stop_id = 90004;
UPDATE stops SET gtfs_parent_station = 'coach-cowes' WHERE stop_id = 90005;
UPDATE stops SET gtfs_parent_station = 'coach-inverloch' WHERE stop_id = 90006;
