# Testing Agent Guide

This file provides specialized guidance for testing the PTV Tracker application across frontend and backend.

## Agent Role

You are a testing specialist focusing on:
- Writing comprehensive unit and integration tests
- Test-driven development (TDD) practices
- Debugging failing tests
- Improving test coverage
- Performance and load testing
- Continuous integration setup

## Test Stack

### Backend Testing
- **Framework**: xUnit 2.9.3
- **Mocking**: Moq 4.20.72
- **Integration**: Microsoft.AspNetCore.Mvc.Testing 9.0.0
- **Coverage**: coverlet.collector 6.0.4
- **Database**: Npgsql 10.0.0 (uses real database)

### Frontend Testing
- **Framework**: Vitest 4.0.18
- **UI Testing**: @testing-library/react 16.3.2
- **DOM Testing**: @testing-library/jest-dom 6.9.1
- **Environment**: jsdom 28.1.0
- **Spy/Mock**: Built-in Vitest spies

## Test Structure

### Backend Tests (`tracker/tracker.Tests/`)

```
tracker.Tests/
├── DatabaseServiceTests.cs      # Database operations (9 tests)
├── PTVControllerTests.cs        # API endpoints (25 tests)
└── tracker.Tests.csproj         # Test project configuration
```

### Frontend Tests (`tracker-frontend/src/tests/`)

```
tests/
├── setup.js                     # Test configuration
├── App.test.jsx                 # Component tests (3 tests)
├── utilities.test.js            # Utility functions (10 tests)
└── api.test.js                  # API integration (9 tests)
```

## Backend Testing

### Test Project Setup

**tracker.Tests.csproj**:
```xml
<PackageReference Include="xunit" Version="2.9.3" />
<PackageReference Include="xunit.runner.visualstudio" Version="3.1.4" />
<PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
<PackageReference Include="Moq" Version="4.20.72" />
<PackageReference Include="coverlet.collector" Version="6.0.4" />
<PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="9.0.0" />

<ProjectReference Include="..\tracker.csproj" />
```

### Test Class Structure

```csharp
using Xunit;
using PTVApp.Services;
using PTVApp.Models;
using Microsoft.Extensions.Configuration;

namespace tracker.Tests;

public class MyTests
{
    private readonly IConfiguration _configuration;

    public MyTests()
    {
        // Setup mock configuration
        var inMemorySettings = new Dictionary<string, string> {
            {"api-key", "test-api-key"},
            {"user-id", "test-user-id"}
        };

        _configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings!)
            .Build();
    }

    [Fact]
    public async Task Method_Scenario_ExpectedBehavior()
    {
        // Arrange
        var service = new DatabaseService(_configuration);

        // Act
        var result = await service.Method();

        // Assert
        Assert.NotNull(result);
    }
}
```

### Test Patterns

#### [Fact] - Single Test
```csharp
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
```

#### [Theory] - Parameterized Tests
```csharp
[Theory]
[InlineData(0)]  // Trains
[InlineData(1)]  // Trams
[InlineData(2)]  // Buses
public async Task GetStops_ValidRouteType_ReturnsStops(int routeType)
{
    // Arrange
    var dbService = new DatabaseService(_configuration);

    // Act
    var stops = await dbService.GetStops(routeType);

    // Assert
    Assert.NotNull(stops);
    Assert.All(stops, stop =>
    {
        Assert.Equal(routeType, stop.RouteType);
        Assert.InRange(stop.StopLatitude, -90, 90);
        Assert.InRange(stop.StopLongitude, -180, 180);
    });
}
```

#### Testing Controller Endpoints
```csharp
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
}
```

#### Testing Exceptions
```csharp
[Fact]
public void Constructor_MissingApiKey_ThrowsException()
{
    // Arrange
    var emptyConfig = new ConfigurationBuilder().Build();

    // Act & Assert
    var exception = Assert.Throws<Exception>(() => new PTVController(emptyConfig));
    Assert.Contains("ApiKey or UserID is null", exception.Message);
}
```

### Database Test Considerations

**Important**: Backend tests connect to the **real PostgreSQL database** at `localhost:5432/tracker`.

**Prerequisites**:
- PostgreSQL must be running
- Database `tracker` must exist
- Database must be populated with test data

