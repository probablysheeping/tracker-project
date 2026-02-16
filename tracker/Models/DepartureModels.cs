using System.Text.Json.Serialization;

namespace PTVApp.Models
{
    public class DeparturesResponse
    {
        [JsonPropertyName("departures")]
        public List<Departure> Departures { get; set; } = [];

        [JsonPropertyName("runs")]
        public Dictionary<string, Run>? Runs { get; set; }

        [JsonPropertyName("routes")]
        public Dictionary<string, DepartureRoute>? Routes { get; set; }

        [JsonPropertyName("stops")]
        public Dictionary<string, DepartureStop>? Stops { get; set; }

        [JsonPropertyName("status")]
        public Status? Status { get; set; }
    }

    public class Departure
    {
        [JsonPropertyName("stop_id")]
        public int StopId { get; set; }

        [JsonPropertyName("route_id")]
        public int RouteId { get; set; }

        [JsonPropertyName("run_ref")]
        public string? RunRef { get; set; }

        [JsonPropertyName("run_id")]
        public int? RunId { get; set; }

        [JsonPropertyName("direction_id")]
        public int DirectionId { get; set; }

        [JsonPropertyName("disruption_ids")]
        public List<long> DisruptionIds { get; set; } = [];

        [JsonPropertyName("scheduled_departure_utc")]
        public DateTime? ScheduledDepartureUtc { get; set; }

        [JsonPropertyName("estimated_departure_utc")]
        public DateTime? EstimatedDepartureUtc { get; set; }

        [JsonPropertyName("at_platform")]
        public bool AtPlatform { get; set; }

        [JsonPropertyName("platform_number")]
        public string? PlatformNumber { get; set; }

        [JsonPropertyName("flags")]
        public string? Flags { get; set; }
    }

    public class Run
    {
        [JsonPropertyName("run_id")]
        public int? RunId { get; set; }

        [JsonPropertyName("run_ref")]
        public string? RunRef { get; set; }

        [JsonPropertyName("route_id")]
        public int RouteId { get; set; }

        [JsonPropertyName("route_type")]
        public int RouteType { get; set; }

        [JsonPropertyName("final_stop_id")]
        public int FinalStopId { get; set; }

        [JsonPropertyName("destination_name")]
        public string? DestinationName { get; set; }

        [JsonPropertyName("status")]
        public string? Status { get; set; }

        [JsonPropertyName("direction_id")]
        public int DirectionId { get; set; }

        [JsonPropertyName("run_sequence")]
        public int RunSequence { get; set; }

        [JsonPropertyName("express_stop_count")]
        public int ExpressStopCount { get; set; }

        [JsonPropertyName("vehicle_position")]
        public VehiclePosition? VehiclePosition { get; set; }
    }

    public class VehiclePosition
    {
        [JsonPropertyName("latitude")]
        public double Latitude { get; set; }

        [JsonPropertyName("longitude")]
        public double Longitude { get; set; }

        [JsonPropertyName("direction")]
        public string? Direction { get; set; }

        [JsonPropertyName("bearing")]
        public double? Bearing { get; set; }

        [JsonPropertyName("supplier")]
        public string? Supplier { get; set; }

        [JsonPropertyName("datetime_utc")]
        public DateTime? DatetimeUtc { get; set; }
    }

    public class DepartureRoute
    {
        [JsonPropertyName("route_type")]
        public int RouteType { get; set; }

        [JsonPropertyName("route_id")]
        public int RouteId { get; set; }

        [JsonPropertyName("route_name")]
        public string? RouteName { get; set; }

        [JsonPropertyName("route_number")]
        public string? RouteNumber { get; set; }

        [JsonPropertyName("route_gtfs_id")]
        public string? RouteGtfsId { get; set; }
    }

    public class DepartureStop
    {
        [JsonPropertyName("stop_id")]
        public int StopId { get; set; }

        [JsonPropertyName("stop_name")]
        public string? StopName { get; set; }

        [JsonPropertyName("stop_latitude")]
        public double StopLatitude { get; set; }

        [JsonPropertyName("stop_longitude")]
        public double StopLongitude { get; set; }

        [JsonPropertyName("route_type")]
        public int RouteType { get; set; }
    }

    // Pattern API response (used for getting stop timings along a route)
    public class PatternResponse
    {
        [JsonPropertyName("departures")]
        public List<Departure> Departures { get; set; } = [];

        [JsonPropertyName("stops")]
        public Dictionary<string, DepartureStop>? Stops { get; set; }

        [JsonPropertyName("routes")]
        public Dictionary<string, DepartureRoute>? Routes { get; set; }

        [JsonPropertyName("runs")]
        public Dictionary<string, Run>? Runs { get; set; }

        [JsonPropertyName("status")]
        public Status? Status { get; set; }
    }
}
