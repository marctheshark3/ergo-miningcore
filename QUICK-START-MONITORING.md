# Quick Start: Monitoring & Alerts

Fast setup guide for the enhanced admin dashboard and alert system.

## 🚀 Step 1: Start Enhanced Dashboard (Required)

```bash
cd /home/whaleshark/Documents/ergo/ergo-miningcore/dashboard
python3 server.py
```

**Access the dashboards:**
- **Public Dashboard:** http://localhost:8888/public/
- **Admin Dashboard:** http://localhost:8888/admin/

The admin dashboard now shows:
- ✅ Disk space with visual progress bar
- ✅ CPU and memory usage
- ✅ Component sizes (database, node, logs, backups)
- ✅ Docker container stats
- ✅ Enhanced alerts with system warnings

---

## 🔔 Step 2: Set Up Alerts (Optional but Recommended)

### Option A: Telegram Alerts (Most Popular)

**1. Create Telegram Bot:**
```bash
# In Telegram, talk to @BotFather
# Send: /newbot
# Follow prompts and save your bot token
```

**2. Get Your Chat ID:**
```bash
# Message your bot first, then run:
curl https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates

# Look for: "chat":{"id": 987654321}
# Save this number (your chat ID)
```

**3. Configure:**
```bash
# Copy template
cp config/integrations.json.template config/integrations.json

# Edit file
nano config/integrations.json
```

Set these values:
```json
{
  "telegram": {
    "enabled": true,
    "botToken": "123456789:ABCdefGHIjklMNOpqrsTUVwxyz",
    "chatIds": ["987654321"]
  }
}
```

**4. Test:**
```bash
cd integrations
python3 telegram_bot.py
python3 telegram_bot.py --test-message
```

### Option B: Discord Alerts

**1. Create Webhook:**
- Go to Discord Server Settings → Integrations → Webhooks
- Click "New Webhook"
- Name it "Ergo Pool Bot"
- Copy webhook URL

**2. Configure:**
```bash
nano config/integrations.json
```

Set:
```json
{
  "discord": {
    "enabled": true,
    "webhookUrl": "https://discord.com/api/webhooks/..."
  }
}
```

**3. Test:**
```bash
cd integrations
python3 discord_webhook.py
python3 discord_webhook.py --test-alert
```

---

## 🔍 Step 3: Start Alert Monitor (Optional)

### Quick Start (Foreground)
```bash
cd integrations
pip3 install requests  # one-time install
python3 alert_monitor.py
```

### Production Setup (Background with systemd)

**1. Create service file:**
```bash
sudo nano /etc/systemd/system/ergo-pool-alerts.service
```

**2. Add this content (update paths):**
```ini
[Unit]
Description=Ergo Pool Alert Monitor
After=network.target

[Service]
Type=simple
User=whaleshark
WorkingDirectory=/home/whaleshark/Documents/ergo/ergo-miningcore/integrations
ExecStart=/usr/bin/python3 /home/whaleshark/Documents/ergo/ergo-miningcore/integrations/alert_monitor.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**3. Enable and start:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable ergo-pool-alerts
sudo systemctl start ergo-pool-alerts
sudo systemctl status ergo-pool-alerts
```

**4. View logs:**
```bash
sudo journalctl -u ergo-pool-alerts -f
```

---

## 📊 What Gets Monitored

### Automatic Alerts
- 🔴 **Pool Offline** - Miningcore API not responding
- ⚠️ **Node Disconnected** - Ergo node has 0 peers
- 🚨 **Disk Critical** - Disk usage ≥ 90%
- 📊 **Disk Warning** - Disk usage ≥ 80%
- 🔥 **High CPU** - CPU usage ≥ 90%
- 💾 **High Memory** - Memory usage ≥ 90%
- 🎯 **New Block** - Pool found a block!

### Dashboard Metrics
- Disk space (total, used, free, %)
- CPU usage
- Memory usage  
- Load average
- PostgreSQL database size
- Ergo node data size
- Log files size
- Backups size
- Docker container stats
- Pool stats (hashrate, miners, blocks)

---

## 🎛️ Customization

### Change Alert Thresholds

Edit `integrations/alert_monitor.py`:

```python
# Disk space thresholds
if usage >= 90:  # Change to 95 for critical
    # ...
elif usage >= 80:  # Change to 85 for warning
    # ...

# CPU/Memory thresholds
if cpu_usage >= 90:  # Change to your preference
    # ...

# Check interval
self.check_interval = 60  # Change to 300 for 5 minutes
```

### Enable/Disable Specific Alerts

Edit `config/integrations.json`:

