# Agent Team Setup Guide

This guide explains how to use the specialized agent files to work on different parts of the PTV Tracker project.

## Agent Team Structure

The project has **four specialized agents**, each with their own expertise:

```
tracker-project/
├── CLAUDE.md                    # Main project coordinator
├── FRONTEND-AGENT.md            # Frontend specialist (React, Leaflet, UI)
├── BACKEND-AGENT.md             # Backend specialist (ASP.NET Core, APIs)
├── TESTING-AGENT.md             # Testing specialist (xUnit, Vitest)
└── DATABASE-AGENT.md            # Database specialist (PostgreSQL, GTFS)
```

## How to Use Agent Files

### Method 1: Reference Agent Files in Prompts (Recommended)

When you need help with a specific domain, reference the appropriate agent file in your prompt:

**Frontend work**:
```
Using FRONTEND-AGENT.md, add a new map layer to show bike lanes
```

**Backend work**:
```
Using BACKEND-AGENT.md, create a new API endpoint for real-time arrivals
```

**Testing work**:
```
Using TESTING-AGENT.md, add tests for the new trip planning feature
```

**Database work**:
```
Using DATABASE-AGENT.md, optimize the edges_v2 table indexing
```

### Method 2: Open Agent File Before Asking

1. Open the relevant agent file (e.g., `FRONTEND-AGENT.md`)
2. Ask your question normally
3. Claude Code will use the file context automatically

### Method 3: Use as Reference Documentation

Read the agent files yourself to understand:
- Best practices for each domain
- Code patterns and conventions
- Common tasks and examples
- Troubleshooting guides

## Agent Specializations

### 📱 Frontend Agent (FRONTEND-AGENT.md)

**Expertise**:
- React component development
- Leaflet map integration
- UI/UX design with glassmorphism theme
- State management patterns
- API integration (fetch, error handling)
- Frontend testing with Vitest

**When to use**:
- Adding/modifying UI components
- Map visualization changes
- Trip planner interface updates
- Disruption display features
- Component testing
- Performance optimization

**Example prompts**:
- "Add a new filter button for night buses"
- "Create a component to show journey alternatives"
- "Fix the map not centering on selected route"
- "Add tests for the disruption panel"

---

### ⚙️ Backend Agent (BACKEND-AGENT.md)

**Expertise**:
- ASP.NET Core Web API development
- RESTful endpoint design
- Database queries with Npgsql
- Dijkstra's algorithm implementation
- PTV API integration
- Error handling and validation

**When to use**:
- Creating/modifying API endpoints
- Database query optimization
- Trip planning algorithm changes
- PTV API integration
- Backend testing
- Performance profiling

**Example prompts**:
- "Add endpoint to get real-time departures"
- "Optimize the trip planning query for better performance"
- "Add validation for stop IDs in endpoints"
- "Fix null reference error in GetGeopath"

---

### 🧪 Testing Agent (TESTING-AGENT.md)

**Expertise**:
- xUnit testing (backend)
- Vitest testing (frontend)
- Test-driven development (TDD)
- Integration testing
- Test coverage analysis
- Debugging failing tests

**When to use**:
- Writing new tests
- Fixing failing tests
- Improving test coverage
- Setting up CI/CD
- Performance testing
- Test refactoring

**Example prompts**:
- "Write tests for the new API endpoint"
- "Fix the failing trip planning test"
- "Add integration tests for the full journey flow"
- "Set up GitHub Actions for automated testing"

---

### 🗄️ Database Agent (DATABASE-AGENT.md)

**Expertise**:
- PostgreSQL schema design
- GTFS data processing
- Routing graph generation
- Query optimization
- Index management
- Data integrity

**When to use**:
- Schema changes or migrations
- GTFS data import/processing
- Edge graph regeneration
- Query performance issues
- Database maintenance
- Backup/restore operations

**Example prompts**:
- "Add a new table for favorite routes"
- "Regenerate edges for bus routes"
- "Optimize the stop lookup query"
- "Add indexes to improve trip planning performance"

## Coordinating Multiple Agents

### Scenario: Add a New Feature (e.g., "Favorite Routes")

**1. Database Agent** - Schema design:
```
Using DATABASE-AGENT.md, create a table to store user favorite routes
```

