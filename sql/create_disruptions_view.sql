-- Create a view that pre-parses JSONB data from disruptions table
-- This makes it easier to query disruption data with parsed routes and stops

CREATE OR REPLACE VIEW disruptions_parsed AS
SELECT
    d.disruption_id,
    d.title,
    d.url,
    d.description,
    d.disruption_status,
    d.disruption_type,
    d.published_on,
    d.last_updated,
    d.from_date,
    d.to_date,
    d.colour,
    d.display_on_board,
    d.display_status,
    d.route_type,

    -- Original JSONB fields
    d.routes,
    d.stops,

    -- Parsed and aggregated data
    COALESCE(
        (SELECT string_agg(r.value->>'route_name', ', ' ORDER BY r.ordinality)
         FROM jsonb_array_elements(d.routes) WITH ORDINALITY AS r(value, ordinality)),
        ''
    ) as route_names,

    COALESCE(
        (SELECT string_agg(s.value->>'stop_name', ', ' ORDER BY s.ordinality)
         FROM jsonb_array_elements(d.stops) WITH ORDINALITY AS s(value, ordinality)),
        ''
    ) as stop_names,

    COALESCE(jsonb_array_length(d.routes), 0) as num_routes,
    COALESCE(jsonb_array_length(d.stops), 0) as num_stops,

    -- Extract first route info (useful for single-route disruptions)
    (d.routes->0->>'route_id')::int as primary_route_id,
    d.routes->0->>'route_name' as primary_route_name,

    -- Extract first stop info (useful for single-stop disruptions)
    (d.stops->0->>'stop_id')::int as primary_stop_id,
    d.stops->0->>'stop_name' as primary_stop_name,

    -- Active status
    CASE
        WHEN (d.from_date IS NULL OR d.from_date <= NOW())
         AND (d.to_date IS NULL OR d.to_date >= NOW())
        THEN true
        ELSE false
    END as is_active

FROM disruptions d;

-- Create an index-friendly view for active disruptions only
CREATE OR REPLACE VIEW active_disruptions AS
SELECT * FROM disruptions_parsed
WHERE display_status = true
  AND is_active = true;

-- Example queries using the views:
-- Get all active train disruptions:
-- SELECT * FROM active_disruptions WHERE route_type = 0;

-- Get disruptions affecting multiple routes:
-- SELECT * FROM disruptions_parsed WHERE num_routes > 1;

-- Get disruptions with stop closures:
-- SELECT * FROM disruptions_parsed WHERE num_stops > 0;
