-- Populate stops table with tram, bus, and V/Line stops from GTFS data

-- Insert tram stops (route_type = 1)
WITH tram_stops AS (
    SELECT DISTINCT
        gs.gtfs_stop_id,
        gs.stop_name,
        gs.stop_lat,
        gs.stop_lon,
        ROW_NUMBER() OVER (ORDER BY gs.gtfs_stop_id) + (SELECT COALESCE(MAX(stop_id), 0) FROM stops) as new_stop_id
    FROM gtfs_stops gs
    WHERE EXISTS (
        SELECT 1
        FROM gtfs_stop_times gst
        JOIN gtfs_trips gt ON gst.trip_id = gt.trip_id
        JOIN gtfs_routes gr ON gt.route_id = gr.route_id
        WHERE gst.stop_id = gs.gtfs_stop_id
        AND gr.route_type = 1
    )
    AND (gs.location_type IS NULL OR gs.location_type = '' OR gs.location_type = '0')
)
INSERT INTO stops (stop_id, stop_name, stop_latitude, stop_longitude, route_type, gtfs_parent_station)
SELECT
    new_stop_id,
    stop_name,
    stop_lat,
    stop_lon,
    1,
    gtfs_stop_id
FROM tram_stops;

-- Insert bus stops (route_type = 2)
WITH bus_stops AS (
    SELECT DISTINCT
        gs.gtfs_stop_id,
        gs.stop_name,
        gs.stop_lat,
        gs.stop_lon,
        ROW_NUMBER() OVER (ORDER BY gs.gtfs_stop_id) + (SELECT COALESCE(MAX(stop_id), 0) FROM stops) as new_stop_id
    FROM gtfs_stops gs
    WHERE EXISTS (
        SELECT 1
        FROM gtfs_stop_times gst
        JOIN gtfs_trips gt ON gst.trip_id = gt.trip_id
        JOIN gtfs_routes gr ON gt.route_id = gr.route_id
        WHERE gst.stop_id = gs.gtfs_stop_id
        AND gr.route_type = 2
    )
    AND (gs.location_type IS NULL OR gs.location_type = '' OR gs.location_type = '0')
    AND NOT EXISTS (
        SELECT 1 FROM stops WHERE gtfs_parent_station = gs.gtfs_stop_id
    )
)
INSERT INTO stops (stop_id, stop_name, stop_latitude, stop_longitude, route_type, gtfs_parent_station)
SELECT
    new_stop_id,
    stop_name,
    stop_lat,
    stop_lon,
    2,
    gtfs_stop_id
FROM bus_stops;

-- Insert V/Line stops (route_type = 3)
WITH vline_stops AS (
    SELECT DISTINCT
        gs.gtfs_stop_id,
        gs.stop_name,
        gs.stop_lat,
        gs.stop_lon,
        ROW_NUMBER() OVER (ORDER BY gs.gtfs_stop_id) + (SELECT COALESCE(MAX(stop_id), 0) FROM stops) as new_stop_id
    FROM gtfs_stops gs
    WHERE EXISTS (
        SELECT 1
        FROM gtfs_stop_times gst
        JOIN gtfs_trips gt ON gst.trip_id = gt.trip_id
        JOIN gtfs_routes gr ON gt.route_id = gr.route_id
        WHERE gst.stop_id = gs.gtfs_stop_id
        AND gr.route_type = 3
    )
    AND (gs.location_type IS NULL OR gs.location_type = '' OR gs.location_type = '0')
    AND NOT EXISTS (
        SELECT 1 FROM stops WHERE gtfs_parent_station = gs.gtfs_stop_id
    )
)
INSERT INTO stops (stop_id, stop_name, stop_latitude, stop_longitude, route_type, gtfs_parent_station)
SELECT
    new_stop_id,
    stop_name,
    stop_lat,
    stop_lon,
    3,
    gtfs_stop_id
FROM vline_stops;

-- Show results
SELECT route_type, COUNT(*) FROM stops GROUP BY route_type ORDER BY route_type;
