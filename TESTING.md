# Testing Guide for PTV Tracker

This guide covers running and maintaining tests for both the backend (ASP.NET Core) and frontend (React/Vitest).

## Backend Tests (ASP.NET Core + xUnit)

### Location
All backend tests are in `tracker/tracker.Tests/`

### Test Files
- **DatabaseServiceTests.cs** - Tests for database operations, routing, and trip planning
- **PTVControllerTests.cs** - Tests for API endpoints and controller logic

### Running Backend Tests

**Run all tests:**
```bash
cd tracker/tracker.Tests
dotnet test
```

**Run with detailed output:**
```bash
dotnet test --logger "console;verbosity=detailed"
```

**Run specific test file:**
```bash
dotnet test --filter "FullyQualifiedName~DatabaseServiceTests"
dotnet test --filter "FullyQualifiedName~PTVControllerTests"
```

**Run specific test method:**
```bash
dotnet test --filter "FullyQualifiedName~GetRoutes_ByRouteType_ReturnsRoutes"
```

**Run tests with coverage (requires coverlet):**
```bash
dotnet test --collect:"XPlat Code Coverage"
```

### What's Tested (Backend)

#### DatabaseService Tests
- ✅ Route type retrieval
- ✅ Stop queries by route type
- ✅ Stops with route associations
- ✅ Route retrieval with/without geopaths
- ✅ Expanded route patterns (Metro Tunnel, City Loop)
- ✅ Disruption queries (all and filtered)
- ✅ Trip planning with Dijkstra's algorithm
- ✅ Multiple journey options (k-shortest paths)
- ✅ Geopath generation for trip segments
- ✅ Route lookup by ID (including expanded pattern IDs)

#### PTVController Tests
- ✅ GET /routes - all routes
- ✅ GET /routes?expandPatterns=true - expanded patterns
- ✅ GET /routes?route_types=0,1,3 - filtered by multiple types
- ✅ GET /routes/{routeType} - routes by type
- ✅ GET /stops?route_type=0&include_routes=true - stops with associations
- ✅ GET /route/{routeId} - single route with geopath
- ✅ GET /tripPlan/{origin}/{destination}?k=3 - journey planning
- ✅ GET /geopath/{routeId}/{origin}/{destination} - trip segment geopath
- ✅ GET /disruptions?route_type=0 - disruptions by type
- ✅ Configuration validation

### Updating Backend Tests

When you add new features:

1. **Add test method to appropriate test file:**
```csharp
[Fact]
public async Task YourNewFeature_WithValidInput_ReturnsExpectedResult()
{
    // Arrange
    var dbService = new DatabaseService(_configuration);
    var expectedValue = 42;

    // Act
    var result = await dbService.YourNewMethod(expectedValue);

    // Assert
    Assert.NotNull(result);
    Assert.Equal(expectedValue, result.SomeProperty);
}
```

2. **Use Theory for testing multiple scenarios:**
```csharp
[Theory]
[InlineData(0)] // Trains
[InlineData(1)] // Trams
[InlineData(2)] // Buses
public async Task TestMethod_WithDifferentInputs(int routeType)
{
    // Your test logic
}
```

3. **Run tests after changes:**
```bash
dotnet test
```

---

## Frontend Tests (React + Vitest)

### Location
All frontend tests are in `tracker-frontend/src/tests/`

### Test Files
- **App.test.jsx** - Component rendering and integration tests
- **utilities.test.js** - Utility function tests (rgbToCss, distance calculations, etc.)
- **api.test.js** - API integration tests

### Running Frontend Tests

**Run all tests:**
```bash
cd tracker-frontend
npm test
```

**Run tests once (CI mode):**
```bash
npm run test:run
```

**Run tests with UI (interactive):**
```bash
npm run test:ui
```

**Run specific test file:**
```bash
npm test App.test
```

**Run in watch mode (auto-rerun on changes):**
```bash
npm test -- --watch
```

**Run with coverage:**
```bash
npm test -- --coverage
```

### What's Tested (Frontend)

#### Component Tests (App.test.jsx)
- ✅ Map container renders without errors
- ✅ Routes are fetched on component mount
- ✅ API errors are handled gracefully

#### Utility Tests (utilities.test.js)
- ✅ RGB to CSS color conversion
- ✅ Distance calculation between coordinates
- ✅ Zoom-based radius calculation
- ✅ Disruption active status checking (date ranges and periods)

#### API Integration Tests (api.test.js)
- ✅ Routes API - fetch all routes
- ✅ Routes API - error handling
- ✅ Stops API - fetch stops by route type
- ✅ Stops API - coordinate validation
- ✅ Trip Planning API - single journey
- ✅ Trip Planning API - multiple journey options
- ✅ Trip Planning API - journey ordering by cost
- ✅ Disruptions API - all disruptions
- ✅ Disruptions API - filtered by route type
- ✅ Geopath API - GeoJSON format validation

### Updating Frontend Tests

When you add new features:

1. **Add test to appropriate file:**
```javascript
import { describe, it, expect } from 'vitest'

describe('Your Feature', () => {
  it('does what you expect', () => {
    const result = yourFunction(input)
    expect(result).toBe(expectedValue)
  })
})
```

2. **Test React components:**
```javascript
import { render, screen, waitFor } from '@testing-library/react'

it('renders your component', async () => {
  render(<YourComponent />)

  await waitFor(() => {
    expect(screen.getByText('Expected Text')).toBeInTheDocument()
  })
})
```

