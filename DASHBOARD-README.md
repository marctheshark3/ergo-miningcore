# 🎯 Ergo Pool Dashboard - Quick Start

A beautiful terminal-themed web dashboard for monitoring your Ergo solo mining pool.

![Dashboard Style](https://img.shields.io/badge/Style-Terminal-00ffaa?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Ready-00ff00?style=for-the-badge)
![Updates](https://img.shields.io/badge/Updates-Real--time-00d4ff?style=for-the-badge)

## ✨ What You Get

### 📊 Public Dashboard (`/public/`)
Perfect for sharing with your miners:
- **Real-time Pool Stats**: Hashrate, miners, shares, blocks
- **Network Information**: Height, difficulty, network hashrate
- **Live Charts**: Hashrate history with auto-updates
- **Recent Blocks**: Latest finds with status indicators
- **Top Miners Leaderboard**: Last 24 hours
- **Pool Information**: Connection details, fees, payment info
- **Sparkline Graphs**: Visual activity indicators

### 🔧 Operator Dashboard (`/admin/`)
Advanced monitoring for pool operators:
- **System Health**: Pool, node, and database status
- **Performance Metrics**: Efficiency, luck factor, predictions
- **Detailed Tables**: Complete block and miner information
- **Quick Actions**: Logs, API docs, memory stats
- **Alert System**: Real-time warnings and notifications
- **Optional Password**: Secure your operator access
- **Advanced Controls**: Multiple chart timeframes

## 🚀 Start Dashboard (3 Simple Steps)

### Step 1: Navigate to Project
```bash
cd /home/whaleshark/Documents/ergo/ergo-miningcore
```

### Step 2: Start Dashboard
```bash
./scripts/start-dashboard.sh
```

### Step 3: Open in Browser
- **Public Dashboard**: http://localhost:8888/public/
- **Operator Dashboard**: http://localhost:8888/admin/

That's it! Your dashboard is now running! 🎉

## 🌐 Access from Other Devices

Replace `localhost` with your server's IP:
- `http://YOUR_SERVER_IP:8888/public/`
- `http://YOUR_SERVER_IP:8888/admin/`

**Example**: If your server IP is `192.168.1.100`:
- http://192.168.1.100:8888/public/
- http://192.168.1.100:8888/admin/

## 🎨 Dashboard Features

### Terminal Theme
- Dark background with neon green/cyan accents
- Glowing borders and effects
- CRT monitor scanline effect
- Smooth animations
- Responsive design (works on mobile!)

### Real-Time Updates
- Auto-refreshes every 10 seconds
- No page reload needed
- Live charts and graphs
- Instant data updates

### Data Visualization
- **Line Charts**: Hashrate history over 24 hours
- **Gauge Charts**: Pool effort indicator
- **Sparklines**: Mini activity graphs
- **Tables**: Sortable, filterable data
- **Bar Charts**: Comparative metrics

## 🔐 Optional Password Protection

To secure your operator dashboard:

### 1. Edit Configuration
```bash
nano dashboard/assets/js/admin.js
```

### 2. Enable Password
```javascript
const adminConfig = {
    passwordEnabled: true,              // Change to true
    password: 'your_secure_password',   // Set your password
    sessionTimeout: 3600000,            // 1 hour
};
```

### 3. Save and Reload
Browser will now prompt for password on `/admin/` access.

### 4. Disable Password Anytime
Set `passwordEnabled: false` and leave `password: ''` empty.

## 📁 Dashboard Structure

```
dashboard/
├── public/
│   └── index.html              # Public dashboard page
├── admin/
│   └── index.html              # Operator dashboard page
├── assets/
│   ├── css/
│   │   ├── terminal-theme.css  # Terminal styling
│   │   ├── dashboard.css       # Layout & widgets
│   │   └── admin.css           # Admin-specific styles
│   └── js/
│       ├── chart.min.js        # Chart.js library
│       ├── dashboard.js        # Main logic
│       └── admin.js            # Admin logic
└── server.py                   # Web server
```

## ⚙️ Configuration

Edit `dashboard/assets/js/dashboard.js`:

```javascript
const config = {
    apiUrl: 'http://localhost:4000/api',  // API endpoint
    poolId: 'ergo-solo',                   // Pool ID
    refreshInterval: 10000,                // Refresh rate (ms)
    chartMaxDataPoints: 24,                // Chart history
};
```

## 🎨 Theme Customization

Edit `dashboard/assets/css/terminal-theme.css`:

```css
:root {
    --bg-primary: #0f0f1e;        /* Background */
    --border-color: #00ffaa;       /* Primary border */
    --text-primary: #00ffaa;       /* Text color */
    --accent-cyan: #00ffff;        /* Cyan accent */
    --accent-yellow: #ffff00;      /* Yellow accent */
    /* Customize all colors! */
}
```

## 📊 Data Sources

The dashboard connects to your Miningcore API (port 4000):

✅ **Pool stats** - Live hashrate, miners, shares
✅ **Network stats** - Block height, difficulty, peers  
✅ **Blocks** - Recent finds with status
✅ **Miners** - Active miner list with stats
✅ **Performance** - Historical data and charts

All data is **read-only** (dashboard doesn't control the pool).

## 🔧 Troubleshooting

### Dashboard Won't Start

```bash
# Check if port 8888 is in use
lsof -i :8888

# Kill existing process
lsof -ti:8888 | xargs kill -9

# Try again
./scripts/start-dashboard.sh
```

### No Data Showing

```bash
# Check if pool API is running
curl http://localhost:4000/api/health-check
# Should return: 👍

# Check pool status
docker-compose -f docker-compose.solo.yml ps

# Check pool logs
tail -f logs/miningcore-solo.log
```

### Charts Not Displaying

```bash
# Re-download Chart.js
cd dashboard/assets/js
curl -o chart.min.js https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js
```

### Python Not Found

```bash
# Install Python 3
sudo apt-get update
sudo apt-get install python3
```

## 📱 Mobile Support

Dashboard is fully responsive:
- ✅ Works on tablets
- ✅ Works on phones  
- ✅ Touch-friendly
- ✅ Landscape recommended for phones

## 🛠️ Advanced Usage

### Run in Background
```bash
# Using nohup
nohup ./scripts/start-dashboard.sh &

# Using screen
screen -S dashboard
./scripts/start-dashboard.sh
# Press Ctrl+A then D to detach
```

### Auto-Start on Boot
```bash
# Create systemd service
sudo nano /etc/systemd/system/ergo-dashboard.service
```

```ini
[Unit]
Description=Ergo Pool Dashboard
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/home/whaleshark/Documents/ergo/ergo-miningcore/dashboard
ExecStart=/usr/bin/python3 server.py
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl enable ergo-dashboard
sudo systemctl start ergo-dashboard
```

### Use with Nginx

```nginx
location /dashboard/ {
    proxy_pass http://localhost:8888/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### Enable HTTPS

Use a reverse proxy like Caddy:
```
your-domain.com {
    reverse_proxy localhost:8888
}
```

## 📖 Full Documentation

- **`DASHBOARD-GUIDE.md`** - Complete guide
- **`VIEW-POOL-DATA.md`** - API documentation
- **`QUICK-REFERENCE.md`** - Command reference

## 💡 Tips

1. **Keep It Open**: Monitor in a dedicated browser tab
2. **Bookmark It**: Add to your bookmarks for quick access
3. **Share Public**: Give miners the `/public/` URL
4. **Secure Admin**: Use password for `/admin/` if exposed
5. **Monitor Logs**: Use Quick Actions → View Logs
6. **Check Alerts**: Watch the alerts widget regularly

## 🎯 Quick Commands

```bash
# Start dashboard
./scripts/start-dashboard.sh

# Check if running
curl http://localhost:8080/

# Stop (Ctrl+C in terminal)

# View pool status
./scripts/check-pool-stats.sh

# Check pool logs
tail -f logs/miningcore-solo.log
```

## 📊 Screenshots Guide

### Public Dashboard Layout:
```
┌─────────────────────────────────────────────────┐
│  ⛏️  ERGO SOLO MINING POOL - PUBLIC DASHBOARD  │
├─────────────────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌───────────────────┐ │
│ │  Pool   │ │ Network │ │   Hashrate Chart  │ │
│ │  Stats  │ │  Stats  │ │                   │ │
│ └─────────┘ └─────────┘ └───────────────────┘ │
│ ┌──────────┐ ┌─────────────────────────────┐  │
│ │  Effort  │ │      Recent Blocks          │  │
│ │  Gauge   │ │                             │  │
│ └──────────┘ └─────────────────────────────┘  │
│ ┌──────────────────┐ ┌─────────────────────┐  │
│ │   Top Miners     │ │   Pool Information  │  │
│ └──────────────────┘ └─────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### Operator Dashboard:
```
┌─────────────────────────────────────────────────┐
│  🔧  ERGO POOL - OPERATOR DASHBOARD            │
├─────────────────────────────────────────────────┤
│ ┌────────┐ ┌────────┐ ┌──────┐ ┌─────────────┐│
│ │ System │ │  Pool  │ │ Net  │ │Performance  ││
│ │ Status │ │  Stats │ │Stats │ │   Metrics   ││
│ └────────┘ └────────┘ └──────┘ └─────────────┘│
│ ┌──────────────────────────────────────────────┤
│ │         Hashrate History (Advanced)         ││
│ │         [1H] [24H] [7D]                      ││
│ └──────────────────────────────────────────────│
│ ┌──────────────┐ ┌────────────────────────────┤
│ │ Recent Blocks│ │   Active Miners (Table)    ││
│ │   (Table)    │ │                            ││
│ └──────────────┘ └────────────────────────────│
│ ┌──────┐ ┌─────────┐ ┌──────┐ ┌─────────────┤
│ │ Node │ │ Payment │ │Quick │ │   Alerts    ││
│ │ Info │ │  Info   │ │Action│ │             ││
│ └──────┘ └─────────┘ └──────┘ └─────────────┘│
└─────────────────────────────────────────────────┘
```

## 🎉 You're All Set!

Your terminal-themed mining pool dashboard is ready to use!

### To Start:
```bash
./scripts/start-dashboard.sh
```

### Then Visit:
- 👥 **Public**: http://localhost:8888/public/
- 🔧 **Operator**: http://localhost:8888/admin/

---

**Questions?** Check `DASHBOARD-GUIDE.md` for detailed documentation.

**Happy Mining!** ⛏️✨

