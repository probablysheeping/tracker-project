-- ============================================================================
-- COMPREHENSIVE DISRUPTION ANALYSIS
-- Text-based analysis to identify which stops are truly closed
-- ============================================================================

-- Create view with text-based severity categorization
DROP VIEW IF EXISTS disruption_analysis CASCADE;

CREATE VIEW disruption_analysis AS
SELECT
    d.disruption_id,
    d.title,
    d.description,
    d.disruption_type,
    d.disruption_status,
    d.from_date,
    d.to_date,
    d.route_type,
    (jsonb_array_elements(d.stops)->>'stop_id')::integer AS stop_id,
    jsonb_array_elements(d.stops)->>'stop_name' AS stop_name_from_disruption,
    -- Text analysis for severity
    CASE
        -- CRITICAL: Stop/Station completely closed or no service
        WHEN (
            LOWER(d.title || ' ' || d.description) ~ '(station closed|stop closed|station is closed|stop is closed|no trains|no buses|no trams|no services|not stopping|will not stop|station will be closed|stop will be closed|will not service)'
            AND LOWER(d.title || ' ' || d.description) !~ '(car park|parking|pedestrian access|lift|escalator)'
        ) THEN 'CRITICAL'

        -- HIGH: Major disruption with replacement services or significant changes
        WHEN (
            LOWER(d.title || ' ' || d.description) ~ '(replacement bus|bus replacement|major disruption|station detour|limited access)'
        ) THEN 'HIGH'

        -- MEDIUM: Delays or service alterations
        WHEN (
            LOWER(d.title || ' ' || d.description) ~ '(delay|altered|changed|different)'
            AND d.disruption_type IN ('Minor Delays', 'Major Delays', 'Timetable/Route Changes')
        ) THEN 'MEDIUM'

        -- LOW: Facility closures but service continues
        WHEN (
            LOWER(d.title || ' ' || d.description) ~ '(car park|parking|pedestrian access|lift|escalator|toilet|waiting room|ticket office)'
        ) THEN 'LOW'

        -- INFO: Everything else
        ELSE 'INFO'
    END AS severity,
    d.url
FROM
    disruptions d
WHERE
    d.disruption_status = 'Current'
    AND jsonb_array_length(d.stops) > 0
    AND (d.to_date IS NULL OR d.to_date > CURRENT_TIMESTAMP);


-- ============================================================================
-- MAIN RESULTS: Stations/Stops that are ACTUALLY down (CRITICAL severity)
-- ============================================================================

\echo ''
\echo '======================================================================================================'
\echo 'CRITICAL: STOPS/STATIONS THAT ARE ACTUALLY CLOSED (NO SERVICE)'
\echo '======================================================================================================'
\echo ''

SELECT
    s.stop_id,
    COALESCE(s.stop_name, da.stop_name_from_disruption) AS stop_name,
    s.stop_suburb,
    CASE da.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
        ELSE 'Unknown'
    END AS route_type,
    da.disruption_type,
    da.title,
    da.from_date::date AS start_date,
    CASE
        WHEN da.to_date IS NULL THEN 'Indefinite'
        ELSE da.to_date::date::text
    END AS end_date,
    LEFT(da.description, 200) AS description_preview,
    da.url
FROM
    disruption_analysis da
    LEFT JOIN stops s ON da.stop_id = s.stop_id
WHERE
    da.severity = 'CRITICAL'
ORDER BY
    da.route_type, s.stop_name;


-- ============================================================================
-- HIGH SEVERITY: Major disruptions (replacement buses, detours, etc.)
-- ============================================================================

\echo ''
\echo '======================================================================================================'
\echo 'HIGH: MAJOR DISRUPTIONS (Replacement buses, detours, limited access)'
\echo '======================================================================================================'
\echo ''

SELECT
    s.stop_id,
    COALESCE(s.stop_name, da.stop_name_from_disruption) AS stop_name,
    s.stop_suburb,
    CASE da.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
    END AS route_type,
    da.title,
    da.from_date::date AS start_date,
    CASE
        WHEN da.to_date IS NULL THEN 'Indefinite'
        ELSE da.to_date::date::text
    END AS end_date,
    da.url
FROM
    disruption_analysis da
    LEFT JOIN stops s ON da.stop_id = s.stop_id
WHERE
    da.severity = 'HIGH'
ORDER BY
    da.route_type, s.stop_name
LIMIT 10;


-- ============================================================================
-- SUMMARY: Count by severity
-- ============================================================================

\echo ''
\echo '======================================================================================================'
\echo 'SUMMARY: Disruption counts by severity level'
\echo '======================================================================================================'
\echo ''

SELECT
    severity,
    COUNT(DISTINCT stop_id) AS unique_stops,
    COUNT(DISTINCT disruption_id) AS total_disruptions,
    COUNT(DISTINCT CASE WHEN route_type = 0 THEN stop_id END) AS train_stops,
    COUNT(DISTINCT CASE WHEN route_type = 1 THEN stop_id END) AS tram_stops,
    COUNT(DISTINCT CASE WHEN route_type = 2 THEN stop_id END) AS bus_stops,
    COUNT(DISTINCT CASE WHEN route_type = 3 THEN stop_id END) AS vline_stops
FROM
    disruption_analysis
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


-- ============================================================================
-- QUICK LIST: Just station names that are down (for easy reference)
-- ============================================================================

\echo ''
\echo '======================================================================================================'
\echo 'QUICK REFERENCE: Unique stations/stops affected (CRITICAL + HIGH)'
\echo '======================================================================================================'
\echo ''

SELECT DISTINCT
    COALESCE(s.stop_name, da.stop_name_from_disruption) AS stop_name,
    s.stop_suburb,
    CASE da.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
    END AS route_type,
    da.severity
FROM
    disruption_analysis da
    LEFT JOIN stops s ON da.stop_id = s.stop_id
WHERE
    da.severity IN ('CRITICAL', 'HIGH')
ORDER BY
    da.severity DESC,
    route_type,
    stop_name;
