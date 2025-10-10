

# Ergo Pool Dashboard Guide

A terminal-themed web dashboard for monitoring your Ergo solo mining pool with real-time statistics, visualizations, and operator tools.

## 🎨 Features

### Public Dashboard
- **Pool Statistics**: Connected miners, hashrate, shares, blocks found, total paid
- **Network Information**: Block height, network hashrate, difficulty, peers
- **Real-time Charts**: Hashrate history with live updates
- **Recent Blocks**: Latest blocks found with status indicators
- **Top Miners**: Leaderboard of active miners
- **Pool Information**: Connection details, payment scheme, fees
- **Sparklines**: Visual activity indicators
- **Auto-refresh**: Updates every 10 seconds

### Operator Dashboard
- **System Status**: Pool health, node connection, database status
- **Enhanced Metrics**: Performance, efficiency, luck factor
- **Detailed Tables**: Comprehensive block and miner information
- **Quick Actions**: View logs, API docs, memory stats
- **Alerts System**: Real-time notifications and warnings
- **Optional Password**: Secure operator access
- **Advanced Charts**: Multiple timeframe views

## 🚀 Quick Start

### 1. Start the Dashboard

```bash
# From the project root
./scripts/start-dashboard.sh
```

The dashboard will be available at:
- **Public**: http://localhost:8888/public/
- **Operator**: http://localhost:8888/admin/

### 2. Access from Another Computer

Replace `localhost` with your server's IP address:
- http://YOUR_SERVER_IP:8888/public/
- http://YOUR_SERVER_IP:8888/admin/

### 3. Stop the Dashboard

Press `Ctrl+C` in the terminal where the server is running.

## 📋 Requirements

- **Python 3**: For running the web server
- **Miningcore Pool**: Must be running on port 4000 (API)
- **Modern Browser**: Chrome, Firefox, Edge, Safari

### Check Requirements

```bash
# Check Python 3
python3 --version

# Check if pool API is accessible
curl http://localhost:4000/api/health-check
```

## 🎯 Dashboard Layout

### Public Dashboard Widgets

1. **Pool Statistics**
   - Connected miners count
   - Current pool hashrate
   - Shares per second
   - Total blocks found
   - Total ERG paid out
   - Current pool effort

2. **Network Statistics**
   - Network type (mainnet/testnet)
   - Current block height
   - Network total hashrate
   - Network difficulty
   - Connected peers
   - Last network block time

3. **Hashrate Chart**
   - 24-hour pool hashrate history
   - Color-coded line graph
   - Auto-scaling axes

4. **Pool Effort Gauge**
   - Visual circular gauge
   - Color-coded (green/yellow/orange/red)
   - Estimated time to next block

5. **Recent Blocks**
   - Last 10 blocks found
   - Status badges (confirmed/pending/orphaned)
   - Block height, reward, time

6. **Top Miners**
   - Last 24 hours leaderboard
   - Individual hashrates
   - Shares per second

7. **Pool Information**
   - Pool wallet address
   - Stratum endpoints
   - Payment scheme
   - Minimum payment
   - Pool fees

8. **Activity Sparklines**
   - Shares activity mini-chart
   - Hashrate activity mini-chart

### Operator Dashboard Additional Widgets

1. **System Status**
   - Pool online/offline status
   - Node connection status
   - Database health
   - Pool uptime

2. **Enhanced Pool Stats**
   - Valid/invalid share counts
   - Share rate over time
   - More detailed metrics

3. **Performance Metrics**
   - Average block time
   - Pool efficiency
   - Expected blocks per day
   - Actual blocks found
   - Luck factor calculation

4. **Advanced Charts**
   - Multiple timeframe options (1H/24H/7D)
   - Interactive controls

5. **Detailed Block Table**
   - Tabular block view
   - Miner who found block
   - Effort percentage
   - Sortable columns

6. **Active Miners Table**
   - Complete miner list
   - Worker counts
   - Last activity timestamps

7. **Node Information**
   - Node host and port
   - Node version
   - Sync status
   - Database type

8. **Payment Information**
   - Total paid out
   - Pending payment count
   - Last payment timestamp
   - Payment configuration

9. **Quick Actions**
   - View API documentation
   - Refresh dashboard data
   - View logs
   - Check memory stats

