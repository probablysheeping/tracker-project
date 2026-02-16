# Database Agent Guide

This file provides specialized guidance for PostgreSQL database management and GTFS data operations for the PTV Tracker application.

## Agent Role

You are a database specialist focusing on:
- PostgreSQL schema design and optimization
- GTFS (General Transit Feed Specification) data processing
- Routing graph generation and maintenance
- Query optimization and indexing
- Data integrity and migrations
- Backup and recovery

## Database Stack

- **Database**: PostgreSQL 16+
- **Driver**: Npgsql 10.0.0 (C# client)
- **Data Format**: GTFS (General Transit Feed Specification)
- **Spatial Data**: PostGIS (optional, for future spatial queries)
- **Connection**: localhost:5432, database: `tracker`, user: `postgres`, password: `password`

## Database Schema

### Core Application Tables

#### routes
Processed route data from GTFS.

```sql
CREATE TABLE routes (
    route_id INTEGER PRIMARY KEY,
    route_name TEXT NOT NULL,
    route_number TEXT,
    route_type INTEGER NOT NULL,
    route_gtfs_id TEXT,
    route_colour JSONB,  -- {RGB: [r, g, b]}
    geopath JSONB        -- GeoJSON LineString
);

CREATE INDEX idx_routes_type ON routes(route_type);
CREATE INDEX idx_routes_gtfs_id ON routes(route_gtfs_id);
```

**Route Types**:
- 0 = Train (Metro)
- 1 = Tram
- 2 = Bus
- 3 = V/Line (Regional train/coach)
- 4 = Night Bus

#### stops
Stop locations and metadata.

```sql
CREATE TABLE stops (
    stop_id INTEGER PRIMARY KEY,
    stop_name TEXT NOT NULL,
    stop_latitude DOUBLE PRECISION NOT NULL,
    stop_longitude DOUBLE PRECISION NOT NULL,
    route_type INTEGER NOT NULL,
    gtfs_stop_id TEXT,
    gtfs_parent_station TEXT,
    stop_suburb TEXT,
    stop_landmark TEXT,
    stop_ticket JSONB,       -- Ticket zone information
    interchange INTEGER[]    -- Connected route types
);

CREATE INDEX idx_stops_route_type ON stops(route_type);
CREATE INDEX idx_stops_gtfs_id ON stops(gtfs_stop_id);
CREATE INDEX idx_stops_parent ON stops(gtfs_parent_station);
CREATE INDEX idx_stops_location ON stops(stop_latitude, stop_longitude);
```

#### edges_v2
Routing graph with route-aware edges.

```sql
CREATE TABLE edges_v2 (
    route_id INTEGER NOT NULL,
    source BIGINT NOT NULL,      -- Composite: (stop_id × 1B) + route_id
    target BIGINT NOT NULL,      -- Composite: (stop_id × 1B) + route_id
    cost DOUBLE PRECISION NOT NULL,  -- Travel time in minutes
    distance_km DOUBLE PRECISION,
    edge_type TEXT NOT NULL,     -- 'route', 'hub', or 'transfer'
    PRIMARY KEY (route_id, source, target)
);

CREATE INDEX idx_edges_source ON edges_v2(source);
CREATE INDEX idx_edges_target ON edges_v2(target);
CREATE INDEX idx_edges_route ON edges_v2(route_id);
CREATE INDEX idx_edges_type ON edges_v2(edge_type);
```

**Node ID Encoding**:
```
nodeId = (stop_id × 1,000,000,000) + route_id

Examples:
- Stop 1071 on route 14: 1071000000014
- Stop 1071 hub (all routes): 1071000000000
```

**Edge Types**:
- `route`: Direct connection within a route (actual transit service)
- `hub`: Transfer between routes at same station (route_id=0, 2.5 min penalty)
- `transfer`: Cross-modal proximity transfer (200m/500m thresholds)

#### shapes
Detailed route geometry from GTFS.

```sql
CREATE TABLE shapes (
    shape_id TEXT NOT NULL,
    shape_pt_lat DOUBLE PRECISION NOT NULL,
    shape_pt_lon DOUBLE PRECISION NOT NULL,
    shape_pt_sequence INTEGER NOT NULL,
    shape_dist_traveled DOUBLE PRECISION,
    PRIMARY KEY (shape_id, shape_pt_sequence)
);

CREATE INDEX idx_shapes_id ON shapes(shape_id);
```

#### stop_trip_sequence
Maps stops to shape points for accurate route visualization.

```sql
CREATE TABLE stop_trip_sequence (
    stop_id INTEGER NOT NULL,
    gtfs_trip_id TEXT NOT NULL,
    shape_id TEXT NOT NULL,
    stop_sequence INTEGER NOT NULL,
    shape_sequence INTEGER NOT NULL,
    PRIMARY KEY (stop_id, gtfs_trip_id)
);

CREATE INDEX idx_stop_trip_stop ON stop_trip_sequence(stop_id);
CREATE INDEX idx_stop_trip_shape ON stop_trip_sequence(shape_id);
```

#### disruptions
Service disruption information from PTV API.

```sql
CREATE TABLE disruptions (
    disruption_id BIGINT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    route_type INTEGER NOT NULL,
    severity TEXT,
    from_date TIMESTAMP,
    to_date TIMESTAMP,
    display_status BOOLEAN DEFAULT true,
    routes JSONB,           -- Array of affected route IDs
    stops JSONB,            -- Array of affected stop IDs
    disruption_event JSONB  -- Full event data including periods
);

CREATE INDEX idx_disruptions_route_type ON disruptions(route_type);
CREATE INDEX idx_disruptions_status ON disruptions(display_status);
CREATE INDEX idx_disruptions_dates ON disruptions(from_date, to_date);
```

#### route_types
Route type definitions and mapping to disruption modes.

```sql
CREATE TABLE route_types (
    route_type INTEGER PRIMARY KEY,
    route_type_name TEXT NOT NULL,
    disruption_mode_id INTEGER,
    FOREIGN KEY (disruption_mode_id) REFERENCES disruption_modes(disruption_mode_id)
);

INSERT INTO route_types VALUES
    (0, 'Train', 1),      -- Metro train
    (1, 'Tram', 3),       -- Metro tram
    (2, 'Bus', 2),        -- Metro bus
    (3, 'V/Line', NULL),  -- Regional (multiple modes)
    (4, 'Night Bus', 4);  -- Night bus
```

### GTFS Raw Tables

These store unprocessed GTFS data:

- `gtfs_routes` - Route definitions
- `gtfs_trips` - Trip patterns
- `gtfs_stops` - Stop locations
- `gtfs_stop_times` - Stop sequences and times
- `gtfs_shapes` - Shape geometries
- `gtfs_calendar` - Service calendar
- `gtfs_calendar_dates` - Service exceptions

## Data Processing

### GTFS Data Import

**Load GTFS files**:
```sql
-- Copy from CSV files
COPY gtfs_routes FROM '/path/to/routes.txt' DELIMITER ',' CSV HEADER;
COPY gtfs_trips FROM '/path/to/trips.txt' DELIMITER ',' CSV HEADER;
COPY gtfs_stops FROM '/path/to/stops.txt' DELIMITER ',' CSV HEADER;
COPY gtfs_stop_times FROM '/path/to/stop_times.txt' DELIMITER ',' CSV HEADER;
COPY gtfs_shapes FROM '/path/to/shapes.txt' DELIMITER ',' CSV HEADER;
```

### Route Processing

**Extract and process routes** (from `queries.sql`):
```sql
INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour)
SELECT DISTINCT ON (gr.route_id)
    CAST(gr.route_id AS INTEGER),
    gr.route_long_name,
    gr.route_short_name,
    gr.route_type,
    gr.route_id::text,
    json_build_object('RGB', ARRAY[
        COALESCE(('x' || LPAD(SUBSTRING(gr.route_color, 1, 2), 2, '0'))::bit(8)::int, 0),
        COALESCE(('x' || LPAD(SUBSTRING(gr.route_color, 3, 2), 2, '0'))::bit(8)::int, 0),
        COALESCE(('x' || LPAD(SUBSTRING(gr.route_color, 5, 2), 2, '0'))::bit(8)::int, 0)
    ])::jsonb
FROM gtfs_routes gr
WHERE gr.route_type IN (0, 1, 2, 3, 4)
ORDER BY gr.route_id;
```

### Stop Processing

**Extract and deduplicate stops**:
```sql
INSERT INTO stops (stop_id, stop_name, stop_latitude, stop_longitude, route_type, gtfs_stop_id, gtfs_parent_station)
SELECT
    ROW_NUMBER() OVER (ORDER BY gs.stop_id) AS stop_id,
    gs.stop_name,
    gs.stop_lat,
    gs.stop_lon,
    COALESCE(gr.route_type, 0) AS route_type,
    gs.stop_id AS gtfs_stop_id,
    gs.parent_station AS gtfs_parent_station
FROM gtfs_stops gs
LEFT JOIN gtfs_stop_times gst ON gs.stop_id = gst.stop_id
LEFT JOIN gtfs_trips gt ON gst.trip_id = gt.trip_id
LEFT JOIN gtfs_routes gr ON gt.route_id = gr.route_id
WHERE gs.parent_station IS NOT NULL
GROUP BY gs.stop_id, gs.stop_name, gs.stop_lat, gs.stop_lon, gr.route_type, gs.parent_station;
```

### Shape Processing

**Process shape geometries** (from `queries.sql`):
```sql
INSERT INTO shapes (shape_id, shape_pt_lat, shape_pt_lon, shape_pt_sequence, shape_dist_traveled)
SELECT DISTINCT
    gs.shape_id,
    gs.shape_pt_lat,
    gs.shape_pt_lon,
    gs.shape_pt_sequence,
    gs.shape_dist_traveled
FROM gtfs_shapes gs
WHERE gs.shape_id IN (
    SELECT DISTINCT gt.shape_id
    FROM gtfs_trips gt
    WHERE gt.route_id IN (SELECT route_gtfs_id FROM routes)
)
ORDER BY gs.shape_id, gs.shape_pt_sequence;
```

**Map stops to shapes**:
```sql
INSERT INTO stop_trip_sequence (stop_id, gtfs_trip_id, shape_id, stop_sequence, shape_sequence)
SELECT DISTINCT ON (s.stop_id, gt.trip_id)
    s.stop_id,
    gt.trip_id AS gtfs_trip_id,
    gt.shape_id,
    gst.stop_sequence,
    -- Find closest shape point
    (SELECT gs.shape_pt_sequence
     FROM gtfs_shapes gs
     WHERE gs.shape_id = gt.shape_id
     ORDER BY ABS(gs.shape_dist_traveled - gst.shape_dist_traveled)
     LIMIT 1) AS shape_sequence
FROM stops s
JOIN gtfs_stops gs ON s.gtfs_parent_station = gs.gtfs_stop_id
    OR s.gtfs_parent_station = gs.parent_station
JOIN gtfs_stop_times gst ON gs.stop_id = gst.stop_id
JOIN gtfs_trips gt ON gst.trip_id = gt.trip_id
WHERE gt.shape_id IS NOT NULL
ORDER BY s.stop_id, gt.trip_id;
```

## Routing Graph Generation

### Route Edges

**Generate route-specific edges** (from `generate_all_modes_edges.sql`):
```sql
-- Helper function to convert GTFS time to seconds
CREATE OR REPLACE FUNCTION gtfs_time_to_seconds(time_str TEXT)
RETURNS INTEGER AS $$
DECLARE
    parts TEXT[];
    hours INTEGER;
    minutes INTEGER;
    seconds INTEGER;
BEGIN
    parts := string_to_array(time_str, ':');
    hours := CAST(parts[1] AS INTEGER);
    minutes := CAST(parts[2] AS INTEGER);
    seconds := CAST(parts[3] AS INTEGER);
    RETURN hours * 3600 + minutes * 60 + seconds;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Generate edges for trains, trams, V/Line (exclude buses for performance)
INSERT INTO edges_v2 (route_id, source, target, cost, distance_km, edge_type)
SELECT DISTINCT
    r.route_id,
    (st1.stop_id::bigint * 1000000000) + r.route_id AS source,
    (st2.stop_id::bigint * 1000000000) + r.route_id AS target,
    GREATEST(1, ABS(gtfs_time_to_seconds(gst2.arrival_time) -
                    gtfs_time_to_seconds(gst1.arrival_time)) / 60.0) AS cost,
    -- Calculate distance using Haversine formula (simplified)
    111.0 * SQRT(
        POW(st2.stop_latitude - st1.stop_latitude, 2) +
        POW((st2.stop_longitude - st1.stop_longitude) *
            COS(RADIANS(st1.stop_latitude)), 2)
    ) AS distance_km,
    'route' AS edge_type
FROM routes r
JOIN gtfs_routes gr ON r.route_gtfs_id = (
    CASE
        WHEN r.route_type IN (0, 1, 3) THEN 'aus:vic:vic-0' || r.route_gtfs_id || ':'
        ELSE r.route_gtfs_id
    END
)
JOIN gtfs_trips gt ON gr.route_id = gt.route_id
JOIN gtfs_stop_times gst1 ON gt.trip_id = gst1.trip_id
JOIN gtfs_stop_times gst2 ON gt.trip_id = gst2.trip_id
    AND gst2.stop_sequence = gst1.stop_sequence + 1
JOIN stops st1 ON gst1.stop_id = st1.gtfs_stop_id
JOIN stops st2 ON gst2.stop_id = st2.gtfs_stop_id
WHERE r.route_type IN (0, 1, 3)  -- Train, Tram, V/Line only
    AND gst1.arrival_time IS NOT NULL
    AND gst2.arrival_time IS NOT NULL;
```

### Hub Edges

**Generate same-station transfer edges**:
```sql
-- Create hub nodes for same-station transfers
INSERT INTO edges_v2 (route_id, source, target, cost, distance_km, edge_type)
SELECT DISTINCT
    0 AS route_id,  -- Hub node indicator
    (stop_id::bigint * 1000000000) AS source,
    (stop_id::bigint * 1000000000) + route_id AS target,
    2.5 AS cost,  -- 2.5 minute transfer penalty
    0.0 AS distance_km,
    'hub' AS edge_type
FROM (
    SELECT DISTINCT s.stop_id, r.route_id
    FROM stops s
    CROSS JOIN routes r
    WHERE EXISTS (
        SELECT 1 FROM gtfs_stop_times gst
        JOIN gtfs_trips gt ON gst.trip_id = gt.trip_id
        JOIN stops s2 ON gst.stop_id = s2.gtfs_stop_id
        WHERE s2.stop_id = s.stop_id
            AND gt.route_id LIKE '%' || r.route_gtfs_id || '%'
    )
) route_stops;

-- Bidirectional hub edges
INSERT INTO edges_v2 (route_id, source, target, cost, distance_km, edge_type)
SELECT route_id, target AS source, source AS target, cost, distance_km, edge_type
FROM edges_v2
WHERE edge_type = 'hub';
```

### Proximity Transfer Edges

**Generate cross-modal transfer edges** (from `create_proximity_transfers.sql`):
```sql
-- Create proximity-based transfers between different modes
INSERT INTO edges_v2 (route_id, source, target, cost, distance_km, edge_type)
SELECT
    r1.route_id,
    (s1.stop_id::bigint * 1000000000) + r1.route_id AS source,
    (s2.stop_id::bigint * 1000000000) + r2.route_id AS target,
    CASE
        WHEN r1.route_type = 1 OR r2.route_type = 1 THEN 4.0  -- Tram: 4 min
        ELSE 3.0  -- Train/V/Line: 3 min
    END AS cost,
    111.0 * SQRT(
        POW(s2.stop_latitude - s1.stop_latitude, 2) +
        POW((s2.stop_longitude - s1.stop_longitude) *
            COS(RADIANS(s1.stop_latitude)), 2)
    ) AS distance_km,
    'transfer' AS edge_type
FROM stops s1
CROSS JOIN stops s2
JOIN routes r1 ON TRUE
JOIN routes r2 ON TRUE
WHERE s1.stop_id != s2.stop_id
    AND (
        -- 200m threshold for tram transfers
        (r1.route_type = 1 OR r2.route_type = 1)
        AND 111.0 * SQRT(
            POW(s2.stop_latitude - s1.stop_latitude, 2) +
            POW((s2.stop_longitude - s1.stop_longitude) *
                COS(RADIANS(s1.stop_latitude)), 2)
        ) <= 0.2
    ) OR (
        -- 500m threshold for train/V/Line transfers
        (r1.route_type IN (0, 3) AND r2.route_type IN (0, 3))
        AND 111.0 * SQRT(
            POW(s2.stop_latitude - s1.stop_latitude, 2) +
            POW((s2.stop_longitude - s1.stop_longitude) *
                COS(RADIANS(s1.stop_latitude)), 2)
        ) <= 0.5
    );
```

## Query Optimization

### Essential Indexes

```sql
-- Routes
CREATE INDEX idx_routes_type ON routes(route_type);
CREATE INDEX idx_routes_gtfs_id ON routes(route_gtfs_id);

-- Stops
CREATE INDEX idx_stops_route_type ON stops(route_type);
CREATE INDEX idx_stops_gtfs_id ON stops(gtfs_stop_id);
CREATE INDEX idx_stops_parent ON stops(gtfs_parent_station);
CREATE INDEX idx_stops_location ON stops(stop_latitude, stop_longitude);

-- Edges (critical for pathfinding)
CREATE INDEX idx_edges_source ON edges_v2(source);
CREATE INDEX idx_edges_target ON edges_v2(target);
CREATE INDEX idx_edges_route ON edges_v2(route_id);
CREATE INDEX idx_edges_type ON edges_v2(edge_type);

-- Shapes
CREATE INDEX idx_shapes_id ON shapes(shape_id);
CREATE INDEX idx_shapes_sequence ON shapes(shape_id, shape_pt_sequence);

-- Stop-trip mapping
CREATE INDEX idx_stop_trip_stop ON stop_trip_sequence(stop_id);
CREATE INDEX idx_stop_trip_shape ON stop_trip_sequence(shape_id);

-- Disruptions
CREATE INDEX idx_disruptions_route_type ON disruptions(route_type);
CREATE INDEX idx_disruptions_status ON disruptions(display_status);
```

### Query Performance

**Analyze query plans**:
```sql
EXPLAIN ANALYZE
SELECT * FROM edges_v2
WHERE source = 1071000000014;
```

**Update statistics**:
```sql
ANALYZE routes;
ANALYZE stops;
ANALYZE edges_v2;
ANALYZE shapes;
```

**Vacuum tables**:
```sql
VACUUM ANALYZE routes;
VACUUM ANALYZE edges_v2;
```

## Database Maintenance

### Regenerate Routing Graph

**Full regeneration**:
```bash
# 1. Drop existing edges
psql -U postgres -d tracker -c "TRUNCATE TABLE edges_v2;"

# 2. Regenerate route edges
psql -U postgres -d tracker -f generate_all_modes_edges.sql

# 3. Generate hub edges
psql -U postgres -d tracker -f generate_hub_edges.sql

# 4. Generate proximity transfers
psql -U postgres -d tracker -f create_proximity_transfers.sql

# 5. Analyze for query optimization
psql -U postgres -d tracker -c "ANALYZE edges_v2;"
```

### Regenerate Shape Mappings

```bash
# Run queries.sql to rebuild shapes and stop_trip_sequence
psql -U postgres -d tracker -f queries.sql
```

**Performance optimization for large regenerations**:
```sql
-- Temporarily drop indexes
DROP INDEX IF EXISTS idx_stop_trip_stop;
DROP INDEX IF EXISTS idx_stop_trip_shape;

-- Increase work memory for session
SET work_mem = '4GB';
SET maintenance_work_mem = '16GB';
SET max_parallel_workers_per_gather = 12;

-- Run regeneration queries...

-- Recreate indexes
CREATE INDEX idx_stop_trip_stop ON stop_trip_sequence(stop_id);
CREATE INDEX idx_stop_trip_shape ON stop_trip_sequence(shape_id);
ANALYZE stop_trip_sequence;
```

### Backup and Restore

**Full database backup**:
```bash
pg_dump -U postgres tracker > tracker_backup_$(date +%Y%m%d).sql
```

**Compressed backup**:
```bash
pg_dump -U postgres tracker | gzip > tracker_backup_$(date +%Y%m%d).sql.gz
```

**Restore from backup**:
```bash
psql -U postgres -d tracker -f tracker_backup.sql

# Or for compressed:
gunzip -c tracker_backup.sql.gz | psql -U postgres -d tracker
```

**Table-specific backup**:
```bash
pg_dump -U postgres -t edges_v2 tracker > edges_backup.sql
```

## Data Quality

### Validation Queries

**Check for orphaned edges**:
```sql
SELECT COUNT(*)
FROM edges_v2 e
WHERE NOT EXISTS (
    SELECT 1 FROM stops
    WHERE stop_id = (e.source / 1000000000)::int
) OR NOT EXISTS (
    SELECT 1 FROM stops
    WHERE stop_id = (e.target / 1000000000)::int
);
```

**Check for missing geopaths**:
```sql
SELECT r.route_id, r.route_name
FROM routes r
WHERE r.geopath IS NULL
    AND r.route_type IN (0, 1, 3);  -- Should have geopaths
```

**Check stop coverage**:
```sql
SELECT s.stop_id, s.stop_name
FROM stops s
WHERE NOT EXISTS (
    SELECT 1 FROM edges_v2 e
    WHERE (e.source / 1000000000)::int = s.stop_id
       OR (e.target / 1000000000)::int = s.stop_id
);
```

**Check for disconnected components in graph**:
```sql
-- This requires recursive CTE to find reachable nodes
WITH RECURSIVE reachable AS (
    -- Start from Flinders Street (well-connected hub)
    SELECT DISTINCT source AS node
    FROM edges_v2
    WHERE (source / 1000000000)::int = 1071

    UNION

    SELECT e.target
    FROM edges_v2 e
    INNER JOIN reachable r ON e.source = r.node
)
SELECT COUNT(DISTINCT stop_id) AS total_stops,
       COUNT(DISTINCT (node / 1000000000)::int) AS reachable_stops,
       COUNT(DISTINCT stop_id) - COUNT(DISTINCT (node / 1000000000)::int) AS unreachable
FROM stops s
CROSS JOIN reachable;
```

## Common Tasks

### Add Coach Destinations

```sql
-- Add V/Line coach stops not in GTFS
INSERT INTO stops (stop_id, stop_name, stop_latitude, stop_longitude, route_type)
VALUES
    (90001, 'Apollo Bay', -38.7578, 143.6712, 3),
    (90002, 'Bright', -36.7294, 146.9594, 3),
    (90003, 'Mildura', -34.1889, 142.1583, 3),
    (90004, 'Lorne', -38.5414, 143.9787, 3),
    (90005, 'Cowes', -38.4592, 145.2372, 3),
    (90006, 'Inverloch', -38.6294, 145.6731, 3);
```

### Update Route Colors

```sql
UPDATE routes
SET route_colour = '{"RGB": [255, 0, 0]}'::jsonb
WHERE route_id = 14;
```

### Add New Route Type

```sql
-- Add to route_types table
INSERT INTO route_types (route_type, route_type_name, disruption_mode_id)
VALUES (5, 'Ferry', 6);

-- Update application to recognize new type
```

### Query Statistics

**Graph size**:
```sql
SELECT
    edge_type,
    COUNT(*) AS edge_count,
    AVG(cost) AS avg_cost,
    AVG(distance_km) AS avg_distance
FROM edges_v2
GROUP BY edge_type;
```

**Stops per route type**:
```sql
SELECT
    rt.route_type_name,
    COUNT(DISTINCT s.stop_id) AS stop_count
FROM stops s
JOIN route_types rt ON s.route_type = rt.route_type
GROUP BY rt.route_type_name;
```

## Troubleshooting

### "stop has no corresponding shape_id"

**Cause**: Stop not mapped in `stop_trip_sequence` table.

**Fix**:
```sql
-- Check if stop exists in mapping
SELECT * FROM stop_trip_sequence WHERE stop_id = 1104;

-- If missing, regenerate mappings
\i queries.sql
```

### "Pathfinding returns no route"

**Cause**: Disconnected graph, missing edges.

**Diagnose**:
```sql
-- Check if stop has outgoing edges
SELECT COUNT(*) FROM edges_v2
WHERE (source / 1000000000)::int = 1071;

-- Check if stop has incoming edges
SELECT COUNT(*) FROM edges_v2
WHERE (target / 1000000000)::int = 1071;
```

**Fix**: Regenerate edges for affected route type.

### "Edge generation takes too long"

**Cause**: Processing millions of GTFS records without optimization.

**Fix**:
```sql
-- Drop indexes before bulk insert
DROP INDEX idx_edges_source;
DROP INDEX idx_edges_target;

-- Set PostgreSQL parameters for bulk operations
SET work_mem = '4GB';
SET maintenance_work_mem = '16GB';

-- Run edge generation...

-- Recreate indexes
CREATE INDEX idx_edges_source ON edges_v2(source);
CREATE INDEX idx_edges_target ON edges_v2(target);
ANALYZE edges_v2;
```

## Best Practices

1. **Always backup before major changes** - Regenerating edges can take hours
2. **Use transactions** - Wrap multi-step operations in BEGIN/COMMIT
3. **Analyze after bulk operations** - Update query planner statistics
4. **Vacuum regularly** - Especially after large deletes
5. **Monitor query performance** - Use EXPLAIN ANALYZE
6. **Keep indexes updated** - After schema changes
7. **Document schema changes** - Maintain migration scripts
8. **Test on sample data first** - Before processing full GTFS
9. **Version control SQL scripts** - Track edge generation logic
10. **Log long-running queries** - Set `log_min_duration_statement`

## Need Help?

- Check main `CLAUDE.md` for project overview
- Review `queries.sql` for data processing examples
- See `edges.sql` and `generate_all_modes_edges.sql` for edge generation
- Check `create_proximity_transfers.sql` for transfer logic
- Use `\d tablename` in psql to view schema
- Use `EXPLAIN ANALYZE` to debug slow queries
- Check PostgreSQL logs for errors: `/var/log/postgresql/`
