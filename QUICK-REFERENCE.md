# Quick Reference - Pool Operator Commands

## 🚀 Quick Start Commands

### Check Pool Status
```bash
# Quick formatted status
./scripts/check-pool-stats.sh

# Raw JSON pool info
curl http://localhost:4000/api/pools/ergo-solo | jq '.'
```

### Check Pool Health
```bash
curl http://localhost:4000/api/health-check
# Expected output: 👍
```

### View All API Endpoints
```bash
curl http://localhost:4000/api/help
```

## 📊 Essential Monitoring Commands

### Current Pool Statistics
```bash
# Pool hashrate and connected miners
curl -s http://localhost:4000/api/pools/ergo-solo | jq '.pool.poolStats'

# Network statistics
curl -s http://localhost:4000/api/pools/ergo-solo | jq '.pool.networkStats'

# Top miners
curl -s http://localhost:4000/api/pools/ergo-solo | jq '.pool.topMiners'
```

### Recent Blocks
```bash
# Last 5 blocks
curl -s "http://localhost:4000/api/pools/ergo-solo/blocks?page=0&pageSize=5" | jq '.'

# Only confirmed blocks
curl -s "http://localhost:4000/api/pools/ergo-solo/blocks?state=confirmed" | jq '.'
```

### List Miners
```bash
# Top 10 miners
curl -s "http://localhost:4000/api/pools/ergo-solo/miners?page=0&pageSize=10" | jq '.'
```

### Specific Miner Stats
```bash
# Replace with your wallet address
WALLET="9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY"

# Current stats
curl -s "http://localhost:4000/api/pools/ergo-solo/miners/${WALLET}" | jq '.'

# Balance only
curl -s "http://localhost:4000/api/admin/pools/ergo-solo/miners/${WALLET}/getbalance"

# Performance (last 24 hours)
curl -s "http://localhost:4000/api/pools/ergo-solo/miners/${WALLET}/performance?mode=day" | jq '.'
```

## 📝 Logs

### View Live Logs
```bash
# Pool logs (main)
tail -f logs/miningcore-solo.log

# API logs
tail -f logs/api-solo.log

# Both logs
tail -f logs/miningcore-solo.log logs/api-solo.log
```

### Search Logs
```bash
# Find errors
grep -i error logs/miningcore-solo.log

# Find block submissions
grep -i "block accepted" logs/miningcore-solo.log

# Count shares in last 1000 lines
tail -n 1000 logs/miningcore-solo.log | grep -c "share accepted"
```

## 🐳 Docker Management

### Check Container Status
```bash
cd /home/whaleshark/Documents/ergo/ergo-miningcore
docker-compose -f docker-compose.solo.yml ps
```

### View Container Logs
```bash
# Pool container
docker-compose -f docker-compose.solo.yml logs -f miningcore

# Database container
docker-compose -f docker-compose.solo.yml logs -f postgres
```

### Restart Pool
```bash
docker-compose -f docker-compose.solo.yml restart miningcore
```

### Stop/Start Pool
```bash
# Stop
docker-compose -f docker-compose.solo.yml stop

# Start
docker-compose -f docker-compose.solo.yml start

# Restart everything
docker-compose -f docker-compose.solo.yml down
docker-compose -f docker-compose.solo.yml up -d
```

## 💾 Database Queries

### Connect to Database
```bash
docker exec -it miningcore-postgres psql -U miningcore -d miningcore
```

### Useful SQL Queries
```sql
-- Get latest pool stats
SELECT * FROM poolstats ORDER BY created DESC LIMIT 5;

-- Count total blocks
SELECT COUNT(*) FROM blocks WHERE poolid = 'ergo-solo';

-- List all blocks
SELECT blockheight, status, reward, effort FROM blocks 
WHERE poolid = 'ergo-solo' 
ORDER BY created DESC LIMIT 10;

-- Miner balances
SELECT address, amount FROM balances 
WHERE poolid = 'ergo-solo' 
ORDER BY amount DESC;

-- Recent shares (last 100)
SELECT miner, difficulty, created FROM shares 
WHERE poolid = 'ergo-solo' 
ORDER BY created DESC LIMIT 100;

-- Total payments
SELECT SUM(amount) as total_paid FROM payments 
WHERE poolid = 'ergo-solo';

-- Payments by miner
SELECT address, COUNT(*) as payment_count, SUM(amount) as total_amount 
FROM payments 
WHERE poolid = 'ergo-solo' 
GROUP BY address;

-- Exit psql
\q
```

## 🔧 Useful One-Liners

### Monitor Connected Miners (auto-refresh every 5 seconds)
```bash
watch -n 5 "curl -s http://localhost:4000/api/pools/ergo-solo | jq -r '.pool.poolStats.connectedMiners'"
```

