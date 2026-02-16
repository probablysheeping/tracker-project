using System.Text.Json.Serialization;

namespace PTVApp.Models
{
    public class StopsResponse
    {
        [JsonPropertyName("stops")]
        public List<Stop> Stops { get; set; } = new List<Stop>();
        
        [JsonPropertyName("status")]
        public required Status Status { get; set; }
    }

    public class Stop
    {
        [JsonPropertyName("stop_id")]
        public int StopId { get; set; }
        
        [JsonPropertyName("stop_name")]
        public required string StopName { get; set; }
        
        [JsonPropertyName("stop_latitude")]
        public required float StopLatitude { get; set; }
        
        [JsonPropertyName("stop_longitude")]
        public required float StopLongitude { get; set; }
        
        [JsonPropertyName("route_type")]
        public required int RouteType { get; set; }

        [JsonPropertyName("stop_ticket")]
        public required StopTicket StopTicket { get; set; }
        [JsonPropertyName("interchange")]
        public List<Interchange> Interchange { get; set; } = new List<Interchange>();

        [JsonPropertyName("stop_suburb")]
        public required string Suburb {get; set;}

        [JsonPropertyName("stop_landmark")]
        public required string Landmark {get; set;}

    }
    public class Interchange
    {
        [JsonPropertyName("route_id")]
        public required int RouteId { get; set; }

        [JsonPropertyName("advertised")]
        public required bool Advertised { get; set; }
    }

    public class StopDto : Stop
    {
        [JsonPropertyName("interchange")]
        public new int[] Interchange { get; set; } = [];

        [JsonPropertyName("route_ids")]
        public int[] RouteIds { get; set; } = [];
    }

    public class StopTicket
    {
        [JsonPropertyName("ticket_type")]
        public string TicketType { get; set; } = null!;

        [JsonPropertyName("zone")]
        public string Zone { get; set; } = null!;

        [JsonPropertyName("is_free_fare_zone")]
        public bool IsFreeFareZone { get; set; }

        [JsonPropertyName("ticket_machine")]
        public bool TicketMachine { get; set; }

        [JsonPropertyName("ticket_checks")]
        public bool TicketChecks { get; set; }

        [JsonPropertyName("vline_reservation")]
        public bool VlineReservation { get; set; }

        [JsonPropertyName("ticket_zones")]
        public List<int> TicketZones { get; set; } = new List<int>();
    }
}