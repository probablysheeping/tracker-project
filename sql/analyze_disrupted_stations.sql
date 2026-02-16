-- ============================================================================
-- ANALYZE DISRUPTED STATIONS
-- This script extracts and analyzes stations affected by disruptions
-- ============================================================================

-- Query 1: Extract all affected stops from current disruptions
-- This unnests the JSONB stops array and joins with the stops table
-- ============================================================================
DROP VIEW IF EXISTS current_disrupted_stops CASCADE;

CREATE VIEW current_disrupted_stops AS
SELECT
    d.disruption_id,
    d.title,
    d.disruption_type,
    d.disruption_status,
    d.from_date,
    d.to_date,
    d.route_type,
    (jsonb_array_elements(d.stops)->>'stop_id')::integer AS stop_id,
    jsonb_array_elements(d.stops)->>'stop_name' AS disruption_stop_name,
    s.stop_name AS actual_stop_name,
    s.stop_latitude,
    s.stop_longitude,
    s.stop_suburb,
    s.stop_landmark,
    d.description,
    d.url
FROM
    disruptions d
    CROSS JOIN LATERAL jsonb_array_elements(d.stops) AS stop_elem
    LEFT JOIN stops s ON (stop_elem->>'stop_id')::integer = s.stop_id
WHERE
    d.disruption_status = 'Current'
    AND jsonb_array_length(d.stops) > 0
ORDER BY
    d.route_type, s.stop_name;


-- Query 2: Summary of affected stops by route type
-- ============================================================================
SELECT
    route_type,
    CASE route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
        ELSE 'Unknown'
    END AS route_type_name,
    COUNT(DISTINCT stop_id) AS affected_stops,
    COUNT(DISTINCT disruption_id) AS total_disruptions
FROM
    current_disrupted_stops
GROUP BY
    route_type
ORDER BY
    route_type;


-- Query 3: List all currently disrupted stations (deduplicated)
-- ============================================================================
SELECT
    stop_id,
    actual_stop_name AS stop_name,
    stop_suburb,
    stop_landmark,
    route_type,
    CASE route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
    END AS route_type_name,
    COUNT(*) AS disruption_count,
    array_agg(DISTINCT disruption_type) AS disruption_types,
    MIN(from_date) AS earliest_disruption,
    MAX(to_date) AS latest_end_date
FROM
    current_disrupted_stops
GROUP BY
    stop_id, actual_stop_name, stop_suburb, stop_landmark, route_type
ORDER BY
    disruption_count DESC, route_type, actual_stop_name;


-- Query 4: Stations with "Planned Closure" disruptions (likely actually down)
-- ============================================================================
SELECT
    stop_id,
    actual_stop_name AS stop_name,
    stop_suburb,
    route_type,
    CASE route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
    END AS route_type_name,
    disruption_type,
    from_date,
    to_date,
    CASE
        WHEN to_date IS NULL THEN 'Indefinite'
        WHEN to_date > CURRENT_TIMESTAMP THEN 'Active until ' || to_date::date::text
        ELSE 'Ended'
    END AS closure_status,
    title,
    url
FROM
    current_disrupted_stops
WHERE
    disruption_type IN ('Planned Closure', 'Station detour', 'Power outage')
    AND (to_date IS NULL OR to_date > CURRENT_TIMESTAMP)
ORDER BY
    route_type, actual_stop_name;


-- Query 5: Detailed view - All current disruptions with affected stops
-- ============================================================================
SELECT
    disruption_id,
    title,
    disruption_type,
    disruption_status,
    CASE
        WHEN from_date IS NOT NULL THEN from_date::date::text
        ELSE 'Not specified'
    END AS start_date,
    CASE
        WHEN to_date IS NOT NULL THEN to_date::date::text
        ELSE 'Not specified'
    END AS end_date,
    stop_id,
    actual_stop_name AS stop_name,
    stop_suburb,
    route_type,
    description,
    url
FROM
    current_disrupted_stops
ORDER BY
    route_type, disruption_type, actual_stop_name;


-- Query 6: Find stops with multiple overlapping disruptions
-- ============================================================================
SELECT
    stop_id,
    actual_stop_name AS stop_name,
    stop_suburb,
    route_type,
    COUNT(*) AS concurrent_disruptions,
    string_agg(DISTINCT disruption_type, ', ') AS disruption_types,
    string_agg(DISTINCT title, ' | ') AS titles
FROM
    current_disrupted_stops
GROUP BY
    stop_id, actual_stop_name, stop_suburb, route_type
HAVING
    COUNT(*) > 1
ORDER BY
    concurrent_disruptions DESC, route_type;
