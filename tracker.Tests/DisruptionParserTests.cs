using Xunit;
using PTVApp.Services;
using PTVApp.Models;
using System.Diagnostics;

namespace tracker.Tests;

public class DisruptionParserTests
{
    // SAMPLE 2: Combined time + date format
    [Fact]
    public void ParseDisruptionDescription_CombinedTimeDate_ReturnsCorrectEvent()
    {
        // Arrange
        var description = "Buses replace trains between Newport and Werribee from 10.30pm Saturday 20 December to 6am Sunday 21 December, while we test the new X'Trapolis 2.0 trains.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("replacement_service", result.EventType);
        Assert.Equal(0, result.RouteType); // Train
        Assert.Equal("Newport", result.AffectedArea.StartLocation);
        Assert.Equal("Werribee", result.AffectedArea.EndLocation);
        Assert.Equal("segment", result.AffectedArea.Type);

        Assert.NotNull(result.Replacement);
        Assert.Equal("bus", result.Replacement.Mode);
        Assert.Equal(2, result.Replacement.RouteType); // Bus

        Assert.Single(result.Periods);
        Assert.NotNull(result.Periods[0].StartDateTime);
        Assert.Equal(22, result.Periods[0].StartDateTime.Value.Hour);
        Assert.Equal(30, result.Periods[0].StartDateTime.Value.Minute);
        Assert.Equal(20, result.Periods[0].StartDateTime.Value.Day);
        Assert.Equal(12, result.Periods[0].StartDateTime.Value.Month);

        Assert.NotNull(result.Periods[0].EndDateTime);
        Assert.Equal(6, result.Periods[0].EndDateTime.Value.Hour);
        Assert.Equal(21, result.Periods[0].EndDateTime.Value.Day);

        Assert.False(result.Periods[0].IsLastService);

    }

    // SAMPLE 1: Separated time and dates with "and"
    [Fact]
    public void ParseDisruptionDescription_SeparatedTimeDateWithAnd_ReturnsCorrectEvent()
    {
        // Arrange - "each night" with "and" creates separate periods for each night
        var description = "Buses replace trains between Newport and Werribee from 10.30pm to last service each night, Monday 22 December and Tuesday 23 December, while we test the new X'Trapolis 2.0 trains.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("replacement_service", result.EventType);
        Assert.Equal("Newport", result.AffectedArea.StartLocation);
        Assert.Equal("Werribee", result.AffectedArea.EndLocation);

        // "each night" with "and" creates 2 separate periods
        Assert.Equal(2, result.Periods.Count);

        // First night (Monday 22nd)
        Assert.NotNull(result.Periods[0].StartDateTime);
        Assert.Equal(22, result.Periods[0].StartDateTime.Value.Hour);
        Assert.Equal(30, result.Periods[0].StartDateTime.Value.Minute);
        Assert.Equal(22, result.Periods[0].StartDateTime.Value.Day);
        Assert.True(result.Periods[0].IsLastService);

        // Second night (Tuesday 23rd)
        Assert.NotNull(result.Periods[1].StartDateTime);
        Assert.Equal(22, result.Periods[1].StartDateTime.Value.Hour);
        Assert.Equal(30, result.Periods[1].StartDateTime.Value.Minute);
        Assert.Equal(23, result.Periods[1].StartDateTime.Value.Day);
        Assert.True(result.Periods[1].IsLastService);
    }

    // SAMPLE 3: Separated time and dates with "to" + "due to" reason
    [Fact]
    public void ParseDisruptionDescription_SeparatedTimeDateWithTo_ReturnsCorrectEvent()
    {
        // Arrange - "each night" with date range creates period for each night
        var description = "Buses replace trains between South Yarra and Moorabbin from 8:30pm to last service each night, Monday 8 December to Wednesday 10 December, due to maintenance works.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("replacement_service", result.EventType);
        Assert.Equal("South Yarra", result.AffectedArea.StartLocation);
        Assert.Equal("Moorabbin", result.AffectedArea.EndLocation);

        // "each night" with "to" date range creates 3 periods (Mon, Tue, Wed)
        Assert.Equal(3, result.Periods.Count);

        // All nights have same start time
        Assert.Equal(20, result.Periods[0].StartDateTime.Value.Hour);
        Assert.Equal(30, result.Periods[0].StartDateTime.Value.Minute);
        Assert.Equal(8, result.Periods[0].StartDateTime.Value.Day);
        Assert.Equal(9, result.Periods[1].StartDateTime.Value.Day);
        Assert.Equal(10, result.Periods[2].StartDateTime.Value.Day);

        // All are last service
        Assert.True(result.Periods[0].IsLastService);
        Assert.True(result.Periods[1].IsLastService);
        Assert.True(result.Periods[2].IsLastService);
    }

