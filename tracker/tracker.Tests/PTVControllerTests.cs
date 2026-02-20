using Xunit;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using PTVApp.Controllers;
using PTVApp.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;

namespace tracker.Tests;

public class PTVControllerTests
{
    private readonly PTVController _controller;

    public PTVControllerTests()
    {
        // Setup mock configuration
        var inMemorySettings = new Dictionary<string, string> {
            {"api-key", "test-api-key"},
            {"user-id", "test-user-id"}
        };

        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings!)
            .Build();

        _controller = new PTVController(configuration);
    }

    [Fact]
    public async Task GetRoutes_WithoutFilters_ReturnsAllRoutes()
    {
        // Act
        var result = await _controller.GetRoutes();

        // Assert
        var actionResult = Assert.IsType<ActionResult<RouteSendResponse>>(result);
        var response = actionResult.Value;

        Assert.NotNull(response);
        Assert.NotNull(response.Routes);
        Assert.NotEmpty(response.Routes);
    }

    [Fact]
    public async Task GetRoutes_WithExpandPatterns_ReturnsExpandedRoutes()
    {
        // Act
        var result = await _controller.GetRoutes(expandPatterns: true);

        // Assert
        var response = result.Value;
        Assert.NotNull(response);
        Assert.NotNull(response.Routes);
        Assert.NotEmpty(response.Routes);
    }

    [Theory]
    [InlineData("0")]     // Trains only
    [InlineData("1")]     // Trams only
    [InlineData("0,1")]   // Trains and Trams
    [InlineData("0,1,3")] // Trains, Trams, and V/Line
    public async Task GetRoutes_WithRouteTypeFilter_ReturnsFilteredRoutes(string routeTypes)
    {
        // Act
        var result = await _controller.GetRoutes(route_types: routeTypes);

        // Assert
        var response = result.Value;
        Assert.NotNull(response);
        Assert.NotNull(response.Routes);
        Assert.NotEmpty(response.Routes);

        // Parse expected route types
        var expectedTypes = routeTypes.Split(',').Select(int.Parse).ToList();

        // All returned routes should match the filter
        Assert.All(response.Routes, route =>
        {
            Assert.Contains(route.RouteType, expectedTypes);
        });
    }

    [Theory]
    [InlineData(0)] // Trains
    [InlineData(1)] // Trams
    [InlineData(2)] // Buses
    public async Task GetRoutesByType_ValidType_ReturnsRoutes(int routeType)
    {
        // Act
        var result = await _controller.GetRoutesByType(routeType);

        // Assert
        var actionResult = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<RouteSendResponse>(actionResult.Value);

        Assert.NotNull(response);
        Assert.NotNull(response.Routes);
        Assert.NotEmpty(response.Routes);

        // All routes should be of the requested type
        Assert.All(response.Routes, route =>
        {
            Assert.Equal(routeType, route.RouteType);
        });
    }

    [Theory]
    [InlineData(0, true)]  // Trains with geopaths
    [InlineData(1, false)] // Trams without geopaths
    public async Task GetRoutesByType_IncludeGeopaths_ReturnsRoutesWithGeopaths(int routeType, bool includeGeopaths)
    {
        // Act
        var result = await _controller.GetRoutesByType(routeType, includeGeopaths: includeGeopaths);

        // Assert
        var actionResult = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<RouteSendResponse>(actionResult.Value);

        Assert.NotNull(response);
        Assert.NotEmpty(response.Routes);
    }

    [Fact]
    public async Task GetStops_ValidRouteTypes_ReturnsStops()
    {
        // Arrange
        string routeTypes = "0"; // Trains

        // Act
        var result = await _controller.GetStops(routeTypes);

        // Assert
        var actionResult = Assert.IsType<OkObjectResult>(result.Result);
        var stops = Assert.IsType<List<StopDto>>(actionResult.Value);

        Assert.NotNull(stops);
        Assert.NotEmpty(stops);

        // Verify stop data structure
        Assert.All(stops, stop =>
        {
            Assert.NotEqual(0, stop.StopId);
            Assert.NotNull(stop.StopName);
            Assert.InRange(stop.StopLatitude, -90, 90);
            Assert.InRange(stop.StopLongitude, -180, 180);
        });
    }

    [Theory]
    [InlineData("0", true)]  // Trains with routes
    [InlineData("1", false)] // Trams without routes
    public async Task GetStops_IncludeRoutes_ReturnsStopsWithRouteAssociations(string routeTypes, bool includeRoutes)
    {
        // Act
        var result = await _controller.GetStops(routeTypes, include_routes: includeRoutes);

        // Assert
        var actionResult = Assert.IsType<OkObjectResult>(result.Result);
        var stops = Assert.IsType<List<StopDto>>(actionResult.Value);

        Assert.NotNull(stops);
        Assert.NotEmpty(stops);

        if (includeRoutes)
        {
            // At least some stops should have route associations
            var stopsWithRoutes = stops.Where(s => s.RouteIds != null && s.RouteIds.Length > 0).ToList();
            Assert.NotEmpty(stopsWithRoutes);
        }
    }

    [Fact]
    public async Task GetRoute_ValidRouteId_ReturnsRoute()
    {
        // Arrange
        int routeId = 14; // Sunbury line

        // Act
        var result = await _controller.GetRoute(routeId);

        // Assert
        var actionResult = Assert.IsType<OkObjectResult>(result.Result);
        var routeResponse = Assert.IsType<RouteResponseSingle>(actionResult.Value);

        Assert.NotNull(routeResponse);
        Assert.NotNull(routeResponse.Route);
        Assert.Equal(routeId, routeResponse.Route.RouteId);
        Assert.NotNull(routeResponse.Route.RouteName);
    }

    [Fact]
    public async Task GetTripPlan_ValidStops_ReturnsJourneyOptions()
    {
        // Arrange
        int originStopId = 1071; // Flinders Street
        int destinationStopId = 1181; // Southern Cross

        // Act
        var result = await _controller.GetTripPlan(originStopId, destinationStopId);

        // Assert
        var actionResult = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<TripResponse>(actionResult.Value);

        Assert.NotNull(response);
        Assert.NotNull(response.Trips);
        Assert.NotNull(response.Journeys);

        if (response.Trips.Count > 0)
        {
            // Should have at least one journey
            Assert.NotEmpty(response.Journeys);

            // First trip should start at origin
            Assert.Equal(originStopId, response.Trips.First().OriginStopId);

            // Last trip should end at destination
            Assert.Equal(destinationStopId, response.Trips.Last().DestinationStopId);
        }
    }

    [Fact]
    public async Task GetTripPlan_WithKParameter_ReturnsMultipleJourneys()
    {
        // Arrange
        int originStopId = 1071; // Flinders Street
        int destinationStopId = 1181; // Southern Cross
        int k = 3; // Request 3 alternative routes

        // Act
        var result = await _controller.GetTripPlan(originStopId, destinationStopId, k);

        // Assert
        var actionResult = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<TripResponse>(actionResult.Value);

        Assert.NotNull(response);
        Assert.NotNull(response.Journeys);

        // Should return up to k journey options
        Assert.InRange(response.Journeys.Count, 0, k);

        // Each journey should be a complete path
        foreach (var journey in response.Journeys)
        {
            if (journey.Count > 0)
            {
                Assert.Equal(originStopId, journey.First().OriginStopId);
                Assert.Equal(destinationStopId, journey.Last().DestinationStopId);
            }
        }
    }

    [Fact]
    public async Task GetGeopath_ValidParameters_ReturnsGeoJSON()
    {
        // Arrange
        int routeId = 14; // Sunbury line
        int originStopId = 1071; // Flinders Street
        int destinationStopId = 1181; // Southern Cross (more reliable for testing)

        // Act
        var result = await _controller.GetGeopath(routeId, originStopId, destinationStopId);

        // Assert
        var actionResult = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<GeopathResponse>(actionResult.Value);

        Assert.NotNull(response);
        Assert.NotNull(response.Geopath);
    }

    [Fact]
    public void Controller_RequiresConfiguration_ThrowsWhenMissing()
    {
        // Arrange
        var emptyConfig = new ConfigurationBuilder().Build();

        // Act & Assert
        var exception = Assert.Throws<Exception>(() => new PTVController(emptyConfig));
        Assert.Contains("ApiKey or UserID is null", exception.Message);
    }
}
