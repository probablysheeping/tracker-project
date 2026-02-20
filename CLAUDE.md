# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Public Transport Victoria (PTV) tracker application consisting of:
- **Backend**: ASP.NET Core 9.0 Web API (`tracker/`)
- **Frontend**: React + Vite application with Leaflet maps (`tracker-frontend/`)
- **Database**: PostgreSQL with GTFS (General Transit Feed Specification) data

The application provides transit routing, real-time stop information, and interactive map visualization of Melbourne's public transport network. Trip planning uses a route-aware graph with Dijkstra's algorithm (k-shortest paths) for finding optimal journeys.

## Architecture

### Backend (tracker/)

**Structure:**
- `Program.cs` - Entry point, configures CORS, Swagger, and initializes DatabaseService
- `Controllers/PTVControllers.cs` - REST API endpoints for routes, stops, trip planning, geopaths, and disruptions
- `Services/PTVClient.cs` - PTV Timetable API client with HMAC-SHA1 signature authentication
- `Services/database.cs` - PostgreSQL operations using Npgsql, includes Dijkstra pathfinding with route-aware graph
- `Models/` - DTOs for routes, stops, disruptions, trips, and API responses

**Key Features:**
- Trip planning using Dijkstra's algorithm with k-shortest paths (returns multiple journey options)
- Route-aware graph routing using composite node IDs: `(stop_id × 1,000,000,000) + route_id`
- Hub nodes (route_id=0) for station transfers with 2.5min transfer penalty
- Geopath generation for visualizing routes between stops
- Route pattern expansion for distinguishing Metro Tunnel vs City Loop patterns
- Route and stop data retrieval with support for filtering by route type (0=Train, 1=Tram, 2=Bus, 3=V/Line, 4=NightBus)
- Service disruption tracking with severity indicators

### Frontend (tracker-frontend/)

**Structure:**
- `src/App.jsx` - Main component with Leaflet map, route visualization, trip planning UI, and disruptions panel
- Uses `react-leaflet` for interactive maps
- Displays routes as polylines with stop markers
- Trip planning interface with origin/destination search by stop name
- Journey-based UI with tabbed options showing alternative routes
- Modern glassmorphism design with dark theme and purple accents

**Design System:**
- Dark theme: `linear-gradient(180deg, #1a1f35 0%, #0f1419 100%)`
- Purple accents: `linear-gradient(135deg, #667eea 0%, #764ba2 100%)`
- Glassmorphism: `backdrop-filter: blur(10px)`, semi-transparent backgrounds
- Color-coded route cards with left borders
- Gradient buttons with hover animations and glow effects

### Database Schema

**Core Tables:**
- `routes` - Route information (id, name, type, color, geopath as GeoJSON)
- `stops` - Stop locations (id, name, lat/lon, route_type, suburb, landmark)
- `edges_v2` - Current routing graph with route-aware edges (route_id, source, target, cost in minutes, distance_km)
- `shapes` - Detailed route geometry from GTFS (shape_id, lat/lon, sequence, distance)
- `stop_trip_sequence` - Maps stops to shape points for accurate route visualization
- `route_types` - Route type definitions (route_type, route_type_name, disruption_mode_id) with FK to disruption_modes
- `disruption_modes` - Disruption mode definitions from PTV API (disruption_mode_id, disruption_mode_name)
- `disruptions` - Service disruptions with route associations, severity levels, and date ranges (includes JSONB routes/stops fields)

**GTFS Tables:**
- `gtfs_routes`, `gtfs_trips`, `gtfs_stops`, `gtfs_stop_times`, `gtfs_shapes` - Raw GTFS data

## Key Features Implemented

### 1. Metro Tunnel Route Pattern Separation
**Problem:** Metro Tunnel stations (Arden, Parkville, State Library, Town Hall, Anzac) weren't distinguished from City Loop patterns.

**Solution (database.cs):**
- Modified `GetAllRoutePatternsFromGtfs()` to detect patterns from trip_headsign:
  - "Metro Tunnel", "City Loop", "Express", "Standard"
