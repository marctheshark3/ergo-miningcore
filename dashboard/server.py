#!/usr/bin/env python3
"""
Enhanced HTTP Server for Ergo Pool Dashboard
Serves the dashboard with API proxy and system monitoring endpoints
"""

import http.server
import socketserver
import os
import sys
import urllib.request
import json
import subprocess
import shutil
from urllib.parse import parse_qs, urlparse
from datetime import datetime

PORT = 8888
DIRECTORY = os.path.dirname(os.path.abspath(__file__))
API_BASE_URL = 'http://localhost:4000'

class DashboardHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # Enable CORS
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()
    
    def do_GET(self):
        # Handle custom monitoring endpoints
        if self.path == '/api/admin/system/disk':
            self.handle_disk_info()
            return
        elif self.path == '/api/admin/system/components':
            self.handle_component_sizes()
            return
        elif self.path == '/api/admin/system/performance':
            self.handle_performance_metrics()
            return
        elif self.path == '/api/admin/system/docker':
            self.handle_docker_stats()
            return
        
        # Proxy API requests to Miningcore API
        if self.path.startswith('/api'):
            self.proxy_api_request()
            return
        
        # Redirect root to public dashboard
        if self.path == '/':
            self.path = '/public/index.html'
        super().do_GET()
    
    def handle_disk_info(self):
        """Get disk space information"""
        try:
            # Get overall disk stats
            stat = shutil.disk_usage('/')
            total_gb = stat.total / (1024**3)
            used_gb = stat.used / (1024**3)
            free_gb = stat.free / (1024**3)
            usage_percent = (stat.used / stat.total) * 100
            
            # Get component sizes
            components = {}
            
            # PostgreSQL database size
            try:
                result = subprocess.run(
                    ['docker', 'exec', 'ergo-miningcore-postgres', 'psql', '-U', 'miningcore', '-t', '-c',
                     "SELECT pg_size_pretty(pg_database_size('miningcore'));"],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    components['postgresql'] = result.stdout.strip()
            except:
                components['postgresql'] = 'N/A'
            
            # Ergo node data size (if accessible)
            ergo_data_path = '/home/whaleshark/.ergo'
            if os.path.exists(ergo_data_path):
                try:
                    result = subprocess.run(
                        ['du', '-sh', ergo_data_path],
                        capture_output=True, text=True, timeout=10
                    )
                    if result.returncode == 0:
                        components['ergoNode'] = result.stdout.split()[0]
                except:
                    components['ergoNode'] = 'N/A'
            else:
                components['ergoNode'] = 'N/A'
            
            # Log files size
            log_path = os.path.join(os.path.dirname(DIRECTORY), 'logs')
            if os.path.exists(log_path):
                try:
                    result = subprocess.run(
                        ['du', '-sh', log_path],
                        capture_output=True, text=True, timeout=5
                    )
                    if result.returncode == 0:
                        components['logs'] = result.stdout.split()[0]
                except:
                    components['logs'] = 'N/A'
            else:
                components['logs'] = 'N/A'
            
            # Backup directory size
            backup_path = os.path.join(os.path.dirname(DIRECTORY), 'backups')
            if os.path.exists(backup_path):
                try:
                    result = subprocess.run(
                        ['du', '-sh', backup_path],
                        capture_output=True, text=True, timeout=5
                    )
                    if result.returncode == 0:
                        components['backups'] = result.stdout.split()[0]
                except:
                    components['backups'] = 'N/A'
            else:
                components['backups'] = '0B'
            
            response_data = {
                'total': f'{total_gb:.1f} GB',
                'used': f'{used_gb:.1f} GB',
                'free': f'{free_gb:.1f} GB',
                'usagePercent': round(usage_percent, 1),
                'components': components,
                'timestamp': datetime.now().isoformat()
            }
            
            self.send_json_response(response_data)
            
        except Exception as e:
            self.send_error_response(f'Error getting disk info: {str(e)}')
    
    def handle_component_sizes(self):
        """Get detailed component size information"""
        try:
            components = {}
            
            # PostgreSQL detailed info
            try:
                # Get table sizes
                result = subprocess.run(
                    ['docker', 'exec', 'ergo-miningcore-postgres', 'psql', '-U', 'miningcore', '-t', '-c',
                     """SELECT tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) 
                        FROM pg_tables WHERE schemaname = 'public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;"""],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    tables = {}
                    for line in result.stdout.strip().split('\n'):
                        if '|' in line:
                            parts = line.split('|')
                            if len(parts) == 2:
                                tables[parts[0].strip()] = parts[1].strip()
                    components['postgresql'] = {
                        'tables': tables,
                        'total': 'See disk info'
                    }
            except:
                components['postgresql'] = {'error': 'Unable to fetch'}
            
            # Docker volume sizes
            try:
                result = subprocess.run(
                    ['docker', 'system', 'df', '-v', '--format', '{{json .}}'],
                    capture_output=True, text=True, timeout=10
                )
                if result.returncode == 0:
                    volume_info = result.stdout.strip()
                    components['dockerVolumes'] = volume_info if volume_info else 'N/A'
            except:
                components['dockerVolumes'] = 'N/A'
            
            response_data = {
                'components': components,
                'timestamp': datetime.now().isoformat()
            }
            
            self.send_json_response(response_data)
            
        except Exception as e:
            self.send_error_response(f'Error getting component sizes: {str(e)}')
    
    def handle_performance_metrics(self):
        """Get system performance metrics"""
        try:
            metrics = {}
            
            # CPU usage
            try:
                result = subprocess.run(
                    ['top', '-bn1'],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    for line in result.stdout.split('\n'):
                        if 'Cpu(s)' in line:
                            # Parse CPU line
                            parts = line.split(',')
                            for part in parts:
                                if 'id' in part:  # idle
                                    idle = float(part.split()[0])
                                    metrics['cpuUsage'] = round(100 - idle, 1)
                                    break
            except:
                metrics['cpuUsage'] = 'N/A'
            
            # Memory usage
            try:
                result = subprocess.run(
                    ['free', '-m'],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    lines = result.stdout.split('\n')
                    if len(lines) > 1:
                        mem_line = lines[1].split()
                        total_mem = int(mem_line[1])
                        used_mem = int(mem_line[2])
                        metrics['memory'] = {
                            'total': f'{total_mem} MB',
                            'used': f'{used_mem} MB',
                            'usagePercent': round((used_mem / total_mem) * 100, 1)
                        }
            except:
                metrics['memory'] = 'N/A'
            
            # Load average
            try:
                with open('/proc/loadavg', 'r') as f:
                    load = f.read().split()[:3]
                    metrics['loadAverage'] = {
                        '1min': load[0],
                        '5min': load[1],
                        '15min': load[2]
                    }
            except:
                metrics['loadAverage'] = 'N/A'
            
            # Network stats (simplified)
            try:
                result = subprocess.run(
                    ['cat', '/proc/net/dev'],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    # This is a simplified version, would need more parsing for accurate rates
                    metrics['networkAvailable'] = True
            except:
                metrics['networkAvailable'] = False
            
            response_data = {
                'metrics': metrics,
                'timestamp': datetime.now().isoformat()
            }
            
            self.send_json_response(response_data)
            
        except Exception as e:
            self.send_error_response(f'Error getting performance metrics: {str(e)}')
    
    def handle_docker_stats(self):
        """Get Docker container statistics"""
        try:
            result = subprocess.run(
                ['docker', 'stats', '--no-stream', '--format', 
                 '{"container":"{{.Container}}","name":"{{.Name}}","cpu":"{{.CPUPerc}}","memory":"{{.MemUsage}}","net":"{{.NetIO}}","block":"{{.BlockIO}}"}'],
                capture_output=True, text=True, timeout=10
            )
            
            if result.returncode == 0:
                containers = []
                for line in result.stdout.strip().split('\n'):
                    if line:
                        try:
                            containers.append(json.loads(line))
                        except:
                            pass
                
                response_data = {
                    'containers': containers,
                    'timestamp': datetime.now().isoformat()
                }
                self.send_json_response(response_data)
            else:
                self.send_error_response('Docker not available')
                
        except Exception as e:
            self.send_error_response(f'Error getting Docker stats: {str(e)}')
    
    def send_json_response(self, data):
        """Send JSON response"""
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def send_error_response(self, error_msg):
        """Send error response"""
        self.send_response(500)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        error_data = {'error': error_msg}
        self.wfile.write(json.dumps(error_data).encode())
    
    def proxy_api_request(self):
        """Proxy API requests to Miningcore API server"""
        try:
            # Build the target URL
            target_url = f"{API_BASE_URL}{self.path}"
            
            # Make request to API
            with urllib.request.urlopen(target_url, timeout=10) as response:
                # Read the response
                data = response.read()
                
                # Send response to client
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(data)
                
        except urllib.error.HTTPError as e:
            # Forward HTTP errors
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_msg = json.dumps({'error': str(e.reason)}).encode()
            self.wfile.write(error_msg)
            
        except Exception as e:
            # Handle other errors
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_msg = json.dumps({'error': f'Proxy error: {str(e)}'}).encode()
            self.wfile.write(error_msg)
            sys.stderr.write(f"Proxy error: {e}\n")
    
    def log_message(self, format, *args):
        # Custom logging format
        sys.stdout.write("%s - [%s] %s\n" %
                         (self.address_string(),
                          self.log_date_time_string(),
                          format%args))

def start_server():
    try:
        with socketserver.TCPServer(("", PORT), DashboardHandler) as httpd:
            print("=" * 60)
            print("🚀 Ergo Pool Dashboard Server")
            print("=" * 60)
            print(f"📊 Public Dashboard:   http://localhost:{PORT}/public/")
            print(f"🔧 Operator Dashboard: http://localhost:{PORT}/admin/")
            print(f"📡 Server running on:  http://0.0.0.0:{PORT}")
            print(f"🔗 API Proxy:          Enabled (proxying to {API_BASE_URL})")
            print(f"📈 Monitoring APIs:    Enabled")
            print("=" * 60)
            print("Available Monitoring Endpoints:")
            print("  • /api/admin/system/disk")
            print("  • /api/admin/system/components")
            print("  • /api/admin/system/performance")
            print("  • /api/admin/system/docker")
            print("=" * 60)
            print("Press Ctrl+C to stop the server")
            print("=" * 60)
            
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped by user")
        sys.exit(0)
    except OSError as e:
        if e.errno == 98:
            print(f"❌ Error: Port {PORT} is already in use")
            print(f"   Try: lsof -ti:{PORT} | xargs kill -9")
        else:
            print(f"❌ Error starting server: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    os.chdir(DIRECTORY)
    start_server()