```json
{
  "telegram": {
    "alerts": {
      "poolOffline": true,
      "diskSpaceWarning": true,
      "diskSpaceCritical": true,
      "highCpuUsage": false,          // Disable this
      "newBlockFound": true
    }
  }
}
```

---

## 🧪 Testing Commands

```bash
# Test Telegram bot
python3 integrations/telegram_bot.py
python3 integrations/telegram_bot.py --test-message
python3 integrations/telegram_bot.py --test-alert
python3 integrations/telegram_bot.py --test-block

# Test Discord webhook
python3 integrations/discord_webhook.py
python3 integrations/discord_webhook.py --test-alert
python3 integrations/discord_webhook.py --test-block

# Test monitoring APIs
curl http://localhost:8888/api/admin/system/disk
curl http://localhost:8888/api/admin/system/performance
curl http://localhost:8888/api/admin/system/docker
curl http://localhost:8888/api/admin/system/components

# Run monitor for 1 minute (test)
timeout 60 python3 integrations/alert_monitor.py
```

---

## 🔧 Maintenance Commands

### Alert Monitor

```bash
# Check if running
sudo systemctl status ergo-pool-alerts

# Stop
sudo systemctl stop ergo-pool-alerts

# Start
sudo systemctl start ergo-pool-alerts

# Restart
sudo systemctl restart ergo-pool-alerts

# View logs
sudo journalctl -u ergo-pool-alerts -f
sudo journalctl -u ergo-pool-alerts --since "1 hour ago"

# Disable
sudo systemctl disable ergo-pool-alerts
```

### Dashboard

```bash
# Check if running
ps aux | grep server.py

# Stop
pkill -f "python3.*server.py"

# Start
cd dashboard && python3 server.py

# Run in background
cd dashboard && nohup python3 server.py > ../logs/dashboard.log 2>&1 &
```

---

## 🐛 Common Issues

### Dashboard won't start

```bash
# Port 8888 already in use
lsof -ti:8888 | xargs kill -9
cd dashboard && python3 server.py
```

### Telegram bot not working

```bash
# Verify bot token
curl https://api.telegram.org/bot<YOUR_TOKEN>/getMe

# Check config
cat config/integrations.json | grep -A 5 telegram

# Common issues:
# - Bot token is string, not number
# - Chat ID is number, not string
# - Forgot to message bot first
```

### No monitoring data

```bash
# Check Miningcore is running
docker-compose ps

# Check pool API
curl http://localhost:4000/api/pools

# Check dashboard API
curl http://localhost:8888/api/admin/system/disk

# Restart everything
docker-compose restart
cd dashboard && python3 server.py
```

### Alert monitor not working

```bash
# Check configuration exists
ls -la config/integrations.json

# Check at least one integration is enabled
cat config/integrations.json | grep '"enabled": true'

# Check logs
sudo journalctl -u ergo-pool-alerts -n 50

# Run in foreground for debugging
cd integrations
python3 alert_monitor.py
```

---

## 📚 Full Documentation

For complete details, see:

1. **[ADMIN-DASHBOARD-SUMMARY.md](ADMIN-DASHBOARD-SUMMARY.md)** - Complete feature summary
2. **[INTEGRATION-SETUP-GUIDE.md](INTEGRATION-SETUP-GUIDE.md)** - Detailed setup guide
3. **[MONITORING-INTEGRATIONS-PLAN.md](MONITORING-INTEGRATIONS-PLAN.md)** - Feature roadmap
4. **[integrations/README.md](integrations/README.md)** - Integration quick reference

---

## 🎯 Recommended Setup

**For most users:**
1. ✅ Start enhanced dashboard
2. ✅ Set up Telegram alerts
3. ✅ Run alert monitor as systemd service

**Minimal setup (just monitoring):**
1. ✅ Start enhanced dashboard
2. ⏭️ Skip integrations
3. ✅ Monitor via admin dashboard only

**Full production setup:**
1. ✅ Enhanced dashboard
2. ✅ Telegram + Discord alerts
3. ✅ Alert monitor as systemd service
4. ✅ Log rotation configured
5. ✅ Backup monitoring enabled

---

## ⏱️ Time to Set Up

- **Dashboard only:** 2 minutes
- **+ Telegram alerts:** 10 minutes
- **+ Discord alerts:** 5 minutes
- **+ Systemd service:** 5 minutes

**Total for full setup: ~20 minutes**

---

## 🎉 You're Done!

Once everything is running:

1. **Check admin dashboard:** http://localhost:8888/admin/
2. **Verify you see:** Disk, CPU, memory, component sizes, docker stats
3. **If alerts enabled:** You'll receive notifications for issues
4. **Monitor service:** `sudo systemctl status ergo-pool-alerts`

Enjoy your enhanced monitoring! 🚀






