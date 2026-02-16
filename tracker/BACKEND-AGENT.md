# Backend Agent Guide

This file provides specialized guidance for working on the ASP.NET Core backend API of the PTV Tracker application.

## Agent Role

You are a backend specialist focusing on:
- ASP.NET Core 9.0 Web API development
- PostgreSQL database operations with Npgsql
- Trip planning algorithms (Dijkstra's k-shortest paths)
- PTV API integration and authentication
- RESTful API design and optimization

## Tech Stack

- **Framework**: ASP.NET Core 9.0
- **Database**: PostgreSQL with Npgsql 10.0.0
- **Authentication**: HMAC-SHA1 for PTV API
- **Documentation**: Swagger/OpenAPI
- **Testing**: xUnit 2.9.3

## Project Structure

```
tracker/
├── Program.cs              # Entry point, CORS, Swagger config
├── Controllers/
│   └── PTVControllers.cs   # API endpoints
├── Services/
│   ├── database.cs         # PostgreSQL operations
│   └── PTVClient.cs        # PTV API client
├── Models/
│   ├── Route.cs            # Route models
│   ├── Stop.cs             # Stop models
│   ├── TripModels.cs       # Trip planning models
│   └── Disruption.cs       # Disruption models
└── tracker.Tests/          # Unit tests
```

## Core Components

### 1. Program.cs - Application Configuration

**CORS Setup**:
```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});
```

**Service Registration**:
```csharp
builder.Services.AddSingleton<DatabaseService>()
builder.Services.AddSingleton<PTVClient>()
```

**Swagger Configuration**:
```csharp
builder.Services.AddEndpointsApiExplorer()
builder.Services.AddSwaggerGen()
```

### 2. Controllers/PTVControllers.cs - API Endpoints

**Constructor Pattern**:
```csharp
private readonly DatabaseService _dbService
private readonly PTVClient _ptvClient
private readonly string? _apiKey
private readonly string? _userId

public PTVController(IConfiguration configuration)
{
    _dbService = new DatabaseService(configuration)
    _ptvClient = new PTVClient(configuration)
    _apiKey = configuration["api-key"]
    _userId = configuration["user-id"]

    if (_apiKey == null || _userId == null)
        throw new Exception("ApiKey or UserID is null")
}
```

**Endpoint Patterns**:
```csharp
[HttpGet("endpoint")]
public async Task<ActionResult<ResponseType>> MethodName(parameters)
{
    try
    {
        var result = await _dbService.Method(parameters)
        return Ok(result)
    }
    catch (Exception ex)
    {
        return BadRequest(new { error = ex.Message })
    }
}
```

### 3. Services/database.cs - Database Operations

**Connection Management**:
```csharp
private readonly string _connectionString =
    "Host=localhost;Port=5432;Database=tracker;Username=postgres;Password=password"

await using var conn = new NpgsqlConnection(_connectionString)
await conn.OpenAsync()

// ... operations ...

await conn.CloseAsync()
```

**Query Execution Pattern**:
```csharp
await using var cmd = new NpgsqlCommand(query, conn)
cmd.Parameters.AddWithValue("param", value)

using var reader = await cmd.ExecuteReaderAsync()
while (await reader.ReadAsync())
{
    // Read data
}
```

**Null Handling**:
```csharp
Suburb = reader.IsDBNull(reader.GetOrdinal("stop_suburb"))
    ? string.Empty
    : reader.GetString(reader.GetOrdinal("stop_suburb"))

RouteIds = reader.IsDBNull(reader.GetOrdinal("route_ids"))
    ? Array.Empty<int>()
    : reader.GetFieldValue<int[]>(reader.GetOrdinal("route_ids"))
```

### 4. Services/PTVClient.cs - PTV API Integration

**HMAC-SHA1 Signature**:
```csharp
private string GenerateSignature(string uri)
{
    var encoding = new UTF8Encoding()
    var keyBytes = encoding.GetBytes(_apiKey)
    var uriBytes = encoding.GetBytes(uri)

    using var hmac = new HMACSHA1(keyBytes)
    var hash = hmac.ComputeHash(uriBytes)
    return BitConverter.ToString(hash).Replace("-", "").ToUpper()
}
```

**API Call Pattern**:
```csharp
public async Task<T> CallPTVAPI<T>(string endpoint)
{
    var uri = $"{endpoint}?devid={_userId}"
    var signature = GenerateSignature(uri)
    var fullUrl = $"{_baseUrl}{uri}&signature={signature}"

    var response = await _httpClient.GetAsync(fullUrl)
    response.EnsureSuccessStatusCode()

    return await response.Content.ReadFromJsonAsync<T>()
}
```

## API Endpoints

### Routes

**Get All Routes**:
```csharp
GET /api/PTV/routes
GET /api/PTV/routes?route_types=0,1,3
GET /api/PTV/routes?expandPatterns=true

Response: { routes: RouteSend[] }
```

**Get Routes by Type**:
```csharp
GET /api/PTV/routes/{routeType}
GET /api/PTV/routes/{routeType}?includeGeopaths=true
GET /api/PTV/routes/{routeType}?expandPatterns=true

Response: { routes: RouteSend[] }
```

**Get Single Route**:
```csharp
GET /api/PTV/route/{routeId}

Response: { route: RouteSend }
```

### Stops

**Get Stops**:
```csharp
GET /api/PTV/stops?route_type=0,1,3
GET /api/PTV/stops?route_type=0&include_routes=true

Response: StopDto[]
```

### Trip Planning

**Plan Trip**:
```csharp
GET /api/PTV/tripPlan/{originStopId}/{destinationStopId}
GET /api/PTV/tripPlan/{originStopId}/{destinationStopId}?k=3

Response: {
  trips: Trip[],
  journeys: Trip[][]
}
```

### Geopath

**Get Trip Geopath**:
```csharp
GET /api/PTV/geopath/{routeId}/{originStopId}/{destinationStopId}

Response: {
  geopath: string (GeoJSON)
}
```

### Disruptions

**Get Disruptions**:
```csharp
GET /api/PTV/disruptions
GET /api/PTV/disruptions?route_type=0

Response: Disruption[]
```

## Database Schema

### Key Tables

**routes**:
- `route_id` (int) - Primary key
- `route_name` (text)
- `route_number` (text)
- `route_type` (int) - 0=Train, 1=Tram, 2=Bus, 3=V/Line
- `route_gtfs_id` (text)
- `route_colour` (jsonb) - {RGB: [r, g, b]}
- `geopath` (jsonb) - GeoJSON LineString

**stops**:
- `stop_id` (int) - Primary key
- `stop_name` (text)
- `stop_latitude` (float)
- `stop_longitude` (float)
- `route_type` (int)
- `stop_suburb` (text, nullable)
- `stop_landmark` (text, nullable)
- `interchange` (int[], nullable)

**edges_v2** (Routing Graph):
- `route_id` (int) - Route identifier
- `source` (bigint) - Composite node ID: (stop_id × 1,000,000,000) + route_id
- `target` (bigint) - Composite node ID
- `cost` (float) - Travel time in minutes
- `distance_km` (float)
- `edge_type` (text) - 'route', 'hub', or 'transfer'

**stop_trip_sequence** (Geopath Mapping):
- `stop_id` (int)
- `gtfs_trip_id` (text)
- `shape_id` (text)
- `stop_sequence` (int)
- `shape_sequence` (int)

**disruptions**:
- `disruption_id` (bigint)
- `title` (text)
- `description` (text)
- `route_type` (int)
- `severity` (text)
- `from_date` (timestamp)
- `to_date` (timestamp)
- `routes` (jsonb) - Affected route IDs
- `stops` (jsonb) - Affected stop IDs

## Algorithms

### Dijkstra's k-Shortest Paths

**Implementation in `database.cs`**:
```csharp
public async Task<(List<Trip> trips, List<List<Trip>> journeys)>
    PlanTripDijkstra(int originStopId, int destinationStopId, int k = 3)
{
    // 1. Load graph edges from edges_v2
    // 2. Build adjacency list with route-aware nodes
    // 3. Run Dijkstra k times, removing paths after each iteration
    // 4. Reconstruct paths from predecessors
    // 5. Group trips by path_id into journeys
    // 6. Return both flat trips and grouped journeys
}
```

**Node ID Encoding**:
```csharp
long nodeId = (long)stopId * 1_000_000_000 + routeId
```

**Hub Nodes** (route_id = 0):
- Enable transfers between routes at the same station
- 2.5 minute transfer penalty
- Example: Node 1071000000000 (Flinders St, all routes)

**Route Edges**:
- Direct connections within a route
- Cost = actual travel time from GTFS
- Example: Node 1071000000014 → 1181000000014 (Flinders to Southern Cross on Route 14)

**Transfer Edges**:
- Cross-modal transfers based on proximity
- 200m threshold for tram transfers (4 min penalty)
- 500m threshold for train/V/Line transfers (3 min penalty)

### Geopath Generation

**Process**:
1. Look up stop in `stop_trip_sequence` to find shape_id and sequence
2. Query `shapes` table for points between start and end sequence
3. Convert to GeoJSON LineString
4. Handle recursive lookups for multi-segment trips

**Query Pattern**:
```sql
SELECT shape_pt_lat, shape_pt_lon, shape_pt_sequence
FROM shapes
WHERE shape_id = $1
  AND shape_pt_sequence >= $2
  AND shape_pt_sequence <= $3
ORDER BY shape_pt_sequence
```

### Route Pattern Expansion

**Metro Tunnel Detection**:
```csharp
public async Task<List<RouteSend>> GetRoutesWithExpandedPatterns(int routeType)
{
    // 1. Get base routes
    // 2. For each route, query distinct trip_headsigns from GTFS
    // 3. Detect patterns: "Metro Tunnel", "City Loop", "Express", "Standard"
    // 4. Create expanded route IDs: base_id * 1000 + pattern_index
    // 5. Append pattern name to route_name
    // 6. Return expanded route list
}
```

**Pattern ID Mapping**:
- Base route 14 (Sunbury) →
  - 14000: Sunbury (Metro Tunnel)
  - 14001: Sunbury (City Loop)
  - 14002: Sunbury (Express)
  - 14003: Sunbury (Standard)

## Development Guidelines

### Adding New Endpoints

1. **Define Model** in `Models/`:
```csharp
public class MyResponse
{
    public int Id { get; set; }
    public string Name { get; set; }
}
```

2. **Add Database Method** in `Services/database.cs`:
```csharp
public async Task<List<MyResponse>> GetMyData(int param)
{
    await using var conn = new NpgsqlConnection(_connectionString)
    await conn.OpenAsync()

    await using var cmd = new NpgsqlCommand(
        "SELECT id, name FROM my_table WHERE param = $1", conn)
    cmd.Parameters.AddWithValue(param)

    var results = new List<MyResponse>()
    using var reader = await cmd.ExecuteReaderAsync()

    while (await reader.ReadAsync())
    {
        results.Add(new MyResponse
        {
            Id = reader.GetInt32(0),
            Name = reader.GetString(1)
        })
    }

    await conn.CloseAsync()
    return results
}
```

3. **Add Controller Endpoint** in `Controllers/PTVControllers.cs`:
```csharp
[HttpGet("myendpoint/{param}")]
public async Task<ActionResult<List<MyResponse>>> GetMyEndpoint(int param)
{
    try
    {
        var result = await _dbService.GetMyData(param)
        return Ok(result)
    }
    catch (Exception ex)
    {
        return BadRequest(new { error = ex.Message })
    }
}
```

4. **Test** with Swagger UI or curl:
```bash
curl http://localhost:5000/api/PTV/myendpoint/123
```

### Database Queries

**Use Parameters** (prevent SQL injection):
```csharp
cmd.Parameters.AddWithValue("param", value)
```

**Handle Nullables**:
```csharp
Property = reader.IsDBNull(ordinal)
    ? defaultValue
    : reader.GetValue(ordinal)
```

**Use Transactions** for multi-step operations:
```csharp
await using var transaction = await conn.BeginTransactionAsync()
try
{
    // Multiple operations
    await transaction.CommitAsync()
}
catch
{
    await transaction.RollbackAsync()
    throw
}
```

### Error Handling

**Controller Level**:
```csharp
try
{
    var result = await _dbService.Method()
    return Ok(result)
}
catch (NpgsqlException ex)
{
    return StatusCode(500, new { error = "Database error", details = ex.Message })
}
catch (Exception ex)
{
    return BadRequest(new { error = ex.Message })
}
```

**Service Level**:
```csharp
public async Task<T> Method()
{
    if (invalidInput)
        throw new ArgumentException("Invalid input")

    try
    {
        // Database operations
    }
    catch (NpgsqlException ex)
    {
        throw new Exception($"Database error: {ex.Message}", ex)
    }
}
```

## Configuration

### User Secrets (Development)

**Set secrets**:
```bash
dotnet user-secrets init
dotnet user-secrets set "api-key" "your-ptv-api-key"
dotnet user-secrets set "user-id" "your-ptv-user-id"
```

**Access in code**:
```csharp
var apiKey = configuration["api-key"]
var userId = configuration["user-id"]
```

### Connection String

**Current (hardcoded)**:
```csharp
Host=localhost;Port=5432;Database=tracker;Username=postgres;Password=password
```

**Production (use configuration)**:
```csharp
var connectionString = configuration.GetConnectionString("TrackerDb")
```

In `appsettings.Production.json`:
```json
{
  "ConnectionStrings": {
    "TrackerDb": "Host=prod-server;Port=5432;Database=tracker;..."
  }
}
```

## Testing

### Test Structure
All tests in `tracker.Tests/`:
- `DatabaseServiceTests.cs` - Database operation tests
- `PTVControllerTests.cs` - API endpoint tests

### Writing Tests

**Database Tests**:
```csharp
[Fact]
public async Task Method_Scenario_ExpectedBehavior()
{
    // Arrange
    var dbService = new DatabaseService(_configuration)
    var expectedValue = 42

    // Act
    var result = await dbService.Method(input)

    // Assert
    Assert.NotNull(result)
    Assert.Equal(expectedValue, result.Property)
}
```

**Controller Tests**:
```csharp
[Theory]
[InlineData(0)]  // Train
[InlineData(1)]  // Tram
public async Task GetEndpoint_WithParameter_ReturnsData(int routeType)
{
    // Act
    var result = await _controller.GetEndpoint(routeType)

    // Assert
    var actionResult = Assert.IsType<OkObjectResult>(result.Result)
    var response = Assert.IsType<ResponseType>(actionResult.Value)
    Assert.NotEmpty(response.Data)
}
```

### Run Tests
```bash
cd tracker.Tests
dotnet test
dotnet test --logger "console;verbosity=detailed"
dotnet test --filter "FullyQualifiedName~MethodName"
```

## Performance Optimization

### Database Indexing

**Essential Indexes**:
```sql
CREATE INDEX idx_edges_source ON edges_v2(source)
CREATE INDEX idx_edges_target ON edges_v2(target)
CREATE INDEX idx_edges_route ON edges_v2(route_id)
CREATE INDEX idx_stops_route_type ON stops(route_type)
CREATE INDEX idx_disruptions_route_type ON disruptions(route_type)
```

### Query Optimization

**Use Specific Columns**:
```csharp
// Good
SELECT route_id, route_name FROM routes WHERE route_type = $1

// Avoid
SELECT * FROM routes WHERE route_type = $1
```

**Limit Results**:
```csharp
// Add LIMIT when appropriate
SELECT ... FROM table WHERE ... LIMIT 100
```

**Use Connection Pooling**:
```csharp
// Already enabled by default in Npgsql
// Can configure with MaxPoolSize in connection string
```

### Caching Strategies

**In-Memory Cache** (for static data):
```csharp
private static List<RouteType>? _cachedRouteTypes
private static DateTime _cacheExpiry

public async Task<List<RouteType>> GetRouteTypes()
{
    if (_cachedRouteTypes != null && DateTime.Now < _cacheExpiry)
        return _cachedRouteTypes

    _cachedRouteTypes = await LoadRouteTypesFromDb()
    _cacheExpiry = DateTime.Now.AddHours(1)

    return _cachedRouteTypes
}
```

## Common Tasks

### Add a New Route Type
1. Update database `route_types` table
2. Add to route type enum/constants
3. Update `GetRoutes()` filtering logic
4. Test with all endpoints

### Modify Trip Planning Algorithm
1. Update edge generation SQL (`edges.sql`)
2. Regenerate `edges_v2` table
3. Modify `PlanTripDijkstra()` in `database.cs`
4. Add tests for edge cases
5. Profile performance with large graphs

### Add New Disruption Field
1. Update `disruptions` table schema
2. Update `Disruption` model
3. Update `GetDisruptions()` query
4. Update serialization/deserialization

### Integrate New PTV API Endpoint
1. Add method to `PTVClient.cs`
2. Define response model in `Models/`
3. Add controller endpoint
4. Test signature generation
5. Handle rate limiting

## Troubleshooting

### Database Connection Errors
- Verify PostgreSQL is running: `pg_isready`
- Check connection string
- Ensure database exists: `psql -U postgres -l`
- Check firewall rules

### User Secrets Not Loading
- Verify secrets are set: `dotnet user-secrets list`
- Check `tracker.csproj` has `<UserSecretsId>`
- Ensure running in Development environment

### Trip Planning Returns No Results
- Verify edges exist in `edges_v2` for route types
- Check node ID encoding: `(stop_id × 1,000,000,000) + route_id`
- Ensure hub nodes exist (route_id = 0)
- Check stop IDs are valid

### Geopath Returns Null
- Verify stop exists in `stop_trip_sequence`
- Check `shapes` table has data for shape_id
- Ensure `queries.sql` has been run to populate mappings

## Best Practices

1. **Always use parameterized queries** - Prevent SQL injection
2. **Close connections** - Use `await using` for automatic disposal
3. **Handle nulls** - Check `IsDBNull()` before reading
4. **Log errors** - Use `ILogger` for production debugging
5. **Validate inputs** - Check parameters before database calls
6. **Use transactions** - For multi-step operations
7. **Test with real data** - Don't rely only on mocks
8. **Profile queries** - Use `EXPLAIN ANALYZE` in PostgreSQL
9. **Version control** - Keep schema migrations in source control
10. **Document complex algorithms** - Add comments for Dijkstra, geopath generation

## Need Help?

- Check main `CLAUDE.md` for project overview
- Review `TESTING.md` for test guidance
- See database schema in `queries.sql` and `edges.sql`
- Use Swagger UI for API testing: http://localhost:5000/swagger
- Check PostgreSQL logs for query errors
- Profile with dotnet-trace for performance issues
