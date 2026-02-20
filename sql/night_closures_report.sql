-- ============================================================================
-- NIGHT CLOSURES & PLANNED WORKS - COMPLETE REPORT
-- Shows both Current and Planned disruptions with replacement buses
-- ============================================================================

\echo ''
\echo '======================================================================================================'
\echo 'UPCOMING NIGHT CLOSURES (Buses replace trains - Status: Planned or Future)'
\echo '======================================================================================================'
\echo ''

-- Upcoming night closures (from now onwards)
SELECT
    d.disruption_id,
    d.disruption_status,
    CASE d.route_type
        WHEN 0 THEN 'Train'
        WHEN 1 THEN 'Tram'
        WHEN 2 THEN 'Bus'
        WHEN 3 THEN 'V/Line'
    END AS type,
    (SELECT string_agg(route_elem->>'route_name', ', ')
     FROM jsonb_array_elements(d.routes) AS route_elem) AS affected_lines,
    d.title,
    d.from_date AT TIME ZONE 'Australia/Melbourne' AS start_time,
    d.to_date AT TIME ZONE 'Australia/Melbourne' AS end_time,
    CASE
        WHEN d.from_date > CURRENT_TIMESTAMP THEN 'Upcoming'
        WHEN d.from_date <= CURRENT_TIMESTAMP AND d.to_date > CURRENT_TIMESTAMP THEN 'ACTIVE NOW'
        ELSE 'Ended'
    END AS status,
    d.description
FROM
    disruptions d
WHERE
    d.route_type = 0
    AND LOWER(d.title) ~ 'buses replace'
    AND d.from_date >= CURRENT_TIMESTAMP - INTERVAL '7 days'
    AND d.disruption_status IN ('Current', 'Planned')
ORDER BY
    d.from_date;


\echo ''
\echo '======================================================================================================'
\echo 'RECENT NIGHT CLOSURES (Past 7 days - for reference)'
\echo '======================================================================================================'
\echo ''

SELECT
    d.disruption_id,
    (SELECT string_agg(route_elem->>'route_name', ', ')
     FROM jsonb_array_elements(d.routes) AS route_elem) AS affected_lines,
    d.title,
    d.from_date::date AS date,
    to_char(d.from_date AT TIME ZONE 'Australia/Melbourne', 'HH24:MI') || ' - ' ||
    to_char(d.to_date AT TIME ZONE 'Australia/Melbourne', 'HH24:MI Day') AS time_period
FROM
    disruptions d
WHERE
    d.route_type = 0
    AND LOWER(d.title) ~ 'buses replace'
    AND d.to_date < CURRENT_TIMESTAMP
    AND d.to_date >= CURRENT_TIMESTAMP - INTERVAL '7 days'
    AND d.disruption_status IN ('Current', 'Planned')
ORDER BY
    d.from_date DESC;


\echo ''
\echo '======================================================================================================'
\echo 'ALL CURRENT ROUTE-LEVEL TRAIN DISRUPTIONS (Including station access changes)'
\echo '======================================================================================================'
\echo ''

SELECT
    d.disruption_id,
    d.disruption_type,
    d.disruption_status,
    (SELECT string_agg(route_elem->>'route_name', ', ')
     FROM jsonb_array_elements(d.routes) AS route_elem) AS affected_lines,
    d.title,
    d.from_date::date AS start_date,
    CASE
        WHEN d.to_date IS NULL THEN 'Ongoing'
        ELSE d.to_date::date::text
    END AS end_date,
    CASE
        WHEN LOWER(d.title || ' ' || d.description) ~ 'buses replace' THEN 'Replacement Bus'
        WHEN LOWER(d.title || ' ' || d.description) ~ '(car park|parking)' THEN 'Car Park'
        WHEN LOWER(d.title || ' ' || d.description) ~ 'timetable' THEN 'Timetable Change'
        WHEN LOWER(d.title || ' ' || d.description) ~ 'access|detour' THEN 'Access Change'
        ELSE 'Other'
    END AS impact_type
FROM
    disruptions d
WHERE
    d.route_type = 0
    AND d.disruption_status IN ('Current', 'Planned')
    AND jsonb_array_length(d.stops) = 0
    AND (d.to_date IS NULL OR d.to_date > CURRENT_TIMESTAMP)
ORDER BY
    CASE
        WHEN LOWER(d.title || ' ' || d.description) ~ 'buses replace' THEN 1
        ELSE 2
    END,
    d.from_date;
