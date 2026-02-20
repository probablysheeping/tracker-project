using Microsoft.AspNetCore.Mvc;
using PTVApp.Services;
using Npgsql;
using System.Diagnostics;

namespace PTVApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HealthController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<HealthController> _logger;

        public HealthController(IConfiguration configuration, ILogger<HealthController> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        /// <summary>
        /// Basic health check endpoint
        /// </summary>
        [HttpGet]
        public IActionResult GetHealth()
        {
            return Ok(new
            {
                status = "healthy",
                timestamp = DateTime.UtcNow,
                uptime = GetUptime(),
                service = _configuration["AppInfo:Name"] ?? "PTV Tracker API",
                version = _configuration["AppInfo:Version"] ?? "1.0.0",
                environment = _configuration["AppInfo:Environment"] ?? "Unknown"
            });
        }

        /// <summary>
        /// Detailed health check with database connectivity
        /// </summary>
        [HttpGet("detailed")]
        public async Task<IActionResult> GetDetailedHealth()
        {
            var health = new
            {
                status = "healthy",
                timestamp = DateTime.UtcNow,
                uptime = GetUptime(),
                service = _configuration["AppInfo:Name"] ?? "PTV Tracker API",
                version = _configuration["AppInfo:Version"] ?? "1.0.0",
                environment = _configuration["AppInfo:Environment"] ?? "Unknown",
                checks = new Dictionary<string, object>()
            };

            // Check database connectivity
            var dbStatus = await CheckDatabaseAsync();
            health.checks["database"] = dbStatus;

            // Check PTV API credentials
            var ptvStatus = CheckPTVCredentials();
            health.checks["ptv_credentials"] = ptvStatus;

            // Check API key authentication status
            var apiKeyStatus = new
            {
                enabled = _configuration.GetValue<bool>("ApiVerification:EnableApiKeyAuth"),
                header = _configuration["ApiVerification:ApiKeyHeader"] ?? "X-API-Key"
            };
            health.checks["api_key_auth"] = apiKeyStatus;

            // Check CORS configuration
            var corsMode = _configuration["Cors:Mode"] ?? "AllowAll";
            var corsOrigins = _configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
            var corsStatus = new
            {
                mode = corsMode,
                allowed_origins = corsMode == "AllowAll" ? new[] { "*" } : corsOrigins
            };
            health.checks["cors"] = corsStatus;

            // Determine overall status
            var overallHealthy = dbStatus.status == "healthy" && ptvStatus.status == "configured";

            if (!overallHealthy)
            {
                return StatusCode(503, new { status = "unhealthy", details = health });
            }

            return Ok(health);
        }

        /// <summary>
        /// Ping endpoint for simple uptime monitoring
        /// </summary>
        [HttpGet("ping")]
        public IActionResult Ping()
        {
            return Ok(new { message = "pong", timestamp = DateTime.UtcNow });
        }

        private async Task<dynamic> CheckDatabaseAsync()
        {
            var stopwatch = Stopwatch.StartNew();
            try
            {
                var host = _configuration["Database:Host"] ?? "localhost";
                var port = _configuration.GetValue<int>("Database:Port", 5432);
                var username = _configuration["Database:Username"] ?? "postgres";
                var password = _configuration["Database:Password"] ?? "password";
                var database = _configuration["Database:Database"] ?? "tracker";

                var connectionString = $"Host={host};Port={port};Username={username};Password={password};Database={database}";

                await using var conn = new NpgsqlConnection(connectionString);
                await conn.OpenAsync();

                // Test query
                await using var cmd = new NpgsqlCommand("SELECT 1", conn);
                await cmd.ExecuteScalarAsync();

                stopwatch.Stop();

                return new
                {
                    status = "healthy",
                    response_time_ms = stopwatch.ElapsedMilliseconds,
                    host = host,
                    port = port,
                    database = database
                };
            }
            catch (Exception ex)
            {
                stopwatch.Stop();
                _logger.LogError(ex, "Database health check failed");
                return new
                {
                    status = "unhealthy",
                    error = ex.Message,
                    response_time_ms = stopwatch.ElapsedMilliseconds
                };
            }
        }

        private dynamic CheckPTVCredentials()
        {
            try
            {
                var apiKey = _configuration["api-key"];
                var userId = _configuration["user-id"];

                if (string.IsNullOrEmpty(apiKey) || string.IsNullOrEmpty(userId))
                {
                    return new
                    {
                        status = "not_configured",
                        message = "PTV API credentials not found in user secrets"
                    };
                }

                return new
                {
                    status = "configured",
                    user_id_present = !string.IsNullOrEmpty(userId),
                    api_key_present = !string.IsNullOrEmpty(apiKey)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking PTV credentials");
                return new
                {
                    status = "error",
                    error = ex.Message
                };
            }
        }

        private string GetUptime()
        {
            var uptime = DateTime.UtcNow - Process.GetCurrentProcess().StartTime.ToUniversalTime();
            return $"{uptime.Days}d {uptime.Hours}h {uptime.Minutes}m {uptime.Seconds}s";
        }
    }
}
