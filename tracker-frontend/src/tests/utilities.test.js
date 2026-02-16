import { describe, it, expect } from 'vitest'

// Utility functions to test
const rgbToCss = (rgb) => {
  if (!rgb || rgb.length !== 3) return "black";
  return `rgb(${rgb[0]},${rgb[1]},${rgb[2]})`;
};

const getDistance = (lat1, lng1, lat2, lng2) => {
  return Math.sqrt(Math.pow(lat1 - lat2, 2) + Math.pow(lng1 - lng2, 2));
};

const getRadius = (zoomLevel) => {
  return Math.min(200, Math.max(5, 300 / Math.pow(2, zoomLevel - 11)));
};

const isDisruptionActive = (disruption) => {
  const now = new Date();

  if (!disruption.disruption_event?.periods) {
    const fromDate = disruption.from_date ? new Date(disruption.from_date) : null;
    const toDate = disruption.to_date ? new Date(disruption.to_date) : null;
    return (!fromDate || fromDate <= now) && (!toDate || toDate >= now);
  }

  return disruption.disruption_event.periods.some(period => {
    if (!period.start_datetime) return false;
    const start = new Date(period.start_datetime);
    const end = period.end_datetime ? new Date(period.end_datetime) : null;
    return start <= now && (!end || end >= now);
  });
};

describe('Utility Functions', () => {
  describe('rgbToCss', () => {
    it('converts RGB array to CSS string', () => {
      expect(rgbToCss([255, 0, 0])).toBe('rgb(255,0,0)');
      expect(rgbToCss([0, 128, 255])).toBe('rgb(0,128,255)');
    });

    it('returns black for invalid input', () => {
      expect(rgbToCss(null)).toBe('black');
      expect(rgbToCss(undefined)).toBe('black');
      expect(rgbToCss([255, 0])).toBe('black');
      expect(rgbToCss([])).toBe('black');
    });
  });

  describe('getDistance', () => {
    it('calculates distance between two points', () => {
      // Same point
      expect(getDistance(0, 0, 0, 0)).toBe(0);

      // Pythagorean theorem: 3-4-5 triangle
      const distance = getDistance(0, 0, 3, 4);
      expect(distance).toBe(5);
    });

    it('handles negative coordinates', () => {
      const distance = getDistance(-1, -1, 2, 3);
      expect(distance).toBeGreaterThan(0);
    });
  });

  describe('getRadius', () => {
    it('returns radius within bounds', () => {
      const minRadius = getRadius(20); // Max zoom in
      const maxRadius = getRadius(5); // Max zoom out

      expect(minRadius).toBeGreaterThanOrEqual(5);
      expect(maxRadius).toBeLessThanOrEqual(200);
    });

    it('returns smaller radius for higher zoom levels', () => {
      const lowZoom = getRadius(8);
      const highZoom = getRadius(16);

      expect(lowZoom).toBeGreaterThan(highZoom);
    });
  });

  describe('isDisruptionActive', () => {
    it('returns true for active disruption with date range', () => {
      const now = new Date();
      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);
      const tomorrow = new Date(now);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const disruption = {
        from_date: yesterday.toISOString(),
        to_date: tomorrow.toISOString()
      };

      expect(isDisruptionActive(disruption)).toBe(true);
    });

    it('returns false for expired disruption', () => {
      const now = new Date();
      const twoDaysAgo = new Date(now);
      twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);

      const disruption = {
        from_date: twoDaysAgo.toISOString(),
        to_date: yesterday.toISOString()
      };

      expect(isDisruptionActive(disruption)).toBe(false);
    });

    it('returns true for active disruption with periods', () => {
      const now = new Date();
      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);
      const tomorrow = new Date(now);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const disruption = {
        disruption_event: {
          periods: [
            {
              start_datetime: yesterday.toISOString(),
              end_datetime: tomorrow.toISOString()
            }
          ]
        }
      };

      expect(isDisruptionActive(disruption)).toBe(true);
    });

    it('returns false for disruption with no matching periods', () => {
      const now = new Date();
      const twoDaysAgo = new Date(now);
      twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
      const yesterday = new Date(now);
      yesterday.setDate(yesterday.getDate() - 1);

      const disruption = {
        disruption_event: {
          periods: [
            {
              start_datetime: twoDaysAgo.toISOString(),
              end_datetime: yesterday.toISOString()
            }
          ]
        }
      };

      expect(isDisruptionActive(disruption)).toBe(false);
    });
  });
});
