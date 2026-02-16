// API Configuration
// This uses Vite's environment variables
// In development: uses localhost
// In production: uses the environment variable VITE_API_URL

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000';

export { API_BASE_URL };
