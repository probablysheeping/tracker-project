# V/Line Coach Routes Import

## Overview

This directory contains scraped V/Line coach route data prepared for import into the PTV tracker database.

**Generated:** 2025-12-29
**Routes:** 5 sample routes
**Stops:** 56 unique locations
**Status:** Ready for review and import

## Files

| File | Description |
|------|-------------|
| `coach_routes.sql` | **Main import script** - Execute this to add routes to database |
| `coach_routes_geocoded.json` | Geocoded stop coordinates and route data |
| `coach_routes_data.json` | Raw route structure (before geocoding) |
| `geocode_stops.py` | Python script used to geocode stops via Nominatim API |
| `generate_sql.py` | Python script used to generate SQL from geocoded data |
| `coach_scraping.log` | Detailed log of the scraping/processing workflow |

## Routes Included

### 1. Warrnambool - Melbourne (Great Ocean Road)
- **Route ID:** 20001
- **Route Number:** GOR
- **Stops:** 10
- **Path:** Warrnambool → Port Fairy → Portland → Nelson → Apollo Bay → Lorne → Anglesea → Torquay → Geelong → Melbourne

**Highlights:** Popular tourist route along the Great Ocean Road

### 2. Mildura - Melbourne (via Swan Hill and Bendigo)
- **Route ID:** 20002
- **Route Number:** MBM
- **Stops:** 15
- **Path:** Mildura → Red Cliffs → Ouyen → Sea Lake → Swan Hill → Kerang → Pyramid Hill → Boort → Wedderburn → Bendigo → Castlemaine → Woodend → Gisborne → Sunbury → Melbourne

**Highlights:** Longest route, connects northern Victoria to Melbourne

### 3. Geelong - Bendigo (via Ballarat)
- **Route ID:** 20003
- **Route Number:** GBB
- **Stops:** 17
- **Path:** Geelong → Bannockburn → Lethbridge → Meredith → Elaine → Lal Lal → Ballarat → Creswick → Clunes → Talbot → Maryborough → Carisbrook → Avoca → Dunolly → Moliagul → Tarnagulla → Bendigo

**Highlights:** Major regional connector between two large regional cities

### 4. Bright - Melbourne (via Wangaratta)
- **Route ID:** 20004
- **Route Number:** BBM
- **Stops:** 10
- **Path:** Bright → Harrietville → Mount Beauty → Beechworth → Myrtleford → Wangaratta → Benalla → Euroa → Seymour → Melbourne

**Highlights:** Alpine region service, popular for skiing/tourism

### 5. Cowes - Melbourne (via Koo Wee Rup and Dandenong)
- **Route ID:** 20005
- **Route Number:** CIM
- **Stops:** 9
- **Path:** Cowes → San Remo → Inverloch → Wonthaggi → Lang Lang → Koo Wee Rup → Pakenham → Dandenong → Melbourne

**Highlights:** Coastal and island service (Phillip Island)

## Database Schema

### Stops Table
```sql
stop_id: 90000-90055 (to avoid conflicts)
stop_name: VARCHAR (e.g., "Bright", "Warrnambool Railway Station")
stop_lat: DECIMAL (latitude, WGS84)
stop_lon: DECIMAL (longitude, WGS84)
route_type: 3 (V/Line)
stop_suburb: VARCHAR (extracted from stop name)
```

### Routes Table
```sql
route_id: 20001-20005 (to avoid conflicts)
route_name: VARCHAR (e.g., "Warrnambool - Melbourne (via Great Ocean Road)")
route_number: VARCHAR (e.g., "GOR", "MBM")
route_type: 3 (V/Line)
route_gtfs_id: VARCHAR (placeholder: "coach-XXX")
route_colour: VARCHAR (hex: "FF6600" - orange)
geopath: JSONB (GeoJSON LineString)
```

## Sample GeoJSON

Each route has a complete geopath stored as a GeoJSON LineString:

```json
{
  "type": "LineString",
  "coordinates": [
    [142.4754663, -38.3850449],  // Warrnambool
    [142.2366722, -38.3855117],  // Port Fairy
    [141.6042304, -38.3456231],  // Portland
    ...
    [144.9533975, -37.8191925]   // Melbourne
  ]
}
```

Note: GeoJSON uses `[longitude, latitude]` order (not `[lat, lon]`).

