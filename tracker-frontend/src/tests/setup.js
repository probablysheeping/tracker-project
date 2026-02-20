import '@testing-library/jest-dom'

// Mock Leaflet to avoid issues in tests
global.L = {
  map: () => ({
    setView: () => {},
    on: () => {},
    off: () => {},
    remove: () => {},
  }),
  tileLayer: () => ({
    addTo: () => {},
  }),
  icon: () => ({}),
  divIcon: () => ({}),
  polyline: () => ({
    addTo: () => {},
    remove: () => {},
  }),
  marker: () => ({
    addTo: () => {},
    remove: () => {},
  }),
}

// Mock fetch for API calls
global.fetch = vi.fn()