    [Fact]
    public void ParseDisruptionDescription_ColonTimeSeparator_ReturnsCorrectEvent()
    {
        // Arrange
        var description = "Buses replace trains between Caulfield and Frankston from 8:30pm to last service each night, Monday 1 December to Wednesday 3 December, due to maintenance works.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("Caulfield", result.AffectedArea.StartLocation);
        Assert.Equal("Frankston", result.AffectedArea.EndLocation);
        Assert.Equal(20, result.Periods[0].StartDateTime.Value.Hour);
        Assert.Equal(30, result.Periods[0].StartDateTime.Value.Minute);
    }

    [Fact]
    public void ParseDisruptionDescription_SpecificTimeToSpecificTime_NoLastService()
    {
        // Arrange
        var description = "Buses replace trains between Newport and Werribee from 10.30pm Friday 12 December to 5am Saturday 13 December, while we test the new X'Trapolis 2.0 trains.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);
        
        // Assert
        Assert.NotNull(result);
        Assert.NotNull(result.Periods[0].StartDateTime);
        Assert.NotNull(result.Periods[0].EndDateTime);
        Assert.Equal(22, result.Periods[0].StartDateTime.Value.Hour);
        Assert.Equal(5, result.Periods[0].EndDateTime.Value.Hour);
        Assert.False(result.Periods[0].IsLastService);
    }
    
    [Fact]
    public void ParseDisruptionDescription_MultipleStationNames_ParsedCorrectly()
    {
        // Arrange
        var description = "Buses replace trains between Caulfield, Cranbourne and East Pakenham from 8.30pm to last service each night, Monday 15 December to Thursday 18 December, due to Metro Tunnel Project works.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        // "Caulfield, Cranbourne" is treated as start location
        Assert.Equal("Caulfield, Cranbourne", result.AffectedArea.StartLocation);
        Assert.Equal("East Pakenham", result.AffectedArea.EndLocation);

    }

    [Fact]
    public void ParseDisruptionDescription_SingleDigitHourAM_ParsedCorrectly()
    {
        // Arrange - Single digit hour test
        var description = "Buses replace trains between Frankston and Stony Point from 11pm Friday 12 December to 5am Saturday 13 December, while we test the new trains.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("Frankston", result.AffectedArea.StartLocation);
        Assert.Equal("Stony Point", result.AffectedArea.EndLocation);

        // Combined date+time format - single period overnight
        Assert.Single(result.Periods);
        Assert.Equal(23, result.Periods[0].StartDateTime.Value.Hour); // 11pm
        Assert.Equal(12, result.Periods[0].StartDateTime.Value.Day);
        Assert.Equal(5, result.Periods[0].EndDateTime.Value.Hour); // 5am
        Assert.Equal(13, result.Periods[0].EndDateTime.Value.Day);
        Assert.False(result.Periods[0].IsLastService);
    }

