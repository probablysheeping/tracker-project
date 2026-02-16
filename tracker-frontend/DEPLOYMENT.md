# Deployment Guide - PTV Tracker to GitHub Pages

This guide explains how to deploy the frontend to GitHub Pages while hosting the backend on a separate server.

## Quick Setup - Change API URL

To change from localhost to your server IP, **just edit one file**:

**File:** `.env.production`

```bash
# Change this line:
VITE_API_URL=http://YOUR_SERVER_IP:5000

# Example with IP:
VITE_API_URL=http://192.168.1.100:5000

# Example with domain:
VITE_API_URL=https://api.yourdomain.com
```

That's it! The app will automatically use this URL when you build for production.

---

## Full Deployment Steps

### 1. Prepare Your Repository

1. Create a new GitHub repository (e.g., `ptv-tracker`)
2. Initialize git in the `tracker-frontend` folder (if not already done):
   ```bash
   cd tracker-frontend
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git push -u origin main
   ```

### 2. Configure Repository for GitHub Pages

1. Go to your GitHub repository
2. Navigate to **Settings** → **Pages**
3. Under **Build and deployment**:
   - Source: **GitHub Actions**
   - (Don't select "Deploy from a branch")

### 3. Set Your API URL as a Secret

1. In your GitHub repo, go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `VITE_API_URL`
4. Value: Your backend server URL (e.g., `http://YOUR_SERVER_IP:5000`)
5. Click **Add secret**

### 4. Configure Base Path (if needed)

If your repository is NOT deployed at the root (e.g., username.github.io/repo-name):

**Edit `vite.config.js`:**
```javascript
export default defineConfig({
  plugins: [react()],
  base: '/YOUR_REPO_NAME/',  // e.g., '/ptv-tracker/'
})
```

If you're using a custom domain or deploying to `username.github.io`, keep `base: '/'`.

### 5. Deploy

Push to the `main` branch, and GitHub Actions will automatically build and deploy:

```bash
git push origin main
```

Or manually trigger deployment:
1. Go to **Actions** tab in GitHub
2. Select **Deploy to GitHub Pages**
3. Click **Run workflow**

Your site will be live at:
- `https://YOUR_USERNAME.github.io/YOUR_REPO/` (if using repo path)
- `https://YOUR_USERNAME.github.io/` (if using root)
- `https://yourdomain.com/` (if using custom domain)

---

## Backend Server Setup

Your backend needs to be hosted on a server (VPS, cloud instance, etc.) that's accessible from the internet.

### Backend Requirements:
- ✅ .NET 9.0 runtime
- ✅ PostgreSQL database (accessible from backend)
- ✅ PTV API credentials configured via User Secrets
- ✅ CORS enabled (already configured in `Program.cs`)
- ✅ Port 5000 open (or configure different port)

### Quick Backend Deploy (Example - Ubuntu Server):

1. **Install .NET 9.0:**
   ```bash
   wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
   sudo dpkg -i packages-microsoft-prod.deb
   sudo apt update
   sudo apt install -y dotnet-sdk-9.0
   ```

2. **Copy backend files to server:**
   ```bash
   scp -r tracker/ user@YOUR_SERVER_IP:/home/user/
   ```

3. **Configure User Secrets on server:**
   ```bash
   cd /home/user/tracker
   dotnet user-secrets set "api-key" "YOUR_PTV_API_KEY"
   dotnet user-secrets set "user-id" "YOUR_PTV_USER_ID"
   ```

4. **Run backend:**
   ```bash
   dotnet run --urls="http://0.0.0.0:5000"
   ```

5. **Make it run on boot (systemd service):**
   Create `/etc/systemd/system/ptv-tracker.service`:
   ```ini
   [Unit]
   Description=PTV Tracker API
   After=network.target

   [Service]
   Type=notify
   WorkingDirectory=/home/user/tracker
   ExecStart=/usr/bin/dotnet run --urls="http://0.0.0.0:5000"
   Restart=always
   User=user
   Environment=ASPNETCORE_ENVIRONMENT=Production

   [Install]
   WantedBy=multi-user.target
   ```

   Enable and start:
   ```bash
   sudo systemctl enable ptv-tracker
   sudo systemctl start ptv-tracker
   ```

---

## Testing Locally with Production API

To test the production build locally before deploying:

1. Update `.env.production` with your server IP
2. Build the app:
   ```bash
   npm run build
   ```
3. Preview the build:
   ```bash
   npm run preview
   ```
4. Visit http://localhost:4173

---

## Environment Variables Reference

| File | Purpose | When Used |
|------|---------|-----------|
| `.env.development` | Local development | `npm run dev` |
| `.env.production` | Production build | `npm run build` |
| `.env.example` | Template file | Copy to create .env files |

---

## Troubleshooting

### Frontend shows "Failed to fetch" errors:
- ✅ Check that backend server is running and accessible
- ✅ Verify `VITE_API_URL` secret is set correctly in GitHub
- ✅ Check browser console for CORS errors
- ✅ Ensure server firewall allows port 5000

### Routes show 404 on GitHub Pages:
- ✅ Verify `base` path in `vite.config.js` matches your repo structure
- ✅ Clear browser cache and reload

### Changes not appearing:
- ✅ Check GitHub Actions completed successfully (Actions tab)
- ✅ Wait 2-3 minutes for GitHub Pages to update
- ✅ Hard refresh browser (Ctrl+Shift+R / Cmd+Shift+R)

### CORS errors:
- ✅ Backend CORS is already configured to allow all origins
- ✅ If you restrict CORS later, add your GitHub Pages URL:
  ```csharp
  policy.WithOrigins("https://YOUR_USERNAME.github.io")
  ```

---

## Architecture Diagram

```
┌─────────────────────────┐
│   GitHub Pages          │
│   (Static Frontend)     │
│                         │
│   React + Vite + Leaflet│
└────────┬────────────────┘
         │
         │ HTTP Requests
         │ (API_BASE_URL from .env)
         │
         ▼
┌─────────────────────────┐
│   Your Server           │
│   (Backend API)         │
│                         │
│   ASP.NET Core          │
│   Port 5000             │
└────────┬────────────────┘
         │
         │ Database Queries
         │
         ▼
┌─────────────────────────┐
│   PostgreSQL            │
│   (GTFS Data)           │
│                         │
│   Routes, Stops, Shapes │
└─────────────────────────┘
```

---

## Cost Estimate

- **Frontend (GitHub Pages)**: FREE
- **Backend Server**: $5-20/month (DigitalOcean, Vultr, Linode, etc.)
- **Database**: Included with server (self-hosted PostgreSQL)

---

## Production Checklist

Before going live:
- [ ] Set `VITE_API_URL` secret in GitHub repository
- [ ] Update `base` in `vite.config.js` if using repo path
- [ ] Backend server is accessible from internet
- [ ] Backend firewall allows port 5000 (or your configured port)
- [ ] PostgreSQL database is populated with GTFS data
- [ ] PTV API credentials are configured on server
- [ ] Test the production build locally first (`npm run preview`)
- [ ] Verify all routes work after deployment

---

## Need Help?

- **Vite Deployment**: https://vitejs.dev/guide/static-deploy.html
- **GitHub Pages Docs**: https://docs.github.com/en/pages
- **ASP.NET Core Hosting**: https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/
