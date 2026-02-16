// Handles the PSQL database connection and operations.
using System.Runtime.CompilerServices;
using Microsoft.VisualBasic;
using Npgsql;
using PTVApp.Models;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;

namespace PTVApp.Services
{
    public class DatabaseService
    {
        private readonly string _connectionString;
        private readonly IConfiguration _config;

        public DatabaseService(IConfiguration config)
        {
            // Basic connection setup
            _connectionString = "Host=localhost;Port=5432;Username=postgres;Password=password;Database=tracker";
            _config = config;
        }

        public async Task UpdateValues()
        {   
            string? apiKey = _config["api-key"];
            string? devId = _config["user-id"];
            if (apiKey is null || devId is null) throw new Exception("ApiKey or UserID is null\n");
            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();
            PTVClient client = new PTVClient(devId, apiKey);


            //await UpdateRouteTypes(client, conn);
            //await UpdateRoutes(client, conn);
            //await UpdateDisruptionModes(client, conn);
            //await UpdateStops(client, conn, 0); // trains
            //await UpdateDisruptions(client, conn);


            await conn.CloseAsync();
        }
        
        public async Task<List<string>> GetRouteTypeNames()
        {
            var routeTypes = new List<string>();
            using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();  // open connection

            using var cmd = new NpgsqlCommand("SELECT * FROM route_types;", conn);
            using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                routeTypes.Add(reader.GetString(reader.GetOrdinal("route_type_name")));
            }

            await conn.CloseAsync(); // close connection

            return routeTypes;
        }