3. **Mock API calls:**
```javascript
beforeEach(() => {
  global.fetch = vi.fn()
})

it('fetches data', async () => {
  global.fetch.mockResolvedValueOnce({
    ok: true,
    json: async () => ({ data: 'test' })
  })

  // Your test logic
})
```

---

## Testing Workflow

### During Development

1. **Backend changes:**
   ```bash
   cd tracker/tracker.Tests
   dotnet test --logger "console;verbosity=detailed"
   ```

2. **Frontend changes:**
   ```bash
   cd tracker-frontend
   npm test -- --watch
   ```

### Before Committing

Run full test suite for both:

```bash
# Backend
cd tracker/tracker.Tests && dotnet test

# Frontend
cd tracker-frontend && npm run test:run
```

### Continuous Integration (Future)

Add to your CI/CD pipeline:

```yaml
# Example GitHub Actions
- name: Backend Tests
  run: |
    cd tracker/tracker.Tests
    dotnet test --logger "trx;LogFileName=test-results.trx"

- name: Frontend Tests
  run: |
    cd tracker-frontend
    npm run test:run
```

---

## Test Data

### Backend Test Configuration

Tests use in-memory configuration with mock API credentials:
```csharp
var inMemorySettings = new Dictionary<string, string> {
    {"api-key", "test-api-key"},
    {"user-id", "test-user-id"}
};
```

**Important:** Backend tests connect to your actual PostgreSQL database at `localhost:5432/tracker`. Ensure the database is running before testing.

### Known Test Stop IDs (for trip planning tests)
- **1071** - Flinders Street Station
- **1181** - Southern Cross Station
- **1104** - North Melbourne Station

### Known Route IDs
- **14** - Sunbury line (base route)
- **14000** - Sunbury Metro Tunnel pattern (expanded)
- **14001** - Sunbury City Loop pattern (expanded)

---

## Adding New Tests

### When to Add Tests

**Always add tests when:**
- Adding new API endpoints
- Adding new database queries
- Modifying trip planning logic
- Adding utility functions
- Changing data structures

**Good test coverage areas:**
- Core business logic (trip planning, routing)
- API endpoints (controllers)
- Data validation
- Error handling
- Edge cases (empty results, invalid inputs)

### Test Naming Conventions

**Backend (xUnit):**
```csharp
[Fact]
public async Task MethodName_Scenario_ExpectedBehavior()
// Example: GetRoutes_WithExpandPatterns_ReturnsExpandedRoutes
```

**Frontend (Vitest):**
```javascript
describe('Feature or Component', () => {
  it('does something specific', () => {
    // Test logic
  })
})
```

---

## Troubleshooting

### Backend Tests Fail

**Database connection errors:**
- Ensure PostgreSQL is running: `docker ps` or check services
- Verify database exists: `psql -U postgres -l`
- Check connection string in `database.cs:19`

**Configuration errors:**
- Tests require `api-key` and `user-id` in configuration
- These are set up in test constructors with mock values

### Frontend Tests Fail

**Module not found:**
```bash
npm install
```

**Leaflet errors:**
- Check `src/tests/setup.js` has Leaflet mocks
- Ensure `vitest.config.js` points to setup file

**API mock errors:**
- Verify `global.fetch = vi.fn()` in beforeEach
- Check mock return structure matches actual API

---

## Coverage Reports

### Backend Coverage (with coverlet)

Install coverlet:
```bash
cd tracker/tracker.Tests
dotnet add package coverlet.collector
```

Run with coverage:
```bash
dotnet test --collect:"XPlat Code Coverage"
```

View HTML report:
```bash
dotnet tool install -g dotnet-reportgenerator-globaltool
reportgenerator -reports:"**/coverage.cobertura.xml" -targetdir:"coverage-report"
```

### Frontend Coverage (with Vitest)

Run with coverage:
```bash
npm test -- --coverage
```

View in browser:
```bash
open coverage/index.html
```

---

## Test Suite Status

### Backend Tests (C# / xUnit)
✅ **All 34 tests passing**

- DatabaseService: 9 tests
- PTVController: 25 tests
- Total duration: ~72 seconds

### Frontend Tests (JavaScript / Vitest)
✅ **All 22 tests passing**

- Component tests: 3 tests
- Utility tests: 10 tests
- API integration tests: 9 tests
- Total duration: ~1.2 seconds

### Known Issues Fixed

1. **Null handling in database.cs** - Fixed `stop_suburb`, `stop_landmark`, and `route_ids` null value errors
2. **Geopath test failure** - Updated test to use valid stop IDs
3. **Frontend tooling** - Switched from `rolldown-vite` to regular `vite` to fix Windows compatibility issues
4. **Component rendering test** - Updated to check for actual rendered elements instead of non-existent `.map-container` class

### Total Coverage
- **56 tests** across both frontend and backend
- **100% passing** (56/56)

## Next Steps

1. **Add integration tests** - Test full request/response cycles with real database
2. **Add E2E tests** - Use Playwright/Cypress for full user flow testing
3. **Add performance tests** - Benchmark trip planning with large graphs
4. **Add load tests** - Test API under concurrent requests
5. **Set up CI/CD** - Automated testing on every commit

---

## Test Maintenance

**Regular updates:**
- Review and update tests when API contracts change
- Add tests for reported bugs before fixing
- Remove obsolete tests when features are deprecated
- Keep test data (stop IDs, route IDs) in sync with database

**Best practices:**
- Keep tests independent (no shared state)
- Use descriptive test names
- Test one thing per test method
- Mock external dependencies (PTV API, etc.)
- Clean up resources (database connections, etc.)
