using System.Text.Json.Serialization;

namespace PTVApp.Models
{
    public class RouteResponse
    {
        [JsonPropertyName("routes")]
        public List<Route> Routes { get; set; } = [];
        
        [JsonPropertyName("status")]
        public required Status Status { get; set; }
    }


    public class RoutePattern
    {
        [JsonPropertyName("pattern_name")]
        public required string PatternName { get; set; }

        [JsonPropertyName("pattern_description")]
        public string? PatternDescription { get; set; }

        [JsonPropertyName("trip_headsign")]
        public string? TripHeadsign { get; set; }

        [JsonPropertyName("geopath")]
        public List<GeoPoint> GeoPath { get; set; } = [];
    }

    public class Route
    {
        [JsonPropertyName("route_type")]
        public required int RouteType { get; set; }

        [JsonPropertyName("route_id")]
        public required int RouteId { get; set; }

        [JsonPropertyName("route_name")]
        public required string RouteName { get; set; }

        [JsonPropertyName("route_number")]
        public string? RouteNumber { get; set; }

        [JsonPropertyName("route_gtfs_id")]
        public required string RouteGtfsId { get; set; }

        [JsonPropertyName("geopaths")]
        public List<List<GeoPoint>>? GeoPaths { get; set; } = null;

        [JsonPropertyName("patterns")]
        public List<RoutePattern> Patterns { get; set; } = [];
    }

    public class RouteSendResponse : RouteResponse
    {
        [JsonPropertyName("routes")]
        public new List<RouteSend> Routes { get; set; } = [];
    }

    public class RouteSend : Route
    {
        [JsonPropertyName("route_colour")]
        public required int[] RouteColour { get; set; }
    }
    
    public class RouteTypeResponse
    {
        [JsonPropertyName("route_types")]
        public required List<RouteType> Route_Types {get; set;}
    }
    
    public class RouteType
    {
        [JsonPropertyName("route_type")]
        public int RouteTypeId { get; set; }
        
        [JsonPropertyName("route_type_name")]
        public required string RouteTypeName { get; set; }
    }
    public class RouteResponseSingle
    {
        [JsonPropertyName("route")]
        public required Route Route { get; set; }
        
        [JsonPropertyName("status")]
        public required Status Status { get; set; }
    }
}