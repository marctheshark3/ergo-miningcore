# Dashboard Port Configuration

## 🔌 Port Summary

Your Ergo mining pool uses the following ports:

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Miningcore API** | 4000 | http://localhost:4000 | Pool API endpoints |
| **Mining Stratum (Low)** | 4074 | stratum+tcp://YOUR_IP:4074 | Miners connect here (low diff) |
| **Mining Stratum (High)** | 4075 | stratum+tcp://YOUR_IP:4075 | Miners connect here (high diff) |
| **Dashboard Server** | **8888** | http://localhost:8888 | Web dashboard (public & operator) |
| **PostgreSQL** | 5444 | localhost:5444 | Database (internal only) |

## 🌐 Dashboard Access

### Local Access
- **Public Dashboard**: http://localhost:8888/public/
- **Operator Dashboard**: http://localhost:8888/admin/

### Remote Access
Replace `YOUR_SERVER_IP` with your actual server IP:
- **Public Dashboard**: http://YOUR_SERVER_IP:8888/public/
- **Operator Dashboard**: http://YOUR_SERVER_IP:8888/admin/

## 🔥 Firewall Configuration

If you need to open ports for external access:

```bash
# Allow mining stratum ports (for miners)
sudo ufw allow 4074/tcp comment 'Ergo Pool - Stratum Low'
sudo ufw allow 4075/tcp comment 'Ergo Pool - Stratum High'

# Allow dashboard (optional - only if you want remote web access)
sudo ufw allow 8888/tcp comment 'Ergo Pool - Dashboard'

# Allow API (optional - usually keep internal only)
# sudo ufw allow 4000/tcp comment 'Ergo Pool - API'

# Check firewall status
sudo ufw status
```

## 🛑 Stop Dashboard

```bash
# If running in foreground: Press Ctrl+C

# If running in background:
lsof -ti:8888 | xargs kill -9

# Or use pkill:
pkill -f "python3.*server.py"
```

## 🔄 Change Port

To use a different port, edit:

### 1. Server Script
```bash
nano dashboard/server.py
```
Change: `PORT = 8888` to your desired port

### 2. Startup Script
```bash
nano scripts/start-dashboard.sh
```
Change: `PORT=8888` to your desired port

### 3. Restart Dashboard
```bash
./scripts/start-dashboard.sh
```

## ✅ Quick Test

```bash
# Test if dashboard is running
curl -I http://localhost:8888/

# Test if API is running
curl http://localhost:4000/api/health-check

# Check all listening ports
netstat -tlnp | grep -E '4000|4074|4075|5444|8888'
```

## 📋 Common Port Issues

### Port Already in Use
```bash
# Find what's using port 8888
lsof -i :8888

# Kill the process
lsof -ti:8888 | xargs kill -9
```

### Can't Access Dashboard Remotely
1. Check firewall: `sudo ufw status`
2. Check if binding to all interfaces (server.py uses `0.0.0.0`)
3. Verify server IP: `ip addr show`
4. Test from server first: `curl http://localhost:8888/`

### API Not Accessible
```bash
# Check if Miningcore is running
docker-compose -f docker-compose.solo.yml ps

# Check API logs
tail -f logs/api-solo.log

# Test API directly
curl http://localhost:4000/api/pools/ergo-solo
```

## 🔐 Security Notes

**Internal Only (Recommended):**
- Port 4000 (API) - Keep internal, accessed by dashboard
- Port 5444 (Database) - Keep internal, accessed by pool only

**External Access Required:**
- Port 4074/4075 (Stratum) - Must be open for miners
- Port 8888 (Dashboard) - Optional, can use SSH tunnel instead

**SSH Tunnel Alternative:**
Instead of opening port 8888, use SSH tunnel:
```bash
# From your local machine
ssh -L 8888:localhost:8888 user@YOUR_SERVER_IP

# Then access via: http://localhost:8888/
```

---

**Current Configuration:** Dashboard on port **8888**







