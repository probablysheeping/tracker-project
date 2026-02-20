# API Verification System

This document explains how to configure and use the API verification system for the PTV Tracker backend.

## Features

### 1. Health Check Endpoints

Three health check endpoints are available to verify API status:

#### Basic Health Check
```bash
GET /api/health
```

Returns:
```json
{
  "status": "healthy",
  "timestamp": "2026-02-17T10:30:00Z",
  "uptime": "0d 2h 15m 30s",
  "service": "PTV Tracker API",
  "version": "1.0.0",
  "environment": "Development"
}
```

#### Detailed Health Check
```bash
GET /api/health/detailed
```

Returns comprehensive system status including:
- Database connectivity and response time
- PTV API credentials status
- API key authentication status
- CORS configuration

Example response:
```json
{
  "status": "healthy",
  "timestamp": "2026-02-17T10:30:00Z",
  "uptime": "0d 2h 15m 30s",
  "service": "PTV Tracker API",
  "version": "1.0.0",
  "environment": "Production",
  "checks": {
    "database": {
      "status": "healthy",
      "response_time_ms": 15,
      "host": "localhost",
      "port": 5432,
      "database": "tracker"
    },
    "ptv_credentials": {
      "status": "configured",
      "user_id_present": true,
      "api_key_present": true
    },
    "api_key_auth": {
      "enabled": true,
      "header": "X-API-Key"
    },
    "cors": {
      "mode": "Restricted",
      "allowed_origins": ["https://probablysheeping.github.io"]
    }
  }
}
```

#### Ping Endpoint
```bash
GET /api/health/ping
```

Simple uptime check that returns:
```json
{
  "message": "pong",
  "timestamp": "2026-02-17T10:30:00Z"
}
```

### 2. API Key Authentication

Protect your API endpoints with API key authentication.

#### Configuration

Edit `appsettings.json` or `appsettings.Production.json`:

```json
{
  "ApiVerification": {
    "EnableApiKeyAuth": true,
    "ApiKeys": [
      "your-secure-api-key-1",
      "your-secure-api-key-2"
    ],
    "ApiKeyHeader": "X-API-Key"
  }
}
```

**Options:**
- `EnableApiKeyAuth`: Set to `true` to enable, `false` to disable
- `ApiKeys`: Array of valid API keys (generate secure random strings)
- `ApiKeyHeader`: Header name for API key (default: `X-API-Key`)

#### Usage

When API key authentication is enabled, all requests (except `/api/health`) must include the API key header:

```bash
curl -H "X-API-Key: your-secure-api-key-1" \
  http://localhost:5000/api/PTV/routes/0
```

**Exempt Endpoints:**
- `/api/health` - Always accessible for monitoring
- `/api/health/detailed` - Always accessible
- `/api/health/ping` - Always accessible
- `/swagger` - Accessible in development mode

### 3. CORS Configuration

Control which origins can access your API.

#### Configuration

Edit `appsettings.json`:

```json
{
  "Cors": {
    "Mode": "AllowAll",
    "AllowedOrigins": [
      "https://probablysheeping.github.io",
      "http://localhost:5173"
    ]
  }
}
```

**Modes:**

**AllowAll** (Development/Testing):
- Allows requests from any origin
- Use for local development or testing
- Not recommended for production

```json
"Cors": {
  "Mode": "AllowAll"
}
```

**Restricted** (Production):
- Only allows requests from specified origins
- Use for production deployments
- Supports credentials (cookies, authorization headers)

```json
"Cors": {
  "Mode": "Restricted",
  "AllowedOrigins": [
    "https://probablysheeping.github.io",
    "https://yourdomain.com"
  ]
}
```

## Quick Configuration Guide

### Development Setup

Use `appsettings.json`:

```json
{
  "ApiVerification": {
    "EnableApiKeyAuth": false
  },
  "Cors": {
    "Mode": "AllowAll"
  }
}
```

This allows unrestricted access for local development.

### Production Setup

Use `appsettings.Production.json`:

```json
{
  "ApiVerification": {
    "EnableApiKeyAuth": true,
    "ApiKeys": [
      "your-production-api-key"
    ]
  },
  "Cors": {
    "Mode": "Restricted",
    "AllowedOrigins": [
      "https://probablysheeping.github.io"
    ]
  }
}
```

