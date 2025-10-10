#!/usr/bin/env python3
"""
Telegram Bot Integration for Ergo Mining Pool
Sends alerts and status updates via Telegram
"""

import requests
import json
import os
from datetime import datetime

class TelegramBot:
    def __init__(self, config_file='config/integrations.json'):
        self.config_file = config_file
        if os.path.exists(config_file):
            with open(config_file) as f:
                config = json.load(f)
                self.telegram = config.get('telegram', {})
        else:
            print(f"⚠️  Config file not found: {config_file}")
            print(f"   Copy config/integrations.json.template to config/integrations.json")
            self.telegram = {}
        
        self.bot_token = self.telegram.get('botToken')
        self.chat_ids = self.telegram.get('chatIds', [])
        self.enabled = self.telegram.get('enabled', False)
        self.alerts = self.telegram.get('alerts', {})
        self.message_format = self.telegram.get('messageFormat', 'Markdown')
    
    def send_message(self, message, parse_mode=None):
        """Send message to all configured chat IDs"""
        if not self.enabled:
            print("ℹ️  Telegram integration is disabled")
            return False
        
        if not self.bot_token:
            print("❌ Bot token not configured")
            return False
        
        if not self.chat_ids:
            print("❌ No chat IDs configured")
            return False
        
        url = f"https://api.telegram.org/bot{self.bot_token}/sendMessage"
        parse_mode = parse_mode or self.message_format
        
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
                    print(f"❌ Error sending to {chat_id}: {response.text}")
                    success = False
                else:
                    print(f"✅ Message sent to {chat_id}")
            except Exception as e:
                print(f"❌ Exception sending to {chat_id}: {e}")
                success = False
        
        return success
    
    def send_alert(self, alert_type, details):
        """Send formatted alert message"""
        if not self.alerts.get(alert_type, False):
            print(f"ℹ️  Alert type '{alert_type}' is disabled")
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
            'newBlockFound': '🎯',
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
    
    def send_new_block(self, block_data):
        """Send new block notification"""
        if not self.alerts.get('newBlockFound', False):
            return False
        
        message = f"""
🎯 *NEW BLOCK FOUND!*

*Height:* {block_data.get('height', 'N/A')}
*Reward:* {block_data.get('reward', 0)} ERG
*Effort:* {block_data.get('effort', 0)}%
*Miner:* `{block_data.get('miner', 'Unknown')}`

_Time: {datetime.now().strftime('%H:%M:%S')}_
"""
        return self.send_message(message)
    
    def test_connection(self):
        """Test bot connection"""
        try:
            if not self.bot_token:
                print("❌ No bot token configured")
                return False
            
            url = f"https://api.telegram.org/bot{self.bot_token}/getMe"
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                bot_info = response.json()
                username = bot_info['result']['username']
                print(f"✅ Connected to bot: @{username}")
                return True
            else:
                print(f"❌ Connection failed: {response.text}")
                return False
        except Exception as e:
            print(f"❌ Exception: {e}")
            return False

# Example usage and testing
if __name__ == '__main__':
    import sys
    
    bot = TelegramBot()
    
    # Test connection
    if bot.test_connection():
        # Send test message
        if '--test-message' in sys.argv:
            bot.send_message("🚀 *Bot is online!*\n\nErgo Pool monitoring bot is now active.")
        
        # Send test alert
        if '--test-alert' in sys.argv:
            bot.send_alert('diskSpaceWarning', 'Disk usage is at 85%')
        
        # Send test block notification
        if '--test-block' in sys.argv:
            bot.send_new_block({
                'height': 123456,
                'reward': 67.5,
                'effort': 95.3,
                'miner': '9f4QF8AD1nQ3nJahQVkMj8hFSVBzVcU...'
            })
    else:
        print("\n⚠️  Setup Instructions:")
        print("1. Talk to @BotFather on Telegram")
        print("2. Send: /newbot")
        print("3. Follow prompts to create your bot")
        print("4. Copy the bot token")
        print("5. Get your chat ID:")
        print("   - Message your bot")
        print("   - Run: curl https://api.telegram.org/bot<TOKEN>/getUpdates")
        print("6. Update config/integrations.json with token and chat ID")
        print("\nUsage:")
        print("  python3 integrations/telegram_bot.py                # Test connection")
        print("  python3 integrations/telegram_bot.py --test-message # Send test message")
        print("  python3 integrations/telegram_bot.py --test-alert   # Send test alert")
        print("  python3 integrations/telegram_bot.py --test-block   # Send test block")

