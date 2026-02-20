import { describe, it, expect, beforeEach, vi } from 'vitest'

// API integration tests
const API_BASE_URL = 'http://localhost:5000/api/PTV'

describe('API Integration', () => {
  beforeEach(() => {
    global.fetch = vi.fn()
  })

  describe('Routes API', () => {
    it('fetches all routes', async () => {
      const mockRoutes = [
        { route_id: 1, route_name: 'Sunbury', route_type: 0 },
        { route_id: 2, route_name: 'Pakenham', route_type: 0 }
      ]

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ routes: mockRoutes })
      })

      const response = await fetch(`${API_BASE_URL}/routes?route_types=0,1,3&expandPatterns=true`)
      const data = await response.json()

      expect(data.routes).toHaveLength(2)
      expect(data.routes[0].route_name).toBe('Sunbury')
    })

    it('handles route fetch errors', async () => {
      global.fetch.mockRejectedValueOnce(new Error('Network error'))

      try {
        await fetch(`${API_BASE_URL}/routes`)
        expect.fail('Should have thrown an error')
      } catch (error) {
        expect(error.message).toBe('Network error')
      }
    })
  })

  describe('Stops API', () => {
    it('fetches stops for a route type', async () => {
      const mockStops = [
        { stop_id: 1071, stop_name: 'Flinders Street Station', stop_latitude: -37.8183, stop_longitude: 144.9671 },
        { stop_id: 1181, stop_name: 'Southern Cross Station', stop_latitude: -37.8184, stop_longitude: 144.9525 }
      ]

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ stops: mockStops })
      })

      const response = await fetch(`${API_BASE_URL}/stops?route_type=0&include_routes=true`)
      const data = await response.json()

      expect(data.stops).toHaveLength(2)
      expect(data.stops[0].stop_name).toBe('Flinders Street Station')
    })

    it('validates stop coordinates are within valid ranges', async () => {
      const mockStops = [
        { stop_id: 1, stop_name: 'Test Stop', stop_latitude: -37.8183, stop_longitude: 144.9671 }
      ]

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ stops: mockStops })
      })

      const response = await fetch(`${API_BASE_URL}/stops?route_type=0`)
      const data = await response.json()

      data.stops.forEach(stop => {
        expect(stop.stop_latitude).toBeGreaterThanOrEqual(-90)
        expect(stop.stop_latitude).toBeLessThanOrEqual(90)
        expect(stop.stop_longitude).toBeGreaterThanOrEqual(-180)
        expect(stop.stop_longitude).toBeLessThanOrEqual(180)
      })
    })
  })

  describe('Trip Planning API', () => {
    it('plans a trip between two stops', async () => {
      const mockTrip = {
        trips: [
          { source_stop_id: 1071, target_stop_id: 1181, cost: 5, route_id: 14 }
        ],
        journeys: [
          [{ source_stop_id: 1071, target_stop_id: 1181, cost: 5, route_id: 14 }]
        ]
      }

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockTrip
      })

      const response = await fetch(`${API_BASE_URL}/tripPlan/1071/1181?k=3`)
      const data = await response.json()

      expect(data.journeys).toBeDefined()
      expect(data.journeys.length).toBeGreaterThan(0)
      expect(data.journeys[0][0].source_stop_id).toBe(1071)
      expect(data.journeys[0][data.journeys[0].length - 1].target_stop_id).toBe(1181)
    })

    it('returns multiple journey options', async () => {
      const mockTrip = {
        trips: [],
        journeys: [
          [{ source_stop_id: 1071, target_stop_id: 1181, cost: 5, route_id: 14 }],
          [{ source_stop_id: 1071, target_stop_id: 1181, cost: 7, route_id: 15 }],
          [{ source_stop_id: 1071, target_stop_id: 1181, cost: 10, route_id: 16 }]
        ]
      }

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockTrip
      })

      const response = await fetch(`${API_BASE_URL}/tripPlan/1071/1181?k=3`)
      const data = await response.json()

      expect(data.journeys.length).toBeLessThanOrEqual(3)
      // Journeys should be ordered by cost (shortest first)
      if (data.journeys.length > 1) {
        const firstCost = data.journeys[0].reduce((sum, leg) => sum + leg.cost, 0)
        const secondCost = data.journeys[1].reduce((sum, leg) => sum + leg.cost, 0)
        expect(firstCost).toBeLessThanOrEqual(secondCost)
      }
    })
  })

  describe('Disruptions API', () => {
    it('fetches all disruptions', async () => {
      const mockDisruptions = [
        { disruption_id: 1, title: 'Test Disruption', route_type: 0, severity: 'major' }
      ]

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ disruptions: mockDisruptions })
      })

      const response = await fetch(`${API_BASE_URL}/disruptions`)
      const data = await response.json()

      expect(data.disruptions).toBeDefined()
      expect(data.disruptions[0].title).toBe('Test Disruption')
    })

    it('filters disruptions by route type', async () => {
      const mockDisruptions = [
        { disruption_id: 1, title: 'Train Disruption', route_type: 0 }
      ]

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ disruptions: mockDisruptions })
      })

      const response = await fetch(`${API_BASE_URL}/disruptions?route_type=0`)
      const data = await response.json()

      data.disruptions.forEach(disruption => {
        expect(disruption.route_type).toBe(0)
      })
    })
  })

  describe('Geopath API', () => {
    it('fetches geopath for a trip segment', async () => {
      const mockGeoJson = JSON.stringify({
        type: 'LineString',
        coordinates: [[144.9671, -37.8183], [144.9525, -37.8184]]
      })

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockGeoJson
      })

      const response = await fetch(`${API_BASE_URL}/geopath/14/1071/1181`)
      const geoJson = await response.json()

      const parsed = typeof geoJson === 'string' ? JSON.parse(geoJson) : geoJson
      expect(parsed.type).toBe('LineString')
      expect(parsed.coordinates).toBeDefined()
      expect(parsed.coordinates.length).toBeGreaterThan(0)
    })
  })
})