### Monitor Pool Hashrate
```bash
watch -n 5 "curl -s http://localhost:4000/api/pools/ergo-solo | jq -r '.pool.poolStats | \"Miners: \(.connectedMiners) | Hashrate: \(.poolHashrate) H/s\"'"
```

### Monitor Network Stats
```bash
watch -n 10 "curl -s http://localhost:4000/api/pools/ergo-solo | jq -r '.pool.networkStats | \"Height: \(.blockHeight) | Difficulty: \(.networkDifficulty) | Network Hashrate: \(.networkHashrate) H/s\"'"
```

### Check if New Block Found
```bash
# Run periodically to check for new blocks
LAST_BLOCK=$(curl -s "http://localhost:4000/api/pools/ergo-solo/blocks?page=0&pageSize=1" | jq -r '.[0].blockHeight // "none"')
echo "Last block found at height: $LAST_BLOCK"
```

### Export Miner Stats to CSV
```bash
curl -s "http://localhost:4000/api/pools/ergo-solo/miners?page=0&pageSize=100" | \
jq -r '.[] | [.miner, .hashrate, .sharesPerSecond, .performance.hashrate] | @csv' > miners.csv
```

## 🌐 Browser URLs

Open these in your web browser:

- **Pool Overview**: http://localhost:4000/api/pools/ergo-solo
- **Recent Blocks**: http://localhost:4000/api/pools/ergo-solo/blocks?page=0&pageSize=20
- **Top Miners**: http://localhost:4000/api/pools/ergo-solo/miners?page=0&pageSize=20
- **Pool Performance**: http://localhost:4000/api/pools/ergo-solo/performance?r=day&i=hour
- **API Help**: http://localhost:4000/api/help
- **Health Check**: http://localhost:4000/api/health-check

## 📱 Remote Access

Replace `localhost` with your server IP:
```bash
# Example: server IP is 192.168.1.100
curl http://192.168.1.100:4000/api/pools/ergo-solo
```

Or use the server hostname:
```bash
curl http://your-server-name:4000/api/pools/ergo-solo
```

## 🚨 Troubleshooting

### API Not Responding
```bash
# Check if container is running
docker-compose -f docker-compose.solo.yml ps

# Check API logs
tail -n 50 logs/api-solo.log

# Test health
curl http://localhost:4000/api/health-check

# Restart if needed
docker-compose -f docker-compose.solo.yml restart miningcore
```

### No Miners Connecting
```bash
# Check if ports are open
netstat -tlnp | grep -E '4074|4075'

# Check firewall
sudo ufw status

# Check pool logs for connection attempts
tail -f logs/miningcore-solo.log | grep -i "connect"
```

### Database Issues
```bash
# Check database container
docker-compose -f docker-compose.solo.yml logs postgres

# Test database connection
docker exec -it miningcore-postgres psql -U miningcore -d miningcore -c "SELECT 1;"
```

## 📊 Performance Metrics

### Calculate Pool Efficiency
```bash
curl -s http://localhost:4000/api/pools/ergo-solo | jq -r '
.pool | 
"Pool Hashrate: \(.poolStats.poolHashrate) H/s
Network Hashrate: \(.networkStats.networkHashrate) H/s  
Pool Network Share: \((.poolStats.poolHashrate / .networkStats.networkHashrate * 100) | tostring | .[0:5])%"
'
```

### Expected Time to Block (rough estimate)
```bash
# Based on current pool hashrate vs network
curl -s http://localhost:4000/api/pools/ergo-solo | jq -r '
.pool | 
(.networkStats.networkHashrate / .poolStats.poolHashrate * 120 / 3600) as $hours |
"Expected time to find a block: \($hours | floor) hours (rough estimate)"
'
```

## 💡 Tips

1. **Bookmark** http://localhost:4000/api/help for quick API reference
2. **Automate** monitoring with cron jobs
3. **Set up alerts** for important events (blocks found, low hashrate)
4. **Keep logs** by rotating them periodically
5. **Monitor disk space** as database can grow large
6. **Backup database** regularly using `scripts/backup-db.sh`

## 🔐 Security

- API is currently **open** on your network
- Consider firewall rules to restrict port 4000 access
- Rate limit: 300 requests/minute (configurable)
- No authentication required for read-only endpoints
- Admin endpoints should be protected

## 📈 Next Steps

1. Set up monitoring dashboard (Grafana)
2. Configure email alerts for blocks found
3. Create backup automation
4. Document your specific mining setup
5. Consider setting up a web frontend for miners

---

**For detailed documentation**, see `POOL-MONITORING-GUIDE.md`

**For pool management**, see available scripts in `scripts/` directory