**2. Backend Agent** - API endpoints:
```
Using BACKEND-AGENT.md, add endpoints to save and retrieve favorite routes
```

**3. Frontend Agent** - UI implementation:
```
Using FRONTEND-AGENT.md, add a star button to routes to mark as favorite
```

**4. Testing Agent** - Test coverage:
```
Using TESTING-AGENT.md, add tests for the favorite routes feature
```

### Scenario: Fix a Bug (e.g., "Trip planner returns no results")

**1. Testing Agent** - Reproduce and document:
```
Using TESTING-AGENT.md, write a failing test that reproduces the bug
```

**2. Database Agent** - Check data integrity:
```
Using DATABASE-AGENT.md, verify edges exist for the problematic stops
```

**3. Backend Agent** - Fix algorithm:
```
Using BACKEND-AGENT.md, debug the PlanTripDijkstra method
```

**4. Testing Agent** - Verify fix:
```
Using TESTING-AGENT.md, ensure all tests pass including the new one
```

### Scenario: Performance Optimization

**1. Testing Agent** - Benchmark:
```
Using TESTING-AGENT.md, create performance tests for trip planning
```

**2. Database Agent** - Query optimization:
```
Using DATABASE-AGENT.md, analyze and optimize edge lookup queries
```

**3. Backend Agent** - Algorithm optimization:
```
Using BACKEND-AGENT.md, profile and optimize the Dijkstra implementation
```

**4. Frontend Agent** - UI feedback:
```
Using FRONTEND-AGENT.md, add loading indicators while trip planning
```

## Best Practices for Agent Teams

### 1. Start with the Main CLAUDE.md

Always read `CLAUDE.md` first for project overview and context. It provides:
- Overall architecture
- Key features and how they work
- Development commands
- Known issues and current state

### 2. Use the Right Agent for the Job

Don't ask the Frontend Agent about database schemas or the Database Agent about React components. Each agent is specialized for efficiency.

### 3. Cross-Reference When Needed

Some tasks require multiple agents. For example:
- Adding a new API endpoint: Backend + Database + Testing agents
- Changing route visualization: Frontend + Backend agents
- Data migration: Database + Testing agents

### 4. Agent Handoffs

When working across domains, use explicit handoffs:

```
# First
Using DATABASE-AGENT.md, create the schema for user preferences

# Then
Using BACKEND-AGENT.md, create API endpoints for the user preferences table created above

# Finally
Using FRONTEND-AGENT.md, create a settings panel to display user preferences
```

### 5. Document Agent Decisions

When agents make architectural decisions, document them:
- Update CLAUDE.md with new features
- Update agent-specific files with new patterns
- Keep TESTING.md updated with new test locations

## Quick Reference

### "I want to..."

**...add a new UI feature**
→ Use FRONTEND-AGENT.md

**...create a new API endpoint**
→ Use BACKEND-AGENT.md + DATABASE-AGENT.md (if database changes)

**...fix a failing test**
→ Use TESTING-AGENT.md + domain-specific agent

**...improve performance**
→ Use DATABASE-AGENT.md (queries) + BACKEND-AGENT.md (algorithms)

**...process new GTFS data**
→ Use DATABASE-AGENT.md

**...change the UI design**
→ Use FRONTEND-AGENT.md

**...debug an error**
→ Identify domain (frontend/backend/database) → Use that agent

**...deploy the application**
→ Use CLAUDE.md (deployment section) + FRONTEND-AGENT.md (frontend deployment)

## Advanced: Claude Code Agent Workflow

If you're using Claude Code CLI with agent features:

### Single Agent Invocation

```bash
# In your prompt/message
@FRONTEND-AGENT.md help me add a dark mode toggle
```

### Multi-Agent Workflow

```bash
# Sequential agent calls
@DATABASE-AGENT.md add stops_favorites table
@BACKEND-AGENT.md add GET /favorites endpoint
@FRONTEND-AGENT.md add favorites panel to sidebar
@TESTING-AGENT.md add tests for favorites feature
```

### Agent as Expert Reviewer

```bash
# After making changes
@BACKEND-AGENT.md review my new API endpoint for best practices
@TESTING-AGENT.md verify test coverage for the new feature
```

