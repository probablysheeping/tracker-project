# PTV Tracker

A full-stack public transport tracking and trip planning application for Melbourne's Public Transport Victoria (PTV) network. Provides real-time routing, interactive maps, and service disruption tracking for trains, trams, buses, and V/Line services. Currently the backend API isn't being hosted.

<insert image: Hero screenshot of the main application showing the map with routes and stops>

## Features

- **Multi-modal trip planning** with route-aware graph routing using Dijkstra's algorithm
- **Interactive map visualization** with color-coded routes and stops
- **Real-time service disruptions** with severity indicators
- **Metro Tunnel pattern separation** (distinguishes City Loop vs Metro Tunnel routes)
- **Cross-modal transfers** (train-tram-bus-V/Line connections)
- **Journey alternatives** (k-shortest paths showing multiple route options)
- **GTFS-based routing** using real timetable data for accurate travel times

## Architecture Overview

- **Backend**: ASP.NET Core 9.0 Web API
- **Frontend**: React + Vite with Leaflet maps
- **Database**: PostgreSQL with GTFS data
- **Deployment**: GitHub Pages (frontend) + self-hosted API

---

## Backend

### Purpose

The backend is a RESTful API that provides public transport data, trip planning, and routing services for Melbourne's PTV network. It processes GTFS (General Transit Feed Specification) data and implements intelligent pathfinding algorithms to generate optimal multi-modal journeys.

### Main Functionality

#### 1. **Trip Planning**

Implements modified Dijkstra's algorithm to find multiple alternative routes:
- Returns k=3 journey options by default
- Uses real GTFS timetable data for accurate travel time calculations
- Supports cross-modal transfers (train→tram, tram→bus, etc.)
- Transfer penalties based on distance (3-4 minutes for realistic connection times)

```
Travel Time Calculation:
cost = MAX(1, ABS(arrival_time₂ - arrival_time₁) / 60) minutes
```

#### 2. **Service Disruption Tracking**

Fetches and stores live disruptions from PTV API:
- Color-coded severity levels (major delays, closures, minor delays)
- Route type filtering (0=Train, 1=Tram, 2=Bus, 3=V/Line, 4=NightBus)
- JSONB fields for affected routes and stops
- Active/inactive status with date ranges

#### 3. **Geopath Generation**

Creates detailed route geometry between stops for map visualization:
- Uses `shapes` and `stop_trip_sequence` tables from GTFS data
- Accurate positioning using `shape_dist_traveled` field
- Supports trams, trains, V/Line, and coach routes
- Returns GeoJSON LineString format

### API Endpoints

All endpoints prefixed with `/api/PTV`:

| Endpoint | Description |
|----------|-------------|
| `GET /routes` | Get all routes |
| `GET /routes/{routeType}` | Get routes by type (0-4) |
| `GET /routes/{routeType}?expandPatterns=true` | Get routes patterns |
| `GET /stops?route_type={type}&include_routes={bool}` | Get stops with optional route associations |
| `GET /route/{routeId}` | Get single route with geopath |
| `GET /tripPlan/{originStopId}/{destinationStopId}?k=3` | Plan trip with k alternative journeys |
| `GET /geopath/{routeId}/{originStopId}/{destinationStopId}` | Get geopath for trip segment |
| `GET /disruptions?route_type={0-4}` | Get service disruptions by route type |

### Technology Stack

- **ASP.NET Core 9.0** - Web API framework
- **Npgsql** - PostgreSQL database client
- **HMAC-SHA1** - PTV API authentication
- **Swagger/OpenAPI** - API documentation

### Database Schema

**Key Tables:**
- `routes` - Route metadata (id, name, type, color, geopath)
- `stops` - Stop locations (lat/lon, suburb, landmark)
- `edges_v2` - Routing graph (18,214 edges)
  - 3,530 route edges (trains/trams/V/Line)
  - 5,666 hub edges (same-stop transfers)
  - 9,018 proximity edges (cross-modal transfers)
- `shapes` - GTFS route geometry
- `stop_trip_sequence` - Maps stops to shape points
- `disruptions` - Service disruptions with JSONB route/stop data

### Multi-Modal Edge Graph

<insert image: Visualization of the edge graph showing different edge types and transfer nodes>

