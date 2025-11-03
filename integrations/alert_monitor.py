#!/usr/bin/env python3
"""
Alert Monitor for Ergo Mining Pool
Continuously monitors pool status and sends alerts via configured integrations
"""

import time
import requests
import json
import os
import sys
from datetime import datetime

# Import integration modules
try:
    from telegram_bot import TelegramBot
    from discord_webhook import DiscordWebhook
except ImportError:
    print("⚠️  Make sure telegram_bot.py and discord_webhook.py are in the same directory")
    sys.exit(1)

class AlertMonitor:
    def __init__(self, config_file='config/integrations.json'):
        self.telegram = TelegramBot(config_file)
        self.discord = DiscordWebhook(config_file)
        
        # Alert state tracking (to avoid duplicate alerts)
        self.last_alerts = {}
        
        # Configuration
        self.check_interval = 60  # seconds
        self.api_base = 'http://localhost:8888'
        self.pool_api_base = 'http://localhost:4000'
    
    def send_alert(self, alert_type, message):
        """Send alert to all enabled integrations"""
        print(f"🚨 ALERT: {alert_type} - {message}")
        
        results = []
        if self.telegram.enabled:
            results.append(self.telegram.send_alert(alert_type, message))
        if self.discord.enabled:
            results.append(self.discord.send_alert(alert_type, message))
        
        return any(results)
    
    def check_disk_space(self):
        """Check disk space and alert if needed"""
        try:
            response = requests.get(f'{self.api_base}/api/admin/system/disk', timeout=5)
            data = response.json()
            
            usage = data.get('usagePercent', 0)
            
            # Critical alert (>=90%)
            if usage >= 90:
                if not self.last_alerts.get('diskCritical'):
                    self.send_alert('diskSpaceCritical', 
                        f"Disk usage is at *{usage}%*!\n"
                        f"Free space: {data.get('free', 'N/A')}\n"
                        f"Used: {data.get('used', 'N/A')} / {data.get('total', 'N/A')}")
                    self.last_alerts['diskCritical'] = True
            # Warning alert (>=80%)
            elif usage >= 80:
                if not self.last_alerts.get('diskWarning'):
                    self.send_alert('diskSpaceWarning',
                        f"Disk usage is at *{usage}%*\n"
                        f"Free space: {data.get('free', 'N/A')}\n"
                        f"Consider cleanup soon.")
                    self.last_alerts['diskWarning'] = True
                # Clear critical flag
                self.last_alerts['diskCritical'] = False
            # Normal (<80%)
            else:
                # Clear all flags
                self.last_alerts['diskCritical'] = False
                self.last_alerts['diskWarning'] = False
                
        except Exception as e:
            print(f"❌ Error checking disk space: {e}")
    
    def check_pool_status(self):
        """Check if pool is online and responding"""
        try:
            response = requests.get(f'{self.pool_api_base}/api/pools', timeout=5)
            if response.status_code != 200:
                if not self.last_alerts.get('poolOffline'):
                    self.send_alert('poolOffline',
                        f'Pool API returned status {response.status_code}')
                    self.last_alerts['poolOffline'] = True
            else:
                # Pool is online
                if self.last_alerts.get('poolOffline'):
                    # Send recovery notification
                    self.send_alert('poolOffline',
                        '✅ Pool is back online!')
                self.last_alerts['poolOffline'] = False
        except requests.exceptions.RequestException as e:
            if not self.last_alerts.get('poolOffline'):
                self.send_alert('poolOffline',
                    f'Cannot connect to pool API: {str(e)}')
                self.last_alerts['poolOffline'] = True
    
    def check_system_performance(self):
        """Check CPU and memory usage"""
        try:
            response = requests.get(f'{self.api_base}/api/admin/system/performance', timeout=5)
            data = response.json()
            metrics = data.get('metrics', {})
            
            # CPU usage check
            cpu_usage = metrics.get('cpuUsage')
            if cpu_usage and cpu_usage != 'N/A' and cpu_usage >= 90:
                if not self.last_alerts.get('highCpu'):
                    self.send_alert('highCpuUsage',
                        f"CPU usage is at *{cpu_usage}%*")
                    self.last_alerts['highCpu'] = True
            else:
                self.last_alerts['highCpu'] = False
            
            # Memory usage check
            mem = metrics.get('memory')
            if mem and mem != 'N/A':
                mem_usage = mem.get('usagePercent', 0)
                if mem_usage >= 90:
                    if not self.last_alerts.get('highMem'):
                        self.send_alert('highMemoryUsage',
                            f"Memory usage is at *{mem_usage}%*\n"
                            f"Used: {mem.get('used', 'N/A')} / {mem.get('total', 'N/A')}")
                        self.last_alerts['highMem'] = True
                else:
                    self.last_alerts['highMem'] = False
                    
        except Exception as e:
            print(f"❌ Error checking performance: {e}")
    
    def check_node_connection(self):
        """Check if Ergo node is connected"""
        try:
            response = requests.get(f'{self.pool_api_base}/api/pools', timeout=5)
            if response.status_code == 200:
                pools = response.json().get('pools', [])
                if pools:
                    pool = pools[0]
                    network_stats = pool.get('networkStats', {})
                    peers = network_stats.get('connectedPeers', 0)
                    
                    if peers == 0:
                        if not self.last_alerts.get('nodeDisconnected'):
                            self.send_alert('nodeDisconnected',
                                'Ergo node has 0 connected peers!')
                            self.last_alerts['nodeDisconnected'] = True
                    else:
                        self.last_alerts['nodeDisconnected'] = False
        except Exception as e:
            print(f"❌ Error checking node connection: {e}")
    
    def run(self):
        """Run continuous monitoring"""
        print("=" * 60)
        print("🔍 Ergo Pool Alert Monitor Started")
        print("=" * 60)
        print(f"Check interval: {self.check_interval} seconds")
        print(f"Dashboard API: {self.api_base}")
        print(f"Pool API: {self.pool_api_base}")
        print("=" * 60)
        print("\nActive Integrations:")
        print(f"  Telegram: {'✅ Enabled' if self.telegram.enabled else '❌ Disabled'}")
        print(f"  Discord:  {'✅ Enabled' if self.discord.enabled else '❌ Disabled'}")
        print("=" * 60)
        print("\nPress Ctrl+C to stop")
        print("=" * 60)
        print()
        
        # Send startup notification
        startup_msg = f"🔍 *Alert Monitor Started*\n\nMonitoring pool status every {self.check_interval} seconds..."
        if self.telegram.enabled:
            self.telegram.send_message(startup_msg)
        if self.discord.enabled:
            self.discord.send_embed(
                "🔍 Alert Monitor Started",
                f"Monitoring pool status every {self.check_interval} seconds...",
                0x00FFAA
            )
        
        while True:
            try:
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                print(f"[{timestamp}] Running checks...")
                
                # Run all checks
                self.check_pool_status()
                self.check_disk_space()
                self.check_system_performance()
                self.check_node_connection()
                
                print(f"[{timestamp}] Checks complete. Next check in {self.check_interval}s")
                print()
                
                time.sleep(self.check_interval)
                
            except KeyboardInterrupt:
                print("\n" + "=" * 60)
                print("⏹️  Monitor stopped by user")
                print("=" * 60)
                
                # Send shutdown notification
                shutdown_msg = "⏹️ *Alert Monitor Stopped*"
                if self.telegram.enabled:
                    self.telegram.send_message(shutdown_msg)
                if self.discord.enabled:
                    self.discord.send_embed(
                        "⏹️ Alert Monitor Stopped",
                        "Monitoring has been stopped",
                        0xFF5555
                    )
                break
                
            except Exception as e:
                print(f"❌ Error in monitor loop: {e}")
                time.sleep(self.check_interval)

if __name__ == '__main__':
    # Check if integrations are configured
    if not os.path.exists('config/integrations.json'):
        print("❌ Config file not found: config/integrations.json")
        print("\n📋 Setup Instructions:")
        print("1. Copy template: cp config/integrations.json.template config/integrations.json")
        print("2. Edit config: nano config/integrations.json")
        print("3. Configure at least one integration (Telegram or Discord)")
        print("4. Run this script again")
        sys.exit(1)
    
    monitor = AlertMonitor()
    
    # Check if at least one integration is enabled
    if not (monitor.telegram.enabled or monitor.discord.enabled):
        print("⚠️  No integrations are enabled!")
        print("\nPlease enable at least one integration in config/integrations.json")
        print("Available integrations: telegram, discord")
        sys.exit(1)
    
    monitor.run()






