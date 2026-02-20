-- ============================================================================
-- COMPLETE DISRUPTION ANALYSIS
-- Includes both stop-specific disruptions AND route-level disruptions
-- ============================================================================

\echo ''
\echo '======================================================================================================'
\echo 'ROUTE-LEVEL DISRUPTIONS (No specific stops listed - affects entire route sections)'
\echo '======================================================================================================'
\echo ''

-- Query 1: Route-level disruptions (empty stops array)
SELECT
    d.disruption_id,
    d.title,
    d.disruption_type,
    d.disruption_status,
    CASE d.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
    END AS route_type,
    d.from_date::date AS start_date,
    CASE
        WHEN d.to_date IS NULL THEN 'Indefinite'
        ELSE d.to_date::date::text
    END AS end_date,
    -- Extract route names from routes JSONB
    (SELECT string_agg(route_elem->>'route_name', ', ')
     FROM jsonb_array_elements(d.routes) AS route_elem) AS affected_routes,
    -- Categorize severity
    CASE
        WHEN (LOWER(d.title || ' ' || d.description) ~ '(buses replace trains|buses replace trams|no trains|no trams|line closed|station closed)')
            THEN 'HIGH'
        WHEN d.disruption_type IN ('Planned Works', 'Planned Closure', 'Power outage', 'Station detour')
            THEN 'MEDIUM'
        ELSE 'LOW'
    END AS severity,
    LEFT(d.description, 250) AS description_preview,
    d.url
FROM
    disruptions d
WHERE
    d.disruption_status = 'Current'
    AND jsonb_array_length(d.stops) = 0
    AND (d.to_date IS NULL OR d.to_date > CURRENT_TIMESTAMP)
ORDER BY
    CASE
        WHEN (LOWER(d.title || ' ' || d.description) ~ '(buses replace trains|buses replace trams|no trains|no trams)') THEN 1
        ELSE 2
    END,
    d.route_type,
    d.from_date DESC;


\echo ''
\echo '======================================================================================================'
\echo 'NIGHT CLOSURES & REPLACEMENT BUS SERVICES (Train lines with buses replacing trains)'
\echo '======================================================================================================'
\echo ''

-- Query 2: Specifically highlight replacement bus services
SELECT
    CASE d.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
    END AS route_type,
    (SELECT string_agg(route_elem->>'route_name', ', ')
     FROM jsonb_array_elements(d.routes) AS route_elem) AS line_name,
    d.title,
    d.from_date::timestamp AS start_datetime,
    d.to_date::timestamp AS end_datetime,
    CASE
        WHEN LOWER(d.title || ' ' || d.description) ~ 'night|evening|8:?30\s?pm|pm to last service'
            THEN 'Night Works'
        ELSE 'All Day'
    END AS timing,
    d.description,
    d.url
FROM
    disruptions d
WHERE
    d.disruption_status = 'Current'
    AND (d.to_date IS NULL OR d.to_date > CURRENT_TIMESTAMP)
    AND LOWER(d.title || ' ' || d.description) ~ '(buses replace trains|buses replace trams|replacement bus)'
ORDER BY
    d.route_type,
    d.from_date;


\echo ''
\echo '======================================================================================================'
\echo 'STOP-SPECIFIC CLOSURES (Individual stops not being serviced)'
\echo '======================================================================================================'
\echo ''

-- Query 3: Stop-specific disruptions (reuse previous logic)
SELECT
    CASE d.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
        WHEN 4 THEN 'Night Bus'
    END AS route_type,
    (jsonb_array_elements(d.stops)->>'stop_name') AS stop_name,
    d.disruption_type,
    d.title,
    d.from_date::date AS start_date,
    CASE
        WHEN d.to_date IS NULL THEN 'Indefinite'
        ELSE d.to_date::date::text
    END AS end_date
FROM
    disruptions d
WHERE
    d.disruption_status = 'Current'
    AND jsonb_array_length(d.stops) > 0
    AND (d.to_date IS NULL OR d.to_date > CURRENT_TIMESTAMP)
    AND LOWER(d.title || ' ' || d.description) ~ '(will not service|not stopping|stop closed|station closed)'
    AND LOWER(d.title || ' ' || d.description) !~ '(car park|parking|pedestrian access)'
ORDER BY
    d.route_type,
    d.from_date;


\echo ''
\echo '======================================================================================================'
\echo 'SUMMARY: All current disruptions by category'
\echo '======================================================================================================'
\echo ''

-- Query 4: Summary statistics
SELECT
    'Route-Level Disruptions' AS category,
    COUNT(*) AS total_disruptions,
    COUNT(*) FILTER (WHERE route_type = 0) AS train,
    COUNT(*) FILTER (WHERE route_type = 1) AS tram,
    COUNT(*) FILTER (WHERE route_type = 2) AS bus,
    COUNT(*) FILTER (WHERE route_type = 3) AS vline
FROM disruptions
WHERE disruption_status = 'Current'
  AND jsonb_array_length(stops) = 0
  AND (to_date IS NULL OR to_date > CURRENT_TIMESTAMP)

UNION ALL

SELECT
    'Stop-Specific Closures' AS category,
    COUNT(*) AS total_disruptions,
    COUNT(*) FILTER (WHERE route_type = 0) AS train,
    COUNT(*) FILTER (WHERE route_type = 1) AS tram,
    COUNT(*) FILTER (WHERE route_type = 2) AS bus,
    COUNT(*) FILTER (WHERE route_type = 3) AS vline
FROM disruptions
WHERE disruption_status = 'Current'
  AND jsonb_array_length(stops) > 0
  AND (to_date IS NULL OR to_date > CURRENT_TIMESTAMP)

UNION ALL

SELECT
    'Replacement Bus Services' AS category,
    COUNT(*) AS total_disruptions,
    COUNT(*) FILTER (WHERE route_type = 0) AS train,
    COUNT(*) FILTER (WHERE route_type = 1) AS tram,
    COUNT(*) FILTER (WHERE route_type = 2) AS bus,
    COUNT(*) FILTER (WHERE route_type = 3) AS vline
FROM disruptions
WHERE disruption_status = 'Current'
  AND (to_date IS NULL OR to_date > CURRENT_TIMESTAMP)
  AND LOWER(title || ' ' || description) ~ '(buses replace trains|buses replace trams|replacement bus)'
ORDER BY category;
