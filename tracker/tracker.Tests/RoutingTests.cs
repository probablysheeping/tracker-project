using Xunit;
using PTVApp.Services;
using PTVApp.Models;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace tracker.Tests;

/// <summary>
/// Integration tests for pgRouting trip planning.
/// These tests hit the real PostgreSQL database and verify that
/// specific known journeys return correct paths.
///
/// Stop IDs referenced:
///   1010 = Ashburton Station (Alamein line, train)
///   1071 = Flinders Street Station (train)
///   1120 = Melbourne Central Station (train)
///   1155 = Parliament Station (train)
///   1162 = Richmond Station (train)
///   1181 = Southern Cross Station (train)
///   1233 = Parkville Station (Metro Tunnel, train)
///   1234 = State Library Station (Metro Tunnel, train)
///   1235 = Town Hall Station (Metro Tunnel, train)
///   1360 = Melbourne Central Station/Elizabeth St #5 (tram, southbound)
///   1371 = Royal Melbourne Hospital tram stop (Melbourne direction)
///   1372 = Royal Melbourne Hospital tram stop (Parkville direction)
///   1375 = Melbourne Central Station/Elizabeth St #5 (tram, northbound)
/// </summary>
public class RoutingTests
{
    private readonly DatabaseService _db;

    public RoutingTests()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string> {
                { "api-key", "test-api-key" },
                { "user-id", "test-user-id" }
            }!)
            .Build();
        _db = new DatabaseService(config);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /// <summary>Returns all stop IDs visited across all legs of all journeys.</summary>
    private static IEnumerable<int> AllStops(List<List<Trip>> journeys) =>
        journeys.SelectMany(j => j.SelectMany(t => new[] { t.OriginStopId, t.DestinationStopId }));

    /// <summary>Returns the last destination stop ID across all journeys.</summary>
    private static List<int> FinalDestinations(List<List<Trip>> journeys) =>
        journeys.Select(j => j.Last().DestinationStopId).ToList();

    // -------------------------------------------------------------------------
    // Destination reachability: the final leg must end at the requested stop
    // -------------------------------------------------------------------------

    [Theory(DisplayName = "Journey last leg reaches requested destination")]
    [InlineData(1010, 1233, "Ashburton → Parkville Station (Metro Tunnel)")]
    [InlineData(1233, 1010, "Parkville Station → Ashburton")]
    [InlineData(1071, 1233, "Flinders St → Parkville Station")]
    [InlineData(1371, 1010, "RMH (Melbourne dir) → Ashburton")]
    [InlineData(1372, 1010, "RMH (Parkville dir) → Ashburton")]
    [InlineData(1071, 1181, "Flinders St → Southern Cross")]
    [InlineData(1181, 1071, "Southern Cross → Flinders St")]
    [InlineData(1010, 1071, "Ashburton → Flinders St")]
    [InlineData(1071, 1010, "Flinders St → Ashburton")]
    public async Task PlanTrip_ReachesDestination(int origin, int destination, string description)
    {
        var (_, journeys, _) = await _db.PlanTripDijkstra(origin, destination, k: 3);

        Assert.NotNull(journeys);
        Assert.NotEmpty(journeys);

        var finalStops = FinalDestinations(journeys!);
        Assert.True(
            finalStops.All(s => s == destination),
            $"[{description}] Expected all journeys to end at stop {destination}, " +
            $"but got: {string.Join(", ", finalStops)}"
        );
    }

    // -------------------------------------------------------------------------
    // Multi-modal journeys: tram + train
    // -------------------------------------------------------------------------

    [Fact(DisplayName = "RMH (Melbourne dir, 1371) → Ashburton: tram leg then train leg")]
    public async Task PlanTrip_RMHMelbDir_ToAshburton_HasTramThenTrain()
    {
        var (_, journeys, _) = await _db.PlanTripDijkstra(1371, 1010, k: 1);

        Assert.NotNull(journeys);
        Assert.NotEmpty(journeys);

        var best = journeys!.First();
        Assert.Equal(2, best.Count);

        // First leg is tram (route_type=1)
        Assert.Equal(1, best[0].RouteType);
        Assert.Equal(1371, best[0].OriginStopId);

        // Second leg is train (route_type=0) ending at Ashburton
        Assert.Equal(0, best[1].RouteType);
        Assert.Equal(1010, best[1].DestinationStopId);
    }

    [Fact(DisplayName = "RMH (Parkville dir, 1372) → Ashburton: tram leg then train leg")]
    public async Task PlanTrip_RMHParkvilleDir_ToAshburton_HasTramThenTrain()
    {
        var (_, journeys, _) = await _db.PlanTripDijkstra(1372, 1010, k: 1);

        Assert.NotNull(journeys);
        Assert.NotEmpty(journeys);

        var best = journeys!.First();
        Assert.Equal(2, best.Count);

        Assert.Equal(1, best[0].RouteType); // tram
        Assert.Equal(1372, best[0].OriginStopId);
        Assert.Equal(0, best[1].RouteType); // train
        Assert.Equal(1010, best[1].DestinationStopId);
    }

    // -------------------------------------------------------------------------
    // Metro Tunnel routing
    // -------------------------------------------------------------------------

    [Fact(DisplayName = "Flinders St → Parkville: uses Sunbury Metro Tunnel leg")]
    public async Task PlanTrip_FlindersStToParkville_UsesSunburyLine()
    {
        var (_, journeys, _) = await _db.PlanTripDijkstra(1071, 1233, k: 3);

        Assert.NotNull(journeys);
        Assert.NotEmpty(journeys);

        // At least one journey should use route_name containing "Sunbury"
        bool hasSunburyLeg = journeys!.Any(j =>
            j.Any(leg => leg.RouteName != null && leg.RouteName.Contains("Sunbury", StringComparison.OrdinalIgnoreCase))
        );
        Assert.True(hasSunburyLeg, "Expected at least one journey via the Sunbury/Metro Tunnel line");
    }

    [Fact(DisplayName = "Ashburton → Parkville: destination is Parkville, not Melbourne Central")]
    public async Task PlanTrip_AshburtonToParkville_DestinationIsParkville()
    {
        var (_, journeys, _) = await _db.PlanTripDijkstra(1010, 1233, k: 3);

        Assert.NotNull(journeys);
        Assert.NotEmpty(journeys);

        foreach (var journey in journeys!)
        {
            Assert.Equal(1233, journey.Last().DestinationStopId);
        }
    }

    // -------------------------------------------------------------------------
    // Simple same-line routes
    // -------------------------------------------------------------------------

    [Theory(DisplayName = "Direct train route returns exactly 1 leg")]
    [InlineData(1071, 1162, "Flinders St → Richmond")]
    [InlineData(1162, 1071, "Richmond → Flinders St")]
    [InlineData(1071, 1181, "Flinders St → Southern Cross")]
    public async Task PlanTrip_DirectTrain_ReturnsOneLeg(int origin, int destination, string description)
    {
        var (_, journeys, _) = await _db.PlanTripDijkstra(origin, destination, k: 1);

        Assert.NotNull(journeys);
        Assert.NotEmpty(journeys);

        Assert.Equal(1, journeys!.First().Count);
        _ = description; // used for display name
    }

    // -------------------------------------------------------------------------
    // Route name population
    // -------------------------------------------------------------------------

    [Fact(DisplayName = "All trip legs have route names populated")]
    public async Task PlanTrip_AnyRoute_AllLegsHaveRouteName()
    {
        var (_, journeys, _) = await _db.PlanTripDijkstra(1371, 1010, k: 3);

        Assert.NotNull(journeys);
        Assert.NotEmpty(journeys);

        foreach (var journey in journeys!)
        foreach (var leg in journey)
        {
            Assert.False(
                string.IsNullOrEmpty(leg.RouteName),
                $"Expected RouteName on leg {leg.OriginStopId}→{leg.DestinationStopId} (route_id={leg.RouteId})"
            );
        }
    }

    // -------------------------------------------------------------------------
    // k journeys: distinct alternatives
    // -------------------------------------------------------------------------

    [Fact(DisplayName = "k=3 returns at most 3 unique journeys")]
    public async Task PlanTrip_K3_ReturnsAtMost3UniqueJourneys()
    {
        var (_, journeys, _) = await _db.PlanTripDijkstra(1071, 1010, k: 3);

        Assert.NotNull(journeys);
        Assert.InRange(journeys!.Count, 1, 3);
    }

    [Fact(DisplayName = "Journeys are deduplicated - no identical route sequences")]
    public async Task PlanTrip_Journeys_NoDuplicateRouteSequences()
    {
        var (_, journeys, _) = await _db.PlanTripDijkstra(1372, 1010, k: 3);

        Assert.NotNull(journeys);

        var signatures = journeys!.Select(j =>
            string.Join("|", j.Select(t => $"{t.OriginStopId}-{t.RouteId}-{t.DestinationStopId}"))
        ).ToList();

        Assert.Equal(signatures.Count, signatures.Distinct().Count());
    }

    // -------------------------------------------------------------------------
    // Edge cases
    // -------------------------------------------------------------------------

    [Fact(DisplayName = "Same origin and destination returns empty result")]
    public async Task PlanTrip_SameStop_ReturnsEmpty()
    {
        var (trips, journeys, _) = await _db.PlanTripDijkstra(1010, 1010, k: 3);

        // Should return empty or null rather than crashing
        Assert.True(
            journeys == null || journeys.Count == 0,
            "Routing from a stop to itself should return no journeys"
        );
    }

    [Fact(DisplayName = "Invalid stop ID returns empty result gracefully")]
    public async Task PlanTrip_InvalidStop_ReturnsEmptyGracefully()
    {
        var (trips, journeys, _) = await _db.PlanTripDijkstra(99999, 1010, k: 3);

        Assert.True(
            journeys == null || journeys.Count == 0,
            "Invalid origin stop should return no journeys"
        );
    }
}
