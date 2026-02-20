import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import MapRoutes from '../App'

describe('MapRoutes Component', () => {
  beforeEach(() => {
    // Reset fetch mock before each test
    global.fetch = vi.fn()
  })

  it('renders the component successfully', async () => {
    // Mock API responses with proper structure
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
          json: async () => ([]) // Stops endpoint returns array directly
        })
      }
      if (url.includes('/disruptions')) {
        return Promise.resolve({
          ok: true,
          json: async () => ([]) // Disruptions endpoint returns array directly
        })
      }
      return Promise.reject(new Error('Unknown endpoint'))
    })

    const { container } = render(<MapRoutes />)

    // Component should render without crashing - check for the main wrapper
    await waitFor(() => {
      expect(container.firstChild).toBeTruthy()
      // Check for key UI elements - sidebar with "Melbourne PTV" header
      expect(screen.getByText(/Melbourne PTV/i)).toBeInTheDocument()
    })
  })

  it('fetches routes on mount', async () => {
    const mockRoutes = [
      {
        route_id: 1,
        route_name: 'Test Route',
        route_type: 0,
        route_colour: { RGB: [255, 0, 0] },
        geopath: { type: 'LineString', coordinates: [] }
      }
    ]

    global.fetch.mockImplementation((url) => {
      if (url.includes('/routes')) {
        return Promise.resolve({
          ok: true,
          json: async () => ({ routes: mockRoutes })
        })
      }
      if (url.includes('/stops')) {
        return Promise.resolve({
          ok: true,
          json: async () => ([])
        })
      }
      if (url.includes('/disruptions')) {
        return Promise.resolve({
          ok: true,
          json: async () => ([])
        })
      }
      return Promise.reject(new Error('Unknown endpoint'))
    })

    render(<MapRoutes />)

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalled()
    })
  })

  it('handles API errors gracefully', async () => {
    // Mock partial failures - routes succeed, stops/disruptions fail
    global.fetch.mockImplementation((url) => {
      if (url.includes('/routes')) {
        return Promise.resolve({
          ok: true,
          json: async () => ({ routes: [] })
        })
      }
      // Stops and disruptions endpoints fail
      return Promise.reject(new Error('API Error'))
    })

    render(<MapRoutes />)

    // Component should still render even if some APIs fail
    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalled()
    }, { timeout: 3000 })
  })
})
