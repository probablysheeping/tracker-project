-- V/Line Coach Routes Import
-- Generated: 2025-12-29
-- Total Routes: 5
-- Total Stops: 56

-- Route IDs: 20001-20005 (coach routes)
-- Route Type: 3 (V/Line)

BEGIN;

-- ============================================
-- Insert Stops
-- ============================================

-- Stop: Anglesea
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90000, 'Anglesea', -38.4051948, 144.188958, 3, 'Anglesea', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Apollo Bay
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90001, 'Apollo Bay', -38.7547442, 143.6691463, 3, 'Apollo Bay', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Avoca
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90002, 'Avoca', -37.0889278, 143.473745, 3, 'Avoca', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Ballarat Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90003, 'Ballarat Railway Station', -37.5587442, 143.8593693, 3, 'Ballarat', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Bannockburn
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90004, 'Bannockburn', -38.0443362, 144.1738367, 3, 'Bannockburn', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Beechworth
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90005, 'Beechworth', -36.3594929, 146.687012, 3, 'Beechworth', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Benalla Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90006, 'Benalla Railway Station', -36.544749, 145.9837177, 3, 'Benalla', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Bendigo Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90007, 'Bendigo Railway Station', -36.7655937, 144.2829551, 3, 'Bendigo', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Boort
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90008, 'Boort', -36.1177895, 143.7222634, 3, 'Boort', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Bright
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90009, 'Bright', -36.7285335, 146.9607724, 3, 'Bright', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Carisbrook
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90010, 'Carisbrook', -37.030783, 143.8373387, 3, 'Carisbrook', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Castlemaine Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90011, 'Castlemaine Railway Station', -37.0629409, 144.2140579, 3, 'Castlemaine', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Clunes
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90012, 'Clunes', -37.287625, 143.7802916, 3, 'Clunes', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Cowes
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90013, 'Cowes', -38.4502447, 145.2389787, 3, 'Cowes', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Creswick
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90014, 'Creswick', -37.4245857, 143.8939669, 3, 'Creswick', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Dandenong Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90015, 'Dandenong Railway Station', -37.9901275, 145.2098283, 3, 'Dandenong', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Dunolly
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90016, 'Dunolly', -36.8590029, 143.7337931, 3, 'Dunolly', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Elaine
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90017, 'Elaine', -37.761595, 144.0062833, 3, 'Elaine', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Euroa Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90018, 'Euroa Railway Station', -36.7491126, 145.5680907, 3, 'Euroa', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Geelong Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90019, 'Geelong Railway Station', -38.1442691, 144.355077, 3, 'Geelong', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Gisborne Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90020, 'Gisborne Railway Station', -37.4589623, 144.5990126, 3, 'Gisborne', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Harrietville
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90021, 'Harrietville', -36.8923168, 147.0638695, 3, 'Harrietville', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Inverloch
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90022, 'Inverloch', -38.6331582, 145.7279504, 3, 'Inverloch', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Kerang
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90023, 'Kerang', -35.7338373, 143.9204152, 3, 'Kerang', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Koo Wee Rup
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90024, 'Koo Wee Rup', -38.1990553, 145.492854, 3, 'Koo Wee Rup', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Lal Lal
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90025, 'Lal Lal', -37.6759746, 144.0127983, 3, 'Lal Lal', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Lang Lang
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90026, 'Lang Lang', -38.2660405, 145.5627778, 3, 'Lang Lang', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Lethbridge
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90027, 'Lethbridge', -37.9672272, 144.1331351, 3, 'Lethbridge', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Lorne
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90028, 'Lorne', -38.5411691, 143.9748166, 3, 'Lorne', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Maryborough Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90029, 'Maryborough Railway Station', -37.0511432, 143.7425571, 3, 'Maryborough', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Meredith
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90030, 'Meredith', -37.8436639, 144.0754653, 3, 'Meredith', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Mildura
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90031, 'Mildura', -34.195274, 142.1503146, 3, 'Mildura', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Moliagul
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90032, 'Moliagul', -36.74844, 143.6712011, 3, 'Moliagul', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Mount Beauty
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90033, 'Mount Beauty', -36.7487, 147.2287534, 3, 'Mount Beauty', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Myrtleford
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90034, 'Myrtleford', -36.5609628, 146.7236797, 3, 'Myrtleford', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Nelson (VIC)
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90035, 'Nelson (VIC)', -37.8166959, 145.1198034, 3, 'Nelson (VIC)', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Ouyen
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90036, 'Ouyen', -35.0692193, 142.3163729, 3, 'Ouyen', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Pakenham Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90037, 'Pakenham Railway Station', -38.0794537, 145.4849487, 3, 'Pakenham', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Port Fairy
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90038, 'Port Fairy', -38.3855117, 142.2366722, 3, 'Port Fairy', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Portland
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90039, 'Portland', -38.3456231, 141.6042304, 3, 'Portland', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Pyramid Hill
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90040, 'Pyramid Hill', -36.0543991, 144.1155932, 3, 'Pyramid Hill', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Red Cliffs
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90041, 'Red Cliffs', -34.3070205, 142.1895377, 3, 'Red Cliffs', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: San Remo
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90042, 'San Remo', -38.5214924, 145.369394, 3, 'San Remo', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Sea Lake
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90043, 'Sea Lake', -35.5056193, 142.8505187, 3, 'Sea Lake', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Seymour Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90044, 'Seymour Railway Station', -37.0244925, 145.1385109, 3, 'Seymour', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Southern Cross Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90045, 'Southern Cross Station', -37.8191925, 144.9533975, 3, 'Southern Cross Station', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Sunbury Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90046, 'Sunbury Railway Station', -37.5791363, 144.7279832, 3, 'Sunbury', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Swan Hill Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90047, 'Swan Hill Railway Station', -35.3415855, 143.5624857, 3, 'Swan Hill', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Talbot
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90048, 'Talbot', -37.176182, 143.6947955, 3, 'Talbot', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Tarnagulla
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90049, 'Tarnagulla', -36.7753645, 143.8306588, 3, 'Tarnagulla', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Torquay
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90050, 'Torquay', -38.3266551, 144.3134076, 3, 'Torquay', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Wangaratta Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90051, 'Wangaratta Railway Station', -36.3552044, 146.316922, 3, 'Wangaratta', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Warrnambool Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90052, 'Warrnambool Railway Station', -38.3850449, 142.4754663, 3, 'Warrnambool', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Wedderburn
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90053, 'Wedderburn', -36.4192187, 143.6143424, 3, 'Wedderburn', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Wonthaggi
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90054, 'Wonthaggi', -38.6043664, 145.5913433, 3, 'Wonthaggi', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;

