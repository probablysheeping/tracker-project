# Frontend Agent Guide

This file provides specialized guidance for working on the React frontend of the PTV Tracker application.

## Agent Role

You are a frontend specialist focusing on:
- React component development and UI/UX
- Leaflet map integration and visualization
- API integration and state management
- Performance optimization and responsiveness
- Testing with Vitest and React Testing Library

## Tech Stack

- **Framework**: React 19.2.0 with functional components and hooks
- **Build Tool**: Vite 6.0.9 (NOT rolldown-vite due to Windows compatibility)
- **Mapping**: Leaflet 1.9.4 + react-leaflet 5.0.0
- **Testing**: Vitest 4.0.18 + @testing-library/react 16.3.2
- **Styling**: Inline styles with glassmorphism design system

## Design System

### Color Palette
```javascript
// Primary gradient (buttons, headers)
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%)

// Background gradient (sidebar)
background: linear-gradient(180deg, #1a1f35 0%, #0f1419 100%)

// Glassmorphism effect
background: rgba(255, 255, 255, 0.03)
backdrop-filter: blur(10px)
border: 1px solid rgba(255, 255, 255, 0.1)
```

### Severity Colors (Disruptions)
- Major delays: `#ff6b6b` (red)
- Minor delays: `#ffd93d` (yellow)
- Closure: `#ff4757` (dark red)
- Delay: `#ffa502` (orange)
- Default: `#6c5ce7` (purple)

### Route Type Colors
- Train (0): Uses route-specific colors from database
- Tram (1): Uses route-specific colors from database
- Bus (2): Uses route-specific colors from database
- V/Line (3): Uses route-specific colors from database

## Component Structure

### Main Component: `App.jsx`

**State Management**:
```javascript
// Map and display state
const [routes, setRoutes] = useState([])
const [stops, setStops] = useState([])
const [allStops, setAllStops] = useState([])
const [disruptions, setDisruptions] = useState([])
const [highlightedRoutes, setHighlightedRoutes] = useState([])
const [selectedRouteTypes, setSelectedRouteTypes] = useState([0, 1, 3]) // Train, Tram, V/Line

// Trip planning state
const [showTripPlanner, setShowTripPlanner] = useState(false)
const [originStop, setOriginStop] = useState(null)
const [destinationStop, setDestinationStop] = useState(null)
const [journeys, setJourneys] = useState([])
const [selectedJourneyIndex, setSelectedJourneyIndex] = useState(0)

// UI state
const [showDisruptions, setShowDisruptions] = useState(false)
const [expandedDisruptionId, setExpandedDisruptionId] = useState(null)
```

**Key Functions**:
- `loadData()` - Fetches routes and disruptions for selected route types
- `loadAllStops()` - Loads all stops (called once on mount)
- `handlePlanTrip()` - Executes trip planning API call
- `highlightJourneyRoute()` - Highlights a complete journey on the map
- `getRouteById()` - Handles both base and expanded pattern route IDs

### Map Features

**Route Visualization**:
- Polylines with route-specific colors
- Dashed lines for V/Line coach routes: `dashArray: "10, 8"`
- Dynamic line weights based on route type
- Click to highlight/unhighlight routes

**Stop Markers**:
- Circle markers with size based on route type:
  - Train stops: normal size (radius from `getRadius()`)
  - Tram stops: 50% smaller (`radius * 0.5`)
  - V/Line stops: 30% larger (`radius * 1.3`)
- Color-coded by route type
- Tooltips showing stop name and route associations

**Journey Visualization**:
- Highlights complete multi-leg journeys
- Different colors for each leg
- Shows all stops along the route
- Clears on journey selection change

## API Integration

### Configuration
All API calls use the centralized config from `src/config.js`:
```javascript
import { API_BASE_URL } from './config'
```

### Endpoints Used

**Routes**:
```javascript
GET ${API_BASE_URL}/api/PTV/routes?route_types=${types}&expandPatterns=true
Response: { routes: Route[] }
```

**Stops**:
```javascript
GET ${API_BASE_URL}/api/PTV/stops?route_type=${types}&include_routes=true
Response: Stop[]
```

**Trip Planning**:
```javascript
GET ${API_BASE_URL}/api/PTV/tripPlan/${origin}/${destination}?k=3
Response: { trips: Trip[], journeys: Trip[][] }
```

**Geopath**:
```javascript
GET ${API_BASE_URL}/api/PTV/geopath/${routeId}/${origin}/${destination}
Response: { geopath: GeoJSON }
```

**Disruptions**:
```javascript
GET ${API_BASE_URL}/api/PTV/disruptions?route_type=${type}
Response: Disruption[]
```

### Error Handling
Always wrap API calls in try-catch:
```javascript
try {
  const response = await fetch(url)
  const data = await response.json()
  // Handle data
} catch (error) {
  console.error('Failed to load data:', error)
  // Graceful degradation - don't crash the app
}
```

## Development Guidelines

### Adding New Features

1. **Component Structure**:
   - Keep `App.jsx` as the main container
   - Extract complex UI into separate components if needed
   - Use functional components with hooks

2. **State Updates**:
   - Always use setter functions from `useState`
   - Batch related state updates
   - Consider useCallback/useMemo for expensive operations

3. **Map Integration**:
   - Use react-leaflet components (MapContainer, TileLayer, Polyline, Circle, etc.)
   - Handle map events with `useMapEvents` hook
   - Clean up layers on unmount

4. **Styling**:
   - Use inline styles for consistency with existing code
   - Follow glassmorphism design patterns
   - Ensure dark theme compatibility
   - Add smooth transitions (0.2s-0.3s ease)

