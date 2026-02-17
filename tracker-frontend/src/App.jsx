import 'leaflet/dist/leaflet.css';
import React, { useState, useEffect } from "react";
import { MapContainer, TileLayer, Polyline, Circle, Tooltip, useMapEvents, Popup, Marker } from "react-leaflet";
import L from 'leaflet';
import { API_BASE_URL, authenticatedFetch } from './config';

function ZoomListener({ onZoomChange }) {
    useMapEvents({
        zoomend: (e) => {
            const map = e.target;
            onZoomChange(map.getZoom());
        }
    });
    return null;
}
const rgbToCss = (rgb) => {
    if (!rgb || rgb.length !== 3) return "black"; // fallback
    return `rgb(${rgb[0]},${rgb[1]},${rgb[2]})`;
};

export default function MapRoutes() {
    const [routes, setRoutes] = useState([]);
    const [stops, setStops] = useState([]);
    const [disruptions, setDisruptions] = useState([]);
    const [zoom, setZoom] = useState(12); // initial zoom
    const [selectedRoutes, setSelectedRoutes] = useState(new Set()); // Track selected route IDs
    const [showTripPlanner, setShowTripPlanner] = useState(false); // Toggle trip planner

    // Trip planning state
    const [originInput, setOriginInput] = useState("");
    const [destinationInput, setDestinationInput] = useState("");
    const [showOriginDropdown, setShowOriginDropdown] = useState(false);
    const [showDestinationDropdown, setShowDestinationDropdown] = useState(false);
    const [plannedJourneys, setPlannedJourneys] = useState(null); // Array of journeys
    const [selectedJourneyIndex, setSelectedJourneyIndex] = useState(0); // Which journey to display
    const [tripError, setTripError] = useState("");
    const [isLoading, setIsLoading] = useState(false);
    const [selectedOriginStopId, setSelectedOriginStopId] = useState(null); // For highlighting on map
    const [selectedDestinationStopId, setSelectedDestinationStopId] = useState(null); // For highlighting on map
    const [departureTime, setDepartureTime] = useState(() => {
        // Default to current time
        const now = new Date();
        now.setSeconds(0);
        now.setMilliseconds(0);
        return now.toISOString().slice(0, 16);
    });

    // Disruptions state
    const [showDisruptions, setShowDisruptions] = useState(false);
    const [selectedDisruptionId, setSelectedDisruptionId] = useState(null);

    // Route type state (0=Train, 1=Tram, 2=Bus, 3=V/Line) - now supports multiple types
    const [selectedRouteTypes, setSelectedRouteTypes] = useState(new Set([0, 1, 3]));
    const [allStops, setAllStops] = useState([]); // All stops for trip planning, regardless of filter

    // Route loading state
    const [isLoadingRoutes, setIsLoadingRoutes] = useState(false);
    const [routeLoadingProgress, setRouteLoadingProgress] = useState(0);

    const getRadius = (zoomLevel) => {
        // Radius in meters - visually grows when zooming OUT, shrinks when zooming IN
        // Uses exponential scaling: larger meter radius at low zoom + zoomed out view = very large visual size
        // Smaller meter radius at high zoom + zoomed in view = very small visual size
        // Significantly increased from previous values for better visibility
        // Min 20m (max zoom in), max 600m (max zoom out) - 4x larger than before
        return Math.min(600, Math.max(20, 800 / Math.pow(2, zoomLevel - 11)));
    };

    // Check if disruption is currently active based on time periods
    const isDisruptionActive = (disruption) => {
        const now = new Date();

        // If no disruption_event, fall back to from_date/to_date
        if (!disruption.disruption_event?.periods) {
            const fromDate = disruption.from_date ? new Date(disruption.from_date) : null;
            const toDate = disruption.to_date ? new Date(disruption.to_date) : null;
            return (!fromDate || fromDate <= now) && (!toDate || toDate >= now);
        }

        // Check if current time falls within any period
        return disruption.disruption_event.periods.some(period => {
            if (!period.start_datetime) return false;

            const start = new Date(period.start_datetime);
            const end = period.end_datetime ? new Date(period.end_datetime) : null;

            return start <= now && (!end || end >= now);
        });
    };

    // Find stop by name (case-insensitive exact or partial match)
    // Uses allStops to search across ALL route types, not just visible ones
    const findStopByName = (name) => {
        const lower = name.toLowerCase().trim();
        const searchArray = allStops.length > 0 ? allStops : stops; // Fallback to stops if allStops not loaded yet

        // First try exact match (for autocomplete selections)
        let stop = searchArray.find(s => s.stop_name.toLowerCase() === lower);

        // If not found, try exact match without " station" suffix
        if (!stop) {
            stop = searchArray.find(s =>
                s.stop_name.toLowerCase().replace(" station", "") === lower ||
                s.stop_name.toLowerCase() === lower.replace(" station", "")
            );
        }

        // Finally, fall back to partial match
        if (!stop) {
            stop = searchArray.find(s =>
                s.stop_name.toLowerCase().includes(lower) ||
                s.stop_name.toLowerCase().replace(" station", "").includes(lower)
            );
        }

        return stop;
    };

    // Check if disruption is for night works (periods after 10pm or labeled as night works)
    const isNightWorks = (disruption) => {
        if (disruption.title?.toLowerCase().includes('night') ||
            disruption.description?.toLowerCase().includes('night work')) {
            return true;
        }

        // Check if any period starts after 10pm
        return disruption.disruption_event?.periods?.some(period => {
            if (!period.start_datetime) return false;
            const hour = new Date(period.start_datetime).getHours();
            return hour >= 22 || hour < 5; // 10pm - 5am
        }) || false;
    };

    // Calculate distance between two points (in degrees, approximation)
    const getDistance = (lat1, lng1, lat2, lng2) => {
        return Math.sqrt(Math.pow(lat1 - lat2, 2) + Math.pow(lng1 - lng2, 2));
    };

    // Find route segments affected by a disruption
    const getDisruptedRouteSegments = (disruption) => {
        if (!disruption.disruption_event?.affected_area) return [];

        // Skip station facility disruptions - they're point locations, not segments
        if (disruption.disruption_event?.event_type === 'station_facility') return [];

        const { start_location, end_location } = disruption.disruption_event.affected_area;

        // Skip if there's no end location (not a segment)
        if (!end_location) return [];

        // Helper to normalize location names for matching
        const normalizeLocationName = (name) => {
            if (!name) return '';
            return name.toLowerCase()
                .replace(' station', '')
                .replace(' railway station', '')
                .replace(/stop \d+ /i, '') // Remove "Stop 37" prefix
                .trim();
        };

        const normalizedStart = normalizeLocationName(start_location);
        const normalizedEnd = normalizeLocationName(end_location);

        // Skip if we don't have valid location names
        if (!normalizedStart || !normalizedEnd) return [];

        // Find start and end stops - match against the disruption's route_type
        const startStop = stops.find(s => {
            if (s.route_type !== disruption.route_type) return false;
            const normalizedStopName = normalizeLocationName(s.stop_name);
            return normalizedStopName.includes(normalizedStart) ||
                   normalizedStart.includes(normalizedStopName);
        });

        const endStop = stops.find(s => {
            if (s.route_type !== disruption.route_type) return false;
            const normalizedStopName = normalizeLocationName(s.stop_name);
            return normalizedStopName.includes(normalizedEnd) ||
                   normalizedEnd.includes(normalizedStopName);
        });

        if (!startStop || !endStop) {
            console.log(`❌ Could not find stops for disruption: "${start_location}" -> "${end_location}" (route_type ${disruption.route_type})`);
            if (!startStop) console.log(`   Missing start stop: "${start_location}"`);
            if (!endStop) console.log(`   Missing end stop: "${end_location}"`);
            return [];
        }

        console.log(`✓ Found stops for disruption: ${startStop.stop_name} (${startStop.stop_id}) -> ${endStop.stop_name} (${endStop.stop_id})`);

        const segments = [];

        // More lenient threshold - routes might not stop exactly at these points
        const maxDistanceThreshold = 0.01; // ~1km in degrees (increased for better matching)

        // Find all routes that pass near both stops and match the route_type
        const matchingRoutes = routes.filter(route => route.route_type === disruption.route_type);
        const routesWithCoords = matchingRoutes.filter(r => r.coords && r.coords.length > 0);
        const routesWithoutCoords = matchingRoutes.filter(r => !r.coords || r.coords.length === 0);

        if (routesWithoutCoords.length > 0) {
            console.log(`⚠ ${routesWithoutCoords.length} routes have no geopath data:`, routesWithoutCoords.map(r => r.route_name).join(', '));
        }

        routesWithCoords.forEach(route => {

            route.coords.forEach((path, pathIdx) => {
                if (path.length < 2) return;

                // Find closest point to start stop
                let closestStartIdx = -1;
                let closestStartDist = Infinity;

                // Find closest point to end stop
                let closestEndIdx = -1;
                let closestEndDist = Infinity;

                path.forEach((coord, idx) => {
                    const [lat, lng] = coord;

                    // Distance to start stop
                    const distToStart = getDistance(lat, lng, startStop.lat, startStop.lng);
                    if (distToStart < closestStartDist) {
                        closestStartDist = distToStart;
                        closestStartIdx = idx;
                    }

                    // Distance to end stop
                    const distToEnd = getDistance(lat, lng, endStop.lat, endStop.lng);
                    if (distToEnd < closestEndDist) {
                        closestEndDist = distToEnd;
                        closestEndIdx = idx;
                    }
                });

                // If route passes reasonably close to both stops, extract segment
                if (closestStartDist < maxDistanceThreshold &&
                    closestEndDist < maxDistanceThreshold &&
                    closestStartIdx !== -1 &&
                    closestEndIdx !== -1 &&
                    Math.abs(closestStartIdx - closestEndIdx) > 1) {  // Must have some distance between them

                    const segmentPath = closestStartIdx < closestEndIdx
                        ? path.slice(closestStartIdx, closestEndIdx + 1)
                        : path.slice(closestEndIdx, closestStartIdx + 1).reverse();

                    if (segmentPath.length > 1) {
                        segments.push({
                            route_id: route.route_id,
                            route_name: route.route_name,
                            path: segmentPath,
                            color: route.color
                        });
                        console.log(`Found disrupted segment: ${route.route_name} (${segmentPath.length} points)`);
                    }
                }
            });
        });

        return segments;
    };

    // Plan trip handler
    const handlePlanTrip = async () => {
        setTripError("");
        setPlannedJourneys(null);
        setSelectedJourneyIndex(0);

        const originStop = findStopByName(originInput);
        const destStop = findStopByName(destinationInput);

        if (!originStop) {
            setTripError(`Could not find origin station: "${originInput}"`);
            setSelectedOriginStopId(null);
            setSelectedDestinationStopId(null);
            return;
        }
        if (!destStop) {
            setTripError(`Could not find destination station: "${destinationInput}"`);
            setSelectedOriginStopId(null);
            setSelectedDestinationStopId(null);
            return;
        }

        // Set the selected stop IDs for map highlighting
        setSelectedOriginStopId(originStop.stop_id);
        setSelectedDestinationStopId(destStop.stop_id);

        setIsLoading(true);
        try {
            // Call the realtime endpoint with departure time
            const res = await authenticatedFetch(
                `${API_BASE_URL}/api/PTV/tripPlanRealtime/${originStop.stop_id}/${destStop.stop_id}?departureTime=${encodeURIComponent(departureTime)}`
            );
            const data = await res.json();

            if (data.journeys && data.journeys.length > 0) {
                setPlannedJourneys(data.journeys);
            } else {
                setTripError("No route found between these stations");
            }
        } catch (err) {
            setTripError("Failed to plan trip: " + err.message);
        } finally {
            setIsLoading(false);
        }
    };

    // Helper to get route info by ID (handles both base and expanded IDs)
    const getRouteById = (routeId) => {
        // First try exact match
        let route = routes.find(r => r.route_id === routeId);

        // If not found and routeId is small (base ID), find expanded version
        if (!route && routeId < 1000) {
            // Look for expanded route ID (base * 1000 + pattern index)
            route = routes.find(r => Math.floor(r.route_id / 1000) === routeId);
        }

        return route;
    };

    // Helper to get stop info by ID
    // Uses allStops first, then falls back to stops
    const getStopById = (stopId) => {
        const searchArray = allStops.length > 0 ? allStops : stops;
        return searchArray.find(s => s.stop_id === stopId);
    };

    // Toggle route selection
    const toggleRouteSelection = (routeId) => {
        setSelectedRoutes(prev => {
            const newSet = new Set(prev);
            if (newSet.has(routeId)) {
                newSet.delete(routeId);
            } else {
                newSet.add(routeId);
            }
            return newSet;
        });
    };

    // Check if a route is selected (show all if none selected)
    const isRouteVisible = (routeId) => {
        return selectedRoutes.size === 0 || selectedRoutes.has(routeId);
    };

    // Load ALL stops once on mount for trip planning (regardless of filter)
    useEffect(() => {
        const loadAllStops = async () => {
            try {
                const response = await authenticatedFetch(`${API_BASE_URL}/api/PTV/stops?route_types=0,1,2,3,4`);
                const data = await response.json();
                setAllStops(data.stops || []);
            } catch (err) {
                console.error('Failed to load all stops:', err);
            }
        };
        loadAllStops();
    }, []); // Run once on mount

    // Load routes/stops/disruptions when selected types change
    useEffect(() => {
        if (selectedRouteTypes.size === 0) {
            setRoutes([]);
            setStops([]);
            setDisruptions([]);
            return;
        }

        const loadData = async () => {
            setIsLoadingRoutes(true);
            setRouteLoadingProgress(0);

            try {
                // Convert selectedRouteTypes to comma-separated string (e.g., "0,1,3")
                const routeTypesParam = Array.from(selectedRouteTypes).join(',');

                // Fetch all data in parallel with a single API call each
                const [routesData, stopsData, disruptionsData] = await Promise.all([
                    authenticatedFetch(`${API_BASE_URL}/api/PTV/routes?route_types=${routeTypesParam}&includeGeopaths=true`)
                        .then(res => res.json())
                        .then(data => data.routes || []),
                    authenticatedFetch(`${API_BASE_URL}/api/PTV/stops?route_types=${routeTypesParam}`)
                        .then(res => res.json()),
                    authenticatedFetch(`${API_BASE_URL}/api/PTV/disruptions?route_types=${routeTypesParam}`)
                        .then(res => res.json())
                        .then(data => data.disruptions || [])
                ]);

                // Process routes with aggressive geopath simplification for better performance
                const simplifyPath = (path, tolerance = 5) => {
                    // Keep every Nth point to reduce coordinate density
                    // This dramatically improves rendering performance
                    if (path.length <= 10) return path;
                    return path.filter((_, index) => index === 0 || index === path.length - 1 || index % tolerance === 0);
                };

                const allRoutes = routesData.map(r => {
                    const geopaths = r.geopaths || [];
                    const allCoords = geopaths.map(geo => {
                        const points = geo
                            .filter(p => p.lat != null && p.lon != null)
                            .map(p => [Number(p.lat), Number(p.lon)]);
                        // Aggressive simplification: keep every 5th point (80% reduction)
                        return simplifyPath(points, 5);
                    });
                    return {
                        ...r,
                        coords: allCoords,
                        color: rgbToCss(r.route_colour)
                    };
                });
                setRoutes(allRoutes);

                // Process stops (already deduplicated by backend)
                setStops(stopsData.map(s => ({
                    ...s,
                    lat: Number(s.stop_latitude),
                    lng: Number(s.stop_longitude),
                })));

                // Process disruptions (already deduplicated by backend)
                setDisruptions(disruptionsData);

                setIsLoadingRoutes(false);
                setRouteLoadingProgress(100);
            } catch (err) {
                console.error("Failed to load data:", err);
                setIsLoadingRoutes(false);
            }
        };

        loadData();
    }, [selectedRouteTypes]);

    return (
        <>
            <style>{`
                @keyframes disruption-pulse {
                    0%, 100% { opacity: 0.85; }
                    50% { opacity: 1; }
                }
                .disruption-pulse {
                    animation: disruption-pulse 2s ease-in-out infinite;
                }
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
                @keyframes pulse {
                    0%, 100% { opacity: 1; }
                    50% { opacity: 0.7; }
                }
            `}</style>
            <div style={{ display: "flex", height: "100vh", background: "#f5f5f5" }}>
            <div style={{
                width: "360px",
                height: "100vh",
                overflowY: "auto",
                background: "linear-gradient(180deg, #1a1f35 0%, #0f1419 100%)",
                color: "white",
                boxShadow: "4px 0 20px rgba(0,0,0,0.3)"
            }}>
                {/* Header */}
                <div style={{
                    padding: "2rem 1.5rem 1.5rem 1.5rem",
                    background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
                    borderBottom: "1px solid rgba(255,255,255,0.1)"
                }}>
                    <h2 style={{
                        margin: 0,
                        fontSize: "1.6rem",
                        fontWeight: "700",
                        letterSpacing: "-0.5px",
                        marginBottom: "0.25rem"
                    }}>
                        🚇 Melbourne PTV
                    </h2>
                    <p style={{
                        margin: 0,
                        fontSize: "0.8rem",
                        color: "rgba(255,255,255,0.7)",
                        fontWeight: "400"
                    }}>
                        Live tracking & trip planning
                    </p>
                </div>

                {/* Route Type Filter */}
                <div style={{
                    padding: "1.25rem 1rem",
                    borderBottom: "1px solid rgba(255,255,255,0.08)",
                    background: "rgba(0,0,0,0.15)"
                }}>
                    <div style={{
                        fontSize: "0.7rem",
                        textTransform: "uppercase",
                        letterSpacing: "1px",
                        color: "rgba(255,255,255,0.5)",
                        fontWeight: "700",
                        marginBottom: "0.75rem"
                    }}>
                        Filter by Transport Mode
                    </div>
                    <div style={{
                        display: "grid",
                        gridTemplateColumns: "1fr 1fr",
                        gap: "0.5rem"
                    }}>
                    {[
                        { type: 0, label: "Train", icon: "🚆" },
                        { type: 1, label: "Tram", icon: "🚊" },
                        { type: 2, label: "Bus", icon: "🚌" },
                        { type: 3, label: "V/Line", icon: "🚄" }
                    ].map(({ type, label, icon }) => {
                        const isSelected = selectedRouteTypes.has(type);
                        return (
                            <button
                                key={type}
                                onClick={() => {
                                    const newTypes = new Set(selectedRouteTypes);
                                    if (isSelected) {
                                        newTypes.delete(type);
                                    } else {
                                        newTypes.add(type);
                                    }
                                    setSelectedRouteTypes(newTypes);
                                }}
                                style={{
                                    padding: "0.85rem 0.75rem",
                                    background: isSelected
                                        ? "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
                                        : "rgba(255,255,255,0.03)",
                                    border: isSelected ? "2px solid rgba(102, 126, 234, 0.5)" : "2px solid rgba(255,255,255,0.1)",
                                    borderRadius: "10px",
                                    color: isSelected ? "white" : "rgba(255,255,255,0.7)",
                                    cursor: "pointer",
                                    fontWeight: isSelected ? "700" : "600",
                                    fontSize: "0.8rem",
                                    transition: "all 0.2s ease",
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    gap: "0.5rem",
                                    boxShadow: isSelected ? "0 4px 12px rgba(102, 126, 234, 0.3)" : "none"
                                }}
                                onMouseEnter={(e) => {
                                    if (!isSelected) {
                                        e.target.style.background = "rgba(255,255,255,0.1)";
                                        e.target.style.color = "rgba(255,255,255,0.9)";
                                    }
                                }}
                                onMouseLeave={(e) => {
                                    if (!isSelected) {
                                        e.target.style.background = "rgba(255,255,255,0.05)";
                                        e.target.style.color = "rgba(255,255,255,0.6)";
                                    }
                                }}
                            >
                                <span style={{ fontSize: "1.2rem" }}>{icon}</span>
                                <span>{label}</span>
                                {isSelected && <span style={{ marginLeft: "auto" }}>✓</span>}
                            </button>
                        );
                    })}
                    </div>
                </div>

                {/* Loading Indicator */}
                {isLoadingRoutes && (
                    <div style={{
                        padding: "1rem 1.5rem",
                        background: "rgba(102, 126, 234, 0.1)",
                        borderBottom: "1px solid rgba(102, 126, 234, 0.3)",
                        animation: "pulse 2s ease-in-out infinite"
                    }}>
                        <div style={{
                            display: "flex",
                            alignItems: "center",
                            gap: "0.75rem",
                            marginBottom: "0.5rem"
                        }}>
                            <div style={{
                                width: "16px",
                                height: "16px",
                                border: "3px solid rgba(102, 126, 234, 0.3)",
                                borderTop: "3px solid #667eea",
                                borderRadius: "50%",
                                animation: "spin 1s linear infinite"
                            }}></div>
                            <span style={{
                                fontSize: "0.85rem",
                                fontWeight: "600",
                                color: "#667eea"
                            }}>
                                Loading routes... {routeLoadingProgress}%
                            </span>
                        </div>
                        <div style={{
                            width: "100%",
                            height: "4px",
                            background: "rgba(255,255,255,0.1)",
                            borderRadius: "2px",
                            overflow: "hidden"
                        }}>
                            <div style={{
                                width: `${routeLoadingProgress}%`,
                                height: "100%",
                                background: "linear-gradient(90deg, #667eea 0%, #764ba2 100%)",
                                transition: "width 0.3s ease",
                                borderRadius: "2px"
                            }}></div>
                        </div>
                    </div>
                )}

                {/* Trip Planner Toggle */}
                <button
                    onClick={() => setShowTripPlanner(!showTripPlanner)}
                    style={{
                        padding: "1.25rem 1.5rem",
                        background: showTripPlanner ? "linear-gradient(135deg, #667eea 0%, #764ba2 100%)" : "rgba(255,255,255,0.03)",
                        border: "none",
                        borderBottom: "1px solid rgba(255,255,255,0.08)",
                        color: "white",
                        cursor: "pointer",
                        textAlign: "left",
                        fontWeight: "700",
                        fontSize: "0.95rem",
                        transition: "all 0.3s ease",
                        display: "flex",
                        alignItems: "center",
                        gap: "0.75rem"
                    }}
                    onMouseEnter={(e) => {
                        if (!showTripPlanner) e.target.style.background = "rgba(255,255,255,0.08)";
                    }}
                    onMouseLeave={(e) => {
                        if (!showTripPlanner) e.target.style.background = "rgba(255,255,255,0.03)";
                    }}
                >
                    <span style={{ fontSize: "0.9rem" }}>{showTripPlanner ? "▼" : "▶"}</span>
                    <span>🗺️ Plan a Trip</span>
                </button>

                {/* Trip Planner Section (Collapsible) */}
                {showTripPlanner && (
                    <div style={{
                        padding: "1.5rem",
                        background: "rgba(0,0,0,0.2)",
                        borderBottom: "1px solid rgba(255,255,255,0.1)",
                        backdropFilter: "blur(10px)"
                    }}>
                        <div style={{ marginBottom: "1rem", position: "relative" }}>
                            <label style={{
                                display: "block",
                                marginBottom: "0.5rem",
                                fontSize: "0.75rem",
                                textTransform: "uppercase",
                                letterSpacing: "0.5px",
                                color: "rgba(255,255,255,0.6)",
                                fontWeight: "600"
                            }}>
                                From Station
                            </label>
                            <input
                                type="text"
                                placeholder="e.g., Flinders Street"
                                value={originInput}
                                onChange={(e) => {
                                    setOriginInput(e.target.value);
                                    setShowOriginDropdown(true);
                                }}
                                onFocus={() => setShowOriginDropdown(true)}
                                onBlur={() => setTimeout(() => setShowOriginDropdown(false), 200)}
                                style={{
                                    width: "100%",
                                    padding: "0.75rem",
                                    borderRadius: "8px",
                                    border: "2px solid rgba(255,255,255,0.1)",
                                    background: "rgba(255,255,255,0.05)",
                                    color: "white",
                                    fontSize: "1rem",
                                    outline: "none",
                                    transition: "all 0.2s ease"
                                }}
                            />
                            {showOriginDropdown && originInput.length >= 2 && (() => {
                                // Deduplicate stops by name (e.g., bidirectional tram stops)
                                // Use allStops for comprehensive search across all route types
                                const searchArray = allStops.length > 0 ? allStops : stops;
                                const uniqueStops = new Map();
                                searchArray
                                    .filter(s => s.stop_name.toLowerCase().includes(originInput.toLowerCase()))
                                    .forEach(s => {
                                        if (!uniqueStops.has(s.stop_name)) {
                                            uniqueStops.set(s.stop_name, s);
                                        }
                                    });
                                const filtered = Array.from(uniqueStops.values()).slice(0, 10);

                                if (filtered.length === 0) return null;

                                return (
                                    <div style={{
                                        position: "absolute",
                                        top: "100%",
                                        left: 0,
                                        right: 0,
                                        background: "rgba(26, 31, 53, 0.98)",
                                        backdropFilter: "blur(10px)",
                                        border: "2px solid rgba(255,255,255,0.1)",
                                        borderRadius: "8px",
                                        marginTop: "0.5rem",
                                        maxHeight: "300px",
                                        overflowY: "auto",
                                        zIndex: 1000,
                                        boxShadow: "0 4px 20px rgba(0,0,0,0.3)"
                                    }}>
                                        {filtered.map(stop => (
                                            <div
                                                key={stop.stop_id}
                                                onClick={() => {
                                                    setOriginInput(stop.stop_name);
                                                    setShowOriginDropdown(false);
                                                }}
                                                style={{
                                                    padding: "0.75rem 1rem",
                                                    cursor: "pointer",
                                                    borderBottom: "1px solid rgba(255,255,255,0.05)",
                                                    transition: "background 0.2s ease"
                                                }}
                                                onMouseEnter={(e) => e.target.style.background = "rgba(102, 126, 234, 0.2)"}
                                                onMouseLeave={(e) => e.target.style.background = "transparent"}
                                            >
                                                <div style={{ fontWeight: "500", color: "white" }}>
                                                    {stop.stop_name}
                                                </div>
                                                {stop.stop_suburb && (
                                                    <div style={{ fontSize: "0.75rem", color: "rgba(255,255,255,0.5)", marginTop: "0.25rem" }}>
                                                        {stop.stop_suburb}
                                                    </div>
                                                )}
                                            </div>
                                        ))}
                                    </div>
                                );
                            })()}
                        </div>

                        <div style={{ marginBottom: "1rem", position: "relative" }}>
                            <label style={{
                                display: "block",
                                marginBottom: "0.5rem",
                                fontSize: "0.75rem",
                                textTransform: "uppercase",
                                letterSpacing: "0.5px",
                                color: "rgba(255,255,255,0.6)",
                                fontWeight: "600"
                            }}>
                                To Station
                            </label>
                            <input
                                type="text"
                                placeholder="e.g., Southern Cross"
                                value={destinationInput}
                                onChange={(e) => {
                                    setDestinationInput(e.target.value);
                                    setShowDestinationDropdown(true);
                                }}
                                onFocus={() => setShowDestinationDropdown(true)}
                                onBlur={() => setTimeout(() => setShowDestinationDropdown(false), 200)}
                                style={{
                                    width: "100%",
                                    padding: "0.75rem",
                                    borderRadius: "8px",
                                    border: "2px solid rgba(255,255,255,0.1)",
                                    background: "rgba(255,255,255,0.05)",
                                    color: "white",
                                    fontSize: "1rem",
                                    outline: "none",
                                    transition: "all 0.2s ease"
                                }}
                            />
                            {showDestinationDropdown && destinationInput.length >= 2 && (() => {
                                // Deduplicate stops by name (e.g., bidirectional tram stops)
                                // Use allStops for comprehensive search across all route types
                                const searchArray = allStops.length > 0 ? allStops : stops;
                                const uniqueStops = new Map();
                                searchArray
                                    .filter(s => s.stop_name.toLowerCase().includes(destinationInput.toLowerCase()))
                                    .forEach(s => {
                                        if (!uniqueStops.has(s.stop_name)) {
                                            uniqueStops.set(s.stop_name, s);
                                        }
                                    });
                                const filtered = Array.from(uniqueStops.values()).slice(0, 10);

                                if (filtered.length === 0) return null;

                                return (
                                    <div style={{
                                        position: "absolute",
                                        top: "100%",
                                        left: 0,
                                        right: 0,
                                        background: "rgba(26, 31, 53, 0.98)",
                                        backdropFilter: "blur(10px)",
                                        border: "2px solid rgba(255,255,255,0.1)",
                                        borderRadius: "8px",
                                        marginTop: "0.5rem",
                                        maxHeight: "300px",
                                        overflowY: "auto",
                                        zIndex: 1000,
                                        boxShadow: "0 4px 20px rgba(0,0,0,0.3)"
                                    }}>
                                        {filtered.map(stop => (
                                            <div
                                                key={stop.stop_id}
                                                onClick={() => {
                                                    setDestinationInput(stop.stop_name);
                                                    setShowDestinationDropdown(false);
                                                }}
                                                style={{
                                                    padding: "0.75rem 1rem",
                                                    cursor: "pointer",
                                                    borderBottom: "1px solid rgba(255,255,255,0.05)",
                                                    transition: "background 0.2s ease"
                                                }}
                                                onMouseEnter={(e) => e.target.style.background = "rgba(102, 126, 234, 0.2)"}
                                                onMouseLeave={(e) => e.target.style.background = "transparent"}
                                            >
                                                <div style={{ fontWeight: "500", color: "white" }}>
                                                    {stop.stop_name}
                                                </div>
                                                {stop.stop_suburb && (
                                                    <div style={{ fontSize: "0.75rem", color: "rgba(255,255,255,0.5)", marginTop: "0.25rem" }}>
                                                        {stop.stop_suburb}
                                                    </div>
                                                )}
                                            </div>
                                        ))}
                                    </div>
                                );
                            })()}
                        </div>

                        <div style={{ marginBottom: "1rem" }}>
                            <label style={{
                                display: "block",
                                marginBottom: "0.5rem",
                                fontSize: "0.75rem",
                                textTransform: "uppercase",
                                letterSpacing: "0.5px",
                                color: "rgba(255,255,255,0.6)",
                                fontWeight: "600"
                            }}>
                                Departure Time
                            </label>
                            <input
                                type="datetime-local"
                                value={departureTime}
                                onChange={(e) => setDepartureTime(e.target.value)}
                                style={{
                                    width: "100%",
                                    padding: "0.75rem",
                                    borderRadius: "8px",
                                    border: "2px solid rgba(255,255,255,0.1)",
                                    background: "rgba(255,255,255,0.05)",
                                    color: "white",
                                    fontSize: "1rem",
                                    outline: "none",
                                    transition: "all 0.2s ease",
                                    colorScheme: "dark"
                                }}
                            />
                        </div>

                        <button
                            onClick={handlePlanTrip}
                            disabled={isLoading}
                            style={{
                                width: "100%",
                                padding: "0.875rem",
                                background: isLoading ? "rgba(255,255,255,0.1)" : "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
                                border: "none",
                                borderRadius: "8px",
                                color: "white",
                                cursor: isLoading ? "wait" : "pointer",
                                fontWeight: "600",
                                fontSize: "1rem",
                                transition: "all 0.3s ease",
                                boxShadow: isLoading ? "none" : "0 4px 15px rgba(102, 126, 234, 0.4)"
                            }}
                            onMouseEnter={(e) => {
                                if (!isLoading) e.target.style.transform = "translateY(-2px)";
                            }}
                            onMouseLeave={(e) => {
                                if (!isLoading) e.target.style.transform = "translateY(0)";
                            }}
                        >
                            {isLoading ? "🔍 Planning..." : "🚆 Plan Trip"}
                        </button>

                        {(tripError || plannedJourneys) && (
                            <div style={{
                                marginTop: "1rem",
                                padding: "1rem",
                                background: "rgba(0,0,0,0.3)",
                                borderRadius: "12px",
                                border: "1px solid rgba(255,255,255,0.1)",
                                fontSize: "0.85rem",
                                backdropFilter: "blur(10px)"
                            }}>
                                {tripError && (
                                    <div style={{
                                        padding: "0.75rem",
                                        background: "rgba(255, 107, 107, 0.1)",
                                        border: "1px solid rgba(255, 107, 107, 0.3)",
                                        borderRadius: "8px",
                                        color: "#ff6b6b"
                                    }}>
                                        {tripError}
                                    </div>
                                )}
                                {plannedJourneys && plannedJourneys.length > 0 && (
                                    <div>
                                        {/* Journey selector tabs */}
                                        {plannedJourneys.length > 1 && (
                                            <div style={{
                                                display: "flex",
                                                gap: "0.5rem",
                                                marginBottom: "1rem",
                                                borderBottom: "2px solid rgba(255,255,255,0.1)",
                                                paddingBottom: "0.75rem",
                                                overflowX: "auto",
                                                overflowY: "hidden",
                                                scrollbarWidth: "thin",
                                                scrollbarColor: "rgba(102, 126, 234, 0.5) rgba(255,255,255,0.1)"
                                            }}>
                                                {plannedJourneys.map((journey, idx) => {
                                                    // Calculate total journey time and departure time
                                                    const firstTrip = journey[0];
                                                    const lastTrip = journey[journey.length - 1];
                                                    const totalMinutes = firstTrip?.departure_time && lastTrip?.arrival_time
                                                        ? Math.round((new Date(lastTrip.arrival_time) - new Date(firstTrip.departure_time)) / 60000)
                                                        : null;
                                                    const departTime = firstTrip?.departure_time
                                                        ? new Date(firstTrip.departure_time).toLocaleTimeString('en-AU', {
                                                            hour: '2-digit',
                                                            minute: '2-digit',
                                                            timeZone: 'Australia/Melbourne'
                                                        })
                                                        : null;

                                                    return (
                                                        <button
                                                            key={idx}
                                                            onClick={() => setSelectedJourneyIndex(idx)}
                                                            style={{
                                                                flex: 1,
                                                                minWidth: "120px",
                                                                padding: "0.5rem 0.75rem",
                                                                background: selectedJourneyIndex === idx
                                                                    ? "linear-gradient(135deg, #667eea 0%, #764ba2 100%)"
                                                                    : "rgba(255,255,255,0.05)",
                                                                border: selectedJourneyIndex === idx
                                                                    ? "2px solid rgba(102, 126, 234, 0.5)"
                                                                    : "2px solid rgba(255,255,255,0.1)",
                                                                borderRadius: "8px",
                                                                color: "white",
                                                                cursor: "pointer",
                                                                fontSize: "0.75rem",
                                                            fontWeight: selectedJourneyIndex === idx ? "600" : "400",
                                                            transition: "all 0.2s ease",
                                                            boxShadow: selectedJourneyIndex === idx
                                                                ? "0 4px 10px rgba(102, 126, 234, 0.3)"
                                                                : "none"
                                                        }}
                                                        onMouseEnter={(e) => {
                                                            if (selectedJourneyIndex !== idx) {
                                                                e.target.style.background = "rgba(255,255,255,0.08)";
                                                            }
                                                        }}
                                                        onMouseLeave={(e) => {
                                                            if (selectedJourneyIndex !== idx) {
                                                                e.target.style.background = "rgba(255,255,255,0.05)";
                                                            }
                                                        }}
                                                        >
                                                            {departTime && (
                                                                <div style={{ fontWeight: "700", fontSize: "0.85rem", color: "#ffd700" }}>
                                                                    {departTime}
                                                                </div>
                                                            )}
                                                            <div style={{ fontSize: "0.7rem", opacity: 0.8, marginTop: "0.25rem" }}>
                                                                {journey.length} leg{journey.length > 1 ? 's' : ''}
                                                                {totalMinutes && (
                                                                    <span style={{ marginLeft: "0.25rem", fontWeight: "600", color: "#fff" }}>
                                                                        • {totalMinutes} min
                                                                    </span>
                                                                )}
                                                            </div>
                                                        </button>
                                                    );
                                                })}
                                            </div>
                                        )}

                                        {/* Display selected journey */}
                                        {plannedJourneys[selectedJourneyIndex]?.map((trip, idx) => {
                                            const route = getRouteById(trip.route_id);
                                            const originStop = getStopById(trip.origin_stop_id);
                                            const destStop = getStopById(trip.destination_stop_id);
                                            return (
                                                <div key={trip.trip_id}>
                                                    <div style={{
                                                        padding: "0.875rem",
                                                        marginBottom: idx < plannedJourneys[selectedJourneyIndex].length - 1 ? "0.5rem" : "0",
                                                        background: "rgba(255,255,255,0.05)",
                                                        borderRadius: "10px",
                                                        border: `2px solid ${route?.color || "#888"}`,
                                                        boxShadow: "0 2px 8px rgba(0,0,0,0.2)"
                                                    }}>
                                                        <div style={{
                                                            display: "flex",
                                                            alignItems: "center",
                                                            gap: "0.5rem",
                                                            marginBottom: "0.5rem"
                                                        }}>
                                                            <div style={{
                                                                padding: "0.25rem 0.5rem",
                                                                background: route?.color || "#888",
                                                                borderRadius: "6px",
                                                                fontSize: "0.7rem",
                                                                fontWeight: "700",
                                                                color: "#000"
                                                            }}>
                                                                LEG {idx + 1}
                                                            </div>
                                                            <div style={{
                                                                fontWeight: "600",
                                                                fontSize: "0.9rem",
                                                                color: route?.color || "#888"
                                                            }}>
                                                                {/* For trams/buses, show route number prominently */}
                                                                {route && (route.route_type === 1 || route.route_type === 2) ? (
                                                                    <>
                                                                        <span style={{ fontWeight: "700", fontSize: "1rem" }}>
                                                                            Route {route.route_number || route.route_id}
                                                                        </span>
                                                                        {route.route_name && (
                                                                            <span style={{ fontWeight: "400", fontSize: "0.75rem", marginLeft: "0.5rem", opacity: 0.8 }}>
                                                                                {route.route_name}
                                                                            </span>
                                                                        )}
                                                                    </>
                                                                ) : (
                                                                    route?.route_name || `Route ${trip.route_id}`
                                                                )}
                                                            </div>
                                                        </div>
                                                        <div style={{
                                                            fontSize: "0.85rem",
                                                            lineHeight: "1.4",
                                                            color: "rgba(255,255,255,0.9)"
                                                        }}>
                                                            <div style={{ marginBottom: "0.25rem" }}>
                                                                <span style={{ opacity: 0.6 }}>From:</span> {originStop?.stop_name}
                                                                {trip.departure_time && (
                                                                    <span style={{
                                                                        marginLeft: "0.5rem",
                                                                        fontWeight: "600",
                                                                        color: "#667eea",
                                                                        fontSize: "0.8rem"
                                                                    }}>
                                                                        Depart: {new Date(trip.departure_time).toLocaleTimeString('en-AU', {
                                                                            hour: '2-digit',
                                                                            minute: '2-digit',
                                                                            timeZone: 'Australia/Melbourne'
                                                                        })}
                                                                    </span>
                                                                )}
                                                            </div>
                                                            <div>
                                                                <span style={{ opacity: 0.6 }}>To:</span> {destStop?.stop_name}
                                                                {trip.arrival_time && (
                                                                    <span style={{
                                                                        marginLeft: "0.5rem",
                                                                        fontWeight: "600",
                                                                        color: "#667eea",
                                                                        fontSize: "0.8rem"
                                                                    }}>
                                                                        Arrive: {new Date(trip.arrival_time).toLocaleTimeString('en-AU', {
                                                                            hour: '2-digit',
                                                                            minute: '2-digit',
                                                                            timeZone: 'Australia/Melbourne'
                                                                        })}
                                                                    </span>
                                                                )}
                                                            </div>
                                                            {trip.departure_time && trip.arrival_time && (
                                                                <div style={{
                                                                    marginTop: "0.5rem",
                                                                    paddingTop: "0.5rem",
                                                                    borderTop: "1px solid rgba(255,255,255,0.1)",
                                                                    fontSize: "0.75rem",
                                                                    color: "rgba(255,255,255,0.6)"
                                                                }}>
                                                                    Duration: {Math.round((new Date(trip.arrival_time) - new Date(trip.departure_time)) / 60000)} min
                                                                </div>
                                                            )}
                                                        </div>
                                                    </div>
                                                    {idx < plannedJourneys[selectedJourneyIndex].length - 1 && (
                                                        <div style={{
                                                            display: "flex",
                                                            alignItems: "center",
                                                            justifyContent: "center",
                                                            padding: "0.5rem 0",
                                                            fontSize: "0.75rem",
                                                            color: "#ffd700",
                                                            fontWeight: "600"
                                                        }}>
                                                            <div style={{
                                                                padding: "0.25rem 0.75rem",
                                                                background: "rgba(255, 215, 0, 0.1)",
                                                                border: "1px dashed rgba(255, 215, 0, 0.3)",
                                                                borderRadius: "6px"
                                                            }}>
                                                                ↓ TRANSFER AT {destStop?.stop_name?.toUpperCase()} ↓
                                                            </div>
                                                        </div>
                                                    )}
                                                </div>
                                            );
                                        })}
                                    </div>
                                )}
                            </div>
                        )}
                    </div>
                )}

                {/* Disruptions Toggle */}
                <button
                    onClick={() => setShowDisruptions(!showDisruptions)}
                    style={{
                        padding: "1.25rem 1.5rem",
                        background: showDisruptions ? "linear-gradient(135deg, #f093fb 0%, #f5576c 100%)" : "rgba(255,255,255,0.03)",
                        border: "none",
                        borderBottom: "1px solid rgba(255,255,255,0.08)",
                        color: "white",
                        cursor: "pointer",
                        textAlign: "left",
                        fontWeight: "700",
                        fontSize: "0.95rem",
                        transition: "all 0.3s ease",
                        display: "flex",
                        alignItems: "center",
                        gap: "0.75rem"
                    }}
                    onMouseEnter={(e) => {
                        if (!showDisruptions) e.target.style.background = "rgba(255,255,255,0.08)";
                    }}
                    onMouseLeave={(e) => {
                        if (!showDisruptions) e.target.style.background = "rgba(255,255,255,0.03)";
                    }}
                >
                    <span style={{ fontSize: "0.9rem" }}>{showDisruptions ? "▼" : "▶"}</span>
                    <span>⚠️ Service Disruptions</span>
                    {disruptions.length > 0 && (
                        <span style={{
                            marginLeft: "auto",
                            background: "#ff4757",
                            padding: "0.35rem 0.65rem",
                            borderRadius: "20px",
                            fontSize: "0.75rem",
                            fontWeight: "800",
                            boxShadow: "0 2px 8px rgba(255, 71, 87, 0.4)"
                        }}>
                            {disruptions.length}
                        </span>
                    )}
                </button>

                {/* Disruptions Section (Collapsible) */}
                {showDisruptions && (
                    <div style={{
                        padding: "1rem",
                        background: "rgba(0,0,0,0.2)",
                        borderBottom: "1px solid rgba(255,255,255,0.1)"
                    }}>
                        {disruptions.length === 0 ? (
                            <div style={{
                                padding: "2rem 1rem",
                                textAlign: "center",
                                color: "rgba(255,255,255,0.5)",
                                fontSize: "0.9rem"
                            }}>
                                ✓ No active disruptions
                            </div>
                        ) : (
                            disruptions.map((disruption, idx) => {
                                const getSeverityColor = (type) => {
                                    if (type.toLowerCase().includes('major')) return '#ff6b6b';
                                    if (type.toLowerCase().includes('minor')) return '#ffd93d';
                                    if (type.toLowerCase().includes('closure')) return '#ff4757';
                                    if (type.toLowerCase().includes('delay')) return '#ffa502';
                                    return '#6c5ce7';
                                };

                                const getRouteTypeName = (routeType) => {
                                    const types = { 0: 'Train', 1: 'Tram', 2: 'Bus', 3: 'V/Line', 4: 'Night Bus' };
                                    return types[routeType] || 'Unknown';
                                };

                                // Determine disruption status using the helper function
                                const isActive = isDisruptionActive(disruption);

                                // Check if upcoming (starts in the future)
                                const now = new Date();
                                const fromDate = disruption.from_date ? new Date(disruption.from_date) : null;
                                const isUpcoming = fromDate && fromDate > now && !isActive;

                                const color = disruption.colour || getSeverityColor(disruption.disruption_type);

                                const event = disruption.disruption_event;

                                const isSelected = selectedDisruptionId === disruption.disruption_id;

                                return (
                                    <div
                                        key={disruption.disruption_id}
                                        onClick={() => setSelectedDisruptionId(isSelected ? null : disruption.disruption_id)}
                                        style={{
                                            marginBottom: "0.75rem",
                                            padding: "0.875rem",
                                            background: isSelected ? "rgba(255,255,255,0.15)" : "rgba(255,255,255,0.05)",
                                            borderRadius: "10px",
                                            border: isSelected ? `3px solid ${color}` : `2px solid ${color}40`,
                                            borderLeft: `4px solid ${color}`,
                                            cursor: "pointer",
                                            transition: "all 0.2s ease",
                                            transform: isSelected ? "scale(1.02)" : "scale(1)"
                                        }}
                                        onMouseEnter={(e) => {
                                            if (!isSelected) e.currentTarget.style.background = "rgba(255,255,255,0.08)";
                                        }}
                                        onMouseLeave={(e) => {
                                            if (!isSelected) e.currentTarget.style.background = "rgba(255,255,255,0.05)";
                                        }}
                                    >
                                        <div style={{
                                            display: "flex",
                                            alignItems: "center",
                                            gap: "0.5rem",
                                            marginBottom: "0.5rem",
                                            flexWrap: "wrap"
                                        }}>
                                            <span style={{
                                                padding: "0.25rem 0.5rem",
                                                background: color,
                                                borderRadius: "6px",
                                                fontSize: "0.65rem",
                                                fontWeight: "700",
                                                color: "#000",
                                                textTransform: "uppercase"
                                            }}>
                                                {getRouteTypeName(disruption.route_type)}
                                            </span>
                                            <span style={{
                                                padding: "0.25rem 0.5rem",
                                                background: "rgba(255,255,255,0.1)",
                                                borderRadius: "6px",
                                                fontSize: "0.65rem",
                                                fontWeight: "600"
                                            }}>
                                                {disruption.disruption_type}
                                            </span>
                                            {isActive && (
                                                <span style={{
                                                    padding: "0.25rem 0.5rem",
                                                    background: "#ff6b6b",
                                                    borderRadius: "6px",
                                                    fontSize: "0.65rem",
                                                    fontWeight: "700",
                                                    color: "#fff",
                                                    textTransform: "uppercase"
                                                }}>
                                                    ACTIVE
                                                </span>
                                            )}
                                            {isUpcoming && (
                                                <span style={{
                                                    padding: "0.25rem 0.5rem",
                                                    background: "#ffa502",
                                                    borderRadius: "6px",
                                                    fontSize: "0.65rem",
                                                    fontWeight: "700",
                                                    color: "#fff",
                                                    textTransform: "uppercase"
                                                }}>
                                                    UPCOMING
                                                </span>
                                            )}
                                        </div>

                                        {/* Show parsed event data if available */}
                                        {event ? (
                                            <div>
                                                {/* Affected Area */}
                                                {event.affected_area && (
                                                    <div style={{
                                                        fontSize: "0.85rem",
                                                        lineHeight: "1.4",
                                                        marginBottom: "0.5rem",
                                                        color: "rgba(255,255,255,0.95)"
                                                    }}>
                                                        {event.replacement && (
                                                            <span style={{
                                                                background: "rgba(255,193,7,0.2)",
                                                                padding: "0.2rem 0.4rem",
                                                                borderRadius: "4px",
                                                                marginRight: "0.5rem",
                                                                fontSize: "0.75rem",
                                                                color: "#ffc107",
                                                                fontWeight: "600"
                                                            }}>
                                                                {event.replacement.mode.toUpperCase()} REPLACEMENT
                                                            </span>
                                                        )}
                                                        <strong>{event.affected_area.start_location}</strong>
                                                        {" → "}
                                                        <strong>{event.affected_area.end_location}</strong>
                                                    </div>
                                                )}

                                                {/* Time Period */}
                                                {event.periods && event.periods.length > 0 && (
                                                    <div style={{
                                                        fontSize: "0.75rem",
                                                        color: "rgba(255,255,255,0.7)",
                                                        marginTop: "0.5rem",
                                                        display: "flex",
                                                        flexDirection: "column",
                                                        gap: "0.25rem"
                                                    }}>
                                                        {event.periods.map((period, i) => (
                                                            <div key={i} style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                                                                <span>🕐</span>
                                                                <span>
                                                                    {period.start_datetime && new Date(period.start_datetime).toLocaleString('en-AU', {
                                                                        month: 'short',
                                                                        day: 'numeric',
                                                                        hour: 'numeric',
                                                                        minute: '2-digit',
                                                                        hour12: true,
                                                                        timeZone: 'Australia/Melbourne'
                                                                    })}
                                                                    {" → "}
                                                                    {period.is_last_service ? (
                                                                        <span style={{ color: "#ffc107" }}>Last Service</span>
                                                                    ) : period.end_datetime ? (
                                                                        new Date(period.end_datetime).toLocaleString('en-AU', {
                                                                            month: 'short',
                                                                            day: 'numeric',
                                                                            hour: 'numeric',
                                                                            minute: '2-digit',
                                                                            hour12: true,
                                                                            timeZone: 'Australia/Melbourne'
                                                                        })
                                                                    ) : "Ongoing"}
                                                                </span>
                                                            </div>
                                                        ))}
                                                    </div>
                                                )}

                                                {/* Full Description - show when selected */}
                                                {isSelected && disruption.description && (
                                                    <div style={{
                                                        fontSize: "0.8rem",
                                                        lineHeight: "1.5",
                                                        marginTop: "0.75rem",
                                                        padding: "0.75rem",
                                                        background: "rgba(0,0,0,0.3)",
                                                        borderRadius: "8px",
                                                        border: "1px solid rgba(255,255,255,0.1)",
                                                        color: "rgba(255,255,255,0.9)"
                                                    }}>
                                                        <div style={{
                                                            fontSize: "0.7rem",
                                                            textTransform: "uppercase",
                                                            letterSpacing: "0.5px",
                                                            color: "rgba(255,255,255,0.5)",
                                                            fontWeight: "600",
                                                            marginBottom: "0.5rem"
                                                        }}>
                                                            Description
                                                        </div>
                                                        {disruption.description}
                                                    </div>
                                                )}
                                            </div>
                                        ) : (
                                            /* Fallback to title if no parsed data */
                                            <>
                                                <div style={{
                                                    fontSize: "0.85rem",
                                                    lineHeight: "1.4",
                                                    marginBottom: "0.5rem",
                                                    color: "rgba(255,255,255,0.95)"
                                                }}>
                                                    {disruption.title}
                                                </div>
                                                {disruption.from_date && disruption.to_date && (
                                                    <div style={{
                                                        fontSize: "0.7rem",
                                                        color: "rgba(255,255,255,0.5)",
                                                        marginTop: "0.5rem"
                                                    }}>
                                                        {new Date(disruption.from_date).toLocaleDateString('en-AU', { timeZone: 'Australia/Melbourne' })} - {new Date(disruption.to_date).toLocaleDateString('en-AU', { timeZone: 'Australia/Melbourne' })}
                                                    </div>
                                                )}

                                                {/* Full Description - show when selected */}
                                                {isSelected && disruption.description && (
                                                    <div style={{
                                                        fontSize: "0.8rem",
                                                        lineHeight: "1.5",
                                                        marginTop: "0.75rem",
                                                        padding: "0.75rem",
                                                        background: "rgba(0,0,0,0.3)",
                                                        borderRadius: "8px",
                                                        border: "1px solid rgba(255,255,255,0.1)",
                                                        color: "rgba(255,255,255,0.9)"
                                                    }}>
                                                        <div style={{
                                                            fontSize: "0.7rem",
                                                            textTransform: "uppercase",
                                                            letterSpacing: "0.5px",
                                                            color: "rgba(255,255,255,0.5)",
                                                            fontWeight: "600",
                                                            marginBottom: "0.5rem"
                                                        }}>
                                                            Description
                                                        </div>
                                                        {disruption.description}
                                                    </div>
                                                )}
                                            </>
                                        )}
                                    </div>
                                );
                            })
                        )}
                    </div>
                )}

            </div>

            {/* Map */}
            <MapContainer
                center={[-37.8136, 144.9631]}
                zoom={12}
                style={{ height: "100%", width: "100vw" }}
                preferCanvas={true}
            >
                <TileLayer
                    url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                <ZoomListener onZoomChange={setZoom} />

                {/* Draw disrupted route segments FIRST (underneath normal routes) */}
                {disruptions
                    .filter(d => d.disruption_event?.affected_area)
                    .map((disruption) => {
                    const isActive = isDisruptionActive(disruption);
                    const now = new Date();
                    const fromDate = disruption.from_date ? new Date(disruption.from_date) : null;
                    const toDate = disruption.to_date ? new Date(disruption.to_date) : null;
                    const isUpcoming = fromDate && fromDate > now && !isActive;

                    // Check if disruption is past by checking:
                    // 1. Overall to_date is in the past
                    // 2. All periods have ended
                    let isPast = false;
                    if (toDate && toDate < now) {
                        // Check all periods to ensure they've all ended
                        if (disruption.disruption_event?.periods) {
                            const allPeriodsEnded = disruption.disruption_event.periods.every(period => {
                                if (!period.end_datetime) return false;
                                return new Date(period.end_datetime) < now;
                            });
                            isPast = allPeriodsEnded;
                        } else {
                            isPast = true;
                        }
                    }

                    // Skip past disruptions
                    if (isPast) return null;

                    const segments = getDisruptedRouteSegments(disruption);
                    if (segments.length === 0) return null; // Skip if no matching route segments found

                    const nightWorks = isNightWorks(disruption);

                    // Color scheme: red for active disruptions, orange for night works, yellow for upcoming
                    const stripeColor = isActive
                        ? (nightWorks ? "#ff8800" : "#ff0000")  // Orange for night works, red for regular
                        : "#ffaa00";  // Yellow for upcoming

                    return segments.map((segment, idx) => (
                        <React.Fragment key={`disruption-${disruption.disruption_id}-segment-${idx}`}>
                            {/* Soft glow effect */}
                            <Polyline
                                positions={segment.path}
                                color={stripeColor}
                                weight={20}
                                opacity={0.25}
                                pane="overlayPane"
                            />

                            {/* Main disrupted route line */}
                            <Polyline
                                positions={segment.path}
                                color={stripeColor}
                                weight={8}
                                opacity={0.85}
                                className={isActive ? "disruption-pulse" : ""}
                                pane="overlayPane"
                            >
                                <Tooltip>
                                    <div style={{ maxWidth: '250px' }}>
                                        <div style={{
                                            background: stripeColor,
                                            color: 'white',
                                            padding: '0.5rem',
                                            marginBottom: '0.5rem',
                                            borderRadius: '4px',
                                            fontWeight: 'bold',
                                            textAlign: 'center'
                                        }}>
                                            {isActive ? (nightWorks ? '🌙 NIGHT WORKS' : '⚠ ACTIVE DISRUPTION') : '🔔 UPCOMING DISRUPTION'}
                                        </div>
                                        <div style={{ fontSize: '0.9rem', fontWeight: '600', marginBottom: '0.25rem' }}>
                                            {segment.route_name}
                                        </div>
                                        <div style={{ fontSize: '0.85rem', color: '#666' }}>
                                            <strong>{disruption.disruption_event.affected_area.start_location}</strong>
                                            {" → "}
                                            <strong>{disruption.disruption_event.affected_area.end_location}</strong>
                                        </div>
                                        {disruption.disruption_event.replacement?.mode && (
                                            <div style={{
                                                marginTop: '0.5rem',
                                                padding: '0.25rem 0.5rem',
                                                background: '#ffc107',
                                                color: '#000',
                                                borderRadius: '4px',
                                                fontSize: '0.75rem',
                                                fontWeight: '700',
                                                textAlign: 'center'
                                            }}>
                                                {disruption.disruption_event.replacement.mode.toUpperCase()} REPLACEMENT SERVICE
                                            </div>
                                        )}
                                    </div>
                                </Tooltip>
                            </Polyline>

                            {/* Subtle white outline with dashed pattern for active disruptions */}
                            {isActive && (
                                <Polyline
                                    positions={segment.path}
                                    color="white"
                                    weight={6}
                                    opacity={0.4}
                                    dashArray="8, 12"
                                    dashOffset="0"
                                    pane="overlayPane"
                                />
                            )}
                        </React.Fragment>
                    ));
                })}

                {/* Draw routes ON TOP - only show selected or all if none selected */}
                {/* Render order: V/Line first (bottom), Train second, Tram third, Bus last (top) */}
                {(() => {
                    const renderPriority = { 3: 0, 0: 1, 1: 2, 2: 3 }; // V/Line, Train, Tram, Bus
                    return [...routes].sort((a, b) => renderPriority[a.route_type] - renderPriority[b.route_type]);
                })().map(r => {
                    const isVisible = isRouteVisible(r.route_id);
                    const isSelected = selectedRoutes.has(r.route_id);

                    if (!isVisible) return null;

                    // Check if this is a V/Line coach route
                    // V/Line trains: Geelong, Ballarat, Bendigo, Traralgon, Seymour, Pakenham
                    // V/Line coaches: Ararat, Maryborough, Swan Hill, Echuca, Shepparton, Bairnsdale, Warrnambool, Albury
                    const coachRouteIds = ['1-ART', '1-MBY', '1-SWL', '1-ECH', '1-SNH', '1-BDE', '1-WBL', '1-ABY'];
                    const isCoach = r.route_type === 3 && r.route_gtfs_id && coachRouteIds.includes(r.route_gtfs_id);

                    // Line thickness: V/Line thickest, trains and trams doubled
                    const lineWeight = r.route_type === 3
                        ? (isSelected ? 12 : 6)     // V/Line: thickest
                        : r.route_type === 0
                        ? (isSelected ? 16 : 8)     // Trains: doubled
                        : r.route_type === 1
                        ? (isSelected ? 12 : 6)     // Trams: doubled
                        : (isSelected ? 6 : 3);     // Buses: normal

                    // Show all geopaths for all route types (including Altona loop for Werribee, etc.)
                    if (!r.coords || r.coords.length === 0) return null;

                    return r.coords.map((path, pathIdx) => (
                        path.length > 1 && (
                            <Polyline
                                key={`${r.route_id}-path-${pathIdx}`}
                                positions={path}
                                color={r.color}
                                weight={lineWeight}
                                opacity={1}
                                dashArray={isCoach ? "10, 8" : undefined}
                            >
                                <Tooltip permanent={false} sticky={true}>
                                    {r.route_name.split('(')[0].trim()}
                                    {isCoach && <span style={{ fontSize: '0.8em', opacity: 0.8 }}> (Coach)</span>}
                                </Tooltip>
                            </Polyline>
                        )
                    ));
                })}

                {/* Draw planned journey routes - consistent color for entire trip */}
                {plannedJourneys && plannedJourneys[selectedJourneyIndex]?.map((trip, tripIdx) => {
                    const geopath = trip.geopath || trip.geo_path || [];

                    if (geopath.length < 2) return null;

                    // Check if this trip segment is affected by any disruption
                    const affectedByDisruption = disruptions.find(d => {
                        if (!d.disruption_event?.affected_area) return false;

                        const { start_location, end_location } = d.disruption_event.affected_area;
                        const originStop = getStopById(trip.origin_stop_id);
                        const destStop = getStopById(trip.destination_stop_id);

                        if (!originStop || !destStop) return false;

                        const normalizeLocation = (name) => {
                            if (!name) return '';
                            return name.toLowerCase()
                                .replace(' station', '')
                                .replace(' railway station', '')
                                .trim();
                        };

                        const normalizedStart = normalizeLocation(start_location);
                        const normalizedEnd = normalizeLocation(end_location);
                        const normalizedOrigin = normalizeLocation(originStop.stop_name);
                        const normalizedDest = normalizeLocation(destStop.stop_name);

                        // Check if trip segment overlaps with disrupted area (skip if missing location data)
                        if (!normalizedStart || !normalizedEnd) return false;

                        return (
                            (normalizedOrigin.includes(normalizedStart) || normalizedStart.includes(normalizedOrigin)) ||
                            (normalizedDest.includes(normalizedEnd) || normalizedEnd.includes(normalizedDest)) ||
                            (normalizedOrigin.includes(normalizedEnd) || normalizedEnd.includes(normalizedOrigin)) ||
                            (normalizedDest.includes(normalizedStart) || normalizedStart.includes(normalizedDest))
                        );
                    });

                    const isActiveDisruption = affectedByDisruption && isDisruptionActive(affectedByDisruption);

                    // Use consistent bright cyan for planned trips, red if disrupted
                    const tripColor = isActiveDisruption ? "#ff0000" : "#00d4ff";

                    return (
                        <React.Fragment key={`trip-${trip.trip_id}`}>
                            {/* White outline for better visibility - render first (bottom) */}
                            <Polyline
                                positions={geopath.map(p => [p.lat, p.lon])}
                                color="white"
                                weight={9}
                                opacity={0.4}
                                pane="overlayPane"
                            />

                            {/* Main trip path - render on top of outline */}
                            <Polyline
                                positions={geopath.map(p => [p.lat, p.lon])}
                                color={tripColor}
                                weight={7}
                                opacity={0.9}
                                pane="overlayPane"
                            />

                            {/* Animated dashes if disrupted - render on top */}
                            {isActiveDisruption && (
                                <Polyline
                                    positions={geopath.map(p => [p.lat, p.lon])}
                                    color="white"
                                    weight={5}
                                    opacity={0.6}
                                    dashArray="10, 15"
                                    pane="overlayPane"
                                />
                            )}
                        </React.Fragment>
                    );
                })}

                {/* Draw stops */}
                {(() => {
                    // Different zoom thresholds for different transport types
                    // Tram stops disappear first (zoom < 13)
                    // Train stops disappear second (zoom < 11)
                    // V/Line stops always visible (or zoom < 9)

                    // Group tram stops that are very close together
                    const groupedStops = new Map();
                    stops.forEach(s => {
                        // Filter based on zoom level and route type
                        if (s.route_type === 1 && zoom < 13) return; // Trams disappear first
                        if (s.route_type === 0 && zoom < 11) return; // Trains disappear second
                        // V/Line (route_type === 3) NEVER disappears
                        if (s.route_type === 2 && zoom < 12) return; // Buses

                        if (s.route_type === 1) {
                            const key = `${Math.round(s.lat * 1000)}:${Math.round(s.lng * 1000)}`;
                            if (!groupedStops.has(key)) {
                                groupedStops.set(key, s);
                            }
                        } else {
                            groupedStops.set(`${s.stop_id}`, s);
                        }
                    });

                    return Array.from(groupedStops.values()).map(s => {
                    // Check if this stop is part of the selected journey
                    const isOnPlannedRoute = plannedJourneys?.[selectedJourneyIndex]?.some(trip =>
                        trip.origin_stop_id === s.stop_id || trip.destination_stop_id === s.stop_id
                    );

                    // Check if this stop is affected by a disruption (current or upcoming)
                    const affectedByDisruption = disruptions.find(d => {
                        if (!d.disruption_event?.affected_area) return false;

                        const area = d.disruption_event.affected_area;
                        return s.stop_name.toLowerCase().includes(area.start_location?.toLowerCase() || '') ||
                               s.stop_name.toLowerCase().includes(area.end_location?.toLowerCase() || '') ||
                               area.start_location?.toLowerCase().includes(s.stop_name.toLowerCase().replace(' station', '')) ||
                               area.end_location?.toLowerCase().includes(s.stop_name.toLowerCase().replace(' station', ''));
                    });

                    const isActiveDisruption = affectedByDisruption && isDisruptionActive(affectedByDisruption);
                    const now = new Date();
                    const fromDate = affectedByDisruption?.from_date ? new Date(affectedByDisruption.from_date) : null;
                    const isUpcomingDisruption = affectedByDisruption &&
                        fromDate && fromDate > now && !isActiveDisruption;

                    // Get default colors based on stop's route_type
                    const defaultFillColors = {
                        0: "yellow",     // Train - yellow
                        1: "#00d4ff",    // Tram - cyan
                        2: "#ff8c42",    // Bus - orange
                        3: "#b19cd9"     // V/Line - light purple
                    };
                    const defaultFillColor = defaultFillColors[s.route_type] || "yellow";

                    // Size multiplier based on route_type
                    // All sizes significantly increased for better visibility
                    const sizeMultiplier = s.route_type === 1 ? 0.3 :   // Tram - 30% of train size (halved from 60%)
                                          s.route_type === 2 ? 0.7 :   // Bus - 70% of train size
                                          s.route_type === 3 ? 1.5 :   // V/Line - 150% larger (regional stations)
                                          1.0;                          // Train - base size (100%)

                    // Check if this stop is the selected origin or destination
                    const isOriginStop = s.stop_id === selectedOriginStopId;
                    const isDestinationStop = s.stop_id === selectedDestinationStopId;

                    const fillColor = isActiveDisruption ? "#ff6b6b" :
                                      isUpcomingDisruption ? "#ffa502" :
                                      isOnPlannedRoute ? "#00ff00" : defaultFillColor;

                    // Bus stops: no border (match fill color), fixed size to prevent lag
                    // Origin/Destination: distinctive thick outlines (blue for origin, red for destination)
                    // Other stops: black border, dynamic size based on zoom
                    const color = isOriginStop ? "#0066ff" :  // Bright blue for origin
                                  isDestinationStop ? "#ff0066" :  // Bright red for destination
                                  isActiveDisruption ? "#ff6b6b" :
                                  isUpcomingDisruption ? "#ffa502" :
                                  isOnPlannedRoute ? "#00ff00" :
                                  s.route_type === 2 ? fillColor : "black";

                    // Origin/Destination: thicker border weight for visibility
                    const weight = isOriginStop || isDestinationStop ? 4 :
                                   s.route_type === 1 ? 0.5 : 1;

                    // Bus stops: fixed 40m radius to prevent lag (increased from 30m for visibility)
                    // Origin/Destination: fixed larger radius (80m) to ensure they're always visible at any zoom
                    // All other stops: scale dynamically with zoom using getRadius() * sizeMultiplier
                    const baseRadius = s.route_type === 2 ? 40 :
                                      isOriginStop || isDestinationStop ? 80 :
                                      (getRadius(zoom) * sizeMultiplier);
                    const radius = isOnPlannedRoute ? baseRadius * 1.5 : baseRadius;

                    return (
                        <Circle
                            key={s.stop_id}
                            center={[s.lat, s.lng]}
                            radius={radius}
                            color={color}
                            weight={weight}
                            fillColor={fillColor}
                            fillOpacity={1.0}
                            pane="markerPane"
                        >
                            <Tooltip direction="top" offset={[0, -10]} opacity={1} permanent={false}>
                                <div>
                                    <strong>{s.stop_name}</strong><br />
                                    {s.stop_suburb && <span>{s.stop_suburb}<br /></span>}
                                    {s.stop_landmark && <span>{s.stop_landmark}</span>}
                                    {isOriginStop && (
                                        <span style={{ color: '#0066ff', fontWeight: 'bold' }}>
                                            <br />📍 Origin Station
                                        </span>
                                    )}
                                    {isDestinationStop && (
                                        <span style={{ color: '#ff0066', fontWeight: 'bold' }}>
                                            <br />🎯 Destination Station
                                        </span>
                                    )}
                                    {isActiveDisruption && (
                                        <span style={{ color: '#ff6b6b', fontWeight: 'bold' }}>
                                            <br />⚠ Active Disruption
                                        </span>
                                    )}
                                    {isUpcomingDisruption && (
                                        <span style={{ color: '#ffa502', fontWeight: 'bold' }}>
                                            <br />🔔 Upcoming Disruption
                                        </span>
                                    )}
                                </div>
                            </Tooltip>
                        </Circle>
                    );
                    });
                })()}

                {/* Disruption Warning Markers */}
                {(() => {
                    // Create custom warning icons based on severity
                    const createDisruptionIcon = (color, isActive) => {
                        return L.divIcon({
                            html: `<div style="
                                width: 32px;
                                height: 32px;
                                background: ${color};
                                border: 3px solid white;
                                border-radius: 50%;
                                display: flex;
                                align-items: center;
                                justify-content: center;
                                font-size: 18px;
                                box-shadow: 0 4px 12px rgba(0,0,0,0.4);
                                ${isActive ? 'animation: pulse 2s infinite;' : ''}
                            ">⚠</div>
                            <style>
                                @keyframes pulse {
                                    0%, 100% { transform: scale(1); }
                                    50% { transform: scale(1.15); }
                                }
                            </style>`,
                            className: 'disruption-marker',
                            iconSize: [32, 32],
                            iconAnchor: [16, 16]
                        });
                    };

                    const getSeverityColor = (type) => {
                        if (type.toLowerCase().includes('major')) return '#ff0000';
                        if (type.toLowerCase().includes('minor')) return '#ffaa00';
                        if (type.toLowerCase().includes('closure')) return '#cc0000';
                        if (type.toLowerCase().includes('delay')) return '#ff8c00';
                        return '#ff6b6b';
                    };

                    const getRouteTypeName = (routeType) => {
                        const types = { 0: 'Train', 1: 'Tram', 2: 'Bus', 3: 'V/Line', 4: 'Night Bus' };
                        return types[routeType] || 'Unknown';
                    };

                    // Filter disruptions that have affected areas (already filtered by selected route types)
                    const activeDisruptions = disruptions.filter(d => d.disruption_event?.affected_area);

                    return activeDisruptions.map(disruption => {
                        const { start_location, end_location } = disruption.disruption_event.affected_area;

                        // Normalize location name for better matching
                        const normalizeLocation = (name) => {
                            if (!name) return '';
                            return name.toLowerCase()
                                .replace(' station', '')
                                .replace(' railway station', '')
                                .trim();
                        };

                        const normalizedStart = normalizeLocation(start_location);

                        // Find the start stop - match by route_type first, prefer exact Station matches
                        let startStop = stops.find(s => {
                            if (s.route_type !== disruption.route_type) return false;
                            const normalizedStopName = normalizeLocation(s.stop_name);
                            // Exact match for stations (e.g., "Geelong Station")
                            if (s.stop_name.toLowerCase().includes('station') &&
                                normalizedStopName === normalizedStart) {
                                return true;
                            }
                            // Partial match
                            return normalizedStopName.includes(normalizedStart) ||
                                   normalizedStart.includes(normalizedStopName);
                        });

                        if (!startStop) return null;

                        const isActive = isDisruptionActive(disruption);

                        // Color based on route type and severity
                        const getDisruptionColor = () => {
                            // V/Line disruptions are purple
                            if (disruption.route_type === 3) return '#b19cd9';
                            // Otherwise use severity color
                            return getSeverityColor(disruption.disruption_type);
                        };

                        const color = getDisruptionColor();
                        const icon = createDisruptionIcon(color, isActive);

                        const event = disruption.disruption_event;

                        return (
                            <Marker
                                key={`disruption-marker-${disruption.disruption_id}`}
                                position={[startStop.lat, startStop.lng]}
                                icon={icon}
                                zIndexOffset={1000}
                            >
                                <Popup maxWidth={300}>
                                    <div style={{ padding: '0.5rem' }}>
                                        <div style={{
                                            display: 'flex',
                                            gap: '0.5rem',
                                            marginBottom: '0.5rem',
                                            flexWrap: 'wrap'
                                        }}>
                                            <span style={{
                                                padding: '0.25rem 0.5rem',
                                                background: color,
                                                borderRadius: '4px',
                                                fontSize: '0.7rem',
                                                fontWeight: '700',
                                                color: 'white'
                                            }}>
                                                {getRouteTypeName(disruption.route_type)}
                                            </span>
                                            <span style={{
                                                padding: '0.25rem 0.5rem',
                                                background: '#6c757d',
                                                borderRadius: '4px',
                                                fontSize: '0.7rem',
                                                fontWeight: '600',
                                                color: 'white'
                                            }}>
                                                {disruption.disruption_type}
                                            </span>
                                            {isActive && (
                                                <span style={{
                                                    padding: '0.25rem 0.5rem',
                                                    background: '#ff0000',
                                                    borderRadius: '4px',
                                                    fontSize: '0.7rem',
                                                    fontWeight: '700',
                                                    color: 'white'
                                                }}>
                                                    ACTIVE NOW
                                                </span>
                                            )}
                                        </div>

                                        {event.affected_area && (
                                            <div style={{
                                                fontSize: '0.85rem',
                                                fontWeight: '600',
                                                marginBottom: '0.5rem',
                                                color: '#333'
                                            }}>
                                                {event.replacement?.mode && (
                                                    <span style={{
                                                        background: '#ffc107',
                                                        padding: '0.15rem 0.4rem',
                                                        borderRadius: '3px',
                                                        marginRight: '0.5rem',
                                                        fontSize: '0.7rem',
                                                        color: '#000',
                                                        fontWeight: '700'
                                                    }}>
                                                        {event.replacement.mode.toUpperCase()} REPLACEMENT
                                                    </span>
                                                )}
                                                <strong>{event.affected_area.start_location}</strong>
                                                {" → "}
                                                <strong>{event.affected_area.end_location}</strong>
                                            </div>
                                        )}

                                        {event.periods && event.periods.length > 0 && (
                                            <div style={{
                                                fontSize: '0.75rem',
                                                color: '#666',
                                                marginTop: '0.5rem',
                                                borderTop: '1px solid #ddd',
                                                paddingTop: '0.5rem'
                                            }}>
                                                {event.periods.map((period, i) => (
                                                    <div key={i} style={{ marginBottom: '0.25rem' }}>
                                                        <strong>🕐</strong>{' '}
                                                        {period.start_datetime && new Date(period.start_datetime).toLocaleString('en-AU', {
                                                            month: 'short',
                                                            day: 'numeric',
                                                            hour: 'numeric',
                                                            minute: '2-digit',
                                                            hour12: true,
                                                            timeZone: 'Australia/Melbourne'
                                                        })}
                                                        {" → "}
                                                        {period.is_last_service ? (
                                                            <span style={{ color: '#ff8c00', fontWeight: '600' }}>Last Service</span>
                                                        ) : period.end_datetime ? (
                                                            new Date(period.end_datetime).toLocaleString('en-AU', {
                                                                month: 'short',
                                                                day: 'numeric',
                                                                hour: 'numeric',
                                                                minute: '2-digit',
                                                                hour12: true,
                                                                timeZone: 'Australia/Melbourne'
                                                            })
                                                        ) : "Ongoing"}
                                                    </div>
                                                ))}
                                            </div>
                                        )}

                                        {/* Full description */}
                                        {disruption.description && (
                                            <div style={{
                                                fontSize: '0.8rem',
                                                color: '#333',
                                                marginTop: '0.75rem',
                                                padding: '0.5rem',
                                                background: '#f8f9fa',
                                                borderRadius: '6px',
                                                borderLeft: `3px solid ${color}`,
                                                lineHeight: '1.4'
                                            }}>
                                                {disruption.description}
                                            </div>
                                        )}
                                    </div>
                                </Popup>
                            </Marker>
                        );
                    });
                })()}

                {/* Render station facility disruptions with info icons */}
                {(() => {
                    const createStationInfoIcon = (isActive) => {
                        return L.divIcon({
                            html: `<div style="
                                width: 28px;
                                height: 28px;
                                background: #3b82f6;
                                border: 3px solid white;
                                border-radius: 50%;
                                display: flex;
                                align-items: center;
                                justify-content: center;
                                font-size: 16px;
                                font-weight: bold;
                                color: white;
                                box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
                                ${isActive ? 'animation: pulse 2s infinite;' : ''}
                            ">ℹ</div>`,
                            className: 'station-info-icon',
                            iconSize: [28, 28],
                            iconAnchor: [14, 14],
                            popupAnchor: [0, -14]
                        });
                    };

                    const getRouteTypeName = (routeType) => {
                        const types = { 0: 'Train', 1: 'Tram', 2: 'Bus', 3: 'V/Line', 4: 'Night Bus' };
                        return types[routeType] || 'Unknown';
                    };

                    const stationDisruptions = disruptions.filter(d =>
                        d.disruption_event?.event_type === 'station_facility' &&
                        d.disruption_event?.affected_area
                    );

                    return stationDisruptions.map(disruption => {
                        const { start_location, facility } = disruption.disruption_event.affected_area;

                        // Normalize location name
                        const normalizeLocation = (name) => {
                            if (!name) return '';
                            return name.toLowerCase()
                                .replace(' station', '')
                                .replace(' railway station', '')
                                .trim();
                        };

                        const normalizedStation = normalizeLocation(start_location);

                        // Find the station - match by route_type and name
                        let station = stops.find(s => {
                            if (s.route_type !== disruption.route_type) return false;
                            const normalizedStopName = normalizeLocation(s.stop_name);
                            // Exact match for stations
                            if (s.stop_name.toLowerCase().includes('station') &&
                                normalizedStopName === normalizedStation) {
                                return true;
                            }
                            // Partial match
                            return normalizedStopName.includes(normalizedStation) ||
                                   normalizedStation.includes(normalizedStopName);
                        });

                        if (!station) return null;

                        const isActive = isDisruptionActive(disruption);
                        const icon = createStationInfoIcon(isActive);

                        return (
                            <Marker
                                key={`station-disruption-${disruption.disruption_id}`}
                                position={[station.lat, station.lng]}
                                icon={icon}
                                zIndexOffset={1100}
                            >
                                <Popup maxWidth={300}>
                                    <div style={{ padding: '0.5rem' }}>
                                        <div style={{
                                            display: 'flex',
                                            gap: '0.5rem',
                                            marginBottom: '0.5rem',
                                            flexWrap: 'wrap'
                                        }}>
                                            <span style={{
                                                padding: '0.25rem 0.5rem',
                                                background: '#3b82f6',
                                                borderRadius: '4px',
                                                fontSize: '0.7rem',
                                                fontWeight: '700',
                                                color: 'white'
                                            }}>
                                                STATION FACILITY
                                            </span>
                                            <span style={{
                                                padding: '0.25rem 0.5rem',
                                                background: '#10b981',
                                                borderRadius: '4px',
                                                fontSize: '0.7rem',
                                                fontWeight: '700',
                                                color: 'white'
                                            }}>
                                                {getRouteTypeName(disruption.route_type)}
                                            </span>
                                        </div>

                                        <div style={{
                                            fontSize: '0.85rem',
                                            fontWeight: '600',
                                            marginBottom: '0.5rem',
                                            color: '#333'
                                        }}>
                                            {start_location}
                                        </div>

                                        {facility && (
                                            <div style={{
                                                fontSize: '0.75rem',
                                                color: '#666',
                                                marginBottom: '0.5rem',
                                                background: '#f0f0f0',
                                                padding: '0.25rem 0.5rem',
                                                borderRadius: '4px'
                                            }}>
                                                <strong>Affected:</strong> {facility.charAt(0).toUpperCase() + facility.slice(1)}
                                            </div>
                                        )}

                                        {/* Full description */}
                                        {disruption.description && (
                                            <div style={{
                                                fontSize: '0.8rem',
                                                color: '#333',
                                                marginTop: '0.5rem',
                                                padding: '0.5rem',
                                                background: '#f8f9fa',
                                                borderRadius: '6px',
                                                borderLeft: '3px solid #3b82f6',
                                                lineHeight: '1.4'
                                            }}>
                                                {disruption.description}
                                            </div>
                                        )}
                                    </div>
                                </Popup>
                            </Marker>
                        );
                    });
                })()}

            </MapContainer>
        </div>
        </>
    );
}
