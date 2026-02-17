using System.Text.Json.Serialization;

namespace PTVApp.Models
{
    public class TripResponse
    {
        [JsonPropertyName("trips")]
        public List<Trip> Trips { get; set; } = [];

        [JsonPropertyName("journeys")]
        public List<List<Trip>> Journeys { get; set; } = [];

        [JsonPropertyName("status")]
        public required Status Status { get; set; }
    }

    public class Trip
    {
        [JsonPropertyName("trip_id")]
        public required int TripId { get; set; }
        [JsonPropertyName("origin_stop_id")]
        public required int OriginStopId { get; set; }

        [JsonPropertyName("destination_stop_id")]
        public required int DestinationStopId { get; set; }

        [JsonPropertyName("departure_time")]
        public required DateTime DepartureTime { get; set; }

        [JsonPropertyName("arrival_time")]
        public required DateTime ArrivalTime { get; set; }

        [JsonPropertyName("route_id")]
        public required int RouteId { get; set; }

        [JsonPropertyName("route_name")]
        public string? RouteName { get; set; }

        [JsonPropertyName("route_number")]
        public string? RouteNumber { get; set; }

        [JsonPropertyName("route_type")]
        public int RouteType { get; set; }

        [JsonPropertyName("route_colour")]
        public string? RouteColour { get; set; }

        [JsonPropertyName("geopath")]
        public List<GeoPoint> GeoPath {get; set;} = [];
    }

}