**Known Test Data**:
```csharp
// Stops
int flindersStreet = 1071;
int southernCross = 1181;
int northMelbourne = 1104;

// Routes
int sunburyLine = 14;
int sunburyMetroTunnel = 14000;
int sunburyCityLoop = 14001;

// Route Types
int train = 0;
int tram = 1;
int bus = 2;
int vline = 3;
```

### Running Backend Tests

```bash
# All tests
cd tracker/tracker.Tests
dotnet test

# Detailed output
dotnet test --logger "console;verbosity=detailed"

# Specific test class
dotnet test --filter "FullyQualifiedName~DatabaseServiceTests"

# Specific test method
dotnet test --filter "FullyQualifiedName~GetRoutes_ByRouteType_ReturnsRoutes"

# With coverage
dotnet test --collect:"XPlat Code Coverage"
```

## Frontend Testing

### Test Setup (`src/tests/setup.js`)

```javascript
import '@testing-library/jest-dom'

// Mock Leaflet
global.L = {
  map: () => ({
    setView: () => {},
    on: () => {},
    off: () => {},
    remove: () => {},
  }),
  tileLayer: () => ({ addTo: () => {} }),
  icon: () => ({}),
  divIcon: () => ({}),
  polyline: () => ({ addTo: () => {}, remove: () => {} }),
  marker: () => ({ addTo: () => {}, remove: () => {} }),
}

// Mock fetch
global.fetch = vi.fn()
```

### Test Patterns

#### Component Tests
```javascript
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import MapRoutes from '../App'

describe('MapRoutes Component', () => {
  beforeEach(() => {
    global.fetch = vi.fn()
  })

  it('renders the component successfully', async () => {
    // Mock API responses
    global.fetch.mockImplementation((url) => {
      if (url.includes('/routes')) {
        return Promise.resolve({
          ok: true,
          json: async () => ({ routes: [] })
        })
      }
      if (url.includes('/stops')) {
        return Promise.resolve({
          ok: true,
          json: async () => ([])
        })
      }
      return Promise.reject(new Error('Unknown endpoint'))
    })

    const { container } = render(<MapRoutes />)

    await waitFor(() => {
      expect(container.firstChild).toBeTruthy()
      expect(screen.getByText(/Melbourne PTV/i)).toBeInTheDocument()
    })
  })
})
```

#### Utility Function Tests
```javascript
describe('rgbToCss', () => {
  it('converts RGB array to CSS string', () => {
    expect(rgbToCss([255, 0, 0])).toBe('rgb(255,0,0)')
  })

  it('returns black for invalid input', () => {
    expect(rgbToCss(null)).toBe('black')
    expect(rgbToCss([255, 0])).toBe('black')
  })
})
```

#### API Integration Tests
```javascript
describe('Routes API', () => {
  beforeEach(() => {
    global.fetch = vi.fn()
  })

  it('fetches all routes', async () => {
    const mockRoutes = [
      { route_id: 1, route_name: 'Sunbury', route_type: 0 }
    ]

    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ routes: mockRoutes })
    })

    const response = await fetch(`${API_BASE_URL}/routes`)
    const data = await response.json()

    expect(data.routes).toHaveLength(1)
    expect(data.routes[0].route_name).toBe('Sunbury')
  })

  it('handles errors gracefully', async () => {
    global.fetch.mockRejectedValueOnce(new Error('Network error'))

    try {
      await fetch(`${API_BASE_URL}/routes`)
      expect.fail('Should have thrown an error')
    } catch (error) {
      expect(error.message).toBe('Network error')
    }
  })
})
```

### Running Frontend Tests

```bash
cd tracker-frontend

# Watch mode (default)
npm test

# Run once (CI mode)
npm run test:run

# Interactive UI
npm run test:ui

# With coverage
npm test -- --coverage

# Specific file
npm test App.test
```

## Test Coverage

### Backend Coverage

**Current Coverage**:
- DatabaseService: 9/9 methods tested (100%)
- PTVController: 12/12 endpoints tested (100%)