-- Stop: Woodend Railway Station
INSERT INTO stops (stop_id, stop_name, stop_lat, stop_lon, route_type, stop_suburb, landmark)
VALUES (90055, 'Woodend Railway Station', -37.3592999, 144.5260842, 3, 'Woodend', NULL)
ON CONFLICT (stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon;


-- ============================================
-- Insert Routes
-- ============================================

-- Route: Warrnambool - Melbourne (via Great Ocean Road)
-- Stops: 10
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour, geopath)
VALUES (
    20001,
    'Warrnambool - Melbourne (via Great Ocean Road)',
    'GOR',
    3,
    'coach-GOR',  -- Placeholder GTFS ID
    'FF6600',
    '{"type": "LineString", "coordinates": [[142.4754663, -38.3850449], [142.2366722, -38.3855117], [141.6042304, -38.3456231], [145.1198034, -37.8166959], [143.6691463, -38.7547442], [143.9748166, -38.5411691], [144.188958, -38.4051948], [144.3134076, -38.3266551], [144.355077, -38.1442691], [144.9533975, -37.8191925]]}'::jsonb
)
ON CONFLICT (route_id) DO UPDATE SET
    route_name = EXCLUDED.route_name,
    geopath = EXCLUDED.geopath;

-- Route: Mildura - Melbourne (via Swan Hill and Bendigo)
-- Stops: 15
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour, geopath)
VALUES (
    20002,
    'Mildura - Melbourne (via Swan Hill and Bendigo)',
    'MBM',
    3,
    'coach-MBM',  -- Placeholder GTFS ID
    'FF6600',
    '{"type": "LineString", "coordinates": [[142.1503146, -34.195274], [142.1895377, -34.3070205], [142.3163729, -35.0692193], [142.8505187, -35.5056193], [143.5624857, -35.3415855], [143.9204152, -35.7338373], [144.1155932, -36.0543991], [143.7222634, -36.1177895], [143.6143424, -36.4192187], [144.2829551, -36.7655937], [144.2140579, -37.0629409], [144.5260842, -37.3592999], [144.5990126, -37.4589623], [144.7279832, -37.5791363], [144.9533975, -37.8191925]]}'::jsonb
)
ON CONFLICT (route_id) DO UPDATE SET
    route_name = EXCLUDED.route_name,
    geopath = EXCLUDED.geopath;

