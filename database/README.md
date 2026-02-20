# Database Backup

This directory contains a compressed PostgreSQL database dump for the PTV Tracker application.

## Files

The database backup is split into multiple parts due to GitHub's 100MB file size limit:

- `tracker_db_backup.sql.gz.partaa` - Part 1 (90MB)
- `tracker_db_backup.sql.gz.partab` - Part 2 (90MB)
- `tracker_db_backup.sql.gz.partac` - Part 3 (90MB)
- `tracker_db_backup.sql.gz.partad` - Part 4 (25MB)

**Total size**: 295MB compressed when reassembled

## Database Contents

The database includes:
- **GTFS data** - Complete General Transit Feed Specification data for Melbourne's public transport
- **Processed routes** - Routes with colors, geopaths, and pattern expansions (Metro Tunnel, City Loop, etc.)
- **Stops** - All train, tram, bus, and V/Line stops with coordinates
- **Routing graph** - 18,214 edges for multi-modal trip planning
  - 3,530 route edges (trains, trams, V/Line)
  - 5,666 hub edges (same-stop transfers)
  - 9,018 proximity transfer edges (cross-modal transfers)
- **Shapes** - Detailed route geometries for map visualization
- **Disruptions** - Service disruption data
- **Stop-trip sequences** - Mappings for accurate geopath generation

## Reassemble Split Files

The database backup is split into multiple parts. First, reassemble them:

### Linux/Mac/Git Bash (Windows)
```bash
cd database
cat tracker_db_backup.sql.gz.part* > tracker_db_backup.sql.gz
```

### Windows PowerShell
```powershell
cd database
Get-Content tracker_db_backup.sql.gz.part* -Encoding Byte -ReadCount 0 | Set-Content tracker_db_backup.sql.gz -Encoding Byte
```

### Windows Command Prompt
```cmd
cd database
copy /b tracker_db_backup.sql.gz.partaa+tracker_db_backup.sql.gz.partab+tracker_db_backup.sql.gz.partac+tracker_db_backup.sql.gz.partad tracker_db_backup.sql.gz
```

After reassembly, verify the file size is approximately 295MB.

## Restore Instructions

### Prerequisites

- PostgreSQL 16+ installed
- At least 2GB free disk space (uncompressed database is larger)

### Full Restore

```bash
# 1. Create database
createdb -U postgres tracker

# 2. Restore from compressed dump
gunzip -c tracker_db_backup.sql.gz | psql -U postgres -d tracker

# Or in one step:
PGPASSWORD=password gunzip -c tracker_db_backup.sql.gz | psql -U postgres -h localhost -p 5432 -d tracker
```

### Windows (PowerShell)

```powershell
# Extract and restore
gzip -d tracker_db_backup.sql.gz
psql -U postgres -d tracker -f tracker_db_backup.sql

# Or use 7-Zip if gzip not available
7z x tracker_db_backup.sql.gz
psql -U postgres -d tracker -f tracker_db_backup.sql
```

### Verify Restore

```sql
-- Check table counts
SELECT 'routes' AS table_name, COUNT(*) AS row_count FROM routes
UNION ALL
SELECT 'stops', COUNT(*) FROM stops
UNION ALL
SELECT 'edges_v2', COUNT(*) FROM edges_v2
UNION ALL
SELECT 'shapes', COUNT(*) FROM shapes
UNION ALL
SELECT 'disruptions', COUNT(*) FROM disruptions;
```

Expected counts (approximate):
- routes: 31 (with expanded patterns)
- stops: ~3,000+
- edges_v2: 18,214
- shapes: ~500,000+ points
- disruptions: varies (current active disruptions)

## Connection Details

After restore, the backend expects:
- **Host**: localhost
- **Port**: 5432
- **Database**: tracker
- **User**: postgres
- **Password**: password (hardcoded in `Services/database.cs`)

## Updating the Backup

To create a new backup with updated data:

```bash
# Full backup
PGPASSWORD=password pg_dump -U postgres -h localhost -p 5432 tracker | gzip > tracker_db_backup.sql.gz

# Or without compression (larger file)
PGPASSWORD=password pg_dump -U postgres -h localhost -p 5432 tracker > tracker_db_backup.sql
```

## File Size Considerations

- **Compressed**: ~295MB
- **Uncompressed**: ~1.5GB+
- **Installed database**: ~2GB+ with indexes

The database is compressed with gzip to reduce repository size. The uncompressed SQL dump would be significantly larger.

## Data Sources

The GTFS data is sourced from Public Transport Victoria (PTV):
- Download: https://www.ptv.vic.gov.au/footer/data-and-reporting/datasets/ptv-timetable-api/
- Updated: [Date of GTFS data import]

## Schema Documentation

For detailed schema information, see:
- `DATABASE-AGENT.md` - Complete database schema and table descriptions
- `queries.sql` - Data processing queries
- `edges.sql` / `generate_all_modes_edges.sql` - Routing graph generation
- `create_proximity_transfers.sql` - Transfer edge generation

## Regenerating Data

If you need to regenerate parts of the database:

### Routing Graph
```bash
psql -U postgres -d tracker -f ../generate_all_modes_edges.sql
psql -U postgres -d tracker -f ../create_proximity_transfers.sql
```

### Shape Mappings
```bash
psql -U postgres -d tracker -f ../queries.sql
```

## Troubleshooting

### Restore Fails with "role does not exist"
```bash
# Create postgres user if needed
createuser -U postgres postgres
```

### Out of Memory During Restore
```bash
# Increase PostgreSQL memory settings
# Edit postgresql.conf:
shared_buffers = 2GB
work_mem = 256MB
maintenance_work_mem = 1GB
```

### Slow Restore Performance
- Disable indexes before restore, rebuild after
- Increase `maintenance_work_mem`
- Use `-j` flag for parallel restore (custom format only)

## Backup Date

This backup was created on: **February 16, 2025**

## License

The GTFS data is provided by Public Transport Victoria under their data licensing terms.
