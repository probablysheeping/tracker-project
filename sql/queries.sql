-- Regenerate shapes table from gtfs_shapes
-- This ensures clean shape data without corrupted stop coordinates mixed in

-- Step 1: Clear and populate shapes from gtfs_shapes
TRUNCATE TABLE shapes;

INSERT INTO shapes (shape_id, shape_pt_lat, shape_pt_lon, shape_pt_sequence, shape_dist_traveled)
SELECT shape_id, shape_pt_lat, shape_pt_lon, shape_pt_sequence, shape_dist_traveled
FROM gtfs_shapes;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_shapes_shape_id_seq ON shapes(shape_id, shape_pt_sequence);

-- Step 2: Regenerate stop_trip_sequence table
-- Uses shape_dist_traveled from gtfs_stop_times to find the correct shape point for each stop
-- This is more accurate than nearest-point matching because it uses the actual GTFS distance data
TRUNCATE TABLE stop_trip_sequence;

INSERT INTO stop_trip_sequence (trip_id, stop_id, shape_pt_sequence)
SELECT DISTINCT ON (st.trip_id, s.stop_id)
    st.trip_id,
    s.stop_id,
    sh.shape_pt_sequence
FROM gtfs_stop_times st
JOIN gtfs_trips t ON t.trip_id = st.trip_id
JOIN gtfs_stops gs ON gs.gtfs_stop_id = st.stop_id
-- Support both parent_station and direct gtfs_stop_id mapping (for trams/V/Line)
JOIN stops s ON s.gtfs_parent_station = gs.gtfs_stop_id OR s.gtfs_parent_station = gs.parent_station
JOIN shapes sh ON sh.shape_id = t.shape_id
WHERE st.shape_dist_traveled IS NOT NULL
  AND sh.shape_dist_traveled IS NOT NULL
ORDER BY st.trip_id, s.stop_id, ABS(sh.shape_dist_traveled - st.shape_dist_traveled);

-- Create stop_trip_sequence table if it doesn't exist
-- CREATE TABLE IF NOT EXISTS stop_trip_sequence
-- (
--     trip_id text,
--     stop_id int,
--     shape_pt_sequence int,
--     PRIMARY KEY (trip_id, stop_id)
-- );
