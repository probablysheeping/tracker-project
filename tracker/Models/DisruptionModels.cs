using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
namespace PTVApp.Models
{
    
    public class DisruptionsResponse
    {
        [JsonPropertyName("disruptions")]
        public Dictionary<string, List<Disruption>> Disruptions { get; set; } = new Dictionary<string, List<Disruption>>();

        [JsonPropertyName("status")]
        public required Status Status { get; set; }
    }

    public class Disruption
    {
        [JsonPropertyName("disruption_id")]
        public required long DisruptionId { get; set; }

        [JsonPropertyName("title")]
        public required string Title { get; set; }

        [JsonPropertyName("url")]
        public required string Url { get; set; }

        [JsonPropertyName("description")]
        public required string Description { get; set; }

        [JsonPropertyName("disruption_status")]
        public required string DisruptionStatus { get; set; }

        [JsonPropertyName("disruption_type")]
        public required string DisruptionType { get; set; }

        [JsonPropertyName("published_on")]
        public DateTimeOffset? PublishedOn { get; set; }

        [JsonPropertyName("last_updated")]
        public DateTimeOffset? LastUpdated { get; set; }

        [JsonPropertyName("from_date")]
        public DateTimeOffset? FromDate { get; set; }

        [JsonPropertyName("to_date")]
        public DateTimeOffset? ToDate { get; set; }

        [JsonPropertyName("routes")]
        public List<Route> Routes { get; set; } = new List<Route>();

        [JsonPropertyName("stops")]
        public List<DisruptionStop> Stops { get; set; } = new List<DisruptionStop>();

        [JsonPropertyName("colour")]
        public required string Colour { get; set; }

        [JsonPropertyName("display_on_board")]
        public required bool DisplayOnBoard { get; set; }

        [JsonPropertyName("display_status")]
        public required bool DisplayStatus { get; set; }

        [JsonPropertyName("route_type")]
        public int? RouteType { get; set; }

        [JsonPropertyName("disruption_event")]
        public DisruptionEvent? DisruptionEventData { get; set; }
    }
    public class DisruptionStop
    {
        [JsonPropertyName("stop_id")]
        public required int StopId { get; set; }

        [JsonPropertyName("stop_name")]
        public required string StopName { get; set; }
    }
    public class Direction
    {
        [JsonPropertyName("route_direction_id")]
        public required int RouteDirectionId { get; set; }

        [JsonPropertyName("direction_id")]
        public required int DirectionId { get; set; }

        [JsonPropertyName("direction_name")]
        public required string DirectionName { get; set; }

        [JsonPropertyName("service_time")]
        public required string ServiceTime { get; set; }
    }
    
    public class DisruptionModesResponse
    {
        [JsonPropertyName("disruption_modes")]
        public required List<DisruptionMode> Disruption_Modes {get; set;}

        [JsonPropertyName("status")]
        public required Status Status { get; set; }
    }

    public class DisruptionMode
    {
        [JsonPropertyName("disruption_mode_name")]
        public required string DisruptionModeName { get; set; }

        [JsonPropertyName("disruption_mode")]
        public required int DisruptionModeId { get; set; }
    }

    // Structured disruption event models
    public class DisruptionEvent
    {
        [JsonPropertyName("event_type")]
        public required string EventType { get; set; }  // "replacement_service", "service_suspended", "service_disrupted", "delay"

        [JsonPropertyName("route_type")]
        public required int RouteType { get; set; }     // 0=Train, 1=Tram, 2=Bus, 3=V/Line

        [JsonPropertyName("route_number")]
        public string? RouteNumber { get; set; }        // Route number (e.g., "82" for trams)

        [JsonPropertyName("delay_minutes")]
        public int? DelayMinutes { get; set; }          // Delay duration for coach delays

        [JsonPropertyName("affected_area")]
        public required DisruptionLocation AffectedArea { get; set; }

        [JsonPropertyName("replacement")]
        public ReplacementService? Replacement { get; set; }

        [JsonPropertyName("periods")]
        public required List<DisruptionPeriod> Periods { get; set; }
    }

    public class DisruptionLocation
    {
        [JsonPropertyName("start_location")]
        public string? StartLocation { get; set; }  // Station/stop name

        [JsonPropertyName("end_location")]
        public string? EndLocation { get; set; }    // Station/stop name

        [JsonPropertyName("route_id")]
        public int? RouteId { get; set; }           // Specific route (for buses/trams)

        [JsonPropertyName("route_name")]
        public string? RouteName { get; set; }      // "Route 86", "Frankston Line"

        [JsonPropertyName("type")]
        public required string Type { get; set; }   // "segment", "station", "route", "stop"

        [JsonPropertyName("facility")]
        public string? Facility { get; set; }       // "entrance", "lift", "escalator", "platform", etc.
    }

    public class ReplacementService
    {
        [JsonPropertyName("mode")]
        public required string Mode { get; set; }  // "bus", "tram", "coach"

        [JsonPropertyName("route_type")]
        public required int RouteType { get; set; }
    }

    public class DisruptionPeriod
    {
        [JsonPropertyName("start_datetime")]
        public DateTime? StartDateTime { get; set; }

        [JsonPropertyName("end_datetime")]
        public DateTime? EndDateTime { get; set; }

        [JsonPropertyName("is_last_service")]
        public bool IsLastService { get; set; }

        [JsonPropertyName("recurrence_pattern")]
        public string? RecurrencePattern { get; set; }  // "each night", "weekdays", etc.
    }
}