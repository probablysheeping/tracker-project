using Microsoft.AspNetCore.Mvc;
using Microsoft.VisualBasic;
using Npgsql;
using PTVApp.Models;
using PTVApp.Services;
using System.Reflection.Metadata;
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
                var (trips, journeys) = await _database.PlanTripDijkstra(originStopId, destinationStopId, k, includeReplacementBuses);

                if (trips == null || journeys == null)
                {
                    return NotFound(new TripResponse
                    {
                        Status = new Status { Version = "dev", Health = 0 },
                        Trips = [],
                        Journeys = []
                    });
                }

                return Ok(new TripResponse
                {
                    Status = _defaultStatus,
                    Trips = trips,
                    Journeys = journeys
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
                var (trips, journeys) = await _database.PlanTripDijkstra(originStopId, destinationStopId, k, includeReplacementBuses);

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