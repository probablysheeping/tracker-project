using Microsoft.AspNetCore.Mvc;
using PTVApp.Models;
using PTVApp.Services;
using PTVApp.Controllers;
using PTVApp.Middleware;
using System.Threading.Tasks;

namespace PTVApp.Program
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);
            builder.Configuration.AddUserSecrets<Program>();

            // Map environment variables for cloud deployment (Railway, Supabase, etc.)
            // PTV_API_KEY, PTV_USER_ID → used for PTV Timetable API authentication
            // FRONTEND_API_KEY → used for the app's own frontend auth (set in GitHub Actions secret)
            var envOverrides = new Dictionary<string, string?>();
            var ptvApiKey = Environment.GetEnvironmentVariable("PTV_API_KEY");
            var ptvUserId = Environment.GetEnvironmentVariable("PTV_USER_ID");
            var frontendApiKey = Environment.GetEnvironmentVariable("FRONTEND_API_KEY");
            if (!string.IsNullOrEmpty(ptvApiKey)) envOverrides["api-key"] = ptvApiKey;
            if (!string.IsNullOrEmpty(ptvUserId)) envOverrides["user-id"] = ptvUserId;
            if (!string.IsNullOrEmpty(frontendApiKey))
            {
                // Override the production API key from environment
                envOverrides["ApiVerification:ApiUsers:0:ApiKey"] = frontendApiKey;
                envOverrides["ApiVerification:EnableApiKeyAuth"] = "true";
            }
            if (envOverrides.Count > 0)
                builder.Configuration.AddInMemoryCollection(envOverrides);
            var database = new DatabaseService(builder.Configuration);

            await database.UpdateValues();

            // Build routing graph in memory (replaces pgRouting dependency)
            var routingGraph = new RoutingGraph();
            await routingGraph.LoadFromConfig(builder.Configuration);

            // Add services to the container.
            builder.Services.AddSingleton(routingGraph);
            builder.Services.AddControllers();
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            // Configure CORS based on appsettings.json
            var corsMode = builder.Configuration["Cors:Mode"] ?? "AllowAll";
            builder.Services.AddCors(options =>
            {
                if (corsMode == "Restricted")
                {
                    var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
                        ?? new[] { "https://probablysheeping.github.io" };

                    options.AddPolicy("AllowFrontend", policy =>
                        policy
                            .WithOrigins(allowedOrigins)
                            .AllowAnyHeader()
                            .AllowAnyMethod()
                            .AllowCredentials());
                }
                else
                {
                    // AllowAll mode for development/testing
                    options.AddPolicy("AllowFrontend", policy =>
                        policy
                            .AllowAnyOrigin()
                            .AllowAnyHeader()
                            .AllowAnyMethod());
                }
            });

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            // API Key authentication middleware
            app.UseMiddleware<ApiKeyMiddleware>();

            app.UseCors("AllowFrontend");

            app.UseAuthorization();

            app.MapControllers();

            var apiKeyEnabled = builder.Configuration.GetValue<bool>("ApiVerification:EnableApiKeyAuth");
            Console.WriteLine($"\n=== PTV Tracker API Configuration ===");
            Console.WriteLine($"CORS Mode: {corsMode}");
            Console.WriteLine($"API Key Auth: {(apiKeyEnabled ? "ENABLED" : "DISABLED")}");
            Console.WriteLine($"Environment: {app.Environment.EnvironmentName}");
            Console.WriteLine($"Health Check: /api/health");
            Console.WriteLine($"=====================================\n");

            app.Run();
        }
    }
}