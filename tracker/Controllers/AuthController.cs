using Microsoft.AspNetCore.Mvc;
using PTVApp.Models;
using System.Security.Cryptography;

namespace PTVApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IConfiguration configuration, ILogger<AuthController> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        /// <summary>
        /// Verify username and API key credentials
        /// </summary>
        [HttpPost("verify")]
        public IActionResult VerifyCredentials([FromBody] ApiAuthRequest request)
        {
            var users = _configuration.GetSection("ApiVerification:ApiUsers").Get<List<ApiUser>>() ?? new List<ApiUser>();

            var validUser = users.FirstOrDefault(u =>
                u.Username == request.Username &&
                u.ApiKey == request.ApiKey &&
                u.IsActive);

            if (validUser == null)
            {
                _logger.LogWarning("Failed verification attempt: Username={Username} from IP={IP}",
                    request.Username, HttpContext.Connection.RemoteIpAddress);
                return Unauthorized(new { error = "Invalid username or API key" });
            }

            return Ok(new
            {
                success = true,
                username = validUser.Username,
                description = validUser.Description,
                message = "Credentials verified successfully"
            });
        }

        /// <summary>
        /// Test connection to server (no auth required)
        /// </summary>
        [HttpGet("test")]
        public IActionResult TestConnection()
        {
            return Ok(new
            {
                status = "connected",
                server = "PTV Tracker API",
                timestamp = DateTime.UtcNow,
                message = "Server is reachable"
            });
        }

        /// <summary>
        /// Generate a new secure API key
        /// </summary>
        [HttpGet("generate-key")]
        public IActionResult GenerateApiKey()
        {
            var apiKey = GenerateSecureApiKey();
            return Ok(new
            {
                api_key = apiKey,
                message = "Add this to your appsettings.json ApiUsers section"
            });
        }

        private string GenerateSecureApiKey()
        {
            var bytes = new byte[32];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(bytes);
            }
            return Convert.ToBase64String(bytes).Replace("/", "_").Replace("+", "-").TrimEnd('=');
        }
    }
}