**Generate Coverage Report**:
```bash
cd tracker/tracker.Tests
dotnet test --collect:"XPlat Code Coverage"

# Install report generator
dotnet tool install -g dotnet-reportgenerator-globaltool

# Generate HTML report
reportgenerator -reports:"**/coverage.cobertura.xml" -targetdir:"coverage-report"

# Open report
start coverage-report/index.html
```

### Frontend Coverage

**Current Coverage**:
- Component tests: 3 tests (rendering, data loading, error handling)
- Utility tests: 10 tests (all utility functions)
- API integration: 9 tests (all endpoints)

**Generate Coverage Report**:
```bash
cd tracker-frontend
npm test -- --coverage

# Open report
open coverage/index.html
```

## Writing New Tests

### When to Add Tests

**Always test**:
- New API endpoints
- New database queries
- New utility functions
- Bug fixes (write test first)
- Modified business logic
- Data transformations

**Consider testing**:
- Edge cases (empty lists, null values)
- Error handling paths
- Validation logic
- Complex algorithms (Dijkstra, geopath)

### Test Naming Convention

**Backend (C#)**:
```
MethodName_Scenario_ExpectedBehavior

Examples:
- GetRoutes_WithExpandPatterns_ReturnsExpandedRoutes
- GetStops_InvalidRouteType_ThrowsException
- PlanTripDijkstra_ValidStops_ReturnsJourneyOptions
```

**Frontend (JavaScript)**:
```
describe('Feature or Component')
  it('does something specific')

Examples:
- describe('rgbToCss')
    it('converts RGB array to CSS string')
- describe('Routes API')
    it('fetches all routes')
```

### Test-Driven Development (TDD)

**Red-Green-Refactor**:

1. **Red** - Write failing test:
```csharp
[Fact]
public async Task GetNewFeature_ReturnsData()
{
    var result = await _dbService.GetNewFeature();
    Assert.NotEmpty(result);
}
```

2. **Green** - Implement minimum code to pass:
```csharp
public async Task<List<Data>> GetNewFeature()
{
    return new List<Data> { new Data() };
}
```

3. **Refactor** - Improve implementation:
```csharp
public async Task<List<Data>> GetNewFeature()
{
    await using var conn = new NpgsqlConnection(_connectionString);
    // Actual implementation
}
```

## Common Testing Scenarios

### Testing Trip Planning

```csharp
[Fact]
public async Task PlanTripDijkstra_ValidStops_ReturnsJourneyOptions()
{
    // Arrange
    var dbService = new DatabaseService(_configuration);
    int originStopId = 1071; // Flinders Street
    int destinationStopId = 1181; // Southern Cross
    int k = 3;

    // Act
    var (trips, journeys) = await dbService.PlanTripDijkstra(
        originStopId, destinationStopId, k);

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
```

### Testing API Responses

```csharp
[Theory]
[InlineData("0")]     // Trains only
[InlineData("1")]     // Trams only
[InlineData("0,1")]   // Trains and Trams
public async Task GetRoutes_WithRouteTypeFilter_ReturnsFilteredRoutes(
    string routeTypes)
{
    // Act
    var result = await _controller.GetRoutes(route_types: routeTypes);

    // Assert
    var response = result.Value;
    Assert.NotNull(response);
    Assert.NotEmpty(response.Routes);

    var expectedTypes = routeTypes.Split(',').Select(int.Parse).ToList();
    Assert.All(response.Routes, route =>
    {
        Assert.Contains(route.RouteType, expectedTypes);
    });
}
```

### Testing Error Handling

```javascript
it('handles API errors gracefully', async () => {
  global.fetch.mockImplementation((url) => {
    if (url.includes('/routes')) {
      return Promise.resolve({
        ok: true,
        json: async () => ({ routes: [] })
      })
    }
    // Other endpoints fail
    return Promise.reject(new Error('API Error'))
  })

  render(<MapRoutes />)

  // Component should still render even if some APIs fail
  await waitFor(() => {
    expect(global.fetch).toHaveBeenCalled()
  }, { timeout: 3000 })
})
```

## Debugging Tests

### Backend Test Debugging

**Visual Studio / VS Code**:
1. Set breakpoint in test method
2. Right-click test → Debug Test
3. Step through code

**Command Line**:
```bash
# Enable detailed logging
dotnet test --logger "console;verbosity=detailed"

# Run single test for focused debugging
dotnet test --filter "FullyQualifiedName~SpecificTestName"
```

### Frontend Test Debugging

**With Vitest UI**:
```bash
npm run test:ui
# Opens browser with interactive test runner
```

**With Console Logs**:
```javascript
it('debugs something', () => {
  const result = myFunction()
  console.log('Result:', result)
  expect(result).toBe(expected)
})
```

**With VS Code**:
1. Add launch configuration for Vitest
2. Set breakpoints in test files
3. Debug test

## Performance Testing

### Backend Performance

**Benchmark Trip Planning**:
```csharp
[Fact]
public async Task PlanTripDijkstra_PerformanceTest()
{
    var dbService = new DatabaseService(_configuration);
    var stopwatch = System.Diagnostics.Stopwatch.StartNew();

    var (trips, journeys) = await dbService.PlanTripDijkstra(1071, 1181, 3);

    stopwatch.Stop();
    Assert.True(stopwatch.ElapsedMilliseconds < 5000,
        $"Trip planning took {stopwatch.ElapsedMilliseconds}ms (expected < 5000ms)");
}
```

### Frontend Performance

**Measure Render Time**:
```javascript
it('renders quickly', async () => {
  const startTime = performance.now()

  render(<MapRoutes />)

  await waitFor(() => {
    expect(screen.getByText(/Melbourne PTV/i)).toBeInTheDocument()
  })

  const renderTime = performance.now() - startTime
  expect(renderTime).toBeLessThan(1000) // Under 1 second
})
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:latest
        env:
          POSTGRES_PASSWORD: password
          POSTGRES_DB: tracker
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v3

      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '9.0.x'

      - name: Restore dependencies
        run: dotnet restore
        working-directory: ./tracker

      - name: Run tests
        run: dotnet test --logger "trx;LogFileName=test-results.trx"
        working-directory: ./tracker/tracker.Tests

  frontend-tests:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm install
        working-directory: ./tracker-frontend

      - name: Run tests
        run: npm run test:run
        working-directory: ./tracker-frontend
```

## Troubleshooting

### Backend Tests Failing

**"Database connection error"**:
- Ensure PostgreSQL is running
- Check connection string in `database.cs`
- Verify database exists: `psql -U postgres -l`

**"Column is null" errors**:
- Check null handling in database reader
- Use `IsDBNull()` before reading values
- Provide default values for nullables

**"Stop has no corresponding shape_id"**:
- Use valid test stop IDs (1071, 1181)
- Verify `stop_trip_sequence` table is populated
- Run `queries.sql` to regenerate mappings

### Frontend Tests Failing

**"Module not found"**:
```bash
npm install
```

**"Leaflet errors"**:
- Check `setup.js` has Leaflet mocks
- Verify `vitest.config.js` points to setup file

**"Cannot read properties of undefined"**:
- Check API mock structure matches actual responses
- Ensure all endpoints are mocked
- Use proper mock implementation pattern

## Best Practices

1. **Test one thing per test** - Single assertion focus
2. **Use descriptive names** - Test name should explain what's being tested
3. **Arrange-Act-Assert** - Follow AAA pattern
4. **Independent tests** - No shared state between tests
5. **Fast tests** - Keep test execution under 2 minutes total
6. **Clean up** - Close connections, reset mocks
7. **Test edge cases** - Empty lists, null values, boundary conditions
8. **Mock external dependencies** - Don't call real PTV API in tests
9. **Maintain tests** - Update when APIs change
10. **Coverage ≠ Quality** - 100% coverage doesn't mean good tests

## Test Maintenance

**Regular Tasks**:
- Update tests when API contracts change
- Add tests for reported bugs
- Remove obsolete tests
- Keep test data in sync with database
- Update mocks to match real responses

**When Tests Break**:
1. Read the error message carefully
2. Check if database schema changed
3. Verify test data still exists
4. Check for API response format changes
5. Update mocks/fixtures if needed

## Need Help?

- Check main `CLAUDE.md` for project overview
- Review `TESTING.md` for detailed test documentation
- See backend tests in `tracker/tracker.Tests/`
- See frontend tests in `tracker-frontend/src/tests/`
- Run tests with verbose output for debugging
- Use test UI for interactive debugging
