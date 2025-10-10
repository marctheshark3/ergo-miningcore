# Pool Integrations

External service integrations for the Ergo Mining Pool.

## 📁 Files

- `telegram_bot.py` - Telegram bot integration
- `discord_webhook.py` - Discord webhook integration  
- `alert_monitor.py` - Continuous monitoring and alerting service
- `manager.py` - Unified integration manager (optional)

## 🚀 Quick Start

### 1. Install Requirements

```bash
pip3 install requests
```

### 2. Configure Integrations

```bash
# Copy template
cp ../config/integrations.json.template ../config/integrations.json

# Edit configuration
nano ../config/integrations.json
```

### 3. Test Integrations

**Telegram:**
```bash
python3 telegram_bot.py                # Test connection
python3 telegram_bot.py --test-message # Send test message
python3 telegram_bot.py --test-alert   # Send test alert
python3 telegram_bot.py --test-block   # Send test block notification
```

**Discord:**
```bash
python3 discord_webhook.py              # Test connection
python3 discord_webhook.py --test-alert # Send test alert
python3 discord_webhook.py --test-block # Send test block notification
```

### 4. Run Alert Monitor

```bash
# Run in foreground
python3 alert_monitor.py

# Run in background
nohup python3 alert_monitor.py > ../logs/alert-monitor.log 2>&1 &

# Check if running
ps aux | grep alert_monitor
```

## 🔧 Setup Guides

### Telegram Setup

1. **Create Bot:**
   - Open Telegram, search for `@BotFather`
   - Send: `/newbot`
   - Follow prompts
   - Save bot token

2. **Get Chat ID:**
   ```bash
   # Message your bot first, then:
   curl https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
   # Look for: "chat":{"id": YOUR_CHAT_ID}
   ```

3. **Configure:**
   ```json
   {
     "telegram": {
       "enabled": true,
       "botToken": "YOUR_BOT_TOKEN",
       "chatIds": ["YOUR_CHAT_ID"]
     }
   }
   ```

### Discord Setup

1. **Create Webhook:**
   - Server Settings → Integrations → Webhooks
   - Click "New Webhook"
   - Copy webhook URL

2. **Configure:**
   ```json
   {
     "discord": {
       "enabled": true,
       "webhookUrl": "YOUR_WEBHOOK_URL"
     }
   }
   ```

## 📊 Available Alerts

- `poolOffline` - Pool API is not responding
- `nodeDisconnected` - Ergo node has no peers
- `diskSpaceWarning` - Disk usage ≥80%
- `diskSpaceCritical` - Disk usage ≥90%
- `highCpuUsage` - CPU usage ≥90%
- `highMemoryUsage` - Memory usage ≥90%
- `newBlockFound` - New block mined
- `noBlocksFound` - No blocks in X hours
- `paymentFailed` - Payment transaction failed

## 🔄 Running as Service

### Using systemd (Recommended)

1. **Create service file:**
   ```bash
   sudo nano /etc/systemd/system/ergo-pool-alerts.service
   ```

2. **Add configuration:**
   ```ini
   [Unit]
   Description=Ergo Pool Alert Monitor
   After=network.target

   [Service]
   Type=simple
   User=YOUR_USER
   WorkingDirectory=/path/to/ergo-miningcore/integrations
   ExecStart=/usr/bin/python3 /path/to/ergo-miningcore/integrations/alert_monitor.py
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   ```

3. **Enable and start:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable ergo-pool-alerts
   sudo systemctl start ergo-pool-alerts
   sudo systemctl status ergo-pool-alerts
   ```

4. **View logs:**
   ```bash
   sudo journalctl -u ergo-pool-alerts -f
   ```

### Using screen (Alternative)

```bash
screen -S pool-alerts
cd /path/to/ergo-miningcore/integrations
python3 alert_monitor.py
# Press Ctrl+A then D to detach

# Reattach later
screen -r pool-alerts
```

## 🧪 Testing

Test individual components:

```bash
# Test Telegram
python3 -c "from telegram_bot import TelegramBot; bot = TelegramBot(); bot.test_connection()"

# Test Discord  
python3 -c "from discord_webhook import DiscordWebhook; hook = DiscordWebhook(); hook.test_connection()"

# Test full monitor (dry run for 1 minute)
timeout 60 python3 alert_monitor.py
```

## 📝 Customization

### Adding New Alert Types

1. Add to `config/integrations.json`:
   ```json
   "alerts": {
     "customAlert": true
   }
   ```

2. Add check in `alert_monitor.py`:
   ```python
   def check_custom_condition(self):
       if condition_met:
           self.send_alert('customAlert', 'Alert message')
   ```

3. Add emoji mapping in integrations:
   ```python
   emojis = {
       'customAlert': '🔔'
   }
   ```

### Adjusting Check Interval

Edit `alert_monitor.py`:
```python
self.check_interval = 300  # 5 minutes
```

## 🐛 Troubleshooting

**Telegram not working:**
- Verify bot token is correct
- Ensure chat ID is a number
- Message your bot first before getting chat ID
- Check firewall allows HTTPS to api.telegram.org

**Discord not working:**
- Verify webhook URL hasn't been deleted
- Check webhook has permissions in Discord
- Ensure JSON payload is valid

**Monitor not detecting issues:**
- Verify API endpoints are accessible
- Check `api_base` and `pool_api_base` URLs
- Ensure dashboard server is running on port 8888
- Verify pool API is running on port 4000

## 📚 More Information

See the main integration guide: `../INTEGRATION-SETUP-GUIDE.md`