-- Route: Geelong - Bendigo (via Ballarat)
-- Stops: 17
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour, geopath)
VALUES (
    20003,
    'Geelong - Bendigo (via Ballarat)',
    'GBB',
    3,
    'coach-GBB',  -- Placeholder GTFS ID
    'FF6600',
    '{"type": "LineString", "coordinates": [[144.355077, -38.1442691], [144.1738367, -38.0443362], [144.1331351, -37.9672272], [144.0754653, -37.8436639], [144.0062833, -37.761595], [144.0127983, -37.6759746], [143.8593693, -37.5587442], [143.8939669, -37.4245857], [143.7802916, -37.287625], [143.6947955, -37.176182], [143.7425571, -37.0511432], [143.8373387, -37.030783], [143.473745, -37.0889278], [143.7337931, -36.8590029], [143.6712011, -36.74844], [143.8306588, -36.7753645], [144.2829551, -36.7655937]]}'::jsonb
)
ON CONFLICT (route_id) DO UPDATE SET
    route_name = EXCLUDED.route_name,
    geopath = EXCLUDED.geopath;

-- Route: Bright - Melbourne (via Wangaratta)
-- Stops: 10
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour, geopath)
VALUES (
    20004,
    'Bright - Melbourne (via Wangaratta)',
    'BBM',
    3,
    'coach-BBM',  -- Placeholder GTFS ID
    'FF6600',
    '{"type": "LineString", "coordinates": [[146.9607724, -36.7285335], [147.0638695, -36.8923168], [147.2287534, -36.7487], [146.687012, -36.3594929], [146.7236797, -36.5609628], [146.316922, -36.3552044], [145.9837177, -36.544749], [145.5680907, -36.7491126], [145.1385109, -37.0244925], [144.9533975, -37.8191925]]}'::jsonb
)
ON CONFLICT (route_id) DO UPDATE SET
    route_name = EXCLUDED.route_name,
    geopath = EXCLUDED.geopath;

-- Route: Cowes - Melbourne (via Koo Wee Rup and Dandenong)
-- Stops: 9
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour, geopath)
VALUES (
    20005,
    'Cowes - Melbourne (via Koo Wee Rup and Dandenong)',
    'CIM',
    3,
    'coach-CIM',  -- Placeholder GTFS ID
    'FF6600',
    '{"type": "LineString", "coordinates": [[145.2389787, -38.4502447], [145.369394, -38.5214924], [145.7279504, -38.6331582], [145.5913433, -38.6043664], [145.5627778, -38.2660405], [145.492854, -38.1990553], [145.4849487, -38.0794537], [145.2098283, -37.9901275], [144.9533975, -37.8191925]]}'::jsonb
)
ON CONFLICT (route_id) DO UPDATE SET
    route_name = EXCLUDED.route_name,
    geopath = EXCLUDED.geopath;


-- ============================================
-- Summary
-- ============================================

-- Verify inserts
SELECT 'Stops inserted:', COUNT(*) FROM stops WHERE stop_id >= 90000 AND stop_id < 91000;
SELECT 'Routes inserted:', COUNT(*) FROM routes WHERE route_id >= 20001 AND route_id <= 20005;

-- Route details:
-- 20001: Warrnambool - Melbourne (via Great Ocean Road) - 10 stops
-- 20002: Mildura - Melbourne (via Swan Hill and Bendigo) - 15 stops
-- 20003: Geelong - Bendigo (via Ballarat) - 17 stops
-- 20004: Bright - Melbourne (via Wangaratta) - 10 stops
-- 20005: Cowes - Melbourne (via Koo Wee Rup and Dandenong) - 9 stops

COMMIT;

-- End of import script