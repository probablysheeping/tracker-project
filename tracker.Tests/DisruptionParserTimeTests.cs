using Xunit;
using PTVApp.Services;
using PTVApp.Models;
using System.Security.Cryptography.X509Certificates;
using System.Diagnostics.Contracts;

namespace tracker.Tests;
public class DisruptionTimeParserTests
{
    [Fact]
    public void ParseDisruptionTime_WithFullDateFormat_DotSeparator_ReturnsCorrectDateTime()
    {
        // Arrange
        var timeStr = "10.30pm Saturday 20 December";

        // Act
        var result = DisruptionParser.ParseDisruptionTime(timeStr);

        // Assert
        Assert.NotNull(result);
        Assert.NotNull(result.Time);
        Assert.NotNull(result.Date);
        Assert.Equal(22, result.Time.Value.Hour);
        Assert.Equal(30, result.Time.Value.Minute);
        Assert.Equal(20, result.Date.Value.Day);
        Assert.Equal(12, result.Date.Value.Month);
        Assert.Equal(DateTime.Now.Year, result.Date.Value.Year);
    }

    [Fact]
    public void ParseDisruptionTime_WithFullDateFormat_ColonSeparator_ReturnsCorrectDateTime()
    {
        // Arrange
        var timeStr = "10:30pm Saturday 20 December";

        // Act
        var result = DisruptionParser.ParseDisruptionTime(timeStr);

        // Assert
        Assert.NotNull(result);
        Assert.NotNull(result.Time);
        Assert.NotNull(result.Date);
        Assert.Equal(22, result.Time.Value.Hour);
        Assert.Equal(30, result.Time.Value.Minute);
        Assert.Equal(20, result.Date.Value.Day);
        Assert.Equal(12, result.Date.Value.Month);
    }

    [Fact]
    public void ParseDisruptionTime_TimeOnly_DotSeparator_ReturnsCorrectTime()
    {
        // Arrange
        var timeStr = "10.30pm";

        // Act
        var result = DisruptionParser.ParseDisruptionTime(timeStr);

        // Assert
        Assert.NotNull(result);
        Assert.NotNull(result.Time);
        Assert.Null(result.Date); // Time only, no date
        Assert.Equal(22, result.Time.Value.Hour);
        Assert.Equal(30, result.Time.Value.Minute);
    }

    [Fact]
    public void ParseDisruptionTime_TimeOnly_ColonSeparator_ReturnsCorrectTime()
    {
        // Arrange
        var timeStr = "10:30pm";

        // Act
        var result = DisruptionParser.ParseDisruptionTime(timeStr);

        // Assert
        Assert.NotNull(result);
        Assert.NotNull(result.Time);
        Assert.Null(result.Date); // Time only, no date
        Assert.Equal(22, result.Time.Value.Hour);
        Assert.Equal(30, result.Time.Value.Minute);
    }

    [Fact]
    public void ParseDisruptionTime_AMTime_ReturnsCorrectHour()
    {
        // Arrange
        var timeStr = "6:00am";

        // Act
        var result = DisruptionParser.ParseDisruptionTime(timeStr);

        // Assert
        Assert.NotNull(result);
        Assert.NotNull(result.Time);
        Assert.Equal(6, result.Time.Value.Hour);
        Assert.Equal(0, result.Time.Value.Minute);
    }

    [Fact]
    public void ParseDisruptionTime_Midnight_ReturnsCorrectHour()
    {
        // Arrange
        var timeStr = "12:00am";

        // Act
        var result = DisruptionParser.ParseDisruptionTime(timeStr);

        // Assert
        Assert.NotNull(result);
        Assert.NotNull(result.Time);
        Assert.Equal(0, result.Time.Value.Hour);
        Assert.Equal(0, result.Time.Value.Minute);
    }

    [Fact]
    public void ParseDisruptionTime_Noon_ReturnsCorrectHour()
    {
        // Arrange
        var timeStr = "12:00pm";

        // Act
        var result = DisruptionParser.ParseDisruptionTime(timeStr);

        // Assert
        Assert.NotNull(result);
        Assert.NotNull(result.Time);
        Assert.Equal(12, result.Time.Value.Hour);
        Assert.Equal(0, result.Time.Value.Minute);
    }

    [Fact]
    public void ParseDisruptionTime_InvalidFormat_ReturnsNull()
    {
        // Arrange
        var timeStr = "invalid time string";

        // Act
        var result = DisruptionParser.ParseDisruptionTime(timeStr);

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public void ParseDisruptionTime_EmptyString_ReturnsNull()
    {
        // Arrange
        var timeStr = "";

        // Act
        var result = DisruptionParser.ParseDisruptionTime(timeStr);

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public void ParseDisruptionTime_SingleDigitHour_ReturnsCorrectTime()
    {
        // Arrange
        var timeStr = "6.30am";

        // Act
        var result = DisruptionParser.ParseDisruptionTime(timeStr);

        // Assert
        Assert.NotNull(result);
        Assert.NotNull(result.Time);
        Assert.Equal(6, result.Time.Value.Hour);
        Assert.Equal(30, result.Time.Value.Minute);
    }

    [Fact]
    public void ParseDisruptionTime_LastServiceEachNight_ReturnsIsLastService()
    {
        // Arrange
        var timeStr = "last service each night";

        // Act
        var result = DisruptionParser.ParseDisruptionTime(timeStr);

        // Assert
        Assert.NotNull(result);
        Assert.True(result.IsLastService);
        Assert.Null(result.Time);
        Assert.Null(result.Date);
    }

    [Fact]
    public void ParseTimeOnly_ValidTime_ReturnsTimeOnly()
    {
        // Arrange
        var timeStr = "11:45pm";

        // Act
        var result = DisruptionParser.ParseTimeOnly(timeStr);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(23, result.Value.Hour);
        Assert.Equal(45, result.Value.Minute);
    }

    [Fact]
    public void ParseDateOnly_ValidDate_ReturnsDateOnly()
    {
        // Arrange
        var dateStr = "Saturday 20 December";

        // Act
        var result = DisruptionParser.ParseDateOnly(dateStr);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(20, result.Value.Day);
        Assert.Equal(12, result.Value.Month);
        Assert.Equal(DateTime.Now.Year, result.Value.Year);
    }

    [Fact]
    public void DisruptionTime_ToDateTime_WithBothTimeAndDate_ReturnsFullDateTime()
    {
        // Arrange
        var disruptionTime = new DisruptionTime
        {
            Time = new TimeOnly(22, 30),
            Date = new DateOnly(2024, 12, 20)
        };

        // Act
        var result = disruptionTime.ToDateTime();

        // Assert
        Assert.NotNull(result);
        Assert.Equal(2024, result.Value.Year);
        Assert.Equal(12, result.Value.Month);
        Assert.Equal(20, result.Value.Day);
        Assert.Equal(22, result.Value.Hour);
        Assert.Equal(30, result.Value.Minute);
    }

    [Fact]
    public void DisruptionTime_ToDateTime_WithTimeOnly_UsesTodaysDate()
    {
        // Arrange
        var disruptionTime = new DisruptionTime
        {
            Time = new TimeOnly(14, 15)
        };

        // Act
        var result = disruptionTime.ToDateTime();

        // Assert
        Assert.NotNull(result);
        Assert.Equal(DateTime.Today.Year, result.Value.Year);
        Assert.Equal(DateTime.Today.Month, result.Value.Month);
        Assert.Equal(DateTime.Today.Day, result.Value.Day);
        Assert.Equal(14, result.Value.Hour);
        Assert.Equal(15, result.Value.Minute);
    }
}