## Maintaining Agent Files

### When to Update Agent Files

**After adding new features**:
- Update relevant agent file with new patterns
- Add examples to "Common Tasks"
- Update troubleshooting if new issues discovered

**After fixing bugs**:
- Add to troubleshooting section
- Document the fix for future reference

**After architectural changes**:
- Update all affected agent files
- Update CLAUDE.md if it affects multiple domains

### Agent File Structure

Each agent file follows this structure:
1. **Agent Role** - What the agent specializes in
2. **Tech Stack** - Technologies used
3. **Core Components** - Main files/structures
4. **Development Guidelines** - How to work in this domain
5. **Common Tasks** - Example implementations
6. **Troubleshooting** - Known issues and fixes
7. **Best Practices** - Domain-specific recommendations

## Tips for Effective Agent Use

1. **Be specific about the domain**: "Add a map layer" → Frontend. "Add an API endpoint" → Backend.

2. **Chain agents for complex tasks**: Database → Backend → Frontend → Testing

3. **Use agents for code review**: Ask an agent to review code in their domain

4. **Leverage agent expertise**: Agents know patterns, best practices, and common pitfalls

5. **Don't fight specialization**: If Frontend Agent doesn't know about PostgreSQL, switch to Database Agent

6. **Keep context**: Reference previous agent work when switching agents

7. **Update agents**: Keep agent files current with project evolution

## Example Conversations

### Adding a Feature (Favorite Stops)

**You**:
```
I want to add a feature where users can mark stops as favorites.
Let's start with the database schema.

Using DATABASE-AGENT.md, create a table for favorite stops.
```

**Claude** (as Database Agent):
```sql
CREATE TABLE favorite_stops (
    user_id INTEGER NOT NULL,
    stop_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, stop_id),
    FOREIGN KEY (stop_id) REFERENCES stops(stop_id)
);
```

**You**:
```
Great! Now using BACKEND-AGENT.md, add API endpoints to manage favorites.
```

**Claude** (as Backend Agent):
```csharp
[HttpGet("favorites/{userId}")]
public async Task<ActionResult<List<StopDto>>> GetFavorites(int userId)
{
    // Implementation...
}

[HttpPost("favorites/{userId}/{stopId}")]
public async Task<ActionResult> AddFavorite(int userId, int stopId)
{
    // Implementation...
}
```

**You**:
```
Perfect! Using FRONTEND-AGENT.md, add a star icon next to stops
to mark them as favorites.
```

---

### Debugging an Issue

**You**:
```
Trip planner is returning no results for some stops.
Using TESTING-AGENT.md, help me write a test that reproduces this.
```

**Claude** (as Testing Agent):
```csharp
[Fact]
public async Task PlanTrip_BetweenProblematicStops_ReturnsResults()
{
    var (trips, journeys) = await _dbService.PlanTripDijkstra(1104, 1181, 3);
    Assert.NotEmpty(journeys);
}
```

**You**:
```
Test fails as expected. Using DATABASE-AGENT.md, check if edges
exist for stop 1104.
```

**Claude** (as Database Agent):
```sql
SELECT COUNT(*) FROM edges_v2
WHERE (source / 1000000000)::int = 1104
   OR (target / 1000000000)::int = 1104;

-- Returns 0 - no edges found!
```

**You**:
```
Ah! Using DATABASE-AGENT.md, regenerate edges for the route that
includes stop 1104.
```

---

## Summary

**The agent team structure allows you to**:

✅ Get specialized help for each domain
✅ Follow best practices automatically
✅ Coordinate complex multi-domain tasks
✅ Maintain consistency across the codebase
✅ Onboard new developers faster
✅ Document domain knowledge effectively

**Remember**: You're the project manager. The agents are domain experts. Direct them to the right tasks, and they'll guide you with specialized knowledge.

## Need Help?

- **Not sure which agent to use?** Start with CLAUDE.md for project context
- **Task spans multiple domains?** Chain agents in logical order
- **Agent doesn't have the answer?** The agent file might need updating
- **Want to add a new agent?** Follow the existing agent file structure

---

**Pro Tip**: Keep all agent files open in your editor tabs for quick reference!