### Performance Considerations

**Map Rendering**:
- Limit visible stops based on zoom level (use `getRadius()`)
- Only render routes for selected route types
- Clear previous journey highlights before adding new ones

**API Calls**:
- Debounce search inputs
- Cache stop data (loaded once, reused for filtering)
- Use `k=3` for trip planning to limit results

**React Optimization**:
- Use `useMemo` for filtered/sorted lists
- Use `useCallback` for event handlers passed to children
- Avoid inline object creation in render

## Testing

### Test Structure
All tests in `src/tests/`:
- `App.test.jsx` - Component rendering and integration
- `utilities.test.js` - Utility functions
- `api.test.js` - API integration tests

### Writing Component Tests
```javascript
import { render, screen, waitFor } from '@testing-library/react'
import { describe, it, expect, beforeEach, vi } from 'vitest'

describe('Feature Name', () => {
  beforeEach(() => {
    global.fetch = vi.fn()
  })

  it('does something', async () => {
    // Mock API
    global.fetch.mockImplementation((url) => {
      if (url.includes('/routes')) {
        return Promise.resolve({
          ok: true,
          json: async () => ({ routes: [] })
        })
      }
      // ... other endpoints
    })

    const { container } = render(<Component />)

    await waitFor(() => {
      expect(screen.getByText(/Expected Text/i)).toBeInTheDocument()
    })
  })
})
```

### Run Tests
```bash
npm run test:run  # CI mode
npm test          # Watch mode
npm run test:ui   # Interactive UI
```

## Common Tasks

### Add a New Route Type Filter
1. Update `selectedRouteTypes` state
2. Add button to route type selector UI
3. Update `loadData()` to include new type
4. Add corresponding color scheme

### Add a New Map Layer
1. Import component from react-leaflet
2. Add to JSX inside `<MapContainer>`
3. Manage visibility with state
4. Add UI toggle in sidebar

### Modify Trip Planning UI
1. Update journey display logic in trip planner section
2. Adjust `highlightJourneyRoute()` for new visualization
3. Update journey tab styling
4. Test with various journey combinations

### Add a New Disruption Severity
1. Add color to severity color map
2. Update `getDisruptionColor()` utility
3. Test with mock disruption data

## Utility Functions

### Color Conversion
```javascript
const rgbToCss = (rgb) => {
  if (!rgb || rgb.length !== 3) return "black"
  return `rgb(${rgb[0]},${rgb[1]},${rgb[2]})`
}
```

### Distance Calculation
```javascript
const getDistance = (lat1, lng1, lat2, lng2) => {
  return Math.sqrt(Math.pow(lat1 - lat2, 2) + Math.pow(lng1 - lng2, 2))
}
```

### Dynamic Radius (Zoom-based)
```javascript
const getRadius = (zoomLevel) => {
  return Math.min(200, Math.max(5, 300 / Math.pow(2, zoomLevel - 11)))
}
```

### Disruption Status
```javascript
const isDisruptionActive = (disruption) => {
  const now = new Date()
  // Check date ranges or periods
  // Return true if active
}
```

## Troubleshooting

### Map Not Rendering
- Check Leaflet CSS is imported
- Verify MapContainer has height/width
- Ensure center and zoom are valid
- Check console for Leaflet errors

### API Calls Failing
- Verify backend is running on correct port
- Check `src/config.js` has correct API_BASE_URL
- Check CORS settings on backend
- Verify endpoint paths match backend

### Tests Failing
- Ensure Vite is regular version (not rolldown-vite)
- Check mock fetch responses match actual API structure
- Use `waitFor` for async operations
- Verify test setup in `src/tests/setup.js`

### Performance Issues
- Profile with React DevTools
- Check for unnecessary re-renders
- Limit map markers based on zoom
- Debounce expensive operations

## File Structure
```
tracker-frontend/
├── src/
│   ├── App.jsx              # Main component
│   ├── config.js            # API configuration
│   ├── main.jsx             # Entry point
│   ├── tests/               # Test files
│   │   ├── setup.js         # Test setup
│   │   ├── App.test.jsx     # Component tests
│   │   ├── utilities.test.js
│   │   └── api.test.js
│   └── assets/              # Static assets
├── public/                  # Public assets
├── .env.development         # Dev environment
├── .env.production          # Prod environment
├── vite.config.js           # Vite configuration
├── vitest.config.js         # Vitest configuration
└── package.json             # Dependencies
```

## Environment Variables

### Development (.env.development)
```
VITE_API_URL=http://localhost:5000
```

### Production (.env.production)
```
VITE_API_URL=https://your-backend-server.com
```

## Deployment

See `DEPLOYMENT.md` for full deployment guide.

### Quick Deploy to GitHub Pages
```bash
npm run build
# Commit and push to master branch
# GitHub Actions will auto-deploy
```

## Best Practices

1. **Always test with real API data** - Don't rely only on mocks
2. **Handle loading states** - Show feedback during API calls
3. **Graceful degradation** - App should work even if some APIs fail
4. **Mobile responsive** - Test on different screen sizes
5. **Accessibility** - Use semantic HTML and ARIA labels
6. **Performance** - Profile before optimizing
7. **Code style** - Follow existing patterns for consistency

## Need Help?

- Check main `CLAUDE.md` for project overview
- Review `TESTING.md` for test guidance
- See backend API docs in `tracker/README.md`
- Check React DevTools for component state
- Use browser DevTools Network tab for API debugging
