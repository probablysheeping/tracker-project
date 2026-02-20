CREATE TEMP TABLE temp_stops (
    stop_id text,
    stop_code text,
    stop_name text,
    stop_lat double precision,
    stop_lon double precision,
    location_type text,
    parent_station text,
    wheelchair_boarding text,
    level_id text,
    platform_code text
);

\COPY temp_stops FROM 'C:/Users/edw37/OneDrive/Documents/CS/gtfs/4/extracted/stops.txt' CSV HEADER;

INSERT INTO gtfs_stops (gtfs_stop_id, stop_name, stop_lat, stop_lon, location_type, parent_station, wheelchair_boarding, level_id, platform_code)
SELECT stop_id, stop_name, stop_lat, stop_lon, location_type, parent_station, wheelchair_boarding, level_id, platform_code
FROM temp_stops
ON CONFLICT (gtfs_stop_id) DO UPDATE SET
    stop_name = EXCLUDED.stop_name,
    stop_lat = EXCLUDED.stop_lat,
    stop_lon = EXCLUDED.stop_lon,
    platform_code = EXCLUDED.platform_code;