        public async Task<List<StopDto>> GetStops( int route_type)
        {
            using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();
            using (var cmd = new NpgsqlCommand(
                @"SELECT json_agg(
                    json_build_object(
                        'stop_id', s.stop_id,
                        'stop_name', s.stop_name,
                        'stop_latitude', s.stop_latitude,
                        'stop_longitude', s.stop_longitude,
                        'route_type', s.route_type,
                        'stop_ticket', s.stop_ticket,
                        'interchange', s.interchange,
                        'stop_suburb', s.stop_suburb,
                        'stop_landmark', s.stop_landmark
                    )
                ) AS stops
                FROM stops s
                WHERE s.route_type = @route_type
                ",
                conn))
                {
                    cmd.Parameters.AddWithValue("route_type", route_type);
                    var result = await cmd.ExecuteScalarAsync();
                    var jsonResult = result == DBNull.Value || result == null ? "[]" : (string)result;
                    var stops = JsonSerializer.Deserialize<List<StopDto>>(jsonResult) ?? new List<StopDto>();
                    return stops;
                }
        }

        public async Task<List<StopDto>> GetStopsWithRoutes(int route_type)
        {
            using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            var query = @"
                SELECT
                    s.stop_id,
                    s.stop_name,
                    s.stop_latitude,
                    s.stop_longitude,
                    s.route_type,
                    s.stop_ticket,
                    s.interchange,
                    s.stop_suburb,
                    s.stop_landmark,
                    s.route_ids
                FROM stops s
                WHERE s.route_type = @route_type
            ";

            using var cmd = new NpgsqlCommand(query, conn);
            cmd.Parameters.AddWithValue("route_type", route_type);

            var stops = new List<StopDto>();
            using var reader = await cmd.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                stops.Add(new StopDto
                {
                    StopId = reader.GetInt32(reader.GetOrdinal("stop_id")),
                    StopName = reader.GetString(reader.GetOrdinal("stop_name")),
                    StopLatitude = (float)reader.GetDouble(reader.GetOrdinal("stop_latitude")),
                    StopLongitude = (float)reader.GetDouble(reader.GetOrdinal("stop_longitude")),
                    RouteType = reader.GetInt32(reader.GetOrdinal("route_type")),
                    StopTicket = JsonSerializer.Deserialize<StopTicket>(
                        reader.GetString(reader.GetOrdinal("stop_ticket"))) ?? new StopTicket(),
                    Interchange = reader.GetFieldValue<int[]>(reader.GetOrdinal("interchange")),
                    Suburb = reader.GetString(reader.GetOrdinal("stop_suburb")),
                    Landmark = reader.GetString(reader.GetOrdinal("stop_landmark")),
                    RouteIds = reader.GetFieldValue<int[]>(reader.GetOrdinal("route_ids"))
                });
            }

            await conn.CloseAsync();
            return stops;
        }
        // Add this method to your DatabaseService class

        public async Task<List<RouteSend>> GetRoutes(int? routeType=null, bool includeGeopaths = false)
        {
            var routes = new List<RouteSend>();
            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmd = new NpgsqlCommand(
                @"SELECT route_id, route_name, route_number, route_type, route_gtfs_id, route_colour
                  FROM routes
                  " + (routeType.HasValue ? "WHERE route_type = @routeType" : "") + ";", conn);

            if (routeType is not null) cmd.Parameters.AddWithValue("routeType", routeType);

            await using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                routes.Add(new RouteSend
                {
                    RouteId = reader.GetInt32(0),
                    RouteName = reader.GetString(1),
                    RouteNumber = reader.IsDBNull(2) ? null : reader.GetString(2),
                    RouteType = reader.GetInt32(3),
                    RouteGtfsId = reader.GetString(4),
                    RouteColour = reader.IsDBNull(5) ? [0,0,0]: reader.GetFieldValue<int[]>(5),
                });
            }

            await reader.CloseAsync();

            // Optionally fetch geopaths for each route
            if (includeGeopaths)
            {
                foreach (var route in routes)
                {
                    // First try GTFS patterns
                    var patterns = await GetAllRoutePatternsFromGtfs(conn, route.RouteGtfsId, route.RouteType);
                    if (patterns.Count > 0)
                    {
                        route.GeoPaths = patterns.Select(p => p.GeoPath).ToList();
                    }
                    else
                    {
                        // Fallback: check if route has stored geopath (e.g., from OSRM for coach routes)
                        var geopath = await GetStoredGeopath(conn, route.RouteGtfsId);
                        if (geopath != null && geopath.Count > 0)
                        {
                            route.GeoPaths = new List<List<GeoPoint>> { geopath };
                        }
                    }
                }
            }

            await conn.CloseAsync();

            return routes;
        }

        public async Task<List<RouteSend>> GetRoutesWithExpandedPatterns(int? routeType = null)
        {
            var expandedRoutes = new List<RouteSend>();
            var baseRoutes = await GetRoutes(routeType, includeGeopaths: false);

            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            foreach (var baseRoute in baseRoutes)
            {
                // Get all patterns for this route
                var patterns = await GetAllRoutePatternsFromGtfs(conn, baseRoute.RouteGtfsId, baseRoute.RouteType);

                if (patterns.Count == 0)
                {
                    // No GTFS patterns - check for stored geopath (coach routes)
                    var storedGeopath = await GetStoredGeopath(conn, baseRoute.RouteGtfsId);
                    if (storedGeopath != null && storedGeopath.Count > 0)
                    {
                        baseRoute.GeoPaths = new List<List<GeoPoint>> { storedGeopath };
                    }
                    expandedRoutes.Add(baseRoute);
                }
                else
                {
                    // Create a separate route entry for each pattern
                    for (int i = 0; i < patterns.Count; i++)
                    {
                        var pattern = patterns[i];
                        expandedRoutes.Add(new RouteSend
                        {
                            RouteId = baseRoute.RouteId * 1000 + i, // Unique ID for each pattern
                            RouteName = $"{baseRoute.RouteName} ({pattern.PatternName})",
                            RouteNumber = baseRoute.RouteNumber,
                            RouteType = baseRoute.RouteType,
                            RouteGtfsId = baseRoute.RouteGtfsId,
                            RouteColour = baseRoute.RouteColour,
                            GeoPaths = new List<List<GeoPoint>> { pattern.GeoPath }
                        });
                    }
                }
            }

            await conn.CloseAsync();
            return expandedRoutes;
        }

        private async Task<List<GeoPoint>?> GetStoredGeopath(NpgsqlConnection conn, string routeGtfsId)
        {
            // Read from geopath table which has individual lat/lon points
            await using var cmd = new NpgsqlCommand(
                @"SELECT g.latitude, g.longitude
                  FROM geopath g
                  JOIN routes r ON g.route_id = r.route_id
                  WHERE r.route_gtfs_id = @routeGtfsId
                  ORDER BY g.id",
                conn);
            cmd.Parameters.AddWithValue("routeGtfsId", routeGtfsId);

            var geopoints = new List<GeoPoint>();
            await using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                geopoints.Add(new GeoPoint
                {
                    Latitude = reader.GetDouble(0),
                    Longitude = reader.GetDouble(1)
                });
            }

            return geopoints.Count > 0 ? geopoints : null;
        }

        private class GeoJsonLineString
        {
            public string? type { get; set; }
            public List<List<double>>? coordinates { get; set; }
        }

        public async Task<RouteResponseSingle?> GetRouteWithGeopath(int routeId, int? directionId = null)
        {
            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            // Check if this is an expanded pattern ID (>= 1000)
            int baseRouteId = routeId;
            int? patternIndex = null;

            if (routeId >= 1000)
            {
                baseRouteId = routeId / 1000;
                patternIndex = routeId % 1000;
            }

            // 1. Get route details including GTFS route ID
            var route = await GetRouteDetails(conn, baseRouteId);
            if (route is null)
                return null;

            // 2. Get all distinct patterns for this route from GTFS
            route.Patterns = await GetAllRoutePatternsFromGtfs(conn, route.RouteGtfsId, route.RouteType, directionId);

            // 3. If requesting a specific pattern, filter and update route info
            if (patternIndex.HasValue && patternIndex.Value < route.Patterns.Count)
            {
                var selectedPattern = route.Patterns[patternIndex.Value];

                // Update route with pattern-specific info
                route.RouteId = routeId; // Use the expanded ID
                route.RouteName = selectedPattern.PatternName ?? route.RouteName;

                // Only include the selected pattern
                route.Patterns = new List<RoutePattern> { selectedPattern };
                route.GeoPaths = new List<List<GeoPoint>> { selectedPattern.GeoPath };
            }
            else
            {
                // 3. Populate geopaths from all patterns
                if (route.Patterns.Count > 0)
                {
                    route.GeoPaths = route.Patterns.Select(p => p.GeoPath).ToList();
                }
            }

            await conn.CloseAsync();

            return new RouteResponseSingle
            {
                Route = route,
                Status = new Status
                {
                    Version = "3.0",
                    Health = 1
                }
            };
        }
        DateTime ParseGtfsTime(string t)
        {
            var parts = t.Split(':');
            int h = int.Parse(parts[0]);
            int m = int.Parse(parts[1]);
            int s = int.Parse(parts[2]);

            return DateTime.Today.AddHours(h).AddMinutes(m).AddSeconds(s);
        }
        private async Task<Models.Route?> GetRouteDetails(NpgsqlConnection conn, int routeId)
        {
            string sql = @"
                SELECT route_id, route_type, route_name, route_number, route_gtfs_id
                FROM routes
                WHERE route_id = @routeId";

            await using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("routeId", routeId);

            await using var reader = await cmd.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return new Models.Route
                {
                    RouteId = reader.GetInt32(0),
                    RouteType = reader.GetInt32(1),
                    RouteName = reader.GetString(2),
                    RouteNumber = reader.GetString(3),
                    RouteGtfsId = reader.IsDBNull(4) ? "" : reader.GetString(4),
                    GeoPaths = null
                };
            }

            return null;
        }

        public async Task<(List<Trip>? trips, List<List<Trip>>? journeys)> PlanTripDijkstra(int originStopId, int destinationStopId, int k = 5, bool includeReplacementBuses = false)
        {
            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            // Use pgRouting k-shortest paths to get multiple alternative routes
            // Hub nodes have route_id = 0 and connect all routes at a station
            // Transfer penalty is built into hub edges (2.5 min each way = 5 min total)

            // Build the edges query with optional replacement bus filtering
            var edgesQuery = includeReplacementBuses
                ? "SELECT id, source_node as source, target_node as target, cost FROM edges_v2"
                : "SELECT id, source_node as source, target_node as target, cost FROM edges_v2 WHERE source_route != 0 OR NOT EXISTS (SELECT 1 FROM routes WHERE routes.route_id = edges_v2.source_route AND routes.is_replacement_bus = true)";

            await using var cmd = new NpgsqlCommand($@"
                SELECT d.path_id, d.seq, d.node, d.edge, d.cost, d.agg_cost,
                       (d.node / 1000000000)::int as stop_id,
                       (d.node % 1000000000)::int as route_id,
                       s.stop_name, s.stop_latitude, s.stop_longitude,
                       e.edge_type
                FROM pgr_ksp(
                    '{edgesQuery.Replace("'", "''")}',
                    @origin,
                    @destination,
                    @k,
                    directed := false
                ) d
                JOIN stops s ON s.stop_id = (d.node / 1000000000)::int
                LEFT JOIN edges_v2 e ON e.id = d.edge
                ORDER BY d.path_id, d.seq;
            ", conn);

            // Use hub nodes (route_id = 0) for origin/destination
            // Must use NpgsqlDbType.Bigint explicitly for pgRouting to accept the parameter
            cmd.Parameters.Add(new NpgsqlParameter("origin", NpgsqlTypes.NpgsqlDbType.Bigint) { Value = (long)originStopId * 1000000000L });
            cmd.Parameters.Add(new NpgsqlParameter("destination", NpgsqlTypes.NpgsqlDbType.Bigint) { Value = (long)destinationStopId * 1000000000L });
            cmd.Parameters.Add(new NpgsqlParameter("k", NpgsqlTypes.NpgsqlDbType.Integer) { Value = k });

            // Collect path nodes grouped by path_id: pathId -> list of (stopId, routeId, lat, lon)
            var pathNodesByPathId = new Dictionary<int, List<(int StopId, int RouteId, double Lat, double Lon)>>();

            await using (var reader = await cmd.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    var pathId = reader.GetInt32(0);
                    var stopId = reader.GetInt32(6);
                    var routeId = reader.GetInt32(7);

                    // Skip hub nodes (route_id = 0) - they're only for routing
                    if (routeId == 0)
                        continue;

                    if (!pathNodesByPathId.ContainsKey(pathId))
                        pathNodesByPathId[pathId] = new List<(int, int, double, double)>();

                    pathNodesByPathId[pathId].Add((stopId, routeId, reader.GetDouble(9), reader.GetDouble(10)));
                }
            }

            if (pathNodesByPathId.Count == 0)
                return (null, null);

            // Convert all paths to Trip segments grouped by journey
            var allJourneys = new List<List<Trip>>();
            int globalTripId = 1;

            foreach (var kvp in pathNodesByPathId.OrderBy(x => x.Key))
            {
                var pathNodes = kvp.Value;

                if (pathNodes.Count == 0)
                    continue;

                var journeyTrips = new List<Trip>();

                // Group consecutive nodes by route to create Trip segments for this path
                int currentRouteId = pathNodes[0].RouteId;
                int segmentStartIdx = 0;

                for (int i = 1; i <= pathNodes.Count; i++)
                {
                    // Check if route changed or we're at the end
                    if (i == pathNodes.Count || pathNodes[i].RouteId != currentRouteId)
                    {
                        // Build geopath for this segment
                        var segmentNodes = pathNodes.Skip(segmentStartIdx).Take(i - segmentStartIdx).ToList();
                        var geopath = await GetSegmentGeopathForRoute(conn, segmentNodes, currentRouteId);

                        journeyTrips.Add(new Trip
                        {
                            TripId = globalTripId++,
                            OriginStopId = segmentNodes.First().StopId,
                            DestinationStopId = segmentNodes.Last().StopId,
                            DepartureTime = DateTime.Now, // Placeholder - real time would come from GTFS
                            ArrivalTime = DateTime.Now,   // Placeholder
                            RouteId = currentRouteId,
                            GeoPath = geopath
                        });

                        // Start new segment if not at end
                        if (i < pathNodes.Count)
                        {
                            currentRouteId = pathNodes[i].RouteId;
                            segmentStartIdx = i;
                        }
                    }
                }

                if (journeyTrips.Count > 0)
                    allJourneys.Add(journeyTrips);
            }

            // Filter out journeys that misuse V/Line for suburban travel
            // Rule: V/Line can ONLY be boarded/alighted at specific stations:
            // - Southern Cross, Flinders Street - city terminuses
            // - Pakenham, Sunbury - V/Line terminuses on suburban network
            // - Pure V/Line regional stations (no metro equivalent)
            // BLOCKED: Caulfield, Footscray, Dandenong, etc. (even their V/Line platform stop_ids)

            // Allowed station NAMES (case-insensitive match)
            var allowedVLineStationNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "Southern Cross", "Flinders Street", "Pakenham", "Sunbury"
            };

            // Blocked station NAMES - suburban stations where V/Line stops but boarding not allowed
            var blockedVLineStationNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "Caulfield", "Footscray", "Sunshine", "Dandenong", "Clayton", "Oakleigh",
                "South Yarra", "Richmond", "Camberwell", "Box Hill", "Ringwood",
                "Flinders Street", // Actually allow this one
                "North Melbourne", "South Kensington", "Seddon", "Yarraville", "Newport",
                "Laverton", "Werribee", "Tarneit", "Wyndham Vale", "Little River",
                "Broadmeadows", "Craigieburn", "Essendon", "Moonee Ponds", "Watergardens"
            };
            // Remove allowed stations from blocked list
            blockedVLineStationNames.ExceptWith(allowedVLineStationNames);

            // Get V/Line route IDs
            var vlineRouteIds = new HashSet<int>();
            await using (var routeCmd = new NpgsqlCommand("SELECT route_id FROM routes WHERE route_type = 3", conn))
            await using (var routeReader = await routeCmd.ExecuteReaderAsync())
            {
                while (await routeReader.ReadAsync())
                    vlineRouteIds.Add(routeReader.GetInt32(0));
            }

            // Get stop names for all stops (to check by name, not just ID)
            var stopNames = new Dictionary<int, string>();
            await using (var stopCmd = new NpgsqlCommand("SELECT stop_id, stop_name FROM stops", conn))
            await using (var stopReader = await stopCmd.ExecuteReaderAsync())
            {
                while (await stopReader.ReadAsync())
                    stopNames[stopReader.GetInt32(0)] = stopReader.GetString(1);
            }

            // Helper to check if a stop name matches a blocked station
            bool IsBlockedStation(int stopId)
            {
                if (!stopNames.TryGetValue(stopId, out var name)) return false;
                // Check if stop name contains any blocked station name
                return blockedVLineStationNames.Any(blocked =>
                    name.Contains(blocked, StringComparison.OrdinalIgnoreCase));
            }

            bool IsAllowedStation(int stopId)
            {
                if (!stopNames.TryGetValue(stopId, out var name)) return true; // Unknown = allow
                // Check if stop name contains any allowed station name
                return allowedVLineStationNames.Any(allowed =>
                    name.Contains(allowed, StringComparison.OrdinalIgnoreCase));
            }

            // Filter journeys - V/Line can only be boarded at allowed stations
            var validJourneys = allJourneys.Where(journey =>
            {
                foreach (var trip in journey)
                {
                    // Check if this trip segment uses a V/Line route
                    // V/Line routes have IDs like 1823, 1745, etc. - check directly
                    // Also check base ID for expanded metro patterns (14000 -> 14)
                    bool isVLine = vlineRouteIds.Contains(trip.RouteId);
                    if (!isVLine && trip.RouteId >= 1000)
                    {
                        // Check if it's an expanded metro pattern (unlikely for V/Line but just in case)
                        int baseRouteId = trip.RouteId / 1000;
                        isVLine = vlineRouteIds.Contains(baseRouteId);
                    }

                    Console.WriteLine($"[Trip Check] RouteId={trip.RouteId}, isVLine={isVLine}, vlineRouteIds.Count={vlineRouteIds.Count}");

                    if (isVLine)
                    {
                        var originName = stopNames.GetValueOrDefault(trip.OriginStopId, "Unknown");
                        var destName = stopNames.GetValueOrDefault(trip.DestinationStopId, "Unknown");

                        bool originIsBlocked = IsBlockedStation(trip.OriginStopId);
                        bool originIsAllowed = IsAllowedStation(trip.OriginStopId);
                        bool destIsBlocked = IsBlockedStation(trip.DestinationStopId);
                        bool destIsAllowed = IsAllowedStation(trip.DestinationStopId);

                        bool originBlocked = originIsBlocked && !originIsAllowed;
                        bool destBlocked = destIsBlocked && !destIsAllowed;

                        Console.WriteLine($"[V/Line Check] Route {trip.RouteId}: {originName} (blocked={originIsBlocked}, allowed={originIsAllowed}) → {destName} (blocked={destIsBlocked}, allowed={destIsAllowed})");

                        if (originBlocked || destBlocked)
                        {
                            Console.WriteLine($"[V/Line Filter] *** REJECTED ***: {originName} → {destName}");
                            return false;
                        }
                        else
                        {
                            Console.WriteLine($"[V/Line Filter] ALLOWED: {originName} → {destName}");
                        }
                    }
                }
                return true;
            }).ToList();

            Console.WriteLine($"[V/Line Filter] {allJourneys.Count} total journeys, {validJourneys.Count} valid after filtering");

            // Don't fall back - if all journeys use invalid V/Line routing, return empty
            // The user should take metro to Southern Cross first, then V/Line

            // Deduplicate journeys by comparing route sequences (ignore specific route IDs, just use route types)
            var uniqueJourneys = new List<List<Trip>>();
            var seenSequences = new HashSet<string>();

            // Get route types for better deduplication
            var routeTypes = new Dictionary<int, int>();
            await using (var rtCmd = new NpgsqlCommand("SELECT route_id, route_type FROM routes", conn))
            await using (var rtReader = await rtCmd.ExecuteReaderAsync())
            {
                while (await rtReader.ReadAsync())
                    routeTypes[rtReader.GetInt32(0)] = rtReader.GetInt32(1);
            }

            foreach (var journey in validJourneys)
            {
                // Limit to 3 unique journeys to reduce API calls
                if (uniqueJourneys.Count >= 3)
                    break;

                // Create signature using stop IDs and ROUTE IDs (not just types)
                // This ensures truly different routes are shown (e.g., via Frankston vs via Dandenong)
                // But normalize expanded pattern IDs (14000 -> 14) to avoid duplicates
                var signature = string.Join("|", journey.Select(t =>
                {
                    var normalizedRouteId = t.RouteId >= 1000 && t.RouteId < 100000
                        ? t.RouteId / 1000  // Expanded metro pattern -> base route
                        : t.RouteId;
                    return $"{t.OriginStopId}-{normalizedRouteId}-{t.DestinationStopId}";
                }));

                if (!seenSequences.Contains(signature))
                {
                    seenSequences.Add(signature);
                    uniqueJourneys.Add(journey);
                    Console.WriteLine($"[Journey] Added: {signature}");
                }
            }

            // Limit to 3 unique journeys for display
            var limitedJourneys = uniqueJourneys.Take(3).ToList();
            Console.WriteLine($"[Result] {uniqueJourneys.Count} unique journeys, returning {limitedJourneys.Count}");

            // Also create flat list for backwards compatibility
            var allTrips = limitedJourneys.SelectMany(j => j).ToList();

            return (allTrips, limitedJourneys);
        }

        // Helper method to convert internal route ID to PTV route ID
        private async Task<string?> GetPtvRouteId(NpgsqlConnection conn, int internalRouteId)
        {
            await using var cmd = new NpgsqlCommand(
                "SELECT route_type, route_gtfs_id FROM routes WHERE route_id = @routeId", conn);
            cmd.Parameters.AddWithValue("routeId", internalRouteId);

            await using var reader = await cmd.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                int routeType = reader.GetInt32(0);
                string gtfsId = reader.GetString(1);

                // Convert based on route type
                if (routeType == 0) // Train
                {
                    // For trains, use base ID if expanded (e.g., 14000 → 14)
                    return internalRouteId >= 1000 ? (internalRouteId / 1000).ToString() : internalRouteId.ToString();
                }
                else if (routeType == 1) // Tram
                {
                    // For trams, extract number from GTFS ID (e.g., "3-59" → "59")
                    return gtfsId.Replace("3-", "").TrimEnd(':');
                }
                else if (routeType == 2) // Bus
                {
                    // For buses, use GTFS ID as-is (e.g., "21-967-aus-1")
                    return gtfsId;
                }
                else if (routeType == 3) // V/Line
                {
                    // For V/Line, extract from GTFS ID (e.g., "1-GEL" → "GEL")
                    return gtfsId.Replace("1-", "").TrimEnd(':');
                }
            }

            return null;
        }

        public async Task<List<List<Trip>>> EnrichJourneysWithRealTimes(List<List<Trip>> journeys, DateTime departureTime, int maxJourneys = 3, int departuresPerJourney = 3)
        {
            string? apiKey = _config["api-key"];
            string? devId = _config["user-id"];
            if (apiKey is null || devId is null) throw new Exception("ApiKey or UserID is null");

            var ptvClient = new PTVClient(devId, apiKey);
            var allEnrichedJourneys = new List<List<Trip>>();
            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            // Only enrich the top N fastest journeys to respect rate limits
            var journeysToEnrich = journeys.Take(maxJourneys).ToList();

            foreach (var journey in journeysToEnrich)
            {
                // For each journey, we'll create multiple variants with different departure times
                // First, get all possible departures for the first leg
                var firstTrip = journey[0];

                try
                {
                    // Get route_type for the first route
                    await using var cmd = new NpgsqlCommand(
                        "SELECT route_type FROM routes WHERE route_id = @routeId", conn);
                    cmd.Parameters.AddWithValue("routeId", firstTrip.RouteId);
                    var routeTypeObj = await cmd.ExecuteScalarAsync();

                    if (routeTypeObj == null)
                    {
                        // If route not found, keep journey with placeholder times
                        allEnrichedJourneys.Add(journey);
                        continue;
                    }

                    int routeType = Convert.ToInt32(routeTypeObj);

                    // Get PTV route ID for filtering
                    var ptvRouteId = await GetPtvRouteId(conn, firstTrip.RouteId);
                    if (ptvRouteId == null)
                    {
                        Console.WriteLine($"Could not find PTV route ID for route {firstTrip.RouteId}");
                        allEnrichedJourneys.Add(journey);
                        continue;
                    }

                    List<Departure>? availableDepartures = null;

                    // Try to get real-time departures from PTV API with failsafe
                    try
                    {
                        // Call PTV API to get departures from origin stop (all routes)
                        // Then filter by our route in the response
                        var departuresJson = await ptvClient.GetDepartures(routeType, firstTrip.OriginStopId, maxResults: 50);

                        var departuresResponse = JsonSerializer.Deserialize<DeparturesResponse>(departuresJson);

                        if (departuresResponse?.Departures != null && departuresResponse.Departures.Count > 0)
                        {
                            // Find multiple departures after the requested time
                            // Convert departure time to UTC for comparison with API times
                            var departureTimeUtc = departureTime.Kind == DateTimeKind.Local
                                ? departureTime.ToUniversalTime()
                                : (departureTime.Kind == DateTimeKind.Unspecified
                                    ? DateTime.SpecifyKind(departureTime, DateTimeKind.Local).ToUniversalTime()
                                    : departureTime);

                            // Filter by PTV route ID (the API returns route_id as int)
                            var ptvRouteIdInt = int.Parse(ptvRouteId);
                            availableDepartures = departuresResponse.Departures
                                .Where(d => d.RouteId == ptvRouteIdInt && d.ScheduledDepartureUtc.HasValue && d.ScheduledDepartureUtc.Value > departureTimeUtc)
                                .OrderBy(d => d.ScheduledDepartureUtc)
                                .Take(departuresPerJourney)
                                .ToList();
                        }
                    }
                    catch (Exception apiEx)
                    {
                        Console.WriteLine($"PTV API error (will use fallback times): {apiEx.Message}");
                        availableDepartures = null;
                    }

                    // FAILSAFE: If API failed or no departures found, create estimated departures using graph data
                    if (availableDepartures == null || availableDepartures.Count == 0)
                    {
                        Console.WriteLine($"Using fallback times for journey starting at stop {firstTrip.OriginStopId}");

                        // Create synthetic departures based on the requested departure time
                        // Assuming service every 10-15 minutes for urban transport
                        availableDepartures = new List<Departure>();
                        var baseDepartureTime = departureTime.Kind == DateTimeKind.Local
                            ? departureTime
                            : DateTime.SpecifyKind(departureTime, DateTimeKind.Local);

                        for (int i = 0; i < departuresPerJourney; i++)
                        {
                            var syntheticDeparture = baseDepartureTime.AddMinutes(i * 12); // 12 min intervals
                            availableDepartures.Add(new Departure
                            {
                                StopId = firstTrip.OriginStopId,
                                RouteId = int.Parse(ptvRouteId),
                                ScheduledDepartureUtc = syntheticDeparture.ToUniversalTime(),
                                RunRef = null // No run_ref for synthetic departures
                            });
                        }
                    }

                    if (availableDepartures.Count == 0)
                    {
                        // Still no departures, keep journey with placeholder times
                        allEnrichedJourneys.Add(journey);
                        continue;
                    }

                    // Rate limiting - wait 300ms between API calls

                    // Rate limiting - wait 300ms between API calls
                    await Task.Delay(300);

                    // For each available departure time, create a complete enriched journey
                    foreach (var initialDeparture in availableDepartures)
                    {
                        var enrichedJourneyVariant = new List<Trip>();
                        var currentTime = initialDeparture.ScheduledDepartureUtc.Value;
                        var tripIdCounter = firstTrip.TripId * 100; // Unique IDs for variants

                        foreach (var trip in journey)
                        {
                            try
                            {
                                // Get route_type for this route
                                await using var rtCmd = new NpgsqlCommand(
                                    "SELECT route_type FROM routes WHERE route_id = @routeId", conn);
                                rtCmd.Parameters.AddWithValue("routeId", trip.RouteId);
                                var rtObj = await rtCmd.ExecuteScalarAsync();

                                if (rtObj == null)
                                {
                                    enrichedJourneyVariant.Add(trip);
                                    continue;
                                }

                                int legRouteType = Convert.ToInt32(rtObj);

                                // Get PTV route ID for this leg
                                var legPtvRouteId = await GetPtvRouteId(conn, trip.RouteId);
                                if (legPtvRouteId == null)
                                {
                                    Console.WriteLine($"Could not find PTV route ID for route {trip.RouteId}");
                                    enrichedJourneyVariant.Add(trip);
                                    continue;
                                }

                                Departure? selectedDeparture = null;
                                DateTime localDeparture;
                                DateTime localArrival;

                                // For first leg, use the selected initial departure
                                if (trip == firstTrip)
                                {
                                    selectedDeparture = initialDeparture;
                                    localDeparture = initialDeparture.ScheduledDepartureUtc.Value.ToLocalTime();
                                }
                                else
                                {
                                    // For subsequent legs, get next actual departure from PTV API
                                    // Add 3-minute transfer time to arrival
                                    var earliestDeparture = currentTime.AddMinutes(3);

                                    try
                                    {
                                        // Get real departures from PTV API (all routes at this stop)
                                        var transferDeparturesJson = await ptvClient.GetDepartures(
                                            legRouteType, trip.OriginStopId, maxResults: 50);

                                        var transferDeparturesResponse = JsonSerializer.Deserialize<DeparturesResponse>(transferDeparturesJson);

                                        if (transferDeparturesResponse?.Departures != null && transferDeparturesResponse.Departures.Count > 0)
                                        {
                                            // Filter by PTV route ID and find first departure after transfer time
                                            var legPtvRouteIdInt = int.Parse(legPtvRouteId);
                                            selectedDeparture = transferDeparturesResponse.Departures
                                                .Where(d => d.RouteId == legPtvRouteIdInt && d.ScheduledDepartureUtc.HasValue && d.ScheduledDepartureUtc.Value > earliestDeparture)
                                                .OrderBy(d => d.ScheduledDepartureUtc)
                                                .FirstOrDefault();

                                            if (selectedDeparture != null)
                                            {
                                                localDeparture = selectedDeparture.ScheduledDepartureUtc.Value.ToLocalTime();
                                            }
                                            else
                                            {
                                                // No matching departures found - estimate based on earliest possible time
                                                Console.WriteLine($"No departures found for route {legPtvRouteId} at stop {trip.OriginStopId}, using estimated times");
                                                localDeparture = earliestDeparture.ToLocalTime().AddMinutes(5);

                                                // Get graph-based travel time
                                                double estTravelMinutes = 10.0;
                                                try
                                                {
                                                    int fallbackBaseRouteId = trip.RouteId >= 1000 ? trip.RouteId / 1000 : trip.RouteId;
                                                    long fallbackSourceNode = ((long)trip.OriginStopId * 1_000_000_000L) + fallbackBaseRouteId;
                                                    long fallbackTargetNode = ((long)trip.DestinationStopId * 1_000_000_000L) + fallbackBaseRouteId;

                                                    await using var costCmd = new NpgsqlCommand(@"
                                                        SELECT COALESCE(SUM(cost), 0) FROM pgr_dijkstra(
                                                            'SELECT id, source_node as source, target_node as target, cost FROM edges_v2 WHERE source_route = ' || @routeId,
                                                            @sourceNode, @targetNode, false
                                                        )", conn);
                                                    costCmd.Parameters.AddWithValue("routeId", fallbackBaseRouteId);
                                                    costCmd.Parameters.AddWithValue("sourceNode", fallbackSourceNode);
                                                    costCmd.Parameters.AddWithValue("targetNode", fallbackTargetNode);

                                                    var costResult = await costCmd.ExecuteScalarAsync();
                                                    if (costResult != null && costResult != DBNull.Value)
                                                    {
                                                        var cost = Convert.ToDouble(costResult);
                                                        if (cost > 0) estTravelMinutes = cost;
                                                    }
                                                }
                                                catch { /* Use default 10 min */ }

                                                localArrival = localDeparture.AddMinutes(estTravelMinutes);

                                                enrichedJourneyVariant.Add(new Trip
                                                {
                                                    TripId = tripIdCounter++,
                                                    OriginStopId = trip.OriginStopId,
                                                    DestinationStopId = trip.DestinationStopId,
                                                    DepartureTime = localDeparture,
                                                    ArrivalTime = localArrival,
                                                    RouteId = trip.RouteId,
                                                    GeoPath = trip.GeoPath
                                                });
                                                currentTime = localArrival.ToUniversalTime();
                                                continue;
                                            }
                                        }
                                        else
                                        {
                                            // No departures at all from API
                                            Console.WriteLine($"No departure data from API for stop {trip.OriginStopId}, using estimated times");
                                            localDeparture = earliestDeparture.ToLocalTime().AddMinutes(5);

                                            // Get graph-based travel time
                                            double estTravelMinutes = 10.0;
                                            try
                                            {
                                                int fallbackRouteId1 = trip.RouteId >= 1000 ? trip.RouteId / 1000 : trip.RouteId;
                                                long fallbackSource1 = ((long)trip.OriginStopId * 1_000_000_000L) + fallbackRouteId1;
                                                long fallbackTarget1 = ((long)trip.DestinationStopId * 1_000_000_000L) + fallbackRouteId1;

                                                await using var costCmd = new NpgsqlCommand(@"
                                                    SELECT COALESCE(SUM(cost), 0) FROM pgr_dijkstra(
                                                        'SELECT id, source_node as source, target_node as target, cost FROM edges_v2 WHERE source_route = ' || @routeId,
                                                        @sourceNode, @targetNode, false
                                                    )", conn);
                                                costCmd.Parameters.AddWithValue("routeId", fallbackRouteId1);
                                                costCmd.Parameters.AddWithValue("sourceNode", fallbackSource1);
                                                costCmd.Parameters.AddWithValue("targetNode", fallbackTarget1);

                                                var costResult = await costCmd.ExecuteScalarAsync();
                                                if (costResult != null && costResult != DBNull.Value)
                                                {
                                                    var cost = Convert.ToDouble(costResult);
                                                    if (cost > 0) estTravelMinutes = cost;
                                                }
                                            }
                                            catch { /* Use default 10 min */ }

                                            localArrival = localDeparture.AddMinutes(estTravelMinutes);

                                            enrichedJourneyVariant.Add(new Trip
                                            {
                                                TripId = tripIdCounter++,
                                                OriginStopId = trip.OriginStopId,
                                                DestinationStopId = trip.DestinationStopId,
                                                DepartureTime = localDeparture,
                                                ArrivalTime = localArrival,
                                                RouteId = trip.RouteId,
                                                GeoPath = trip.GeoPath
                                            });
                                            currentTime = localArrival.ToUniversalTime();
                                            continue;
                                        }

                                        // Rate limiting - wait between API calls
                                        await Task.Delay(300);
                                    }
                                    catch (Exception apiEx)
                                    {
                                        Console.WriteLine($"Error getting transfer departures: {apiEx.Message}");
                                        // Fallback with graph-based travel time
                                        localDeparture = currentTime.ToLocalTime().AddMinutes(5);

                                        // Get graph-based travel time
                                        double estTravelMinutes = 10.0;
                                        try
                                        {
                                            int fallbackRouteId2 = trip.RouteId >= 1000 ? trip.RouteId / 1000 : trip.RouteId;
                                            long fallbackSource2 = ((long)trip.OriginStopId * 1_000_000_000L) + fallbackRouteId2;
                                            long fallbackTarget2 = ((long)trip.DestinationStopId * 1_000_000_000L) + fallbackRouteId2;

                                            await using var costCmd = new NpgsqlCommand(@"
                                                SELECT COALESCE(SUM(cost), 0) FROM pgr_dijkstra(
                                                    'SELECT id, source_node as source, target_node as target, cost FROM edges_v2 WHERE source_route = ' || @routeId,
                                                    @sourceNode, @targetNode, false
                                                )", conn);
                                            costCmd.Parameters.AddWithValue("routeId", fallbackRouteId2);
                                            costCmd.Parameters.AddWithValue("sourceNode", fallbackSource2);
                                            costCmd.Parameters.AddWithValue("targetNode", fallbackTarget2);

                                            var costResult = await costCmd.ExecuteScalarAsync();
                                            if (costResult != null && costResult != DBNull.Value)
                                            {
                                                var cost = Convert.ToDouble(costResult);
                                                if (cost > 0) estTravelMinutes = cost;
                                            }
                                        }
                                        catch { /* Use default 10 min */ }

                                        localArrival = localDeparture.AddMinutes(estTravelMinutes);

                                        enrichedJourneyVariant.Add(new Trip
                                        {
                                            TripId = tripIdCounter++,
                                            OriginStopId = trip.OriginStopId,
                                            DestinationStopId = trip.DestinationStopId,
                                            DepartureTime = localDeparture,
                                            ArrivalTime = localArrival,
                                            RouteId = trip.RouteId,
                                            GeoPath = trip.GeoPath
                                        });
                                        currentTime = localArrival.ToUniversalTime();
                                        continue;
                                    }
                                }

                                // Get travel time from graph as failsafe
                                int routeIdForGraph = trip.RouteId >= 1000 ? trip.RouteId / 1000 : trip.RouteId;
                                double graphTravelMinutes = 10.0; // Default failback

                                try
                                {
                                    long sourceNode = ((long)trip.OriginStopId * 1_000_000_000L) + routeIdForGraph;
                                    long targetNode = ((long)trip.DestinationStopId * 1_000_000_000L) + routeIdForGraph;

                                    await using var costCmd = new NpgsqlCommand(@"
                                        SELECT COALESCE(SUM(cost), 0) as total_cost
                                        FROM pgr_dijkstra(
                                            'SELECT id, source_node as source, target_node as target, cost FROM edges_v2 WHERE source_route = ' || @routeId,
                                            @sourceNode,
                                            @targetNode,
                                            false
                                        )
                                    ", conn);
                                    costCmd.Parameters.AddWithValue("routeId", routeIdForGraph);
                                    costCmd.Parameters.AddWithValue("sourceNode", sourceNode);
                                    costCmd.Parameters.AddWithValue("targetNode", targetNode);

                                    var costResult = await costCmd.ExecuteScalarAsync();
                                    if (costResult != null && costResult != DBNull.Value)
                                    {
                                        var cost = Convert.ToDouble(costResult);
                                        if (cost > 0)
                                        {
                                            graphTravelMinutes = cost;
                                        }
                                    }
                                }
                                catch (Exception graphEx)
                                {
                                    Console.WriteLine($"Error getting graph travel time: {graphEx.Message}");
                                }

                                // Now use PTV pattern API to get actual arrival time at destination
                                // This is the 2nd API call per leg (1st was departures, 2nd is pattern)
                                if (selectedDeparture != null && !string.IsNullOrEmpty(selectedDeparture.RunRef))
                                {
                                    try
                                    {
                                        var patternJson = await ptvClient.GetPattern(selectedDeparture.RunRef, legRouteType);
                                        var patternResponse = JsonSerializer.Deserialize<PatternResponse>(patternJson);

                                        if (patternResponse?.Departures != null)
                                        {
                                            // Find the arrival time at our destination stop
                                            var arrivalAtDest = patternResponse.Departures
                                                .FirstOrDefault(d => d.StopId == trip.DestinationStopId);

                                            if (arrivalAtDest?.ScheduledDepartureUtc != null)
                                            {
                                                localArrival = arrivalAtDest.ScheduledDepartureUtc.Value.ToLocalTime();
                                            }
                                            else
                                            {
                                                // Fallback: use graph-based travel time
                                                localArrival = localDeparture.AddMinutes(graphTravelMinutes);
                                            }
                                        }
                                        else
                                        {
                                            // Fallback: use graph-based travel time
                                            localArrival = localDeparture.AddMinutes(graphTravelMinutes);
                                        }

                                        await Task.Delay(300); // Rate limiting
                                    }
                                    catch (Exception patternEx)
                                    {
                                        Console.WriteLine($"Error getting pattern: {patternEx.Message}");
                                        // Fallback: use graph-based travel time
                                        localArrival = localDeparture.AddMinutes(graphTravelMinutes);
                                    }
                                }
                                else
                                {
                                    // No run_ref available, use graph-based travel time
                                    localArrival = localDeparture.AddMinutes(graphTravelMinutes);
                                }

                                // Create a new trip instance with real times
                                enrichedJourneyVariant.Add(new Trip
                                {
                                    TripId = tripIdCounter++,
                                    OriginStopId = trip.OriginStopId,
                                    DestinationStopId = trip.DestinationStopId,
                                    DepartureTime = localDeparture,
                                    ArrivalTime = localArrival,
                                    RouteId = trip.RouteId,
                                    GeoPath = trip.GeoPath
                                });

                                // Update current time for next segment
                                currentTime = localArrival.ToUniversalTime();
                            }
                            catch (Exception ex)
                            {
                                Console.WriteLine($"Error enriching trip leg: {ex.Message}");
                                enrichedJourneyVariant.Add(trip);
                            }
                        }

                        allEnrichedJourneys.Add(enrichedJourneyVariant);
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error enriching journey: {ex.Message}");
                    // Keep the journey with placeholder times
                    allEnrichedJourneys.Add(journey);
                }
            }

            await conn.CloseAsync();

            // Sort all journeys by total journey time (departure of first leg to arrival of last leg)
            var sortedJourneys = allEnrichedJourneys
                .Where(j => j.Count > 0 && j[0].DepartureTime != default && j[^1].ArrivalTime != default)
                .OrderBy(j => (j[^1].ArrivalTime - j[0].DepartureTime).TotalMinutes)
                .ToList();

            // Add any journeys without valid times at the end
            sortedJourneys.AddRange(allEnrichedJourneys
                .Where(j => j.Count == 0 || j[0].DepartureTime == default || j[^1].ArrivalTime == default));

            return sortedJourneys;
        }

        public async Task<List<Disruption>> GetDisruptions(int? routeType = null)
        {
            var disruptions = new List<Disruption>();
            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            var query = @"
                SELECT disruption_id, title, url, description, disruption_status, disruption_type,
                       published_on, last_updated, from_date, to_date, routes, stops, colour,
                       display_on_board, display_status, route_type, disruption_event
                FROM disruptions
                WHERE (
                    -- Show if display_status is true AND not clearly past the to_date
                    (display_status = true AND (to_date IS NULL OR to_date >= NOW()))
                    OR
                    -- Show if currently within the date range (even if display_status is false)
                    (from_date <= NOW() AND (to_date IS NULL OR to_date >= NOW()))
                )";

            if (routeType.HasValue)
            {
                query += " AND route_type = @routeType";
            }

            query += " ORDER BY published_on DESC;";

            await using var cmd = new NpgsqlCommand(query, conn);
            if (routeType.HasValue)
                cmd.Parameters.AddWithValue("routeType", routeType.Value);

            await using var reader = await cmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                disruptions.Add(new Disruption
                {
                    DisruptionId = reader.GetInt64(0),
                    Title = reader.GetString(1),
                    Url = reader.GetString(2),
                    Description = reader.GetString(3),
                    DisruptionStatus = reader.GetString(4),
                    DisruptionType = reader.GetString(5),
                    PublishedOn = reader.IsDBNull(6) ? null : reader.GetFieldValue<DateTimeOffset>(6),
                    LastUpdated = reader.IsDBNull(7) ? null : reader.GetFieldValue<DateTimeOffset>(7),
                    FromDate = reader.IsDBNull(8) ? null : reader.GetFieldValue<DateTimeOffset>(8),
                    ToDate = reader.IsDBNull(9) ? null : reader.GetFieldValue<DateTimeOffset>(9),
                    Routes = reader.IsDBNull(10) ? new List<PTVApp.Models.Route>() :
                        System.Text.Json.JsonSerializer.Deserialize<List<PTVApp.Models.Route>>(reader.GetString(10)) ?? new List<PTVApp.Models.Route>(),
                    Stops = reader.IsDBNull(11) ? new List<DisruptionStop>() :
                        System.Text.Json.JsonSerializer.Deserialize<List<DisruptionStop>>(reader.GetString(11)) ?? new List<DisruptionStop>(),
                    Colour = reader.GetString(12),
                    DisplayOnBoard = reader.GetBoolean(13),
                    DisplayStatus = reader.GetBoolean(14),
                    RouteType = reader.IsDBNull(15) ? null : reader.GetInt32(15),
                    DisruptionEventData = reader.IsDBNull(16) ? null :
                        System.Text.Json.JsonSerializer.Deserialize<DisruptionEvent>(reader.GetString(16))
                });
            }

            await conn.CloseAsync();
            return disruptions;
        }

        private async Task<List<GeoPoint>> GetSegmentGeopathForRoute(
            NpgsqlConnection conn,
            List<(int StopId, int RouteId, double Lat, double Lon)> nodes,
            int routeId)
        {
            if (nodes.Count < 2)
                return nodes.Select(n => new GeoPoint { Latitude = n.Lat, Longitude = n.Lon }).ToList();

            var geopath = new List<GeoPoint>();

            for (int i = 0; i < nodes.Count - 1; i++)
            {
                var fromNode = nodes[i];
                var toNode = nodes[i + 1];

                var segment = await GetSegmentGeopath(conn, fromNode.StopId, toNode.StopId, routeId);

                if (segment.Count > 0)
                {
                    var startIndex = (i == 0) ? 0 : 1;
                    for (int j = startIndex; j < segment.Count; j++)
                        geopath.Add(segment[j]);
                }
                else
                {
                    if (i == 0)
                        geopath.Add(new GeoPoint { Latitude = fromNode.Lat, Longitude = fromNode.Lon });
                    geopath.Add(new GeoPoint { Latitude = toNode.Lat, Longitude = toNode.Lon });
                }
            }

            return geopath;
        }

        private async Task<List<GeoPoint>> GetSegmentGeopath(NpgsqlConnection conn, int fromStopId, int toStopId, int routeId)
        {
            var segment = new List<GeoPoint>();

            // Find a trip ON THE SPECIFIC ROUTE that goes through both stops
            // Check BOTH directions (forward and reverse) and pick the shortest path
            // This handles cases where the shape goes via city loop in one direction but direct in the other
            await using var cmdGetTrip = new NpgsqlCommand(@"
                SELECT trip_id, seq1, seq2, reversed FROM (
                    -- Forward direction: stop1 -> stop2
                    SELECT sts1.trip_id, sts1.shape_pt_sequence as seq1, sts2.shape_pt_sequence as seq2,
                           false as reversed,
                           ABS(sts2.shape_pt_sequence - sts1.shape_pt_sequence) as diff
                    FROM stop_trip_sequence sts1
                    JOIN stop_trip_sequence sts2 ON sts1.trip_id = sts2.trip_id
                    JOIN gtfs_trips t ON t.trip_id = sts1.trip_id
                    JOIN routes r ON (
                        -- Train (type 0): aus:vic:vic-02-XXX:
                        (r.route_type = 0 AND (t.route_id = 'aus:vic:vic-02-' || r.route_gtfs_id OR t.route_id = 'aus:vic:vic-02-' || r.route_gtfs_id || '-R:'))
                        -- Tram (type 1): aus:vic:vic-03-XXX:
                        OR (r.route_type = 1 AND (t.route_id = 'aus:vic:vic-03-' || REPLACE(r.route_gtfs_id, '3-', '') || ':' OR t.route_id = 'aus:vic:vic-03-' || REPLACE(r.route_gtfs_id, '3-', '') || '-R:'))
                        -- V/Line (type 3): aus:vic:vic-01-XXX:
                        OR (r.route_type = 3 AND (t.route_id = 'aus:vic:vic-01-' || REPLACE(r.route_gtfs_id, '1-', '') || ':' OR t.route_id = 'aus:vic:vic-01-' || REPLACE(r.route_gtfs_id, '1-', '') || '-R:'))
                    )
                    WHERE sts1.stop_id = @stop1 AND sts2.stop_id = @stop2
                    AND sts1.shape_pt_sequence < sts2.shape_pt_sequence
                    AND r.route_id = @routeId

                    UNION ALL

                    -- Reverse direction: stop2 -> stop1 (will be drawn reversed)
                    SELECT sts1.trip_id, sts1.shape_pt_sequence as seq1, sts2.shape_pt_sequence as seq2,
                           true as reversed,
                           ABS(sts2.shape_pt_sequence - sts1.shape_pt_sequence) as diff
                    FROM stop_trip_sequence sts1
                    JOIN stop_trip_sequence sts2 ON sts1.trip_id = sts2.trip_id
                    JOIN gtfs_trips t ON t.trip_id = sts1.trip_id
                    JOIN routes r ON (
                        -- Train (type 0): aus:vic:vic-02-XXX:
                        (r.route_type = 0 AND (t.route_id = 'aus:vic:vic-02-' || r.route_gtfs_id OR t.route_id = 'aus:vic:vic-02-' || r.route_gtfs_id || '-R:'))
                        -- Tram (type 1): aus:vic:vic-03-XXX:
                        OR (r.route_type = 1 AND (t.route_id = 'aus:vic:vic-03-' || REPLACE(r.route_gtfs_id, '3-', '') || ':' OR t.route_id = 'aus:vic:vic-03-' || REPLACE(r.route_gtfs_id, '3-', '') || '-R:'))
                        -- V/Line (type 3): aus:vic:vic-01-XXX:
                        OR (r.route_type = 3 AND (t.route_id = 'aus:vic:vic-01-' || REPLACE(r.route_gtfs_id, '1-', '') || ':' OR t.route_id = 'aus:vic:vic-01-' || REPLACE(r.route_gtfs_id, '1-', '') || '-R:'))
                    )
                    WHERE sts1.stop_id = @stop2 AND sts2.stop_id = @stop1
                    AND sts1.shape_pt_sequence < sts2.shape_pt_sequence
                    AND r.route_id = @routeId
                ) combined
                ORDER BY diff ASC
                LIMIT 1;
            ", conn);
            cmdGetTrip.Parameters.AddWithValue("stop1", fromStopId);
            cmdGetTrip.Parameters.AddWithValue("stop2", toStopId);
            cmdGetTrip.Parameters.AddWithValue("routeId", routeId);

            string? tripId = null;
            int seq1 = 0, seq2 = 0;
            bool reversed = false;

            await using (var reader = await cmdGetTrip.ExecuteReaderAsync())
            {
                if (await reader.ReadAsync())
                {
                    tripId = reader.GetString(0);
                    seq1 = reader.GetInt32(1);
                    seq2 = reader.GetInt32(2);
                    reversed = reader.GetBoolean(3);
                }
            }

            if (tripId == null)
                return segment;

            // Get the shape_id for this trip
            await using var cmdGetShape = new NpgsqlCommand(@"
                SELECT shape_id FROM gtfs_trips WHERE trip_id = @tripId;
            ", conn);
            cmdGetShape.Parameters.AddWithValue("tripId", tripId);
            var shapeId = await cmdGetShape.ExecuteScalarAsync() as string;

            if (shapeId == null)
                return segment;

            // Fetch shape points between the two stops
            // If reversed, order DESC to reverse the path direction
            await using var cmdGetPath = new NpgsqlCommand($@"
                SELECT shape_pt_lat, shape_pt_lon
                FROM shapes
                WHERE shape_id = @shapeId
                AND shape_pt_sequence >= @seq1 AND shape_pt_sequence <= @seq2
                ORDER BY shape_pt_sequence {(reversed ? "DESC" : "ASC")};
            ", conn);
            cmdGetPath.Parameters.AddWithValue("shapeId", shapeId);
            cmdGetPath.Parameters.AddWithValue("seq1", seq1);
            cmdGetPath.Parameters.AddWithValue("seq2", seq2);

            await using var pathReader = await cmdGetPath.ExecuteReaderAsync();
            while (await pathReader.ReadAsync())
            {
                segment.Add(new GeoPoint
                {
                    Latitude = pathReader.GetDouble(0),
                    Longitude = pathReader.GetDouble(1)
                });
            }

            return segment;
        }

        public async Task<List<Trip>> PlanTrip(int originStopId, int destinationStopId, int maxResults = 10)
        {
            return [];
        }


        public async Task<List<GeoPoint>> GetTripGeopath(int originStopId, int destinationStopId, int routeId)
        {
            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            await using var cmdGetRouteId = new NpgsqlCommand(@"select route_gtfs_id from routes where route_id=@routeId;", conn);
            cmdGetRouteId.Parameters.AddWithValue("routeId", routeId);
            var gtfsRouteId = await cmdGetRouteId.ExecuteScalarAsync() as string ?? 
            throw new Exception("Route id: " + routeId + "does not have gtfs id");

            await using var cmdGetTripId = new NpgsqlCommand(@"select trip_id from gtfs_trips where route_id=@gtfsRouteId;", conn);
            cmdGetTripId.Parameters.AddWithValue("gtfsRouteId", "aus:vic:vic-0"+gtfsRouteId+":");
            var tripId = await cmdGetTripId.ExecuteScalarAsync() as string ??
            throw new Exception("Trip id for " + gtfsRouteId + " not found");
            
            await using var cmdGetStart = new NpgsqlCommand(@"
                select shape_pt_sequence from stop_trip_sequence where trip_id = @tripId and stop_id=@stopId;
            ", conn);
            cmdGetStart.Parameters.AddWithValue("tripId", tripId);
            cmdGetStart.Parameters.AddWithValue("stopId", originStopId);
            var startSequence = await cmdGetStart.ExecuteScalarAsync() as int? 
            ?? throw new Exception("origin stop id " + originStopId + "has no corresponding shape_id");

            await using var cmdGetEnd = new NpgsqlCommand(@"
                select shape_pt_sequence from stop_trip_sequence where trip_id = @tripId AND stop_id=@stopId;
            ", conn);
            cmdGetEnd.Parameters.AddWithValue("tripId", tripId);
            cmdGetEnd.Parameters.AddWithValue("stopId", destinationStopId);
            var endSequence = await cmdGetEnd.ExecuteScalarAsync() as int? ??
            throw new Exception("origin stop id " + destinationStopId + "has no corresponding shape_id");
            
            if (startSequence > endSequence)
            {
                (endSequence, startSequence) = (startSequence, endSequence);
            }

            await using var cmdGetGeopath = new NpgsqlCommand(@"
                select shape_pt_lat, shape_pt_lon from shapes where
                shape_id = (select shape_id from gtfs_trips where trip_id=@tripId)
                and shape_pt_sequence >= @start and shape_pt_sequence <= @end
                order by shape_pt_sequence asc;
            ", conn);
            cmdGetGeopath.Parameters.AddWithValue("start", startSequence);
            cmdGetGeopath.Parameters.AddWithValue("end", endSequence);
            cmdGetGeopath.Parameters.AddWithValue("tripId", tripId);

            await using var reader = await cmdGetGeopath.ExecuteReaderAsync();
            var points = new List<GeoPoint>();
            while (await reader.ReadAsync())
            {
                points.Add(new GeoPoint
                {
                    Latitude = reader.GetDouble(0),
                    Longitude = reader.GetDouble(1)
                });
            }

            return points;
        }

        private async Task<List<GeoPoint>> GetGeopathFromShape(NpgsqlConnection conn, string shapeId)
        {
            var geopath = new List<GeoPoint>();

            string sqlShape = @"
                SELECT shape_pt_lat, shape_pt_lon
                FROM gtfs_shapes
                WHERE shape_id = @shapeId
                ORDER BY shape_pt_sequence ASC";

            await using var cmdShape = new NpgsqlCommand(sqlShape, conn);
            cmdShape.Parameters.AddWithValue("shapeId", shapeId);

            await using var reader = await cmdShape.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                geopath.Add(new GeoPoint
                {
                    Latitude = reader.GetDouble(0),
                    Longitude = reader.GetDouble(1)
                });
            }

            return geopath;
        }

        private async Task<List<RoutePattern>> GetAllRoutePatternsFromGtfs(NpgsqlConnection conn, string gtfsRouteId, int routeType, int? directionId = null)
        {
            var patterns = new List<RoutePattern>();

            if (string.IsNullOrEmpty(gtfsRouteId))
                return patterns;

            // Group trips to find distinct patterns (Metro Tunnel, City Loop, Express, via variations, etc.)
            // Simplified query for better performance
            string sqlPatterns = @"
                WITH trip_stops AS (
                    SELECT
                        t.trip_id,
                        t.shape_id,
                        t.trip_headsign,
                        COUNT(st.stop_sequence) as stop_count,
                        -- Check for Metro Tunnel stations by checking gtfs_stop_id directly
                        BOOL_OR(gs.gtfs_stop_id IN (
                            SELECT gtfs_parent_station FROM stops WHERE stop_id IN (1232, 1233, 1234, 1235, 1236)
                        )) as has_metro_tunnel_stops,
                        -- Check for City Loop stations
                        BOOL_OR(gs.gtfs_stop_id IN (
                            SELECT gtfs_parent_station FROM stops WHERE stop_id IN (1068, 1120, 1155)
                        )) as has_city_loop_stops
                    FROM gtfs_trips t
                    JOIN gtfs_stop_times st ON st.trip_id = t.trip_id
                    JOIN gtfs_stops gs ON st.stop_id = gs.gtfs_stop_id
                    WHERE t.route_id = @gtfsRouteId
                    " + (directionId.HasValue ? "AND t.direction_id = @directionId" : "") + @"
                    GROUP BY t.trip_id, t.shape_id, t.trip_headsign
                ),
                trip_stop_counts AS (
                    SELECT
                        trip_id,
                        shape_id,
                        trip_headsign,
                        stop_count,
                        CASE
                            -- Check actual stops first (most reliable)
                            WHEN has_metro_tunnel_stops THEN 'metro_tunnel'
                            WHEN has_city_loop_stops THEN 'city_loop'
                            -- Fallback to trip_headsign if no characteristic stops found
                            WHEN LOWER(trip_headsign) LIKE '%express%' THEN 'express'
                            WHEN LOWER(trip_headsign) LIKE '%via%' THEN 'via_' || LOWER(trip_headsign)
                            ELSE 'direct_' || LOWER(trip_headsign)
                        END as pattern_type
                    FROM trip_stops
                ),
                pattern_groups AS (
                    SELECT DISTINCT ON (pattern_type, shape_id)
                        shape_id,
                        trip_headsign,
                        stop_count,
                        pattern_type,
                        COUNT(*) OVER (PARTITION BY shape_id) as trip_count
                    FROM trip_stop_counts
                    ORDER BY pattern_type, shape_id, trip_count DESC
                )
                SELECT
                    shape_id,
                    trip_headsign,
                    stop_count,
                    pattern_type
                FROM pattern_groups
                ORDER BY
                    CASE
                        WHEN pattern_type LIKE 'metro_tunnel%' THEN 1
                        WHEN pattern_type LIKE 'city_loop%' THEN 2
                        WHEN pattern_type LIKE 'direct_%' THEN 3
                        WHEN pattern_type LIKE 'via_%' THEN 4
                        WHEN pattern_type LIKE 'express%' THEN 5
                        ELSE 6
                    END,
                    stop_count DESC;";

            await using var cmdPatterns = new NpgsqlCommand(sqlPatterns, conn);
            cmdPatterns.CommandTimeout = 120; // Increase timeout to 120 seconds
            // Construct GTFS route ID based on route type
            // Trains: route_gtfs_id="ALM:" → "aus:vic:vic-02-ALM:"
            // Trams: route_gtfs_id="3-109" → "aus:vic:vic-03-109:"
            // V/Line: route_gtfs_id="1-GEL" → "aus:vic:vic-01-GEL:"
            string fullRouteId;
            if (gtfsRouteId.Contains("-aus-"))
            {
                fullRouteId = gtfsRouteId;  // Bus route - use as-is
            }
            else if (routeType == 0)
            {
                // Trains: add "2-" before the route code
                fullRouteId = "aus:vic:vic-02-" + gtfsRouteId;
            }
            else
            {
                // Trams/V/Line: use simple concatenation (route_gtfs_id already has the prefix like "3-" or "1-")
                fullRouteId = "aus:vic:vic-0" + gtfsRouteId.TrimEnd(':') + ":";
            }
            cmdPatterns.Parameters.AddWithValue("gtfsRouteId", fullRouteId);
            if (directionId.HasValue)
                cmdPatterns.Parameters.AddWithValue("directionId", directionId.Value);

            var patternData = new List<(string ShapeId, string TripHeadsign, int StopCount, string PatternType)>();

            await using (var reader = await cmdPatterns.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    patternData.Add((
                        reader.GetString(0),
                        reader.IsDBNull(1) ? "" : reader.GetString(1),
                        reader.GetInt32(2),
                        reader.GetString(3)
                    ));
                }
            }

            // Select all unique shapes - different shapes = different physical routes (e.g., Werribee via Altona vs via Newport)
            var selectedPatterns = patternData
                .GroupBy(p => p.ShapeId)
                .Select(g => g.First()) // Take one representative from each shape (they're the same path)
                .ToList();

            // Create RoutePattern for each selected pattern
            foreach (var (shapeId, tripHeadsign, stopCount, patternType) in selectedPatterns)
            {
                var geopath = await GetGeopathFromShape(conn, shapeId);

                // Determine pattern name and description based on pattern type
                string patternName;
                string? patternDescription = null;

                if (patternType == "metro_tunnel")
                {
                    patternName = "Metro Tunnel";
                    patternDescription = $"Via Metro Tunnel stations ({stopCount} stops)";
                }
                else if (patternType == "city_loop")
                {
                    patternName = "City Loop";
                    patternDescription = $"Via City Loop stations ({stopCount} stops)";
                }
                else if (patternType == "express")
                {
                    patternName = "Express";
                    patternDescription = $"Limited stops service ({stopCount} stops)";
                }
                else if (patternType.StartsWith("via_"))
                {
                    // Extract the actual headsign from the pattern type
                    patternName = tripHeadsign;
                    patternDescription = $"Via route ({stopCount} stops)";
                }
                else if (patternType.StartsWith("direct_"))
                {
                    // Direct service (express or limited stops)
                    patternName = tripHeadsign;
                    patternDescription = $"Direct service ({stopCount} stops)";
                }
                else
                {
                    patternName = !string.IsNullOrEmpty(tripHeadsign) ? tripHeadsign : "All Stops";
                    patternDescription = $"Standard service ({stopCount} stops)";
                }

                patterns.Add(new RoutePattern
                {
                    PatternName = patternName,
                    PatternDescription = patternDescription,
                    TripHeadsign = tripHeadsign,
                    GeoPath = geopath
                });
            }

            return patterns;
        }

        private async Task<List<GeoPoint>> GetGeopathFromGtfs(NpgsqlConnection conn, string gtfsRouteId, int? directionId = null)
        {
            var geopath = new List<GeoPoint>();

            if (string.IsNullOrEmpty(gtfsRouteId))
                return geopath;

            // 1. Get one shape_id for the route from gtfs_trips
            string sqlTrip = @"
                SELECT shape_id
                FROM gtfs_trips
                WHERE route_id = @gtfsRouteId
                " + (directionId.HasValue ? "AND direction_id = @directionId" : "") + @"
                LIMIT 1";

            await using var cmdTrip = new NpgsqlCommand(sqlTrip, conn);
            // Bus routes use a different format (e.g., "23-526-aus-1") vs trains/trams/V-Line (e.g., "aus:vic:vic-03-109:")
            string fullRouteId = gtfsRouteId.Contains("-aus-")
                ? gtfsRouteId  // Bus route - use as-is
                : "aus:vic:vic-0" + gtfsRouteId + ":";  // Train/Tram/V-Line - add prefix
            cmdTrip.Parameters.AddWithValue("gtfsRouteId", fullRouteId);
            if (directionId.HasValue)
                cmdTrip.Parameters.AddWithValue("directionId", directionId.Value);

            var shapeId = await cmdTrip.ExecuteScalarAsync() as string;
            Console.WriteLine(shapeId);
            if (shapeId == null)
                return geopath;

            // 2. Fetch the coordinates from gtfs_shapes
            string sqlShape = @"
                SELECT shape_pt_lat, shape_pt_lon
                FROM gtfs_shapes
                WHERE shape_id = @shapeId
                ORDER BY shape_pt_sequence ASC";

            await using var cmdShape = new NpgsqlCommand(sqlShape, conn);
            // WARNING: THIS IS A TEMPORARY FIX.
            cmdShape.Parameters.AddWithValue("shapeId", shapeId);

            await using var reader = await cmdShape.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                geopath.Add(new GeoPoint
                {
                    Latitude = reader.GetDouble(0),
                    Longitude = reader.GetDouble(1)
                });
            }

            return geopath;
        }

        private async Task UpdateStops(PTVClient client, NpgsqlConnection conn, int route_type)
        {
            await using var readConn = new NpgsqlConnection(_connectionString);
            await readConn.OpenAsync();
            // get/update all train stops
            await using (var cmd = new NpgsqlCommand($"SELECT route_id FROM routes where route_type={route_type} ORDER BY route_id ASC;", readConn))
            {
                await using var reader = await cmd.ExecuteReaderAsync();
                int route_id_ord = reader.GetOrdinal("route_id");
                while (await reader.ReadAsync())
                {
                    var route_id = reader.GetInt16(route_id_ord);
                    var response = JsonSerializer.Deserialize<StopsResponse>(await client.GetStops(route_type, route_id)) ??
                        throw new Exception($"Stop Response was null with route_id {route_id}");
                    foreach (var stop in response.Stops)
                    {
                        await using (var addStop = new NpgsqlCommand(
                            @"insert into stops (stop_suburb, route_type, stop_latitude, stop_longitude, stop_ticket, interchange, stop_id, stop_name, stop_landmark, route_ids)
                            values (@suburb, @route_type, @lat, @lon, @ticket::jsonb, @interchange, @id, @name, @landmark, ARRAY[@route_id]::integer[])
                            on conflict (stop_id) do update
                            set stop_suburb = @suburb, stop_latitude=@lat, route_type=@route_type, stop_longitude=@lon, stop_ticket=@ticket::jsonb, interchange=@interchange, stop_name=@name, stop_landmark=@landmark,
                                route_ids = (
                                    SELECT array_agg(DISTINCT route_id ORDER BY route_id)
                                    FROM unnest(COALESCE(stops.route_ids, ARRAY[]::integer[]) || @route_id) AS route_id
                                );",
                            conn
                        ))
                        {
                            addStop.Parameters.AddWithValue("id", stop.StopId);
                            addStop.Parameters.AddWithValue("route_type", stop.RouteType);
                            addStop.Parameters.AddWithValue("route_id", route_id);
                            addStop.Parameters.AddWithValue("lon", stop.StopLongitude);
                            addStop.Parameters.AddWithValue("lat", stop.StopLatitude);
                            addStop.Parameters.AddWithValue("suburb", stop.Suburb);
                            addStop.Parameters.AddWithValue("landmark", stop.Landmark);
                            addStop.Parameters.AddWithValue("name", stop.StopName);
                            addStop.Parameters.AddWithValue("ticket", JsonSerializer.Serialize<StopTicket>(stop.StopTicket));
                            addStop.Parameters.AddWithValue("interchange", stop.Interchange.Select(x=>x.RouteId).ToArray());
                            await addStop.ExecuteNonQueryAsync();
                        }

                    }
                    await Task.Delay(1000);
                }

            }
            await readConn.CloseAsync();
            await Task.Delay(1000);
        }
        
        private async Task UpdateRouteTypes(PTVClient client, NpgsqlConnection conn)
        {
            // Get/Update Route Types
            var routeTypesResponse = JsonSerializer.Deserialize<RouteTypeResponse>(await client.GetRouteTypes()) 
                ?? throw new Exception("Route types was null\n");
            
            foreach (var routeType in routeTypesResponse.Route_Types) {
                await using var cmd = new NpgsqlCommand(
                    @"insert into route_types (route_type, route_type_name) 
                    values (@id, @name)
                    ON CONFLICT (route_type) DO UPDATE
                    SET route_type = @id, route_type_name = @name;"
                    , conn);
                cmd.Parameters.AddWithValue("id", routeType.RouteTypeId);
                cmd.Parameters.AddWithValue("name", routeType.RouteTypeName);
                await cmd.ExecuteNonQueryAsync();
            }
            await Task.Delay(1000);
        }

        private async Task UpdateRoutes(PTVClient client, NpgsqlConnection conn)
        {
            // Get/Update Routes
            var routesResponse = JsonSerializer.Deserialize<RouteResponse>(await client.GetRoutes())
                ?? throw new Exception("Routes was null\n");

            await using (var cmd = new NpgsqlCommand(
                    @"INSERT INTO routes (route_id, route_name, route_number, route_type, route_gtfs_id)
                    VALUES (@id, @name, @number, @type, @gtfs)
                    ON CONFLICT (route_id) DO UPDATE
                    SET route_name = @name, route_number = @number, route_type = @type, route_gtfs_id = @gtfs;",
                    conn))
            
            foreach (var route in routesResponse.Routes)
            {
                cmd.Parameters.Clear();

                cmd.Parameters.AddWithValue("id", route.RouteId);
                cmd.Parameters.AddWithValue("name", route.RouteName);
                cmd.Parameters.AddWithValue("number", route.RouteNumber is not null ? route.RouteNumber : "");
                cmd.Parameters.AddWithValue("type", route.RouteType);
                cmd.Parameters.AddWithValue("gtfs", route.RouteGtfsId);

                await cmd.ExecuteNonQueryAsync();

                // Update geopath table if GeoPaths is available (use first path for legacy support)
                if (route.GeoPaths != null && route.GeoPaths.Count > 0)
                {
                    int i = 0;
                    await using (var geoCmd = new NpgsqlCommand(
                        @"INSERT INTO geopath (route_id, id, latitude, longitude)
                        VALUES (@route_id, @seq, @lat, @lon)
                        ON CONFLICT (route_id, id) DO UPDATE
                        SET latitude = @lat, longitude = @lon;",
                        conn))
                    foreach (var point in route.GeoPaths[0])
                    {
                        geoCmd.Parameters.Clear();

                        geoCmd.Parameters.AddWithValue("route_id", route.RouteId);
                        geoCmd.Parameters.AddWithValue("seq", i);
                        geoCmd.Parameters.AddWithValue("lat", point.Latitude);
                        geoCmd.Parameters.AddWithValue("lon", point.Longitude);

                        await geoCmd.ExecuteNonQueryAsync();
                        i++;
                    }
                }


            }
            await Task.Delay(1000);
        }
        
        private async Task UpdateDisruptionModes(PTVClient client, NpgsqlConnection conn)
        {
            // get/update disruption modes
            var disruptionModesResponse = JsonSerializer.Deserialize<DisruptionModesResponse>(await client.GetDisruptionModes())
                ?? throw new Exception("Disruption Modes was null\n");
            foreach (var mode in disruptionModesResponse.Disruption_Modes)
            {
                await using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO disruption_modes (disruption_mode_id, disruption_mode_name)
                    VALUES (@id, @name)
                    ON CONFLICT (disruption_mode_id) DO UPDATE
                    SET disruption_mode_name = @name;",
                    conn))
                {   
                    cmd.Parameters.AddWithValue("id", mode.DisruptionModeId);
                    cmd.Parameters.AddWithValue("name", mode.DisruptionModeName);
                    await cmd.ExecuteNonQueryAsync();
                }
            }
            await Task.Delay(1000);
        }
        
        private int MapDisruptionModeToRouteType(int disruptionModeId)
        {
            // Mapping based on PTV disruption_mode_id to route_type
            // 1 = metro_train → 0 (Train)
            // 2 = metro_bus → 2 (Bus)
            // 3 = metro_tram → 1 (Tram)
            // 4 = regional_coach → 3 (V/Line)
            // 5 = regional_train → 3 (V/Line)
            // 7 = regional_bus → 2 (Bus)
            // 8 = school_bus → 2 (Bus)
            // 9 = telebus → 2 (Bus)
            // 10 = night_bus → 4 (Night Bus)
            // 13 = skybus → 2 (Bus)
            return disruptionModeId switch
            {
                1 => 0,  // metro_train → Train
                2 => 2,  // metro_bus → Bus
                3 => 1,  // metro_tram → Tram
                4 => 3,  // regional_coach → V/Line
                5 => 3,  // regional_train → V/Line
                7 => 2,  // regional_bus → Bus
                8 => 2,  // school_bus → Bus
                9 => 2,  // telebus → Bus
                10 => 4, // night_bus → Night Bus
                13 => 2, // skybus → Bus
                _ => 3   // Default to V/Line for unknown types
            };
        }

        private async Task UpdateDisruptions(PTVClient client, NpgsqlConnection conn)
        {
            // get/update disruptions
            var readConn = new NpgsqlConnection(_connectionString);
            await readConn.OpenAsync();
            var disruptionsResponse = JsonSerializer.Deserialize<DisruptionsResponse>(await client.GetDisruptions())
                ?? throw new Exception("Disruptions was null\n");
            foreach (var kv in disruptionsResponse.Disruptions)
            {
                string disruptionType = kv.Key;
                using var readCmd = new NpgsqlCommand("SELECT disruption_mode_id FROM disruption_modes WHERE disruption_mode_name = @name;", readConn);
                readCmd.Parameters.AddWithValue("name", disruptionType);
                var disruptionModeId = await readCmd.ExecuteScalarAsync() ?? throw new Exception("Disruption Mode ID does not match: " + disruptionType);

                int routeType = MapDisruptionModeToRouteType(Convert.ToInt32(disruptionModeId));

                foreach (var disruption in kv.Value)
                {

                    // Parse disruption description to structured event
                    var disruptionEvent = DisruptionParser.ParseDisruptionDescription(disruption.Description ?? "");
                    string? disruptionEventJson = disruptionEvent != null ? JsonSerializer.Serialize(disruptionEvent) : null;

                    await using var cmd = new NpgsqlCommand(@"
                    INSERT INTO disruptions (
                        disruption_id,
                        title,
                        url,
                        route_type,
                        description,
                        disruption_status,
                        disruption_type,
                        published_on,
                        last_updated,
                        from_date,
                        to_date,
                        routes,
                        stops,
                        colour,
                        display_on_board,
                        display_status,
                        disruption_event
                    )
                    VALUES (
                        @id,
                        @title,
                        @url,
                        @route_type,
                        @description,
                        @status,
                        @type,
                        @published,
                        @updated,
                        @from,
                        @to,
                        @routesJson::jsonb,
                        @stopsJson::jsonb,
                        @colour,
                        @displayBoard,
                        @displayStatus,
                        @disruptionEvent::jsonb
                    )
                    ON CONFLICT (disruption_id) DO UPDATE SET
                        title = EXCLUDED.title,
                        url = EXCLUDED.url,
                        description = EXCLUDED.description,
                        disruption_status = EXCLUDED.disruption_status,
                        route_type = EXCLUDED.route_type,
                        disruption_type = EXCLUDED.disruption_type,
                        published_on = EXCLUDED.published_on,
                        last_updated = EXCLUDED.last_updated,
                        from_date = EXCLUDED.from_date,
                        to_date = EXCLUDED.to_date,
                        routes = EXCLUDED.routes::jsonb,
                        stops = EXCLUDED.stops::jsonb,
                        colour = EXCLUDED.colour,
                        display_on_board = EXCLUDED.display_on_board,
                        display_status = EXCLUDED.display_status,
                        disruption_event = EXCLUDED.disruption_event::jsonb;
                ", conn);

                // Bind parameters
                cmd.Parameters.AddWithValue("id", disruption.DisruptionId);
                cmd.Parameters.AddWithValue("title", disruption.Title ?? "");
                cmd.Parameters.AddWithValue("url", disruption.Url ?? "");
                cmd.Parameters.AddWithValue("route_type", routeType);
                cmd.Parameters.AddWithValue("description", disruption.Description ?? "");
                cmd.Parameters.AddWithValue("status", disruption.DisruptionStatus ?? "");
                cmd.Parameters.AddWithValue("type", disruption.DisruptionType ?? "");
                cmd.Parameters.AddWithValue("published", disruption.PublishedOn ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("updated", disruption.LastUpdated ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("from", disruption.FromDate ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("to", disruption.ToDate ?? (object)DBNull.Value);
                cmd.Parameters.AddWithValue("routesJson", JsonSerializer.Serialize(disruption.Routes));
                cmd.Parameters.AddWithValue("stopsJson", JsonSerializer.Serialize(disruption.Stops));
                cmd.Parameters.AddWithValue("colour", disruption.Colour ?? "");
                cmd.Parameters.AddWithValue("displayBoard", disruption.DisplayOnBoard);
                cmd.Parameters.AddWithValue("displayStatus", disruption.DisplayStatus);
                cmd.Parameters.AddWithValue("disruptionEvent", disruptionEventJson ?? (object)DBNull.Value);

                await cmd.ExecuteNonQueryAsync();

            }


            }
            await Task.Delay(1000);

        }

        public async Task FetchCoachRouteGeopaths()
        {
            await using var conn = new NpgsqlConnection(_connectionString);
            await conn.OpenAsync();

            // Define coach routes with their waypoints for accurate routing
            // Format: route_gtfs_id -> list of stop IDs (in order)
            var coachRoutes = new Dictionary<string, List<int>>
            {
                { "coach-GOR", new List<int> { 1181, 90010, 90004, 90001 } },  // Southern Cross -> Geelong -> Lorne -> Apollo Bay
                { "coach-BBM", new List<int> { 1181, 90014, 90015, 90002 } },  // Southern Cross -> Seymour -> Wangaratta -> Bright
                { "coach-MBM", new List<int> { 1181, 90012, 90016, 90003 } },  // Southern Cross -> Bendigo -> Swan Hill -> Mildura
                { "coach-CIM", new List<int> { 1181, 90005 } },                // Southern Cross -> Cowes (direct)
                { "coach-GBB", new List<int> { 90010, 90011, 90012 } }         // Geelong -> Ballarat -> Bendigo
            };

            using var httpClient = new HttpClient();

            foreach (var (routeGtfsId, stopIds) in coachRoutes)
            {
                if (stopIds.Count < 2)
                {
                    Console.WriteLine($"Skipping {routeGtfsId} - need at least 2 stops");
                    continue;
                }

                // Get coordinates for all stops in order
                var waypoints = new List<(double lon, double lat)>();
                foreach (var stopId in stopIds)
                {
                    await using var cmdStop = new NpgsqlCommand(
                        "SELECT stop_longitude, stop_latitude FROM stops WHERE stop_id = @stopId", conn);
                    cmdStop.Parameters.AddWithValue("stopId", stopId);

                    await using var reader = await cmdStop.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        waypoints.Add((reader.GetDouble(0), reader.GetDouble(1)));
                    }
                    await reader.CloseAsync();
                }

                if (waypoints.Count != stopIds.Count)
                {
                    Console.WriteLine($"Skipping {routeGtfsId} - missing stop coordinates");
                    continue;
                }

                // Build OSRM URL with all waypoints
                var coordinatesList = string.Join(";", waypoints.Select(w => $"{w.lon},{w.lat}"));
                var osrmUrl = $"http://router.project-osrm.org/route/v1/driving/{coordinatesList}?overview=full&geometries=geojson";

                Console.WriteLine($"Fetching geopath for {routeGtfsId} with {waypoints.Count} waypoints from OSRM...");
                var response = await httpClient.GetStringAsync(osrmUrl);
                var osrmData = JsonSerializer.Deserialize<OsrmResponse>(response);

                if (osrmData?.routes != null && osrmData.routes.Count > 0)
                {
                    var coordinates = osrmData.routes[0].geometry.coordinates;

                    // Get route_id for this route
                    await using var cmdGetRouteId = new NpgsqlCommand(
                        "SELECT route_id FROM routes WHERE route_gtfs_id = @routeGtfsId", conn);
                    cmdGetRouteId.Parameters.AddWithValue("routeGtfsId", routeGtfsId);
                    var routeIdObj = await cmdGetRouteId.ExecuteScalarAsync();

                    if (routeIdObj == null)
                    {
                        Console.WriteLine($"Route not found: {routeGtfsId}");
                        continue;
                    }

                    var routeId = Convert.ToInt32(routeIdObj);

                    // Delete existing geopath points for this route
                    await using var cmdDelete = new NpgsqlCommand(
                        "DELETE FROM geopath WHERE route_id = @routeId", conn);
                    cmdDelete.Parameters.AddWithValue("routeId", routeId);
                    await cmdDelete.ExecuteNonQueryAsync();

                    // Insert new geopath points
                    int pointsInserted = 0;
                    foreach (var coord in coordinates)
                    {
                        if (coord.Count < 2) continue;

                        await using var cmdInsert = new NpgsqlCommand(
                            @"INSERT INTO geopath (route_id, latitude, longitude)
                              VALUES (@routeId, @lat, @lon)", conn);
                        cmdInsert.Parameters.AddWithValue("routeId", routeId);
                        cmdInsert.Parameters.AddWithValue("lat", coord[1]); // GeoJSON is [lon, lat]
                        cmdInsert.Parameters.AddWithValue("lon", coord[0]);
                        await cmdInsert.ExecuteNonQueryAsync();
                        pointsInserted++;
                    }

                    Console.WriteLine($"Updated route {routeGtfsId} with {pointsInserted} geopath points");
                }

                await Task.Delay(500); // Rate limiting
            }

            await conn.CloseAsync();
        }

        // OSRM response models
        private class OsrmResponse
        {
            public List<OsrmRoute>? routes { get; set; }
        }

        private class OsrmRoute
        {
            public OsrmGeometry geometry { get; set; } = new OsrmGeometry();
        }

        private class OsrmGeometry
        {
            public List<List<double>> coordinates { get; set; } = new List<List<double>>();
        }
    }
}