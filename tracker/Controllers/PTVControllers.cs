using Microsoft.AspNetCore.Mvc;
using Microsoft.VisualBasic;
using Npgsql;
using PTVApp.Models;
using PTVApp.Services;
using System.Reflection.Metadata;
using System.Text.Json;
using System.Threading.Tasks;

namespace PTVApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PTVController : ControllerBase
    {
        private readonly PTVClient _ptvClient;
        private readonly Status _defaultStatus = new Status
            {
                Version = "dev",
                Health = 1
            };
        private readonly DatabaseService _database;

        public PTVController(IConfiguration configuration)
        {
            string? apiKey = configuration["api-key"];
            string? devId = configuration["user-id"];
            if (apiKey is null || devId is null) throw new Exception("ApiKey or UserID is null\n");
            _ptvClient = new PTVClient(devId, apiKey);
            _database = new DatabaseService(configuration);
        }
        [HttpGet("routes")]
        public async Task<ActionResult<RouteSendResponse>> GetRoutes(
            [FromQuery] bool includeGeopaths = false,
            [FromQuery] bool expandPatterns = false,
            [FromQuery] string? route_types = null
        )
        {
            // Parse route types if provided (e.g., "0,1,3")
            List<int>? routeTypeFilter = null;
            if (!string.IsNullOrEmpty(route_types))
            {
                routeTypeFilter = route_types.Split(',')
                    .Select(x => int.TryParse(x.Trim(), out var rt) ? rt : -1)
                    .Where(x => x >= 0)
                    .ToList();
            }

            List<RouteSend> routes;
            if (expandPatterns)
            {
                // Fetch expanded patterns for all or filtered route types
                if (routeTypeFilter != null && routeTypeFilter.Count > 0)
                {
                    var routeLists = new List<List<RouteSend>>();
                    foreach (var type in routeTypeFilter)
                    {
                        routeLists.Add(await _database.GetRoutesWithExpandedPatterns(type));
                    }
                    routes = routeLists.SelectMany(r => r).ToList();
                }
                else
                {
                    routes = await _database.GetRoutesWithExpandedPatterns(null);
                }
            }
            else
            {
                // Fetch routes without pattern expansion
                if (routeTypeFilter != null && routeTypeFilter.Count > 0)
                {
                    var routeLists = new List<List<RouteSend>>();
                    foreach (var type in routeTypeFilter)
                    {
                        routeLists.Add(await _database.GetRoutes(type, includeGeopaths));
                    }
                    routes = routeLists.SelectMany(r => r).ToList();
                }
                else
                {
                    routes = await _database.GetRoutes(null, includeGeopaths);
                }
            }

            var response = new RouteSendResponse {
                Status = _defaultStatus,
                Routes = routes
            };
            return response;
        }

        [HttpGet("routes/{routeType}")]
        public async Task<ActionResult<RouteSendResponse>> GetRoutesByType(
            int routeType,
            [FromQuery] bool expandPatterns = false,
            [FromQuery] bool includeGeopaths = true
        )
        {
            if (expandPatterns)
            {
                var expandedRoutes = await _database.GetRoutesWithExpandedPatterns(routeType);
                var response = new RouteSendResponse
                {
                    Status = _defaultStatus,
                    Routes = expandedRoutes
                };
                return Ok(response);
            }
            else
            {
                var routes = await _database.GetRoutes(routeType, includeGeopaths);
                var response = new RouteSendResponse
                {
                    Status = _defaultStatus,
                    Routes = routes
                };
                return Ok(response);
            }
        }

        [HttpGet("stops")]
        public async Task<ActionResult<List<StopDto>>> GetStops(
            [FromQuery] string? route_types = null,
            [FromQuery] bool include_routes = false
        )
        {
            // Parse route types if provided (e.g., "0,1,3")
            List<int>? routeTypeFilter = null;
            if (!string.IsNullOrEmpty(route_types))
            {
                routeTypeFilter = route_types.Split(',')
                    .Select(x => int.TryParse(x.Trim(), out var rt) ? rt : -1)
                    .Where(x => x >= 0)
                    .ToList();
            }

            if (routeTypeFilter == null || routeTypeFilter.Count == 0)
            {
                return BadRequest(new { error = "route_types parameter is required (e.g., ?route_types=0,1,3)" });
            }

            var allStops = new List<StopDto>();
            foreach (var type in routeTypeFilter)
            {
                var stops = include_routes
                    ? await _database.GetStopsWithRoutes(type)
                    : await _database.GetStops(type);
                allStops.AddRange(stops);
            }

            // Remove duplicates by stop_id
            var uniqueStops = allStops
                .GroupBy(s => s.StopId)
                .Select(g => g.First())
                .ToList();

            return Ok(uniqueStops);
        }

        [HttpGet("route/{routeId}")]
        public async Task<ActionResult<RouteResponseSingle>> GetRoute(int routeId)
        {
            var routeResponse = await _database.GetRouteWithGeopath(routeId);

            if (routeResponse == null)
            {
                return NotFound(new { message = $"Route with ID {routeId} not found" });
            }

            return Ok(routeResponse);
        }

        // --- Helpers for realtime departure lookup ---

        private List<DateTime> ParseDepartures(string json)
        {
            try
            {
                var response = JsonSerializer.Deserialize<DeparturesResponse>(json);
                if (response?.Departures == null) return [];
                var times = response.Departures
                    .Select(d => d.EstimatedDepartureUtc ?? d.ScheduledDepartureUtc)
                    .Where(d => d.HasValue)
                    .Select(d => d!.Value)
                    .OrderBy(d => d)
                    .ToList();
                return times;
            }
            catch
            {
                return [];
            }
        }

        private async Task<DateTime?> GetNextDeparture(int routeType, int stopId, int routeId, DateTime afterTime)
        {
            try
            {
                var json = await _ptvClient.GetDeparturesForRoute(routeType, stopId, routeId, maxResults: 2, afterTime: afterTime);
                var times = ParseDepartures(json);
                // Use Cast to get DateTime? so FirstOrDefault returns null (not DateTime.MinValue) when empty
                return times.Where(t => t >= afterTime).Cast<DateTime?>().FirstOrDefault();
            }
            catch
            {
                return null;
            }
        }

        private async Task<List<DateTime>> GetUpcomingDepartures(int routeType, int stopId, int routeId, int count)
        {
            try
            {
                var json = await _ptvClient.GetDeparturesForRoute(routeType, stopId, routeId, maxResults: count);
                return ParseDepartures(json);
            }
            catch
            {
                return [];
            }
        }

        [HttpGet("tripPlan/{originStopId}/{destinationStopId}")]
        public async Task<ActionResult<TripResponse>> GetTripPlan(
            int originStopId,
            int destinationStopId,
            [FromQuery] int k = 3,
            [FromQuery] bool includeReplacementBuses = false
        )
        {
            try
            {
                int internalK = Math.Max(k * 2, 6);
                var (_, journeys, legMinutesList) = await _database.PlanTripDijkstra(
                    originStopId, destinationStopId, internalK, includeReplacementBuses);

                if (journeys == null || journeys.Count == 0 || legMinutesList == null)
                {
                    return NotFound(new TripResponse
                    {
                        Status = new Status { Version = "dev", Health = 0 },
                        Trips = [],
                        Journeys = []
                    });
                }

                var utcNow = DateTime.UtcNow;
                var candidates = new List<(List<Trip> Legs, DateTime Arrival, double WaitMins)>();

                for (int ji = 0; ji < journeys.Count && ji < legMinutesList.Count; ji++)
                {
                    var journey = journeys[ji];
                    var legMins = legMinutesList[ji];
                    if (journey.Count == 0) continue;

                    var firstLeg = journey[0];
                    int ptvFirstRouteId = firstLeg.PtvRouteId ?? (firstLeg.RouteId > 10000 ? firstLeg.RouteId / 1000 : firstLeg.RouteId);

                    var leg1Deps = await GetUpcomingDepartures(firstLeg.RouteType, originStopId, ptvFirstRouteId, count: 4);

                    foreach (var dep1 in leg1Deps.Where(d => d >= utcNow))
                    {
                        var current = dep1;
                        var legsCopy = journey.Select(t => new Trip
                        {
                            TripId = t.TripId,
                            OriginStopId = t.OriginStopId,
                            DestinationStopId = t.DestinationStopId,
                            DepartureTime = t.DepartureTime,
                            ArrivalTime = t.ArrivalTime,
                            RouteId = t.RouteId,
                            RouteName = t.RouteName,
                            RouteNumber = t.RouteNumber,
                            RouteType = t.RouteType,
                            RouteColour = t.RouteColour,
                            GeoPath = t.GeoPath,
                            TravelMinutes = t.TravelMinutes,
                            PtvRouteId = t.PtvRouteId
                        }).ToList();
                        bool valid = true;

                        for (int li = 0; li < legsCopy.Count; li++)
                        {
                            var leg = legsCopy[li];
                            int ptvRouteId = leg.PtvRouteId ?? (leg.RouteId > 10000 ? leg.RouteId / 1000 : leg.RouteId);
                            double legTravelMins = li < legMins.Count ? legMins[li] : (leg.TravelMinutes ?? 10);

                            DateTime departure;
                            if (li == 0)
                            {
                                departure = dep1;
                            }
                            else
                            {
                                var nextDep = await GetNextDeparture(leg.RouteType, leg.OriginStopId, ptvRouteId, current);
                                if (nextDep == null) { valid = false; break; }
                                departure = nextDep.Value;
                            }

                            var arrival = departure + TimeSpan.FromMinutes(legTravelMins);
                            leg.DepartureTime = departure.ToLocalTime();
                            leg.ArrivalTime = arrival.ToLocalTime();
                            current = arrival;
                        }

                        if (valid)
                        {
                            double waitMins = (dep1 - utcNow).TotalMinutes;
                            candidates.Add((legsCopy, current, waitMins));
                        }
                    }
                }

                // Rank by arrival time at destination, take top k
                var top = candidates.OrderBy(c => c.Arrival).Take(k).ToList();

                // If no realtime candidates, fall back to static journeys
                if (top.Count == 0)
                {
                    Console.WriteLine("[TripPlan] No realtime candidates — returning static journeys");
                    var staticTrips = journeys.Take(k).SelectMany(j => j).ToList();
                    return Ok(new TripResponse
                    {
                        Status = _defaultStatus,
                        Trips = staticTrips,
                        Journeys = journeys.Take(k).ToList()
                    });
                }

                // Annotate first leg of each result with wait/total minutes
                foreach (var (legs, arrival, waitMins) in top)
                {
                    legs[0].WaitMinutes = (int)Math.Max(0, waitMins);
                    // TotalMinutes = wait until first departure + sum of all leg travel times
                    double totalTravelMins = legs.Sum(leg => (double)(leg.TravelMinutes ?? 0));
                    legs[0].TotalMinutes = (int)Math.Round(Math.Max(0, waitMins) + totalTravelMins);
                }

                var resultJourneys = top.Select(c => c.Legs).ToList();
                var resultTrips = resultJourneys.SelectMany(j => j).ToList();

                return Ok(new TripResponse
                {
                    Status = _defaultStatus,
                    Trips = resultTrips,
                    Journeys = resultJourneys
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    Status = new Status { Version = "dev", Health = 0 },
                    Error = ex.Message
                });
            }
        }

        [HttpGet("geopath/{routeId}/{originStopId}/{destinationStopId}")]
        public async Task<ActionResult<GeopathResponse>> GetGeopath(
            int routeId,
            int originStopId,
            int destinationStopId
        )
        {
            var geopath = await _database.GetTripGeopath( originStopId, destinationStopId, routeId);
             return Ok(new GeopathResponse
                {
                    Status = _defaultStatus,
                    Geopath = geopath,
                });
        }

        [HttpGet("tripPlanRealtime/{originStopId}/{destinationStopId}")]
        public async Task<ActionResult<TripResponse>> GetTripPlanRealtime(
            int originStopId,
            int destinationStopId,
            [FromQuery] string? departureTime = null,
            [FromQuery] int k = 3,
            [FromQuery] int departuresPerRoute = 3,
            [FromQuery] bool includeReplacementBuses = false
        )
        {
            try
            {
                // Parse departure time (default to now if not provided)
                DateTime parsedDepartureTime = DateTime.Now;
                if (!string.IsNullOrEmpty(departureTime))
                {
                    if (!DateTime.TryParse(departureTime, out parsedDepartureTime))
                    {
                        return BadRequest(new
                        {
                            Status = new Status { Version = "dev", Health = 0 },
                            Error = "Invalid departure time format. Use ISO 8601 format (e.g., 2024-01-04T14:30:00)"
                        });
                    }

                    // Treat as local time if unspecified
                    if (parsedDepartureTime.Kind == DateTimeKind.Unspecified)
                    {
                        parsedDepartureTime = DateTime.SpecifyKind(parsedDepartureTime, DateTimeKind.Local);
                    }
                }

                // Get the graph-based routes (fastest paths)
                var (trips, journeys, _) = await _database.PlanTripDijkstra(originStopId, destinationStopId, k, includeReplacementBuses);

                if (trips == null || journeys == null || journeys.Count == 0)
                {
                    return NotFound(new TripResponse
                    {
                        Status = new Status { Version = "dev", Health = 0 },
                        Trips = [],
                        Journeys = []
                    });
                }

                // Enrich with real-time departure data
                // This will return multiple variants of each journey with different departure times
                var enrichedJourneys = await _database.EnrichJourneysWithRealTimes(
                    journeys,
                    parsedDepartureTime,
                    maxJourneys: k,
                    departuresPerJourney: departuresPerRoute
                );

                // Flatten for backwards compatibility
                var enrichedTrips = enrichedJourneys.SelectMany(j => j).ToList();

                return Ok(new TripResponse
                {
                    Status = _defaultStatus,
                    Trips = enrichedTrips,
                    Journeys = enrichedJourneys
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    Status = new Status { Version = "dev", Health = 0 },
                    Error = ex.Message,
                    StackTrace = ex.StackTrace
                });
            }
        }

        [HttpGet("disruptions")]
        public async Task<ActionResult> GetDisruptions(
            [FromQuery] string? route_types = null
        )
        {
            try
            {
                // Parse route types if provided (e.g., "0,1,3")
                List<int>? routeTypeFilter = null;
                if (!string.IsNullOrEmpty(route_types))
                {
                    routeTypeFilter = route_types.Split(',')
                        .Select(x => int.TryParse(x.Trim(), out var rt) ? rt : -1)
                        .Where(x => x >= 0)
                        .ToList();
                }

                var allDisruptions = new List<Disruption>();
                if (routeTypeFilter != null && routeTypeFilter.Count > 0)
                {
                    foreach (var type in routeTypeFilter)
                    {
                        var disruptions = await _database.GetDisruptions(type);
                        allDisruptions.AddRange(disruptions);
                    }
                }
                else
                {
                    // No filter - get all disruptions
                    allDisruptions = await _database.GetDisruptions(null);
                }

                // Remove duplicates by disruption_id
                var uniqueDisruptions = allDisruptions
                    .GroupBy(d => d.DisruptionId)
                    .Select(g => g.First())
                    .ToList();

                return Ok(new
                {
                    disruptions = uniqueDisruptions,
                    status = _defaultStatus
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    status = new Status { Version = "dev", Health = 0 },
                    error = ex.Message
                });
            }
        }

        [HttpPost("update")]
        public async Task<ActionResult> TriggerUpdate()
        {
            try
            {
                await _database.UpdateValues();
                return Ok(new
                {
                    message = "Update completed successfully. Disruptions have been fetched and parsed.",
                    status = _defaultStatus
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    status = new Status { Version = "dev", Health = 0 },
                    error = ex.Message
                });
            }
        }

        [HttpPost("fetchCoachGeopaths")]
        public async Task<ActionResult> FetchCoachGeopaths()
        {
            try
            {
                await _database.FetchCoachRouteGeopaths();
                return Ok(new
                {
                    message = "Coach route geopaths fetched successfully from OSRM.",
                    status = _defaultStatus
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    status = new Status { Version = "dev", Health = 0 },
                    error = ex.Message
                });
            }
        }

        [HttpGet("ptvRoutes/{routeType}")]
        public async Task<ActionResult> GetPTVRoutes(int routeType)
        {
            try
            {
                var response = await _ptvClient.GetRoutes(routeType);
                return Content(response, "application/json");
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    status = new Status { Version = "dev", Health = 0 },
                    error = ex.Message
                });
            }
        }

        [HttpGet("ptvStops/{routeId}/{routeType}")]
        public async Task<ActionResult> GetPTVStops(int routeId, int routeType)
        {
            try
            {
                var response = await _ptvClient.GetStops(routeType, routeId);
                return Content(response, "application/json");
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    status = new Status { Version = "dev", Health = 0 },
                    error = ex.Message
                });
            }
        }
    }
}