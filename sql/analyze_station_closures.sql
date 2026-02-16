-- ============================================================================
-- IDENTIFY STATIONS THAT ARE ACTUALLY DOWN
-- This filters for true closures vs minor disruptions
-- ============================================================================

-- Create a simplified view that categorizes disruption severity
DROP VIEW IF EXISTS station_closure_severity CASCADE;

CREATE VIEW station_closure_severity AS
SELECT
    d.disruption_id,
    d.title,
    d.disruption_type,
    d.disruption_status,
    d.description,
    d.from_date,
    d.to_date,
    d.route_type,
    (jsonb_array_elements(d.stops)->>'stop_id')::integer AS stop_id,
    jsonb_array_elements(d.stops)->>'stop_name' AS stop_name,
    -- Categorize severity based on disruption type and title keywords
    CASE
        WHEN disruption_type IN ('Power outage', 'Station detour') THEN 'CRITICAL'
        WHEN disruption_type = 'Planned Closure' AND
             (LOWER(title) LIKE '%station closed%' OR
              LOWER(title) LIKE '%station closure%' OR
              LOWER(description) LIKE '%station will be closed%' OR
              LOWER(description) LIKE '%no trains%' OR
              LOWER(description) LIKE '%station is closed%')
             AND LOWER(title) NOT LIKE '%car park%'
             AND LOWER(title) NOT LIKE '%parking%' THEN 'HIGH'
        WHEN disruption_type = 'Planned Closure' AND
             (LOWER(title) LIKE '%car park%' OR
              LOWER(title) LIKE '%parking%' OR
              LOWER(title) LIKE '%pedestrian access%') THEN 'LOW'
        WHEN disruption_type IN ('Major Delays', 'Minor Delays') THEN 'MEDIUM'
        ELSE 'INFO'
    END AS severity,
    d.url
FROM
    disruptions d
WHERE
    d.disruption_status = 'Current'
    AND jsonb_array_length(d.stops) > 0
    AND (to_date IS NULL OR to_date > CURRENT_TIMESTAMP);


-- Query 1: Stations that are ACTUALLY closed (CRITICAL or HIGH severity)
-- ============================================================================
SELECT
    s.stop_id,
    s.stop_name,
    s.stop_suburb,
    sc.route_type,
    CASE sc.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
    END AS route_type_name,
    sc.severity,
    sc.disruption_type,
    sc.title,
    sc.from_date::date AS start_date,
    CASE
        WHEN sc.to_date IS NULL THEN 'Indefinite'
        ELSE sc.to_date::date::text
    END AS end_date,
    sc.description,
    sc.url
FROM
    station_closure_severity sc
    LEFT JOIN stops s ON sc.stop_id = s.stop_id
WHERE
    sc.severity IN ('CRITICAL', 'HIGH')
ORDER BY
    sc.severity DESC,
    sc.route_type,
    s.stop_name;


-- Query 2: Summary by severity
-- ============================================================================
SELECT
    severity,
    COUNT(DISTINCT stop_id) AS affected_stops,
    COUNT(DISTINCT disruption_id) AS disruption_count,
    string_agg(DISTINCT disruption_type, ', ') AS disruption_types
FROM
    station_closure_severity
GROUP BY
    severity
ORDER BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
        ELSE 5
    END;


-- Query 3: Quick list - Just the station names that are down (HIGH/CRITICAL only)
-- ============================================================================
SELECT DISTINCT
    s.stop_name,
    s.stop_suburb,
    CASE sc.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
    END AS route_type_name,
    sc.severity
FROM
    station_closure_severity sc
    LEFT JOIN stops s ON sc.stop_id = s.stop_id
WHERE
    sc.severity IN ('CRITICAL', 'HIGH')
    AND s.stop_name IS NOT NULL
ORDER BY
    sc.severity DESC,
    s.stop_name;
