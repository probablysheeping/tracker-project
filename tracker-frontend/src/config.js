// API Configuration
// This uses Vite's environment variables
// In development: uses localhost
// In production: uses the environment variable VITE_API_URL

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000';
const API_USERNAME = import.meta.env.VITE_API_USERNAME || 'frontend';
const API_KEY = import.meta.env.VITE_API_KEY || 'dev-key-12345';

// Helper function to create headers with authentication
export const getAuthHeaders = () => {
    return {
        'Content-Type': 'application/json',
        'X-Username': API_USERNAME,
        'X-API-Key': API_KEY
    };
};

// Helper function for authenticated fetch
export const authenticatedFetch = async (url, options = {}) => {
    const headers = {
        ...getAuthHeaders(),
        ...(options.headers || {})
    };

    return fetch(url, {
        ...options,
        headers
    });
};

export { API_BASE_URL, API_USERNAME, API_KEY };