### Switching Between Configurations

The API automatically uses the correct configuration based on the environment:

**Development:**
```bash
dotnet run
# Uses appsettings.json
```

**Production:**
```bash
dotnet run --configuration Release
# Uses appsettings.Production.json
```

Or set the environment variable:
```bash
export ASPNETCORE_ENVIRONMENT=Production
dotnet run
```

## Database Configuration

Configure database connection in `appsettings.json`:

```json
{
  "Database": {
    "Host": "localhost",
    "Port": 5432,
    "Username": "postgres",
    "Password": "password",
    "Database": "tracker"
  }
}
```

**For production**, update `appsettings.Production.json` with your server details:

```json
{
  "Database": {
    "Host": "your-server-ip",
    "Port": 5432,
    "Username": "postgres",
    "Password": "your-secure-password",
    "Database": "tracker"
  }
}
```

**Security Note:** For production, consider using environment variables or Azure Key Vault instead of storing passwords in config files.

## Updating Frontend API URL

When you deploy to a remote server, update the frontend to point to your server:

**File:** `tracker-frontend/.env.production`

```bash
VITE_API_URL=https://your-server-ip:5000
```

Or if using a domain:
```bash
VITE_API_URL=https://api.yourdomain.com
```

Then rebuild the frontend:
```bash
cd tracker-frontend
npm run build
```

## Monitoring and Testing

### Test Health Endpoints

```bash
# Basic health check
curl http://localhost:5000/api/health

# Detailed health check
curl http://localhost:5000/api/health/detailed

# Ping
curl http://localhost:5000/api/health/ping
```

### Test API Key Authentication

```bash
# Without API key (should fail if enabled)
curl http://localhost:5000/api/PTV/routes/0

# With valid API key (should succeed)
curl -H "X-API-Key: your-api-key" \
  http://localhost:5000/api/PTV/routes/0
```

### Test CORS

```bash
# Check CORS headers
curl -H "Origin: https://probablysheeping.github.io" \
  -H "Access-Control-Request-Method: GET" \
  -X OPTIONS \
  http://localhost:5000/api/PTV/routes/0 \
  -v
```

## Startup Output

When the API starts, you'll see configuration details:

```
=== PTV Tracker API Configuration ===
CORS Mode: Restricted
API Key Auth: ENABLED
Environment: Production
Health Check: /api/health
=====================================
```

## Generating Secure API Keys

Use these methods to generate secure API keys:

**PowerShell:**
```powershell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```

**Linux/Mac:**
```bash
openssl rand -base64 32
```

**Online (use with caution):**
- https://www.uuidgenerator.net/api/guid

## Troubleshooting

### Health Check Returns Unhealthy Database

**Problem:** Database connection fails

**Solution:**
1. Check database is running: `systemctl status postgresql`
2. Verify connection settings in `appsettings.json`
3. Test connection: `psql -h localhost -U postgres -d tracker`

### API Key Authentication Not Working

**Problem:** Requests fail even with valid API key

**Solution:**
1. Check `EnableApiKeyAuth` is `true` in config
2. Verify API key is in the `ApiKeys` array
3. Check header name matches `ApiKeyHeader` setting
4. Look at console logs for authentication attempts

### CORS Errors in Browser

**Problem:** Browser blocks requests with CORS error

**Solution:**
1. Check `Cors:Mode` in `appsettings.json`
2. Verify frontend origin is in `AllowedOrigins` array
3. For development, temporarily set `Mode: "AllowAll"`
4. Check browser console for specific CORS error details

## Security Best Practices

1. **Never commit API keys to Git** - Use `.gitignore` for `appsettings.Production.json`
2. **Use strong, random API keys** - Minimum 32 characters
3. **Enable HTTPS in production** - Use reverse proxy (nginx/caddy)
4. **Restrict CORS to known origins** - Don't use `AllowAll` in production
5. **Rotate API keys regularly** - Update keys periodically
6. **Monitor health endpoints** - Set up uptime monitoring
7. **Use environment variables** - For sensitive production settings
8. **Keep PTV credentials in user secrets** - Don't store in config files