**Current Coverage:**
-  Trains: 791 edges (17 routes)
-  Trams: 2,228 edges (24 routes)
-  V/Line: 511 edges (14 routes)
-  Cross-modal transfers: 9,018 proximity-based edges
-  Buses: Not included (692 routes - optimization needed, so please don't touch this)

**Transfer Thresholds:**
- 500m for train/V/Line (3 min penalty)
- 200m for tram transfers (4 min penalty)

### Development

**Build and run:**
```bash
cd tracker
dotnet restore
dotnet build
dotnet run
```

**Access Swagger UI:**
```
http://localhost:5000/swagger
```

**Configuration:**
- User Secrets required: `api-key`, `user-id` (PTV API credentials)
- Database: PostgreSQL on localhost:5432
- CORS: Allows all origins (update for production)

---

## Frontend

### Purpose

The frontend is a modern, interactive web application for visualizing Melbourne's public transport network and planning multi-modal journeys. Built with React and Leaflet, it provides an intuitive map-based interface for exploring routes, stops, and service disruptions.

<insert image: Full UI screenshot showing map, sidebar, and controls>

### Main Functionality

#### 1. **Interactive Map Visualization**

- **Leaflet-based map** with OpenStreetMap tiles
- **Color-coded route polylines** matching PTV brand colors
- **Stop markers** with size differentiation:
  - Train stops: Normal size
  - Tram stops: 50% smaller
  - V/Line stops: 30% larger
- **Dashed lines** for coach routes (e.g., Apollo Bay, Warrnambool)
- **Click-to-view** route details and stop information

<insert image: Map view showing multiple colored route lines and stop markers>

#### 2. **Journey-Based Trip Planning**

Modern trip planning interface with tabbed journey options:

**Features:**
- Autocomplete search by stop name (with deduplication for trams)
- Returns 3 alternative route options (k-shortest paths)
- Tabbed UI: "Option 1", "Option 2", "Option 3"
- Each journey shows:
  - Total travel time
  - Number of segments
  - Route names and colors
  - Origin → Destination stops

**Journey Display:**
- Click a journey tab to highlight the entire route on the map
- Segment-by-segment breakdown with route colors
- Visual route cards with left border accents

<insert image: Trip planner sidebar showing journey options with tabs and route segments>

#### 3. **Service Disruptions Panel**

Collapsible panel showing real-time service disruptions:

**Features:**
- Badge counter showing active disruption count
- Color-coded severity indicators:
  - 🔴 Major delays (#ff6b6b)
  - 🟡 Minor delays (#ffd93d)
  - 🔴 Closures (#ff4757)
  - 🟠 Delays (#ffa502)
  - 🟣 Info (#6c5ce7)
- Route type badges (Train/Tram/Bus/V/Line)
- Date ranges for active disruptions
- Full descriptions on click/expand

<insert image: Disruptions panel showing color-coded cards with severity indicators>

#### 4. **Design System**

Modern glassmorphism aesthetic with dark theme:

**Color Palette:**
- Background: Dark gradient `#1a1f35 → #0f1419`
- Accent: Purple gradient `#667eea → #764ba2`
- Glassmorphism: `backdrop-filter: blur(10px)`, semi-transparent panels
- Gradient buttons with hover glow effects

**UI Components:**
- Sidebar with route list and filters
- Floating trip planner panel
- Collapsible disruptions drawer
- Gradient action buttons with animations

<insert image: Close-up of UI components showing glassmorphism design and gradients>

#### 5. **Route Filtering & Selection**

- Filter by route type (Train/Tram/Bus/V/Line)
- Route list with color-coded cards
- Click to highlight route on map
- Metro Tunnel vs City Loop pattern separation
- Stop counts and route type badges

### Technology Stack

- **React** - UI framework
- **Vite** - Build tool and dev server
- **Leaflet** - Interactive maps
- **react-leaflet** - React bindings for Leaflet
- **Axios** - HTTP client for API requests

### Development

**Run dev server:**
```bash
cd tracker-frontend
npm install
npm run dev
# Opens at http://localhost:5173
```

**Build for production:**
```bash
npm run build
npm run preview
```

**Configuration:**
- `.env.development` - Uses `http://localhost:5000` API
- `.env.production` - Uses `VITE_API_URL` environment variable
- `src/config.js` - Centralized API URL management

### Deployment

**GitHub Pages:**
- Live at: https://probablysheeping.github.io/tracker-frontend/
- Repository: https://github.com/probablysheeping/tracker-frontend
- Auto-deploys on push to `master` branch via GitHub Actions

**Configuration:**
- `vite.config.js` - Base path set to `/tracker-frontend/`
- Environment-based API URL switching
- See `DEPLOYMENT.md` for backend server setup

---

## Route Types Reference

| Code | Type | Description |
|------|------|-------------|
| 0 | Train | Metro train (City Loop, Metro Tunnel) |
| 1 | Tram | Melbourne tram network |
| 2 | Bus | Metropolitan buses |
| 3 | V/Line | Regional trains and coaches |
| 4 | NightBus | Night network buses |

---

## Database Setup
Note that I have used user:postgres with password:password. change this to whatever you have

**Restore database:**
```bash
PGPASSWORD=password psql -U postgres -d tracker -f database.dump
```

**Initialize routing graph:**
```bash
psql -U postgres -d tracker -f generate_all_modes_edges.sql
psql -U postgres -d tracker -f create_proximity_transfers.sql
```

**Regenerate shapes:**
```bash
psql -U postgres -d tracker -f queries.sql
```

---

## Known Issues & Solutions

### ⚠️ Current Limitations

1. **Bus routes not included in routing**
   - Displaying bus routes causes severe lag (692 routes)
   - One can't differentiate the routes they overlap too much. It is hard to make meaningful sense of them.

2. **VLine Coach Stops**
   - I've tried to generate the VLINE Coach routes but I couldn't find data for the stops.

---

## Testing

**Backend:**
```bash
# Using Swagger UI
http://localhost:5000/swagger

# Using curl
curl http://localhost:5000/api/PTV/routes/0?expandPatterns=true
curl http://localhost:5000/api/PTV/tripPlan/1/100?k=3
curl http://localhost:5000/api/PTV/disruptions?route_type=0
```

**Frontend:**
```bash
cd tracker-frontend
npm run dev
# Expects backend at http://localhost:5000
```

---

## Contributing

This project uses GTFS data from Public Transport Victoria. For development:

1. Ensure PostgreSQL is running with `tracker` database
2. Configure .NET User Secrets for PTV API access
3. Run backend on port 5000
4. Run frontend dev server on port 5173

---

## License

This project is for educational and demonstration purposes. PTV data and API access are subject to PTV's terms of service.

---

## Acknowledgments

- **Public Transport Victoria** - GTFS data and API access
- **OpenStreetMap** - Map tiles
- **Leaflet** - Map visualization library
- **ASP.NET Core** - Backend framework