- Created `GetRoutesWithExpandedPatterns()` generating unique route IDs per pattern:
  - Base route ID 14 → 14000 (Metro Tunnel), 14001 (City Loop), etc.
  - Pattern name appended: "Sunbury (Metro Tunnel)"
- Result: 31 route patterns instead of ~16 base routes

**API:**
```csharp
GET /api/PTV/routes/{routeType}?expandPatterns=true
```

### 2. Journey-Based Trip Planning
**Problem:** Trip planner showed confusing flat list of all segments (e.g., "6 legs" for 3 alternative routes).

**Solution (database.cs):**
- Modified `PlanTripDijkstra()` to return `(List<Trip> trips, List<List<Trip>> journeys)`
- Groups trip segments by path_id into separate journey options
- k=3 returns 3 alternative complete journeys

**Models (TripModels.cs):**
```csharp
public class TripResponse {
    public List<Trip> Trips { get; set; }           // All segments
    public List<List<Trip>> Journeys { get; set; }  // Grouped by route option
}
```

**Frontend (App.jsx):**
- Journey tabs: "Option 1", "Option 2", "Option 3"
- Clicking highlights entire journey route on map
- Fixed `getRouteById()` to handle both base IDs (14) and expanded IDs (14000+)

### 3. Service Disruptions Feature
**Database Schema:**
- Added `route_type` column to disruptions table (mapped from old `disruption_mode`)
- Mapping: 1→0 (metro_train→Train), 2→2 (metro_bus→Bus), 3→1 (metro_tram→Tram), etc.
- Dropped old `disruption_mode` column
- Added indexes for performance

**Backend (database.cs):**
```csharp
public async Task<List<Disruption>> GetDisruptions(int? routeType = null)
// Filters by display_status=true and optional route_type
// Deserializes JSONB routes/stops fields
```

**Frontend (App.jsx):**
- Collapsible disruptions panel with badge showing count
- Color-coded cards by severity:
  - Major delays: #ff6b6b (red)
  - Minor delays: #ffd93d (yellow)
  - Closure: #ff4757 (dark red)
  - Delay: #ffa502 (orange)
  - Default: #6c5ce7 (purple)
- Route type badges (Train/Tram/Bus/V/Line)
- Date ranges for active disruptions

## Development Commands

### Backend (tracker/)

**Build and run:**
```bash
cd tracker
dotnet build
dotnet run
```

**Run specific configuration:**
```bash
dotnet run --configuration Debug
dotnet run --configuration Release
```

**Restore packages:**
```bash
dotnet restore
```

