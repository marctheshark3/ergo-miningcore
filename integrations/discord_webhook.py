#!/usr/bin/env python3
"""
Discord Webhook Integration for Ergo Mining Pool
Sends rich embed messages to Discord channels
"""

import requests
import json
import os
from datetime import datetime

class DiscordWebhook:
    def __init__(self, config_file='config/integrations.json'):
        self.config_file = config_file
        if os.path.exists(config_file):
            with open(config_file) as f:
                config = json.load(f)
                self.discord = config.get('discord', {})
        else:
            print(f"⚠️  Config file not found: {config_file}")
            self.discord = {}
        
        self.webhook_url = self.discord.get('webhookUrl')
        self.username = self.discord.get('username', 'Pool Monitor')
        self.avatar_url = self.discord.get('avatarUrl', '')
        self.enabled = self.discord.get('enabled', False)
        self.alerts = self.discord.get('alerts', {})
    
    def send_embed(self, title, description, color=0x00FFAA, fields=None):
        """Send rich embed message to Discord"""
        if not self.enabled:
            print("ℹ️  Discord integration is disabled")
            return False
        
        if not self.webhook_url:
            print("❌ Webhook URL not configured")
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
            if response.status_code == 204:
                print("✅ Message sent to Discord")
                return True
            else:
                print(f"❌ Error: {response.status_code} - {response.text}")
                return False
        except Exception as e:
            print(f"❌ Error sending Discord webhook: {e}")
            return False
    
    def send_alert(self, alert_type, details):
        """Send alert to Discord"""
        if not self.alerts.get(alert_type, False):
            print(f"ℹ️  Alert type '{alert_type}' is disabled")
            return False
        
        # Color mapping
        colors = {
            'poolOffline': 0xFF0000,       # Red
            'diskSpaceCritical': 0xFF0000, # Red
            'diskSpaceWarning': 0xFFAA00,  # Orange
            'newBlockFound': 0x00FF00,     # Green
            'highCpuUsage': 0xFFAA00,      # Orange
            'nodeDisconnected': 0xFF5555   # Light Red
        }
        
        color = colors.get(alert_type, 0x00FFAA)
        title = f"⚠️ {alert_type.replace('_', ' ').upper()}"
        
        return self.send_embed(title, details, color)
    
    def send_new_block(self, block_data):
        """Send new block notification"""
        if not self.alerts.get('newBlockFound', False):
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
            },
            {
                'name': 'Miner',
                'value': f"`{block_data.get('miner', 'Unknown')}`",
                'inline': False
            }
        ]
        
        return self.send_embed(
            '🎯 New Block Found!',
            'Your pool has found a new block!',
            0x00FF00,
            fields
        )
    
    def send_pool_status(self, pool_data):
        """Send pool status update"""
        fields = [
            {
                'name': 'Hashrate',
                'value': pool_data.get('hashrate', 'N/A'),
                'inline': True
            },
            {
                'name': 'Miners',
                'value': str(pool_data.get('miners', 0)),
                'inline': True
            },
            {
                'name': 'Network Height',
                'value': str(pool_data.get('blockHeight', 'N/A')),
                'inline': True
            },
            {
                'name': 'Pool Share',
                'value': pool_data.get('networkShare', 'N/A'),
                'inline': True
            }
        ]
        
        return self.send_embed(
            '📊 Pool Status Update',
            'Current pool statistics',
            0x00FFAA,
            fields
        )
    
    def test_connection(self):
        """Test webhook connection"""
        return self.send_embed(
            '✅ Webhook Connected',
            'Discord integration is working correctly!',
            0x00FFAA
        )

# Example usage and testing
if __name__ == '__main__':
    import sys
    
    webhook = DiscordWebhook()
    
    if webhook.test_connection():
        print("✅ Discord webhook is working!")
        
        if '--test-alert' in sys.argv:
            webhook.send_alert('diskSpaceWarning', 'Disk usage is at 85%')
        
        if '--test-block' in sys.argv:
            webhook.send_new_block({
                'height': 123456,
                'reward': 67.5,
                'effort': 95.3,
                'miner': '9f4QF8AD1nQ3nJahQVkMj8hFSVBzVcU...'
            })
    else:
        print("❌ Discord webhook failed!")
        print("\n⚠️  Setup Instructions:")
        print("1. Go to your Discord server")
        print("2. Server Settings → Integrations → Webhooks")
        print("3. Click 'New Webhook'")
        print("4. Configure:")
        print("   - Name: Ergo Pool Bot")
        print("   - Channel: Select your channel")
        print("5. Copy webhook URL")
        print("6. Update config/integrations.json")
        print("\nUsage:")
        print("  python3 integrations/discord_webhook.py                # Test connection")
        print("  python3 integrations/discord_webhook.py --test-alert   # Send test alert")
        print("  python3 integrations/discord_webhook.py --test-block   # Send test block")

