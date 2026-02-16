using Xunit;
using PTVApp.Services;
using PTVApp.Models;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;

namespace tracker.Tests;

public class DatabaseServiceTests
{
    private readonly IConfiguration _configuration;

    public DatabaseServiceTests()
    {
        // Setup mock configuration for tests
        var inMemorySettings = new Dictionary<string, string> {
            {"api-key", "test-api-key"},
            {"user-id", "test-user-id"}
        };

        _configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings!)
            .Build();
    }

    [Fact]
    public async Task GetRouteTypeNames_ReturnsListOfRouteTypes()
    {
        // Arrange
        var dbService = new DatabaseService(_configuration);

        // Act
        var routeTypes = await dbService.GetRouteTypeNames();

        // Assert
        Assert.NotNull(routeTypes);
        Assert.NotEmpty(routeTypes);
    }

    [Theory]
    [InlineData(0)] // Trains
    [InlineData(1)] // Trams
    [InlineData(2)] // Buses
    public async Task GetStops_ValidRouteType_ReturnsStops(int routeType)
    {
        // Arrange
        var dbService = new DatabaseService(_configuration);

        // Act
        var stops = await dbService.GetStops(routeType);

        // Assert
        Assert.NotNull(stops);
        if (stops.Count > 0)
        {
            Assert.All(stops, stop =>
            {
                Assert.NotEqual(0, stop.StopId);
                Assert.NotNull(stop.StopName);
                Assert.InRange(stop.StopLatitude, -90, 90);
                Assert.InRange(stop.StopLongitude, -180, 180);
            });
        }
    }

    [Theory]
    [InlineData(0)] // Trains
    [InlineData(1)] // Trams
    public async Task GetStopsWithRoutes_ValidRouteType_ReturnsStopsWithRouteInfo(int routeType)
    {
        // Arrange
        var dbService = new DatabaseService(_configuration);

        // Act
        var stops = await dbService.GetStopsWithRoutes(routeType);

        // Assert
        Assert.NotNull(stops);
        if (stops.Count > 0)
        {
            Assert.All(stops, stop =>
            {
                Assert.NotEqual(0, stop.StopId);
                Assert.NotNull(stop.StopName);
            });
        }
    }

    [Theory]
    [InlineData(0, true)]  // Trains with geopaths
    [InlineData(0, false)] // Trains without geopaths
    [InlineData(1, true)]  // Trams with geopaths
    public async Task GetRoutes_ByRouteType_ReturnsRoutes(int routeType, bool includeGeopaths)
    {
        // Arrange
        var dbService = new DatabaseService(_configuration);

        // Act
        var routes = await dbService.GetRoutes(routeType, includeGeopaths);

        // Assert
        Assert.NotNull(routes);
        Assert.NotEmpty(routes);
        Assert.All(routes, route =>
        {
            Assert.NotNull(route.RouteName);
            Assert.Equal(routeType, route.RouteType);
        });
    }

    [Fact]
    public async Task GetRoutesWithExpandedPatterns_Train_ReturnsExpandedPatterns()
    {
        // Arrange
        var dbService = new DatabaseService(_configuration);
        int trainRouteType = 0;

        // Act
        var routes = await dbService.GetRoutesWithExpandedPatterns(trainRouteType);

        // Assert
        Assert.NotNull(routes);
        Assert.NotEmpty(routes);
    }

    [Fact]
    public async Task GetDisruptions_NoFilter_ReturnsDisruptions()
    {
        // Arrange
        var dbService = new DatabaseService(_configuration);

        // Act
        var disruptions = await dbService.GetDisruptions();

        // Assert
        Assert.NotNull(disruptions);
    }

    [Theory]
    [InlineData(0)] // Train disruptions
    [InlineData(1)] // Tram disruptions
    public async Task GetDisruptions_FilteredByRouteType_ReturnsFilteredDisruptions(int routeType)
    {
        // Arrange
        var dbService = new DatabaseService(_configuration);

        // Act
        var disruptions = await dbService.GetDisruptions(routeType);

        // Assert
        Assert.NotNull(disruptions);
        if (disruptions.Count > 0)
        {
            Assert.All(disruptions, disruption =>
            {
                Assert.Equal(routeType, disruption.RouteType);
            });
        }
    }

    [Fact]
    public async Task PlanTripDijkstra_ValidStops_ReturnsJourneyOptions()
    {
        // Arrange
        var dbService = new DatabaseService(_configuration);
        int originStopId = 1071; // Flinders Street Station
        int destinationStopId = 1181; // Southern Cross Station
        int k = 3;

        // Act
        var (trips, journeys) = await dbService.PlanTripDijkstra(originStopId, destinationStopId, k);

        // Assert
        Assert.NotNull(trips);
        Assert.NotNull(journeys);

        if (trips.Count > 0)
        {
            Assert.InRange(journeys.Count, 1, k);
            foreach (var journey in journeys)
            {
                Assert.NotEmpty(journey);
                Assert.Equal(originStopId, journey.First().OriginStopId);
                Assert.Equal(destinationStopId, journey.Last().DestinationStopId);
            }
        }
    }

    [Fact]
    public async Task GetRouteWithGeopath_ValidId_ReturnsRoute()
    {
        // Arrange
        var dbService = new DatabaseService(_configuration);
        int routeId = 14; // Sunbury line

        // Act
        var routeResponse = await dbService.GetRouteWithGeopath(routeId);

        // Assert
        if (routeResponse != null)
        {
            Assert.NotNull(routeResponse.Route);
            Assert.Equal(routeId, routeResponse.Route.RouteId);
            Assert.NotNull(routeResponse.Route.RouteName);
        }
    }
}