**Access Swagger UI:**
When running in development, navigate to `http://localhost:<port>/swagger` (typically http://localhost:5000/swagger)

**User Secrets:**
The backend uses .NET User Secrets for PTV API credentials. Required secrets:
- `api-key` - PTV API key
- `user-id` - PTV developer ID

### Frontend (tracker-frontend/)

**Development server:**
```bash
cd tracker-frontend
npm run dev
# Dev server: http://localhost:5173
```

**Build for production:**
```bash
npm run build
```

**Lint code:**
```bash
npm run lint
```

**Preview production build:**
```bash
npm run preview
```

## Deployment

### GitHub Pages Deployment (Frontend)

The frontend is deployed to GitHub Pages at: **https://probablysheeping.github.io/tracker-frontend/**

**Repository:** https://github.com/probablysheeping/tracker-frontend

**Configuration:**
- `vite.config.js` - Base path set to `/tracker-frontend/` for GitHub Pages
- `src/config.js` - Centralized API URL configuration using environment variables
- `.env.development` - Development environment (uses `http://localhost:5000`)
- `.env.production` - Production environment (uses server IP via `VITE_API_URL`)
- `.github/workflows/deploy.yml` - GitHub Actions workflow for automatic deployment

**API Endpoint Configuration:**
The frontend uses environment variables to configure the backend API URL:
- Development (`npm run dev`): Uses `http://localhost:5000`
- Production (`npm run build`): Uses the `VITE_API_URL` environment variable

**To change the API URL:**
1. Update `.env.production` file with your backend server URL
2. Or set the `VITE_API_URL` GitHub secret in repository settings

**Deployment Process:**
1. Push to `master` branch triggers automatic deployment via GitHub Actions
2. GitHub Actions builds the app with production environment variables
3. Static files are deployed to GitHub Pages
4. Site is live at https://probablysheeping.github.io/tracker-frontend/

**Manual Deployment:**
```bash
cd tracker-frontend
npm run build
# Dist folder contains the static build
```

**See `tracker-frontend/DEPLOYMENT.md` for complete deployment guide including backend server setup.**

### Database

**Connection:**
- Host: localhost
- Port: 5432
- Database: tracker
- User: postgres
- Password: password (hardcoded in `database.cs:19`)

**Restore database:**
```bash
# From root directory
PGPASSWORD=password psql -U postgres -d tracker -f database.dump
```

**Initialize edge graph:**
The `edges.sql` file generates routing edges from GTFS data by calculating travel time and distance between consecutive stops on each route.

**Regenerate shapes:**
Run `queries.sql` to rebuild the shapes and stop_trip_sequence tables from GTFS data.

## API Endpoints

All endpoints are prefixed with `/api/PTV`:

- `GET /routes` - Get all routes
- `GET /routes/{routeType}` - Get routes by type (0-4)
- `GET /routes/{routeType}?expandPatterns=true` - Get routes with expanded patterns (Metro Tunnel, City Loop, etc.)
- `GET /stops?route_type={type}&include_routes={bool}` - Get stops, optionally with route associations
- `GET /route/{routeId}` - Get single route with geopath
- `GET /tripPlan/{originStopId}/{destinationStopId}?k=3` - Get trip plan with k alternative journeys using Dijkstra's algorithm
- `GET /geopath/{routeId}/{originStopId}/{destinationStopId}` - Get geopath for a specific trip segment
- `GET /disruptions?route_type={0-4}` - Get service disruptions, optionally filtered by route type

## Route Types

Always use the correct route type integer when querying:
- 0 = Train (Metro)
- 1 = Tram
- 2 = Bus
- 3 = V/Line (Regional train)
- 4 = Night Bus

## Important Notes

**Route-Aware Graph Routing:**
- Composite node IDs: `(stop_id × 1,000,000,000) + route_id`
- Hub nodes (route_id=0) for station transfers with 2.5min penalty
- Edges stored in `edges_v2` table with route-specific costs
- This prevents unrealistic journeys and ensures route continuity

**Database Connection:**
The connection string is hardcoded in `DatabaseService.cs`. When modifying database operations, ensure connection is properly opened/closed using `await using` or explicit OpenAsync/CloseAsync calls.

**CORS:**
Backend allows all origins for development. Update `Program.cs:25-29` for production deployment.

**GTFS Data Processing:**
- Raw GTFS data is stored in `gtfs_*` tables
- Processed data is in `routes`, `stops`, `shapes`, and `edges_v2` tables
- Use `stop_trip_sequence` to map stops to their correct position on shape geometry
- The `shape_dist_traveled` field is critical for accurate positioning

**Trip Planning:**
The Dijkstra implementation in `database.cs` uses edge costs in minutes. The algorithm constructs k-shortest paths through the stop graph, returning multiple journey options grouped by path_id. Each journey is a complete route from origin to destination.

**Route ID Compatibility:**
Frontend's `getRouteById()` handles both:
- Base route IDs (e.g., 14 for Sunbury line)
- Expanded pattern IDs (e.g., 14000 for Sunbury Metro Tunnel, 14001 for Sunbury City Loop)

## Testing

**Frontend:**
The frontend expects the backend to be running on http://localhost:5000. Check `App.jsx` for the API base URL.

**Backend:**
Use Swagger UI for API testing or make requests directly:
```bash
# Example: Get all train routes with expanded patterns
curl http://localhost:5000/api/PTV/routes/0?expandPatterns=true

# Example: Plan a trip with 3 alternative journeys
curl http://localhost:5000/api/PTV/tripPlan/1/100?k=3

# Example: Get current disruptions for trains
curl http://localhost:5000/api/PTV/disruptions?route_type=0
```

## Known Issues Resolved

1. ✅ Ambiguous Route reference in GetDisruptions() - Fixed with `PTVApp.Models.Route`
2. ✅ Confusing 6-leg trip display - Fixed with journey grouping
3. ✅ Metro Tunnel routes not showing - Fixed with pattern expansion
4. ✅ Route ID mismatches - Fixed `getRouteById()` backward compatibility

## Current State

All features complete and functional:
- Metro Tunnel patterns displaying as separate routes (31 total patterns)
- Journey-based trip planning with tabbed UI (3 alternative routes)
- Modern glassmorphism UI design with dark theme
- Disruptions panel with color-coded severity indicators (with full descriptions on click)
- Route-aware graph routing preventing unrealistic transfers
- V/Line coach destinations added: Apollo Bay, Bright, Mildura, Lorne, Cowes, Inverloch (stop IDs 90001-90006)
- Coach routes displayed with dashed lines on map
- Differentiated stop sizes: Train (normal), Tram (50% smaller), V/Line (30% larger)
- **GitHub Pages deployment** with configurable API endpoint (https://probablysheeping.github.io/tracker-frontend/)
- Environment-based configuration for easy switching between development and production backends

**Deployment:**
- Frontend: GitHub Pages (https://probablysheeping.github.io/tracker-frontend/)
- Backend: Requires separate server (localhost:5000 for development)
- Repository: https://github.com/probablysheeping/tracker-frontend

## Multi-Modal Routing Implementation (Latest Session)

### Edge Generation Status

**Current Configuration:**
- ✅ **Trains**: 791 route edges (17 routes) - Using GTFS timetable data
- ✅ **Trams**: 2,228 route edges (24 routes) - Using GTFS timetable data
- ✅ **V/Line**: 511 route edges (14 routes) - Using GTFS timetable data
- ❌ **Buses**: Not included (692 routes - edge generation took 2+ hours, too slow)

**Total Graph Size:**
- 3,530 route edges
- 5,666 hub edges (for same-stop transfers between routes)
- 9,018 proximity transfer edges (cross-modal transfers)
- **Total**: 18,214 edges

### Cross-Modal Transfers

Proximity-based transfers support multi-modal journeys:
- **Train ↔ Tram**: 2,352 transfers (1,176 each direction)
- **Train ↔ V/Line**: 676 transfers (338 each direction)
- **Tram ↔ V/Line**: 434 transfers (217 each direction)
- **Train ↔ Train**: 84 transfers (same-mode, different routes)
- **Tram ↔ Tram**: 5,472 transfers (same-mode, different routes)

Transfer thresholds:
- 500m for Train/V/Line transfers (3 min penalty)
- 200m for transfers involving Tram (4 min penalty)

### Travel Time Calculation

Edge costs use **real GTFS timetable data** for all modes:
```sql
GREATEST(1, ABS(gtfs_time_to_seconds(st2.arrival_time) - gtfs_time_to_seconds(st1.arrival_time)) / 60.0) AS cost
```

This calculates actual scheduled travel time in minutes between consecutive stops.

### GTFS Route ID Mapping

Different transport modes use different GTFS ID formats:
- **Trains/Trams/V/Line**: `'aus:vic:vic-0' || route_gtfs_id || ':'`
  - Example: `'aus:vic:vic-02-ALM:'` (Alamein train)
  - Example: `'aus:vic:vic-03-82:'` (Route 82 tram)
  - Example: `'aus:vic:vic-01-GEL:'` (Geelong V/Line)
- **Buses**: Direct match `route_gtfs_id`
  - Example: `'21-967-aus-1'` (Route 967 bus)

### Known Issues & Fixes

**Issue 1: Pathfinding Failure (Tram→Train)**
- **Cause**: Bus edge generation script truncated edges table and ran for 2+ hours
- **Fix**: Cancelled bus script, regenerate edges for trains/trams/V/Line only
- **Script**: `generate_all_modes_edges.sql` (excludes buses, completes in ~5 min)

**Issue 2: Duplicate Tram Stops in Autocomplete**
- **Cause**: Bidirectional tram stops with identical names showing twice
- **Fix**: Added deduplication in `App.jsx` autocomplete (groups by `stop_name`)
- **Location**: Lines 532-541 and 627-636

**Issue 3: Missing Geopaths for Tram/V/Line Routes**
- **Cause**: `stop_trip_sequence` table only mapped trains (`gs.parent_station` join)
- **Fix**: Updated `queries.sql` line 28 to use OR join:
  ```sql
  JOIN stops s ON s.gtfs_parent_station = gs.gtfs_stop_id OR s.gtfs_parent_station = gs.parent_station
  ```
- **Status**: ⏳ Requires regeneration (currently in progress)

### Performance Optimization Needed

The `stop_trip_sequence` regeneration is slow due to:
- Processing millions of GTFS records with OR join
- Indexes active during INSERT

**Recommended optimization (not yet applied):**
1. Drop indexes before INSERT
2. Increase PostgreSQL settings for 32GB RAM / Ryzen 5 7500:
   ```sql
   SET work_mem = '4GB';
   SET maintenance_work_mem = '16GB';
   SET max_parallel_workers_per_gather = 12;
   SET shared_buffers = '8GB';
   ```
3. Run INSERT
4. Recreate indexes

### Edge Generation Scripts

- `generate_all_modes_edges.sql` - Main script (trains/trams/V/Line, excludes buses)
- `generate_train_edges_only.sql` - Trains only (fast test)
- `create_proximity_transfers.sql` - Proximity-based cross-modal transfers
- `queries.sql` - Regenerates shapes and stop_trip_sequence tables

### Future Work

**Bus Route Integration:**
- Need to optimize edge generation (current approach takes 2+ hours)
- Consider processing in batches or only major routes (SmartBus, orbital routes)
- Alternatively, add bus-to-other-mode transfers only (no internal bus routing)

**Geopath Display:**
- Once `stop_trip_sequence` completes, tram/V/Line routes will show geopaths
- Currently only trains display geopaths correctly

**Database Schema Notes:**
- `edges_v2.edge_type`: 'route', 'hub', or 'transfer'
- Hub edges have `route_id = 0` and connect all routes at a station
- Node IDs: `(stop_id × 1,000,000,000) + route_id`
- Proximity transfers calculated using Haversine distance formula

### V/Line Coach Routes

**Issue:** Pure coach routes (e.g., Apollo Bay, Bright, Cowes) are not included in GTFS data, only in PTV's route metadata. Routes like `coach-GOR`, `coach-BBM`, `coach-CIM` exist in the `routes` table but have no trips, stops, or shapes data.

**Solution:** Manually added major coach destination stops to enable trip planning:
- **stop_id 90001**: Apollo Bay (-38.7578, 143.6712) - Great Ocean Road service
- **stop_id 90002**: Bright (-36.7294, 146.9594) - Alpine coach service
- **stop_id 90003**: Mildura (-34.1889, 142.1583) - Swan Hill connection
- **stop_id 90004**: Lorne (-38.5414, 143.9787) - Great Ocean Road intermediate
- **stop_id 90005**: Cowes (-38.4592, 145.2372) - Phillip Island
- **stop_id 90006**: Inverloch (-38.6294, 145.6731) - Gippsland coast

SQL file: `add_coach_stops.sql`

**Displayable Coach Routes (with GTFS data):**
These coach services share infrastructure with train lines and have full routing data:
- Ararat (1-ART) - via Ballarat
- Swan Hill (1-SWL) - via Bendigo
- Echuca-Moama (1-ECH) - via Bendigo/Heathcote
- Shepparton (1-SNH) - via Seymour
- Bairnsdale (1-BDE) - via Traralgon
- Warrnambool (1-WBL) - via Geelong
- Maryborough (1-MBY) - via Ballarat
- Albury (1-ABY) - via Seymour

These routes render with dashed lines (`dashArray: "10, 8"`) to distinguish from train services.