    [Fact]
    public void ParseDisruptionDescription_NonBusReplacement_ReturnsNull()
    {
        // Arrange
        var description = "Due to a police incident, Route 604 towards Anzac Station is not servicing stops.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public void ParseDisruptionDescription_EmptyString_ReturnsNull()
    {
        // Arrange
        var description = "";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public void ParseDisruptionDescription_MalformedBusReplacement_ReturnsNull()
    {
        // Arrange (missing "from")
        var description = "Buses replace trains between Newport and Werribee 10.30pm to 6am.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public void ParseDisruptionDescription_VerifyJSONStructure_AllFieldsPresent()
    {
        // Arrange
        var description = "Buses replace trains between Newport and Werribee from 10.30pm Saturday 20 December to 6am Sunday 21 December, while we test the new X'Trapolis 2.0 trains.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert - Verify the structure is complete for JSON serialization
        Assert.NotNull(result);
        Assert.NotNull(result.EventType);
        Assert.NotNull(result.AffectedArea);
        Assert.NotNull(result.AffectedArea.Type);
        Assert.NotNull(result.Replacement);
        Assert.NotNull(result.Replacement.Mode);
        Assert.NotNull(result.Periods);
        Assert.NotEmpty(result.Periods);

        // Verify it serializes to JSON without errors
        var json = System.Text.Json.JsonSerializer.Serialize(result);
        Assert.NotNull(json);
        Assert.Contains("replacement_service", json);
        Assert.Contains("Newport", json);
        Assert.Contains("Werribee", json);
    }

    // =============== TRAM DISRUPTION TESTS ===============

    [Fact]
    public void ParseDisruptionDescription_TramRoute82Closure_ReturnsCorrectEvent()
    {
        // Arrange - Real disruption from database (ID 351443)
        var description = "Due to a car accident in Ascot Vale Road. No route 82 trams run between Stop 37 Union Road and Moonee Ponds. Passengers may consider Bus 472, 404 in Ascot Vale Road as an alternative.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("service_suspended", result.EventType);
        Assert.Equal(1, result.RouteType); // Tram
        Assert.Equal("82", result.RouteNumber);
        Assert.Equal("Stop 37 Union Road", result.AffectedArea.StartLocation);
        Assert.Equal("Moonee Ponds", result.AffectedArea.EndLocation);
        Assert.Equal("segment", result.AffectedArea.Type);
        Assert.Null(result.Replacement); // No replacement specified in this pattern
        Assert.Empty(result.Periods); // No specific time period - ongoing
    }

    [Fact]
    public void ParseDisruptionDescription_TramRouteWithPeriod_ReturnsCorrectEvent()
    {
        // Arrange
        var description = "No route 96 trams run between St Kilda Beach and Acland Street.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("service_suspended", result.EventType);
        Assert.Equal(1, result.RouteType);
        Assert.Equal("96", result.RouteNumber);
        Assert.Equal("St Kilda Beach", result.AffectedArea.StartLocation);
        Assert.Equal("Acland Street", result.AffectedArea.EndLocation);
    }

    [Fact]
    public void ParseDisruptionDescription_TramRouteGeneric_ReturnsCorrectEvent()
    {
        // Arrange
        var description = "Route 19 trams are delayed between Batman Avenue and Elizabeth Street, due to road works.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("service_disrupted", result.EventType);
        Assert.Equal(1, result.RouteType);
        Assert.Equal("19", result.RouteNumber);
        Assert.Equal("Batman Avenue", result.AffectedArea.StartLocation);
        Assert.Equal("Elizabeth Street", result.AffectedArea.EndLocation);
    }

    [Fact]
    public void ParseDisruptionDescription_NonTramText_DoesNotMatchTram()
    {
        // Arrange
        var description = "Due to heavy traffic, Route 605 services are experiencing delays.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.Null(result); // Should not match tram pattern
    }

    // =============== V/LINE DISRUPTION TESTS ===============

    [Fact]
    public void ParseDisruptionDescription_VLineCoachReplacement_ReturnsCorrectEvent()
    {
        // Arrange
        var description = "Coaches replace trains between Geelong and Melbourne from 9:00am to 5:00pm Saturday 25 December, due to track maintenance.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("replacement_service", result.EventType);
        Assert.Equal(3, result.RouteType); // V/Line
        Assert.Equal("Geelong", result.AffectedArea.StartLocation);
        Assert.Equal("Melbourne", result.AffectedArea.EndLocation);
        Assert.Equal("segment", result.AffectedArea.Type);

        Assert.NotNull(result.Replacement);
        Assert.Equal("coach", result.Replacement.Mode);
        Assert.Equal(2, result.Replacement.RouteType); // Bus/Coach

        // Note: Time period parsing for "9:00am to 5:00pm Saturday 25 December" format
        // needs improvement - currently not fully supported
        // TODO: Add support for this time format in ParseDisruptionTime
    }

    [Fact]
    public void ParseDisruptionDescription_VLineCoachReplacementNoDates_ReturnsCorrectEvent()
    {
        // Arrange
        var description = "Coaches replace trains between Ballarat and Wendouree.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("replacement_service", result.EventType);
        Assert.Equal(3, result.RouteType);
        Assert.Equal("Ballarat", result.AffectedArea.StartLocation);
        Assert.Equal("Wendouree", result.AffectedArea.EndLocation);
        Assert.Empty(result.Periods); // No time period specified
    }

    [Fact]
    public void ParseDisruptionDescription_VLineCoachDelay_ReturnsCorrectEvent()
    {
        // Arrange - Real disruption from database (ID 351660)
        var description = "The 1:30pm Lorne Hotel to Geelong scheduled coach is delayed 35 minutes due to road traffic congestion.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("delay", result.EventType);
        Assert.Equal(3, result.RouteType); // V/Line
        Assert.Equal("Lorne Hotel", result.AffectedArea.StartLocation);
        Assert.Equal("Geelong", result.AffectedArea.EndLocation);
        Assert.Equal("route", result.AffectedArea.Type);
        Assert.Equal(35, result.DelayMinutes);
        Assert.Empty(result.Periods); // Delays don't have periods
    }

    [Fact]
    public void ParseDisruptionDescription_VLineCoachDelayMajor_ReturnsCorrectEvent()
    {
        // Arrange - Real disruption from database (ID 351530)
        var description = "The 11:10am Geelong to Apollo Bay scheduled coach is delayed by 60 minutes due to a road accident between Wye River and Lorne.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("delay", result.EventType);
        Assert.Equal(3, result.RouteType);
        Assert.Equal("Geelong", result.AffectedArea.StartLocation);
        Assert.Equal("Apollo Bay", result.AffectedArea.EndLocation);
        Assert.Equal(60, result.DelayMinutes);
    }

    [Fact]
    public void ParseDisruptionDescription_VLineCoachDelayWithColon_ParsesTimeCorrectly()
    {
        // Arrange
        var description = "The 2:45pm Warrnambool to Melbourne scheduled coach is delayed 20 minutes due to mechanical issues.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("delay", result.EventType);
        Assert.Equal(3, result.RouteType);
        Assert.Equal("Warrnambool", result.AffectedArea.StartLocation);
        Assert.Equal("Melbourne", result.AffectedArea.EndLocation);
        Assert.Equal(20, result.DelayMinutes);
    }

    [Fact]
    public void ParseDisruptionDescription_VLineOvernight_ReturnsCorrectPeriods()
    {
        // Arrange - Overnight disruption spanning two days (no "each night" keyword)
        var description = "Coaches replace trains between Geelong and Melbourne from 6am Monday 8 December to 11pm Tuesday 9 December, due to track maintenance.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("replacement_service", result.EventType);
        Assert.Equal(3, result.RouteType);
        Assert.Equal("Geelong", result.AffectedArea.StartLocation);
        Assert.Equal("Melbourne", result.AffectedArea.EndLocation);

        // Should be single continuous period
        Assert.Single(result.Periods);
        Assert.NotNull(result.Periods[0].StartDateTime);
        Assert.NotNull(result.Periods[0].EndDateTime);
        Assert.Equal(6, result.Periods[0].StartDateTime.Value.Hour);
        Assert.Equal(8, result.Periods[0].StartDateTime.Value.Day);
        Assert.Equal(23, result.Periods[0].EndDateTime.Value.Hour);
        Assert.Equal(9, result.Periods[0].EndDateTime.Value.Day);
        Assert.False(result.Periods[0].IsLastService);
    }

    [Fact]
    public void ParseDisruptionDescription_VLineMultiNight_ReturnsMultiplePeriods()
    {
        // Arrange - Multiple nights "each night" with "and"
        var description = "Coaches replace trains between Ballarat and Melbourne from 9pm to last service each night, Monday 15 December and Tuesday 16 December, due to upgrade works.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("replacement_service", result.EventType);
        Assert.Equal(3, result.RouteType);

        // Should create 2 separate periods (one for each night)
        Assert.Equal(2, result.Periods.Count);

        // First night
        Assert.Equal(21, result.Periods[0].StartDateTime.Value.Hour); // 9pm
        Assert.Equal(15, result.Periods[0].StartDateTime.Value.Day);
        Assert.True(result.Periods[0].IsLastService);

        // Second night
        Assert.Equal(21, result.Periods[1].StartDateTime.Value.Hour);
        Assert.Equal(16, result.Periods[1].StartDateTime.Value.Day);
        Assert.True(result.Periods[1].IsLastService);
    }

    [Fact]
    public void ParseDisruptionDescription_VLineDateRange_ReturnsMultiplePeriods()
    {
        // Arrange - Date range "each night" with "to"
        var description = "Coaches replace trains between Bendigo and Melbourne from 8pm to last service each night, Wednesday 10 December to Friday 12 December, due to maintenance.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("replacement_service", result.EventType);
        Assert.Equal(3, result.RouteType);

        // Should create 3 periods (Wed, Thu, Fri)
        Assert.Equal(3, result.Periods.Count);

        Assert.Equal(10, result.Periods[0].StartDateTime.Value.Day);
        Assert.Equal(11, result.Periods[1].StartDateTime.Value.Day);
        Assert.Equal(12, result.Periods[2].StartDateTime.Value.Day);

        // All should be "last service"
        Assert.True(result.Periods[0].IsLastService);
        Assert.True(result.Periods[1].IsLastService);
        Assert.True(result.Periods[2].IsLastService);
    }

    [Fact]
    public void ParseDisruptionDescription_VLineContinuousPeriod_ReturnsSinglePeriod()
    {
        // Arrange - Continuous period across multiple days (no "each night")
        var description = "Coaches replace trains between Traralgon and Melbourne from 6am Monday 8 December to 11pm Wednesday 10 December, due to upgrade works.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("replacement_service", result.EventType);
        Assert.Equal(3, result.RouteType);

        // Should be single continuous period
        Assert.Single(result.Periods);
        Assert.Equal(6, result.Periods[0].StartDateTime.Value.Hour);
        Assert.Equal(8, result.Periods[0].StartDateTime.Value.Day);
        Assert.Equal(23, result.Periods[0].EndDateTime.Value.Hour);
        Assert.Equal(10, result.Periods[0].EndDateTime.Value.Day);
        Assert.False(result.Periods[0].IsLastService);
    }

    // =============== INTEGRATION TESTS ===============

    [Fact]
    public void ParseDisruptionDescription_AllModesJSON_SerializesCorrectly()
    {
        // Arrange
        var tramDesc = "No route 82 trams run between Stop 37 Union Road and Moonee Ponds.";
        var vlineDesc = "The 1:30pm Lorne Hotel to Geelong scheduled coach is delayed 35 minutes due to road traffic congestion.";
        var trainDesc = "Buses replace trains between Newport and Werribee from 10.30pm Saturday 20 December to 6am Sunday 21 December.";

        // Act
        var tramResult = DisruptionParser.ParseDisruptionDescription(tramDesc);
        var vlineResult = DisruptionParser.ParseDisruptionDescription(vlineDesc);
        var trainResult = DisruptionParser.ParseDisruptionDescription(trainDesc);

        // Assert - All should serialize to JSON
        Assert.NotNull(tramResult);
        Assert.NotNull(vlineResult);
        Assert.NotNull(trainResult);

        var tramJson = System.Text.Json.JsonSerializer.Serialize(tramResult);
        var vlineJson = System.Text.Json.JsonSerializer.Serialize(vlineResult);
        var trainJson = System.Text.Json.JsonSerializer.Serialize(trainResult);

        Assert.Contains("\"route_type\":1", tramJson); // Tram
        Assert.Contains("\"route_type\":3", vlineJson); // V/Line
        Assert.Contains("\"route_type\":0", trainJson); // Train

        Assert.Contains("service_suspended", tramJson);
        Assert.Contains("delay", vlineJson);
        Assert.Contains("replacement_service", trainJson);
    }

    [Fact]
    public void ParseDisruptionDescription_TramWithComma_ParsesCorrectly()
    {
        // Arrange
        var description = "No route 86 trams run between Waterfront City, Docklands and Bourke Street, due to road works.";

        // Act
        var result = DisruptionParser.ParseDisruptionDescription(description);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("86", result.RouteNumber);
        // Should handle comma in location name
        Assert.Equal("Waterfront City, Docklands", result.AffectedArea.StartLocation);
        Assert.Equal("Bourke Street", result.AffectedArea.EndLocation);
    }

}