## Installation

### Prerequisites
- PostgreSQL database running (localhost:5432)
- Database: `tracker`
- User: `postgres`
- Password: `password`

### Execute Import

```bash
# Navigate to SQL directory
cd C:\Users\edw37\OneDrive\Documents\CS\sql

# Execute SQL script
PGPASSWORD=password psql -U postgres -d tracker -f coach_routes.sql

# Or on Windows with psql in PATH:
set PGPASSWORD=password
psql -U postgres -d tracker -f coach_routes.sql
```

### Verify Import

After execution, you should see:

```
Stops inserted: 56
Routes inserted: 5
```

Check the database:

```sql
-- View all coach routes
SELECT route_id, route_name, route_number
FROM routes
WHERE route_type = 3 AND route_id >= 20000
ORDER BY route_id;

-- View all coach stops
SELECT stop_id, stop_name, stop_lat, stop_lon
FROM stops
WHERE stop_id >= 90000 AND stop_id < 91000
ORDER BY stop_name;

-- View a route with geopath
SELECT route_id, route_name, geopath
FROM routes
WHERE route_id = 20001;
```

## API Testing

Once imported, test the routes via the backend API:

```bash
# Get all V/Line routes (includes coaches)
curl http://localhost:5000/api/PTV/routes/3

# Get stops for route type 3
curl http://localhost:5000/api/PTV/stops?route_type=3

# Get specific route with geopath
curl http://localhost:5000/api/PTV/route/20001
```

## Frontend Display

The routes should appear in the tracker frontend at `http://localhost:5173`:

1. Filter routes by "V/Line" (route_type = 3)
2. Coach routes 20001-20005 should appear alongside V/Line train routes
3. Click a route to display its geopath on the map
4. Stop markers should appear along the route

## Data Quality Notes

### Geocoding
- All coordinates obtained from OpenStreetMap Nominatim API
- Rate limited to 1 request per second (respectful usage)
- 100% success rate: 56/56 stops geocoded
- Coordinates are in WGS84 (standard GPS coordinates)

### Route Accuracy
- Stop sequences based on typical V/Line coach routes
- **Note:** These are sample/representative routes, not official timetable data
- For production use, verify against current V/Line timetables
- Some routes may have variations (express services, seasonal changes, etc.)

### Known Limitations
- No GTFS integration (placeholder IDs used)
- No edge data for trip planning (routes display only)
- No timetable/schedule data
- Geopaths are simple straight-line connections between stops (not following roads)

## Future Expansion

This is a sample import of 5 routes. There are 54+ additional V/Line coach routes available:

**Western Victoria:** 8 routes (3 included)
**Northern Victoria:** 14 routes (2 included)
**North Eastern Victoria:** 5 routes (1 included)
**Eastern Victoria:** 6 routes (1 included)
**South Western Victoria:** 5 routes (1 included)
**Interstate:** 4 routes (0 included)

To expand:
1. Edit `coach_routes_data.json` to add more routes
2. Run `python geocode_stops.py` (rate limited, ~1 stop per second)
3. Run `python generate_sql.py`
4. Review and execute updated `coach_routes.sql`

## Troubleshooting

### Import Fails
- Ensure PostgreSQL is running: `pg_ctl status`
- Check database exists: `psql -U postgres -l | grep tracker`
- Verify schema matches (routes and stops tables exist)

### Routes Don't Appear
- Check route_type filter in frontend (should include type 3)
- Verify geopath is valid JSONB: `SELECT geopath FROM routes WHERE route_id = 20001;`
- Check backend API response: `curl http://localhost:5000/api/PTV/routes/3`

### Duplicate Key Errors
- SQL uses `ON CONFLICT` for idempotent execution
- Safe to re-run the script multiple times
- If stop/route IDs conflict, adjust starting IDs in `generate_sql.py`

## Contact

For questions about this data or the import process, refer to:
- `coach_scraping.log` for detailed processing steps
- CLAUDE.md in project root for overall architecture
- V/Line official website for current timetable data

## License

Route and stop data sourced from:
- V/Line (https://www.vline.com.au) - Route information
- OpenStreetMap (https://www.openstreetmap.org) - Geocoding via Nominatim

This is educational/development data. For production use, consult V/Line and comply with their data usage terms.
