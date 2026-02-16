using System;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

namespace PTVApp.Services {
    public class PTVClient
    {
        private readonly string _userId;
        private readonly string _apiKey;
        private readonly string _baseUrl = "https://timetableapi.ptv.vic.gov.au";
        private readonly HttpClient _httpClient;

        public PTVClient(string userId, string apiKey)
        {
            _userId = userId;
            _apiKey = apiKey;
            _httpClient = new HttpClient();
        }

        private string GenerateSignature(string uri)
        {
            // Add devid parameter to the URI
            string uriWithDevId = uri + (uri.Contains("?") ? "&" : "?") + "devid=" + _userId;

            // Calculate HMAC-SHA1 signature
            byte[] keyBytes = Encoding.UTF8.GetBytes(_apiKey);
            byte[] uriBytes = Encoding.UTF8.GetBytes(uriWithDevId);

            using (var hmac = new HMACSHA1(keyBytes))
            {
                byte[] hash = hmac.ComputeHash(uriBytes);
                string signature = BitConverter.ToString(hash).Replace("-", "").ToUpper();
                return signature;
            }
        }

        private async Task<string> CallApi(string endpoint)
        {
            // Generate the signature
            string signature = GenerateSignature(endpoint);
            
            // Build the full URL
            string fullUrl = $"{_baseUrl}{endpoint}";
            fullUrl += (endpoint.Contains("?") ? "&" : "?") + $"devid={_userId}&signature={signature}";

            Console.WriteLine($"Requesting: {fullUrl}");

            // Make the request
            var response = await _httpClient.GetAsync(fullUrl);
            response.EnsureSuccessStatusCode();
            
            return await response.Content.ReadAsStringAsync();
        }

        // Health Check endpoint
        public async Task<string> GetHealthCheck()
        {
            return await CallApi("/v3/healthcheck");
        }

        // Get stops nearby a coordinate
        public async Task<string> GetStopsNearby(double latitude, double longitude, int maxResults = 30)
        {
            return await CallApi($"/v3/stops/location/{latitude},{longitude}?max_results={maxResults}");
        }

        // Get departures from a stop
        public async Task<string> GetDepartures(int routeType, int stopId, int maxResults = 5)
        {
            // routeType: 0=Train, 1=Tram, 2=Bus, 3=V/Line, 4=NightBus
            return await CallApi($"/v3/departures/route_type/{routeType}/stop/{stopId}?max_results={maxResults}");
        }

        // Search for stops or routes
        public async Task<string> Search(string searchTerm)
        {
            return await CallApi($"/v3/search/{Uri.EscapeDataString(searchTerm)}");
        }
        public async Task<string> GetRoute(int routeId, int? routeType = null)
        {   
            if (routeType.HasValue)
            {
                return await CallApi($"/v3/routes/{routeId}?route_type={routeType}");
            }
            return await CallApi($"/v3/routes/{routeId}");
        }
        public async Task<string> GetRoutes(int? routeType = null)
        {
            if (routeType.HasValue)
            {
                return await CallApi($"/v3/routes?route_types={routeType}");
            }
            return await CallApi("/v3/routes");
        }
        // Get route types
        public async Task<string> GetRouteTypes()
        {
            return await CallApi("/v3/route_types");
        }
        public async Task<string> GetStops(int routeType, int routeId)
        {   
            return await CallApi($"/v3/stops/route/{routeId}/route_type/{routeType}");
        }

        public async Task<string> GetDisruptionModes()
        {
            return await CallApi("/v3/disruptions/modes");
        }

        public async Task<string> GetDisruptions(int? routeType=null)
        {
            if (routeType is not null) {
                return await CallApi($"/v3/disruptions?route_types={routeType}");
            }
            return await CallApi("/v3/disruptions");
        }

        // Get runs for a route (to find run_ref for pattern lookup)
        public async Task<string> GetRuns(int routeId, int routeType)
        {
            return await CallApi($"/v3/runs/route/{routeId}/route_type/{routeType}");
        }

        // Get pattern (geopath) for a specific run
        public async Task<string> GetPattern(string runRef, int routeType)
        {
            return await CallApi($"/v3/pattern/run/{Uri.EscapeDataString(runRef)}/route_type/{routeType}");
        }

        // Get directions for a route
        public async Task<string> GetDirections(int routeId, int routeType)
        {
            return await CallApi($"/v3/directions/route/{routeId}");
        }

        // Get departures from a specific stop on a specific route
        public async Task<string> GetDeparturesForRoute(int routeType, int stopId, int routeId, int maxResults = 10)
        {
            return await CallApi($"/v3/departures/route_type/{routeType}/stop/{stopId}/route/{routeId}?max_results={maxResults}&expand=run&expand=route&expand=stop");
        }

        // Get departures from a stop (all routes)
        public async Task<string> GetDeparturesFromStop(int routeType, int stopId, int maxResults = 10)
        {
            return await CallApi($"/v3/departures/route_type/{routeType}/stop/{stopId}?max_results={maxResults}");
        }
    }
}