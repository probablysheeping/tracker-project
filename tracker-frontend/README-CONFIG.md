# Quick Configuration Guide

## Change API URL (Localhost → Server)

**Only one file to edit:** `.env.production`

```bash
# Open this file:
tracker-frontend/.env.production

# Change this line:
VITE_API_URL=http://YOUR_SERVER_IP:5000

# Examples:
VITE_API_URL=http://192.168.1.100:5000     # Local network
VITE_API_URL=http://123.45.67.89:5000      # Public IP
VITE_API_URL=https://api.mydomain.com      # Custom domain
```

## How It Works

The app uses different environment files for different builds:

- **Development** (`npm run dev`): Uses `.env.development` → `http://localhost:5000`
- **Production** (`npm run build`): Uses `.env.production` → Your server URL

All API calls in `App.jsx` now use `API_BASE_URL` from `config.js`, which reads the environment variable.

## Build for GitHub Pages

1. Update `.env.production` with your server IP
2. Run build:
   ```bash
   npm run build
   ```
3. The `dist/` folder contains your static site
4. GitHub Actions will do this automatically when you push

## Test Production Build Locally

```bash
npm run build
npm run preview
```

Visit http://localhost:4173 to test with your production API URL.

## Files Changed

- ✅ `src/config.js` - Centralized API URL configuration
- ✅ `src/App.jsx` - All fetch calls now use `API_BASE_URL`
- ✅ `.env.development` - Dev environment (localhost)
- ✅ `.env.production` - Production environment (your server)
- ✅ `.env.example` - Template for others
- ✅ `.github/workflows/deploy.yml` - Auto-deployment to GitHub Pages
- ✅ `vite.config.js` - Base path configuration

## Full Deployment Guide

See **DEPLOYMENT.md** for complete step-by-step instructions.
