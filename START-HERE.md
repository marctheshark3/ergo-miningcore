# 🚀 Ergo Solo Mining Pool - Quick Start

## ✅ What's Running

Your Ergo solo mining pool is configured and ready! Here's what you have:

### Pool Services
- ✅ **Miningcore Pool**: Running on ports 4074, 4075 (for miners)
- ✅ **Pool API**: Running on port 4000
- ✅ **PostgreSQL Database**: Running on port 5444
- ✅ **Web Dashboard**: Ready to start on port 8888

---

## 🎯 Quick Actions

### Start the Web Dashboard
```bash
./scripts/start-dashboard.sh
```

Then open in your browser:
- **Public Dashboard**: http://localhost:8888/public/
- **Operator Dashboard**: http://localhost:8888/admin/

### Check Pool Status
```bash
./scripts/check-pool-stats.sh
```

### View Pool Logs
```bash
tail -f logs/miningcore-solo.log
```

---

## 📊 Available Dashboards

### 1. Terminal-Style Web Dashboard (NEW! 🎨)
- **Port**: 8888
- **Public View**: Real-time stats, blocks, miners
- **Operator View**: Advanced monitoring, system health
- **Theme**: Terminal-inspired with neon effects
- **Updates**: Every 10 seconds automatically

**Start**: `./scripts/start-dashboard.sh`
**Access**: http://localhost:8888/

### 2. API Monitoring
- **Port**: 4000
- **Health Check**: http://localhost:4000/api/health-check
- **Pool Stats**: http://localhost:4000/api/pools/ergo-solo
- **All Endpoints**: http://localhost:4000/api/help

---

## 🔌 Port Summary

| Service | Port | Access |
|---------|------|--------|
| Mining Stratum (Low Diff) | 4074 | For miners |
| Mining Stratum (High Diff) | 4075 | For miners |
| Pool API | 4000 | Internal/Dashboard |
| Web Dashboard | **8888** | Your browser |
| PostgreSQL | 5444 | Internal only |

---

## 📖 Documentation

### For Quick Reference
- **`DASHBOARD-README.md`** - Dashboard quick start
- **`DASHBOARD-PORTS.md`** - Port configuration guide
- **`QUICK-REFERENCE.md`** - Command cheat sheet

### For Detailed Info
- **`DASHBOARD-GUIDE.md`** - Complete dashboard guide
- **`POOL-MONITORING-GUIDE.md`** - Monitoring guide
- **`VIEW-POOL-DATA.md`** - API documentation

### For Mining
- **`SOLO-MINING-SIMPLE.md`** - Simple mining guide
- **`SOLO-MINING.md`** - Detailed mining guide

---

## 🎨 Dashboard Features

### Public Dashboard
✨ Pool statistics
✨ Network information
✨ Live hashrate charts
✨ Recent blocks
✨ Top miners leaderboard
✨ Sparkline graphs
✨ Pool information

### Operator Dashboard
🔧 System health monitoring
🔧 Performance metrics
🔧 Detailed tables
🔧 Node information
🔧 Quick action buttons
🔧 Alert system
🔧 Optional password protection

---

## 🌐 Share with Miners

Give your miners this URL for real-time pool stats:
```
http://YOUR_SERVER_IP:8888/public/
```

Replace `YOUR_SERVER_IP` with your actual server IP address.

**Connection Details for Miners:**
```
Stratum URL: stratum+tcp://YOUR_SERVER_IP:4074
Pool Address: 9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY
Worker Name: anything you want
Password: x
```

---

## 🔧 Common Commands

```bash
# Start dashboard
./scripts/start-dashboard.sh

# Stop dashboard (Ctrl+C or:)
pkill -f "python3.*server.py"

# Check pool status
./scripts/check-pool-stats.sh

# View pool logs
tail -f logs/miningcore-solo.log

# Check API
curl http://localhost:4000/api/health-check

# Check dashboard
curl http://localhost:8888/

# Check pool containers
docker-compose -f docker-compose.solo.yml ps
```

---

## 🆘 Troubleshooting

### Dashboard Won't Start
```bash
# Check if port is in use
lsof -i :8888

# Kill existing process
lsof -ti:8888 | xargs kill -9

# Try again
./scripts/start-dashboard.sh
```

### No Data in Dashboard
```bash
# Make sure pool is running
docker-compose -f docker-compose.solo.yml ps

# Check API is responding
curl http://localhost:4000/api/health-check

# Check pool logs
tail -f logs/miningcore-solo.log
```

### Can't Access Remotely
```bash
# Check firewall (if enabled)
sudo ufw status

# Allow dashboard port
sudo ufw allow 8888/tcp
```

---

## 🎉 Next Steps

1. **Start the Dashboard**
   ```bash
   ./scripts/start-dashboard.sh
   ```

2. **Open in Browser**
   - Public: http://localhost:8888/public/
   - Operator: http://localhost:8888/admin/

3. **Start Mining** (on a mining rig)
   ```bash
   # Example with lolMiner
   ./lolMiner --algo AUTOLYKOS2 \
     --pool YOUR_SERVER_IP:4074 \
     --user YOUR_WALLET_ADDRESS
   ```

4. **Monitor Everything**
   - Watch the dashboard update in real-time
   - Check alerts in operator dashboard
   - View logs for detailed information

---

## 💡 Tips

- **Bookmark the Dashboard**: Add to your browser favorites
- **Keep it Open**: Monitor in a dedicated tab
- **Check Regularly**: Review operator dashboard for issues
- **Share Public URL**: Let miners see pool stats
- **Secure Admin**: Use password for operator dashboard if exposed to internet

---

## 📱 Mobile Access

The dashboard works great on mobile devices! Just use:
- http://YOUR_SERVER_IP:8888/public/ (on your phone/tablet)

---

## 🔐 Security

**Ports to Keep Internal:**
- 4000 (API) - Used by dashboard
- 5444 (Database) - Used by pool only

**Ports Miners Need:**
- 4074, 4075 (Stratum) - Must be accessible

**Ports Optional:**
- 8888 (Dashboard) - Can use SSH tunnel instead

**SSH Tunnel Example:**
```bash
# From your computer
ssh -L 8888:localhost:8888 user@YOUR_SERVER

# Then access: http://localhost:8888/
```

---

## ✨ Enjoy Your Pool!

Your Ergo solo mining pool with a beautiful terminal-themed dashboard is ready!

**Quick Start:**
```bash
./scripts/start-dashboard.sh
```

**Then visit:** http://localhost:8888/

---

**Happy Mining!** ⛏️🚀

*For questions or issues, check the documentation in the project folder.*


