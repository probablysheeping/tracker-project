using Microsoft.AspNetCore.Http;
using PTVApp.Models;
using System.Linq;
using System.Threading.Tasks;

namespace PTVApp.Middleware
{
    public class ApiKeyMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ApiKeyMiddleware> _logger;

        public ApiKeyMiddleware(RequestDelegate next, IConfiguration configuration, ILogger<ApiKeyMiddleware> logger)
        {
            _next = next;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            // Check if API key authentication is enabled
            var isEnabled = _configuration.GetValue<bool>("ApiVerification:EnableApiKeyAuth");

            if (!isEnabled)
            {
                await _next(context);
                return;
            }

            // Skip authentication for health check endpoint
            if (context.Request.Path.StartsWithSegments("/health") ||
                context.Request.Path.StartsWithSegments("/api/health") ||
                context.Request.Path.StartsWithSegments("/api/auth/verify"))
            {
                await _next(context);
                return;
            }

            // Skip authentication for Swagger in development
            if (context.Request.Path.StartsWithSegments("/swagger"))
            {
                await _next(context);
                return;
            }

            // Get username and API key from headers
            if (!context.Request.Headers.TryGetValue("X-Username", out var username))
            {
                context.Response.StatusCode = 401;
                await context.Response.WriteAsJsonAsync(new
                {
                    error = "Username is missing",
                    required_headers = new[] { "X-Username", "X-API-Key" }
                });
                return;
            }

            if (!context.Request.Headers.TryGetValue("X-API-Key", out var apiKey))
            {
                context.Response.StatusCode = 401;
                await context.Response.WriteAsJsonAsync(new
                {
                    error = "API Key is missing",
                    required_headers = new[] { "X-Username", "X-API-Key" }
                });
                return;
            }

            // Get valid users from configuration
            var users = _configuration.GetSection("ApiVerification:ApiUsers").Get<List<ApiUser>>() ?? new List<ApiUser>();

            var validUser = users.FirstOrDefault(u =>
                u.Username == username.ToString() &&
                u.ApiKey == apiKey.ToString() &&
                u.IsActive);

            if (validUser == null)
            {
                _logger.LogWarning("Invalid credentials attempt: Username={Username} from IP={IP}",
                    username, context.Connection.RemoteIpAddress);
                context.Response.StatusCode = 401;
                await context.Response.WriteAsJsonAsync(new { error = "Invalid username or API key" });
                return;
            }

            // Add user info to request items for later use
            context.Items["AuthenticatedUser"] = validUser.Username;

            await _next(context);
        }
    }
}
