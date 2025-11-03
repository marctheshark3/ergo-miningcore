# Pool Integration Setup Guide

Complete guide for setting up external integrations with your Ergo Mining Pool.

---

## 📱 Telegram Bot Integration

### Step 1: Create Your Telegram Bot

1. **Open Telegram** and search for `@BotFather`
2. **Start a chat** with BotFather
3. **Send the command:** `/newbot`
4. **Follow the prompts:**
   - Enter a name for your bot (e.g., "My Ergo Pool Bot")
   - Enter a username for your bot (must end with 'bot', e.g., "my_ergo_pool_bot")
5. **Save your bot token** (looks like: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### Step 2: Get Your Chat ID

1. **Start a chat** with your new bot
2. **Send any message** to your bot
3. **Run this command** to get updates:
   ```bash
   curl https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
   ```
4. **Look for** `"chat":{"id": YOUR_CHAT_ID}` in the response
5. **Save your chat ID** (it's a number like: `987654321`)

### Step 3: Configure the Integration

Create configuration file at `config/integrations.json`:

```json
{
  "telegram": {
    "enabled": true,
    "botToken": "123456789:ABCdefGHIjklMNOpqrsTUVwxyz",
    "chatIds": ["987654321"],
    "alerts": {
      "poolOffline": true,
      "nodeDisconnected": true,
      "diskSpaceWarning": true,
      "diskSpaceCritical": true,
      "highCpuUsage": true,
      "highMemoryUsage": true,
      "noBlocksFound": true,
      "paymentFailed": false
    },
    "messageFormat": "markdown"
  }
}
```

### Step 4: Implement the Bot (Python Example)

Create `integrations/telegram_bot.py`:

```python
#!/usr/bin/env python3
import requests
import json
from datetime import datetime

class TelegramBot:
    def __init__(self, config_file='config/integrations.json'):
        with open(config_file) as f:
            config = json.load(f)
            self.telegram = config.get('telegram', {})
            self.bot_token = self.telegram.get('botToken')
            self.chat_ids = self.telegram.get('chatIds', [])
            self.enabled = self.telegram.get('enabled', False)
            self.alerts = self.telegram.get('alerts', {})
    
    def send_message(self, message, parse_mode='Markdown'):
        """Send message to all configured chat IDs"""
        if not self.enabled:
            return False
        
        url = f"https://api.telegram.org/bot{self.bot_token}/sendMessage"
        
        success = True
        for chat_id in self.chat_ids:
            payload = {
                'chat_id': chat_id,
                'text': message,
                'parse_mode': parse_mode
            }
            try:
                response = requests.post(url, json=payload, timeout=10)
                if response.status_code != 200:
                    print(f"Error sending to {chat_id}: {response.text}")
                    success = False
            except Exception as e:
                print(f"Exception sending to {chat_id}: {e}")
                success = False
        
        return success
    
    def send_alert(self, alert_type, details):
        """Send formatted alert message"""
        if not self.alerts.get(alert_type, False):
            return False
        
        # Alert emoji mapping
        emojis = {
            'poolOffline': '🔴',
            'nodeDisconnected': '⚠️',
            'diskSpaceWarning': '📊',
            'diskSpaceCritical': '🚨',
            'highCpuUsage': '🔥',
            'highMemoryUsage': '💾',
            'noBlocksFound': '⏰',
            'paymentFailed': '💸'
        }
        
        emoji = emojis.get(alert_type, '⚠️')
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        message = f"""
{emoji} *ALERT: {alert_type.replace('_', ' ').title()}*

{details}

_Time: {timestamp}_
"""
        
        return self.send_message(message)
    
    def send_pool_status(self, pool_data):
        """Send pool status update"""
        message = f"""
📊 *Pool Status Update*

*Hashrate:* {pool_data.get('hashrate', 'N/A')}
*Miners:* {pool_data.get('miners', 0)}
*Network Height:* {pool_data.get('blockHeight', 'N/A')}
*Pool Share:* {pool_data.get('networkShare', 'N/A')}

_Updated: {datetime.now().strftime('%H:%M:%S')}_
"""
        return self.send_message(message)
    
    def test_connection(self):
        """Test bot connection"""
        try:
            url = f"https://api.telegram.org/bot{self.bot_token}/getMe"
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                bot_info = response.json()
                print(f"✅ Connected to bot: {bot_info['result']['username']}")
                return True
            else:
                print(f"❌ Connection failed: {response.text}")
                return False
        except Exception as e:
            print(f"❌ Exception: {e}")
            return False

# Example usage
if __name__ == '__main__':
    bot = TelegramBot()
    
    # Test connection
    if bot.test_connection():
        # Send test message
        bot.send_message("🚀 *Bot is online!*\n\nErgo Pool monitoring bot is now active.")
        
        # Send test alert
        bot.send_alert('diskSpaceWarning', 'Disk usage is at 85%')
```

### Step 5: Set Up Alert Monitoring

Create `integrations/alert_monitor.py`:

```python
#!/usr/bin/env python3
import time
import requests
from telegram_bot import TelegramBot

class AlertMonitor:
    def __init__(self):
        self.bot = TelegramBot()
        self.last_alerts = {}
        self.check_interval = 60  # seconds
    
    def check_disk_space(self):
        """Check disk space and alert if needed"""
        try:
            response = requests.get('http://localhost:8888/api/admin/system/disk')
            data = response.json()
            
            usage = data.get('usagePercent', 0)
            
            if usage >= 90 and not self.last_alerts.get('diskCritical'):
                self.bot.send_alert('diskSpaceCritical', 
                    f"Disk usage is at *{usage}%*!\nFree space: {data.get('free', 'N/A')}")
                self.last_alerts['diskCritical'] = True
            elif usage >= 80 and not self.last_alerts.get('diskWarning'):
                self.bot.send_alert('diskSpaceWarning',
                    f"Disk usage is at *{usage}%*\nConsider cleanup soon.")
                self.last_alerts['diskWarning'] = True
            elif usage < 80:
                self.last_alerts['diskCritical'] = False
                self.last_alerts['diskWarning'] = False
                
        except Exception as e:
            print(f"Error checking disk space: {e}")
    
    def check_pool_status(self):
        """Check if pool is online"""
        try:
            response = requests.get('http://localhost:4000/api/pools')
            if response.status_code != 200:
                if not self.last_alerts.get('poolOffline'):
                    self.bot.send_alert('poolOffline',
                        'Pool API is not responding!')
                    self.last_alerts['poolOffline'] = True
            else:
                self.last_alerts['poolOffline'] = False
        except Exception as e:
            if not self.last_alerts.get('poolOffline'):
                self.bot.send_alert('poolOffline',
                    f'Cannot connect to pool API: {str(e)}')
                self.last_alerts['poolOffline'] = True
    
    def run(self):
        """Run continuous monitoring"""
        print("🔍 Alert monitor started...")
        self.bot.send_message("🔍 *Alert Monitor Started*\n\nMonitoring pool status...")
        
        while True:
            try:
                self.check_disk_space()
                self.check_pool_status()
                # Add more checks here
                
                time.sleep(self.check_interval)
            except KeyboardInterrupt:
                print("\n⏹️ Monitor stopped")
                self.bot.send_message("⏹️ *Alert Monitor Stopped*")
                break
            except Exception as e:
                print(f"Error in monitor loop: {e}")
                time.sleep(self.check_interval)

if __name__ == '__main__':
    monitor = AlertMonitor()
    monitor.run()
```

### Step 6: Run the Monitor

```bash
# Make scripts executable
chmod +x integrations/telegram_bot.py
chmod +x integrations/alert_monitor.py

# Install requirements
pip3 install requests

# Test the bot
python3 integrations/telegram_bot.py

# Run the monitor
python3 integrations/alert_monitor.py

# Or run in background
nohup python3 integrations/alert_monitor.py > logs/telegram-monitor.log 2>&1 &
```

---

## 💬 Discord Webhook Integration

### Step 1: Create Discord Webhook

1. **Go to your Discord server**
2. **Click on** Server Settings → Integrations → Webhooks
3. **Click** "New Webhook"
4. **Configure webhook:**
   - Name: "Ergo Pool Bot"
   - Channel: Select your channel
   - Copy webhook URL
5. **Save** the webhook URL

### Step 2: Configure Integration

Add to `config/integrations.json`:

```json
{
  "discord": {
    "enabled": true,
    "webhookUrl": "https://discord.com/api/webhooks/123456789/abcdefg...",
    "username": "Ergo Pool Monitor",
    "avatarUrl": "https://your-logo-url.com/logo.png",
    "alerts": {
      "poolOffline": true,
      "diskSpaceCritical": true,
      "newBlock": true
    }
  }
}
```

### Step 3: Implement Discord Webhook

Create `integrations/discord_webhook.py`:

```python
#!/usr/bin/env python3
import requests
import json
from datetime import datetime

class DiscordWebhook:
    def __init__(self, config_file='config/integrations.json'):
        with open(config_file) as f:
            config = json.load(f)
            self.discord = config.get('discord', {})
            self.webhook_url = self.discord.get('webhookUrl')
            self.username = self.discord.get('username', 'Pool Monitor')
            self.avatar_url = self.discord.get('avatarUrl', '')
            self.enabled = self.discord.get('enabled', False)
            self.alerts = self.discord.get('alerts', {})
    
    def send_embed(self, title, description, color=0x00FFAA, fields=None):
        """Send rich embed message to Discord"""
        if not self.enabled:
            return False
        
        embed = {
            'title': title,
            'description': description,
            'color': color,
            'timestamp': datetime.utcnow().isoformat(),
            'footer': {
                'text': 'Ergo Mining Pool'
            }
        }
        
        if fields:
            embed['fields'] = fields
        
        payload = {
            'username': self.username,
            'embeds': [embed]
        }
        
        if self.avatar_url:
            payload['avatar_url'] = self.avatar_url
        
        try:
            response = requests.post(self.webhook_url, json=payload, timeout=10)
            return response.status_code == 204
        except Exception as e:
            print(f"Error sending Discord webhook: {e}")
            return False
    
    def send_alert(self, alert_type, details):
        """Send alert to Discord"""
        if not self.alerts.get(alert_type, False):
            return False
        
        # Color mapping
        colors = {
            'poolOffline': 0xFF0000,      # Red
            'diskSpaceCritical': 0xFF0000, # Red
            'diskSpaceWarning': 0xFFAA00,  # Orange
            'newBlock': 0x00FF00,          # Green
            'highCpuUsage': 0xFFAA00       # Orange
        }
        
        color = colors.get(alert_type, 0x00FFAA)
        title = f"⚠️ {alert_type.replace('_', ' ').upper()}"
        
        return self.send_embed(title, details, color)
    
    def send_new_block(self, block_data):
        """Send new block notification"""
        if not self.alerts.get('newBlock', False):
            return False
        
        fields = [
            {
                'name': 'Height',
                'value': str(block_data.get('height', 'N/A')),
                'inline': True
            },
            {
                'name': 'Reward',
                'value': f"{block_data.get('reward', 0)} ERG",
                'inline': True
            },
            {
                'name': 'Effort',
                'value': f"{block_data.get('effort', 0)}%",
                'inline': True
            }
        ]
        
        return self.send_embed(
            '🎯 New Block Found!',
            'Your pool has found a new block!',
            0x00FF00,
            fields
        )
    
    def test_connection(self):
        """Test webhook connection"""
        return self.send_embed(
            '✅ Webhook Connected',
            'Discord integration is working correctly!',
            0x00FFAA
        )

# Example usage
if __name__ == '__main__':
    webhook = DiscordWebhook()
    if webhook.test_connection():
        print("✅ Discord webhook is working!")
    else:
        print("❌ Discord webhook failed!")
```

---

## 📧 Email Notifications

### Step 1: Configure SMTP

Add to `config/integrations.json`:

```json
{
  "email": {
    "enabled": true,
    "smtp": {
      "host": "smtp.gmail.com",
      "port": 587,
      "username": "your-email@gmail.com",
      "password": "your-app-password",
      "useTLS": true
    },
    "from": "noreply@yourpool.com",
    "recipients": [
      "admin@yourpool.com",
      "alerts@yourpool.com"
    ],
    "alerts": {
      "poolOffline": true,
      "criticalOnly": false
    }
  }
}
```

### Step 2: Implement Email Notifications

Create `integrations/email_notifier.py`:

```python
#!/usr/bin/env python3
import smtplib
import json
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

class EmailNotifier:
    def __init__(self, config_file='config/integrations.json'):
        with open(config_file) as f:
            config = json.load(f)
            self.email = config.get('email', {})
            self.smtp_config = self.email.get('smtp', {})
            self.enabled = self.email.get('enabled', False)
            self.from_addr = self.email.get('from')
            self.recipients = self.email.get('recipients', [])
    
    def send_email(self, subject, body_html):
        """Send email notification"""
        if not self.enabled:
            return False
        
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = self.from_addr
        msg['To'] = ', '.join(self.recipients)
        
        html_part = MIMEText(body_html, 'html')
        msg.attach(html_part)
        
        try:
            server = smtplib.SMTP(
                self.smtp_config['host'],
                self.smtp_config['port']
            )
            if self.smtp_config.get('useTLS', True):
                server.starttls()
            
            server.login(
                self.smtp_config['username'],
                self.smtp_config['password']
            )
            
            server.send_message(msg)
            server.quit()
            return True
        except Exception as e:
            print(f"Error sending email: {e}")
            return False
    
    def send_alert(self, alert_type, details):
        """Send formatted alert email"""
        subject = f"🚨 Pool Alert: {alert_type.replace('_', ' ').title()}"
        
        body = f"""
        <html>
          <body style="font-family: Arial, sans-serif;">
            <h2 style="color: #FF5555;">Alert: {alert_type}</h2>
            <p>{details}</p>
            <hr>
            <p style="color: #666;">
              <small>Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</small>
            </p>
          </body>
        </html>
        """
        
        return self.send_email(subject, body)

# Example usage
if __name__ == '__main__':
    notifier = EmailNotifier()
    notifier.send_alert('test', 'This is a test alert')
```

---

## 🔧 Integration Manager

Create a unified manager for all integrations at `integrations/manager.py`:

```python
#!/usr/bin/env python3
import json
from telegram_bot import TelegramBot
from discord_webhook import DiscordWebhook
from email_notifier import EmailNotifier

class IntegrationManager:
    def __init__(self, config_file='config/integrations.json'):
        self.telegram = TelegramBot(config_file)
        self.discord = DiscordWebhook(config_file)
        self.email = EmailNotifier(config_file)
    
    def send_alert_all(self, alert_type, details):
        """Send alert to all enabled integrations"""
        results = {
            'telegram': self.telegram.send_alert(alert_type, details),
            'discord': self.discord.send_alert(alert_type, details),
            'email': self.email.send_alert(alert_type, details)
        }
        return results
    
    def test_all(self):
        """Test all integrations"""
        print("Testing integrations...")
        print(f"Telegram: {'✅' if self.telegram.test_connection() else '❌'}")
        print(f"Discord: {'✅' if self.discord.test_connection() else '❌'}")
        print(f"Email: {'✅' if self.email.send_email('Test', '<p>Test</p>') else '❌'}")

if __name__ == '__main__':
    manager = IntegrationManager()
    manager.test_all()
```

---

## 🚀 Quick Start Commands

```bash
# Create integrations directory
mkdir -p integrations
mkdir -p config

# Install Python requirements
pip3 install requests

# Copy integration scripts (from above examples)

# Configure your integrations
nano config/integrations.json

# Test integrations
python3 integrations/telegram_bot.py
python3 integrations/discord_webhook.py

# Run alert monitor
python3 integrations/alert_monitor.py

# Run in background with systemd (recommended)
sudo nano /etc/systemd/system/ergo-pool-alerts.service
```

### Systemd Service File

Create `/etc/systemd/system/ergo-pool-alerts.service`:

```ini
[Unit]
Description=Ergo Pool Alert Monitor
After=network.target

[Service]
Type=simple
User=youruser
WorkingDirectory=/path/to/ergo-miningcore
ExecStart=/usr/bin/python3 /path/to/ergo-miningcore/integrations/alert_monitor.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable ergo-pool-alerts
sudo systemctl start ergo-pool-alerts
sudo systemctl status ergo-pool-alerts
```

---

## 📊 Monitoring Dashboard Integration

To display integration status in the admin dashboard, you can add API endpoints and UI elements. The monitoring data from the enhanced server.py is already integrated into the admin dashboard.

---

## 🔍 Troubleshooting

### Telegram Bot Issues
- Verify bot token is correct
- Ensure chat ID is a number
- Check firewall allows HTTPS to api.telegram.org
- Test with: `curl https://api.telegram.org/bot<TOKEN>/getMe`

### Discord Webhook Issues
- Verify webhook URL hasn't been deleted
- Check webhook permissions in Discord
- Ensure JSON payload is valid

### Email Issues
- Use app-specific password for Gmail
- Enable "Less secure app access" or use OAuth2
- Check SMTP port (usually 587 for TLS, 465 for SSL)
- Verify firewall allows SMTP traffic

---

## 📝 Next Steps

1. Configure your preferred integrations
2. Test each integration separately
3. Set up alert monitoring
4. Customize alert rules
5. Set up systemd service for continuous monitoring
6. Monitor logs for issues

For additional help, check the main `MONITORING-INTEGRATIONS-PLAN.md` document.






