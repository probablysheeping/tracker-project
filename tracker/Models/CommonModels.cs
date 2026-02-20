using System.Text.Json.Serialization;

namespace PTVApp.Models
{
    public class Status
    {
        [JsonPropertyName("version")]
        public required string Version { get; set; }
        
        [JsonPropertyName("health")]
        public int Health { get; set; }
    }
    public class GeoPoint
    {
        [JsonPropertyName("lat")]
        public required double Latitude { get; set; }

        [JsonPropertyName("lon")]
        public required double Longitude { get; set; }
    }

    public class GeopathResponse
    {
        [JsonPropertyName("geopath")]
        public List<GeoPoint> Geopath { get; set;} = [];
        [JsonPropertyName("staus")]
        public required Status Status{ get; set; }
    }
}