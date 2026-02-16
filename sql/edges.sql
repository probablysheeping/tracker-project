INSERT INTO edges (route_id, source, target, cost, distance_km)
SELECT DISTINCT ON (route_id, origin, next_stop_id)
    route_id, origin, next_stop_id,
    ABS(gtfs_time_to_seconds(next_arrival) - gtfs_time_to_seconds(arrival_time))/60 AS cost,
    ABS(next_dist - shape_dist_traveled)/1000 AS distance_km
FROM (
    SELECT
        r2.route_id,
        s.stop_id AS origin,
        LEAD(s.stop_id) OVER (PARTITION BY trips.route_id ORDER BY st.stop_sequence) AS next_stop_id,
        LEAD(st.arrival_time) OVER (PARTITION BY trips.route_id ORDER BY st.stop_sequence) AS next_arrival,
        st.arrival_time, st.shape_dist_traveled,
        LEAD(st.shape_dist_traveled) OVER (PARTITION BY trips.route_id ORDER BY st.stop_sequence) AS next_dist
    FROM (
        SELECT DISTINCT ON (r.route_id) r.route_id, t.trip_id
        FROM gtfs_routes r
        JOIN gtfs_trips t ON t.route_id = r.route_id
        ORDER BY r.route_id, t.trip_id
    ) trips
    JOIN gtfs_stop_times st ON st.trip_id = trips.trip_id
    JOIN gtfs_stops gs ON gs.gtfs_stop_id = st.stop_id
    JOIN stops s ON s.gtfs_parent_station = gs.parent_station
    JOIN routes r2 ON trips.route_id = 'aus:vic:vic-0' || r2.route_gtfs_id || ':'
                   OR trips.route_id = 'aus:vic:vic-0' || r2.route_gtfs_id || '-R:'
) sub
WHERE next_stop_id IS NOT NULL
ORDER BY route_id, origin, next_stop_id;