10. **Alerts & Notifications**
    - Real-time warnings
    - System health alerts
    - Connection issues

## 🔐 Password Protection (Optional)

To enable password protection for the operator dashboard:

### 1. Edit the Admin Configuration

Edit: `dashboard/assets/js/admin.js`

```javascript
const adminConfig = {
    ...config,
    passwordEnabled: true,  // Change to true
    password: 'your_secure_password',  // Set your password
    sessionTimeout: 3600000, // 1 hour
};
```

### 2. Set a Strong Password

Choose a password that:
- Is at least 12 characters long
- Contains uppercase, lowercase, numbers, symbols
- Is unique to this dashboard

### 3. Session Management

- Sessions expire after 1 hour (configurable)
- Stored locally in browser
- Logout button available in footer

### 4. Disable Password

To disable password protection:

```javascript
const adminConfig = {
    ...config,
    passwordEnabled: false,  // Set to false
    password: '',  // Empty password
};
```

Then click "Skip (No Password Set)" on the login screen.

## 🎨 Theme Customization

The dashboard uses a terminal-inspired theme with these characteristics:

### Color Scheme

- **Background**: Dark blue-black tones
- **Primary**: Neon green (#00ffaa)
- **Accents**: Cyan, yellow, magenta, red
- **Text**: Green/cyan on dark background
- **Borders**: Glowing neon effects

### Customizing Colors

Edit: `dashboard/assets/css/terminal-theme.css`

```css
:root {
    --bg-primary: #0f0f1e;      /* Main background */
    --border-color: #00ffaa;     /* Primary border color */
    --text-primary: #00ffaa;     /* Main text color */
    --accent-cyan: #00ffff;      /* Cyan accent */
    --accent-yellow: #ffff00;    /* Yellow accent */
    /* ... customize more colors */
}
```

### Effects

- **Glow Effects**: Borders and text have subtle glow
- **Scan Lines**: Optional CRT monitor effect
- **Animations**: Smooth transitions and pulses
- **Hover States**: Interactive widget highlighting

## 📊 Data Refresh

### Auto-Refresh Settings

Edit: `dashboard/assets/js/dashboard.js`

```javascript
const config = {
    apiUrl: 'http://localhost:4000/api',
    poolId: 'ergo-solo',
    refreshInterval: 10000,  // 10 seconds (change this)
    chartMaxDataPoints: 24,  // Chart history points
};
```

### Manual Refresh

- Operator dashboard has a "Refresh Data" button
- Browser refresh (F5) works too
- Auto-refresh runs in background

## 🔧 Troubleshooting

### Dashboard Won't Start

**Error: Port 8888 in use**
```bash
# Kill existing process
lsof -ti:8888 | xargs kill -9

# Try again
./scripts/start-dashboard.sh
```

**Error: Python 3 not found**
```bash
# Install Python 3
sudo apt-get update
sudo apt-get install python3
```

### No Data Showing

**Check API Connection**
```bash
# Test API
curl http://localhost:4000/api/health-check

# Should return: 👍
```

**Check Pool Status**
```bash
# Check if pool is running
docker-compose -f docker-compose.solo.yml ps

# Check pool logs
tail -f logs/miningcore-solo.log
```

### Charts Not Displaying

**Browser Console Errors**
1. Open browser developer tools (F12)
2. Check Console tab for errors
3. Check Network tab for failed requests

**Chart.js Not Loading**
```bash
# Re-download Chart.js
cd dashboard/assets/js
rm chart.min.js
curl -o chart.min.js https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js
```

### Slow Performance

**Increase Refresh Interval**

Edit `dashboard/assets/js/dashboard.js`:
```javascript
refreshInterval: 30000,  // 30 seconds instead of 10
```

**Reduce Chart Data Points**
```javascript
chartMaxDataPoints: 12,  // Half the points
```

### CORS Errors

The dashboard server has CORS enabled by default. If you still get errors:

1. Check browser console
2. Verify API URL in config
3. Try accessing API directly

## 📱 Mobile Support

The dashboard is responsive and works on mobile devices:

- **Tablets**: Full experience with adjusted layout
- **Phones**: Stacked widgets, simplified tables
- **Landscape**: Better for phones
- **Touch**: All buttons are touch-friendly

## 🔗 Integration

### With Monitoring Tools

**Prometheus/Grafana**
- Dashboard uses same API as Grafana would
- Can run both simultaneously
- Different visualizations

**Custom Scripts**
```bash
# Access same data as dashboard
curl http://localhost:4000/api/pools/ergo-solo | jq '.'
```

### With Nginx

To serve dashboard through Nginx:

```nginx
# Add to nginx config
location /dashboard/ {
    proxy_pass http://localhost:8888/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### With SSL/HTTPS

For HTTPS access, use a reverse proxy like Nginx or Caddy:

**Caddy Example:**
```
your-domain.com {
    reverse_proxy localhost:8888
}
```

## 🎯 Best Practices

### For Pool Operators

1. **Keep Dashboard Open**: Monitor in a dedicated browser tab or screen
2. **Set Up Alerts**: Check alerts widget regularly
3. **Monitor Logs**: Use Quick Actions → View Logs
4. **Check Efficiency**: Watch pool efficiency and luck factor
5. **Secure Access**: Use password protection if exposed to internet

### For Security

1. **Firewall**: Only expose port 8080 to trusted IPs
2. **Password**: Enable and use strong password for admin dashboard
3. **Updates**: Keep system and dependencies updated
4. **Logs**: Monitor access logs for suspicious activity
5. **HTTPS**: Use SSL/TLS for remote access

### For Performance

1. **Dedicated Server**: Run dashboard on same server as pool
2. **Resource Monitoring**: Check CPU/RAM usage
3. **Browser**: Use modern browser, close unused tabs
4. **Network**: Local access is fastest
5. **Refresh Rate**: Balance between real-time and performance

## 📖 API Endpoints Used

The dashboard consumes these Miningcore API endpoints:

- `GET /api/health-check` - Health status
- `GET /api/pools/ergo-solo` - Pool overview
- `GET /api/pools/ergo-solo/blocks` - Recent blocks
- `GET /api/pools/ergo-solo/miners` - Active miners
- `GET /api/pools/ergo-solo/performance` - Performance history
- `GET /api/admin/stats/gc` - Memory statistics (admin only)

See `VIEW-POOL-DATA.md` for complete API documentation.

## 🛠️ Development

### File Structure

```
dashboard/
├── public/
│   └── index.html          # Public dashboard
├── admin/
│   └── index.html          # Operator dashboard
├── assets/
│   ├── css/
│   │   ├── terminal-theme.css  # Terminal styling
│   │   ├── dashboard.css       # Dashboard layout
│   │   └── admin.css           # Admin styles
│   └── js/
│       ├── chart.min.js        # Chart.js library
│       ├── dashboard.js        # Main dashboard logic
│       └── admin.js            # Admin dashboard logic
└── server.py               # Python web server
```

### Modifying the Dashboard

**Add New Widget:**
1. Add HTML in `public/index.html` or `admin/index.html`
2. Add CSS styling in `dashboard.css` or `admin.css`
3. Add JavaScript update function in `dashboard.js` or `admin.js`
4. Call update function in main update loop

**Add New Metric:**
1. Check if API provides the data
2. Add display element in HTML
3. Add update logic in JavaScript

**Change Theme:**
1. Edit color variables in `terminal-theme.css`
2. Modify effects and animations as desired
3. Test in multiple browsers

## 📝 Notes

- Dashboard is read-only (no pool control functionality)
- Requires pool to be running on port 4000
- Lightweight and fast
- No database required for dashboard itself
- Can run 24/7
- Browser-based, no installation needed

## 🆘 Getting Help

If you encounter issues:

1. **Check Logs**: 
   ```bash
   tail -f logs/miningcore-solo.log
   tail -f logs/api-solo.log
   ```

2. **Test API**:
   ```bash
   curl http://localhost:4000/api/help
   ```

3. **Browser Console**: Check for JavaScript errors (F12)

4. **Documentation**: 
   - `VIEW-POOL-DATA.md` - API guide
   - `QUICK-REFERENCE.md` - Command reference
   - `POOL-MONITORING-GUIDE.md` - Monitoring guide

## 🎉 Enjoy Your Dashboard!

Your terminal-themed mining pool dashboard is ready to use. Keep it open and monitor your pool in style!

**Quick Start Again:**
```bash
./scripts/start-dashboard.sh
```

Then open: http://localhost:8888/

---

**Happy Mining!** ⛏️🚀

