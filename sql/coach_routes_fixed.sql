-- V/Line Coach Routes Import (Fixed)
-- Generated: 2025-12-29
-- Total Routes: 5
-- Total Stops: 56

BEGIN;

-- ==========================================
-- Insert Coach Routes
-- ==========================================

-- Route 20001: Warrnambool - Melbourne (via Great Ocean Road)
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour)
VALUES (20001, 'Warrnambool - Melbourne (via Great Ocean Road)', 'GOR', 3, 'coach-GOR', ARRAY[255, 102, 0])
ON CONFLICT (route_id) DO UPDATE SET
    route_name = EXCLUDED.route_name,
    route_colour = EXCLUDED.route_colour;

-- Route 20002: Mildura - Melbourne (via Swan Hill and Bendigo)
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour)
VALUES (20002, 'Mildura - Melbourne (via Swan Hill and Bendigo)', 'MBM', 3, 'coach-MBM', ARRAY[255, 102, 0])
ON CONFLICT (route_id) DO UPDATE SET
    route_name = EXCLUDED.route_name,
    route_colour = EXCLUDED.route_colour;

-- Route 20003: Geelong - Bendigo (via Ballarat)
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour)
VALUES (20003, 'Geelong - Bendigo (via Ballarat)', 'GBB', 3, 'coach-GBB', ARRAY[255, 102, 0])
ON CONFLICT (route_id) DO UPDATE SET
    route_name = EXCLUDED.route_name,
    route_colour = EXCLUDED.route_colour;

-- Route 20004: Bright - Melbourne (via Wangaratta)
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour)
VALUES (20004, 'Bright - Melbourne (via Wangaratta)', 'BBM', 3, 'coach-BBM', ARRAY[255, 102, 0])
ON CONFLICT (route_id) DO UPDATE SET
    route_name = EXCLUDED.route_name,
    route_colour = EXCLUDED.route_colour;

-- Route 20005: Cowes - Melbourne (via Koo Wee Rup and Dandenong)
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour)
VALUES (20005, 'Cowes - Melbourne (via Koo Wee Rup and Dandenong)', 'CIM', 3, 'coach-CIM', ARRAY[255, 102, 0])
ON CONFLICT (route_id) DO UPDATE SET
    route_name = EXCLUDED.route_name,
    route_colour = EXCLUDED.route_colour;

-- ==========================================
-- Insert Geopaths for Route 20001
-- ==========================================
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20001, -38.3850449, 142.4754663); -- Warrnambool Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20001, -38.3855117, 142.2366722); -- Port Fairy
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20001, -38.3456231, 141.6042304); -- Portland
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20001, -37.8166959, 145.1198034); -- Nelson (VIC)
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20001, -38.7547442, 143.6691463); -- Apollo Bay
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20001, -38.5411691, 143.9748166); -- Lorne
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20001, -38.4051948, 144.188958); -- Anglesea
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20001, -38.3266551, 144.3134076); -- Torquay
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20001, -38.1442691, 144.355077); -- Geelong Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20001, -37.8191925, 144.9533975); -- Southern Cross Station

-- ==========================================
-- Insert Geopaths for Route 20002
-- ==========================================
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -34.195274, 142.1503146); -- Mildura
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -34.3070205, 142.1895377); -- Red Cliffs
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -35.0692193, 142.3163729); -- Ouyen
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -35.5056193, 142.8505187); -- Sea Lake
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -35.3415855, 143.5624857); -- Swan Hill Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -35.7338373, 143.9204152); -- Kerang
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -36.0543991, 144.1155932); -- Pyramid Hill
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -36.1177895, 143.7222634); -- Boort
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -36.4192187, 143.6143424); -- Wedderburn
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -36.7655937, 144.2829551); -- Bendigo Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -37.0629409, 144.2140579); -- Castlemaine Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -37.3592999, 144.5260842); -- Woodend Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -37.4589623, 144.5990126); -- Gisborne Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -37.5791363, 144.7279832); -- Sunbury Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20002, -37.8191925, 144.9533975); -- Southern Cross Station

-- ==========================================
-- Insert Geopaths for Route 20003
-- ==========================================
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -38.1442691, 144.355077); -- Geelong Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -38.0443362, 144.1738367); -- Bannockburn
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -37.9672272, 144.1331351); -- Lethbridge
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -37.8436639, 144.0754653); -- Meredith
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -37.761595, 144.0062833); -- Elaine
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -37.6759746, 144.0127983); -- Lal Lal
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -37.5587442, 143.8593693); -- Ballarat Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -37.4245857, 143.8939669); -- Creswick
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -37.287625, 143.7802916); -- Clunes
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -37.176182, 143.6947955); -- Talbot
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -37.0511432, 143.7425571); -- Maryborough Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -37.030783, 143.8373387); -- Carisbrook
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -37.0889278, 143.473745); -- Avoca
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -36.8590029, 143.7337931); -- Dunolly
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -36.74844, 143.6712011); -- Moliagul
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -36.7753645, 143.8306588); -- Tarnagulla
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20003, -36.7655937, 144.2829551); -- Bendigo Railway Station

-- ==========================================
-- Insert Geopaths for Route 20004
-- ==========================================
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20004, -36.7285335, 146.9607724); -- Bright
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20004, -36.8923168, 147.0638695); -- Harrietville
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20004, -36.7487, 147.2287534); -- Mount Beauty
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20004, -36.3594929, 146.687012); -- Beechworth
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20004, -36.5609628, 146.7236797); -- Myrtleford
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20004, -36.3552044, 146.316922); -- Wangaratta Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20004, -36.544749, 145.9837177); -- Benalla Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20004, -36.7491126, 145.5680907); -- Euroa Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20004, -37.0244925, 145.1385109); -- Seymour Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20004, -37.8191925, 144.9533975); -- Southern Cross Station

-- ==========================================
-- Insert Geopaths for Route 20005
-- ==========================================
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20005, -38.4502447, 145.2389787); -- Cowes
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20005, -38.5214924, 145.369394); -- San Remo
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20005, -38.6331582, 145.7279504); -- Inverloch
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20005, -38.6043664, 145.5913433); -- Wonthaggi
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20005, -38.2660405, 145.5627778); -- Lang Lang
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20005, -38.1990553, 145.492854); -- Koo Wee Rup
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20005, -38.0794537, 145.4849487); -- Pakenham Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20005, -37.9901275, 145.2098283); -- Dandenong Railway Station
INSERT INTO geopath (route_id, latitude, longitude) VALUES (20005, -37.8191925, 144.9533975); -- Southern Cross Station

COMMIT;

-- Summary
SELECT 'Routes inserted:', COUNT(*) FROM routes WHERE route_id >= 20001 AND route_id <= 20005;
SELECT 'Geopath points inserted:', COUNT(*) FROM geopath WHERE route_id >= 20001 AND route_id <= 20005;
