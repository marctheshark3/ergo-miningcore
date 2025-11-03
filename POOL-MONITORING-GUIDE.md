# Pool Monitoring Guide for Operators

This guide explains how to monitor and view data from your Ergo solo mining pool.

## Quick Start

### 1. Quick Status Check
```bash
./scripts/check-pool-stats.sh
```

### 2. View All Available API Endpoints
```bash
curl http://localhost:4000/api/help
```

### 3. Check Pool Health
```bash
curl http://localhost:4000/api/health-check
```

## API Configuration

Your pool's API is configured in `config/ergo-solo-simple.json`:
- **Enabled**: Yes
- **Port**: 4000
- **Listen Address**: `*` (accessible from any network interface)
- **Rate Limiting**: 300 requests per minute

## Available API Endpoints

### General Pool Information

#### List All Pools
```bash
curl http://localhost:4000/api/pools | jq '.'
```

Returns overview of all configured pools with stats.

#### Get Specific Pool Details
```bash
curl http://localhost:4000/api/pools/ergo-solo | jq '.'
```

Returns detailed information including:
- Connected miners count
- Pool hashrate
- Network hashrate and difficulty
- Top miners
- Total blocks found
- Total payments made
- Pool effort
- Current block height

#### Pool Performance Over Time
```bash
# Last 24 hours (hourly intervals)
curl "http://localhost:4000/api/pools/ergo-solo/performance?r=day&i=hour" | jq '.'

# Last 30 days (hourly intervals)
curl "http://localhost:4000/api/pools/ergo-solo/performance?r=month&i=hour" | jq '.'
```

Parameters:
- `r` (range): `day` or `month`
- `i` (interval): `hour`

### Miners Information

#### List All Miners
```bash
# First page (15 miners)
curl "http://localhost:4000/api/pools/ergo-solo/miners?page=0&pageSize=15" | jq '.'

# Second page
curl "http://localhost:4000/api/pools/ergo-solo/miners?page=1&pageSize=15" | jq '.'
```

Parameters:
- `page`: Page number (starts at 0)
- `pageSize`: Number of results per page (default: 15)
- `topMinersRange`: Hours to look back for top miners (default: 24)

#### Get Specific Miner Stats
```bash
WALLET="9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY"
curl "http://localhost:4000/api/pools/ergo-solo/miners/${WALLET}" | jq '.'
```

Returns:
- Current hashrate
- Shares per second
- Pending balance
- Total paid
- Last payment info
- Performance samples

#### Miner Performance History
```bash
WALLET="9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY"

# Last hour (3-minute intervals)
curl "http://localhost:4000/api/pools/ergo-solo/miners/${WALLET}/performance?mode=hour" | jq '.'

# Last day (hourly intervals)
curl "http://localhost:4000/api/pools/ergo-solo/miners/${WALLET}/performance?mode=day" | jq '.'

# Last month (daily intervals)
curl "http://localhost:4000/api/pools/ergo-solo/miners/${WALLET}/performance?mode=month" | jq '.'
```

#### Miner Settings
```bash
WALLET="9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY"
curl "http://localhost:4000/api/pools/ergo-solo/miners/${WALLET}/settings" | jq '.'
```

### Blocks Information

#### List Blocks
```bash
# All blocks (first page)
curl "http://localhost:4000/api/pools/ergo-solo/blocks?page=0&pageSize=15" | jq '.'

# Only confirmed blocks
curl "http://localhost:4000/api/pools/ergo-solo/blocks?page=0&state=confirmed" | jq '.'

# Pending and confirmed blocks
curl "http://localhost:4000/api/pools/ergo-solo/blocks?page=0&state=pending&state=confirmed" | jq '.'
```

Parameters:
- `page`: Page number (starts at 0)
- `pageSize`: Number of results per page (default: 15)
- `state`: Block status filter (can specify multiple)
  - `confirmed`: Confirmed blocks
  - `pending`: Pending confirmation
  - `orphaned`: Orphaned blocks

Block information includes:
- Block height
- Block hash
- Reward amount
- Status
- Effort percentage
- Transaction confirmation link
- Block explorer link

#### Paginated Blocks (V2 API)
```bash
curl "http://localhost:4000/api/v2/pools/ergo-solo/blocks?page=0&pageSize=15" | jq '.'
```

Returns blocks with pagination metadata (total page count).

### Payments Information

#### List All Pool Payments
```bash
curl "http://localhost:4000/api/pools/ergo-solo/payments?page=0&pageSize=15" | jq '.'
```

#### List Payments for Specific Miner
```bash
WALLET="9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY"
curl "http://localhost:4000/api/pools/ergo-solo/miners/${WALLET}/payments?page=0" | jq '.'
```

Payment information includes:
- Payment amount
- Transaction hash
- Transaction confirmation link
- Address explorer link
- Timestamp

#### Miner Balance Changes
```bash
WALLET="9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY"
curl "http://localhost:4000/api/pools/ergo-solo/miners/${WALLET}/balancechanges?page=0" | jq '.'
```

Shows all balance changes (rewards added, payments deducted).

#### Miner Earnings by Day
```bash
WALLET="9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY"
curl "http://localhost:4000/api/pools/ergo-solo/miners/${WALLET}/earnings/daily?page=0" | jq '.'
```

### Admin Endpoints

#### Get Miner Balance
```bash
WALLET="9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY"
curl "http://localhost:4000/api/admin/pools/ergo-solo/miners/${WALLET}/getbalance"
```

Returns the current balance for a specific miner.

#### Memory and GC Statistics
```bash
curl http://localhost:4000/api/admin/stats/gc | jq '.'
```

Shows garbage collection statistics and memory usage.

## Monitoring with Scripts

### 1. Quick Pool Status
```bash
./scripts/check-pool-stats.sh
```

Shows:
- Pool overview (miners, hashrates, blocks, payments)
- Recent blocks (last 5)
- Top miners (top 5)
- Health status

### 2. View Pool Logs
```bash
# Pool operational logs
tail -f logs/miningcore-solo.log

# API access logs
tail -f logs/api-solo.log

# Follow both logs simultaneously
tail -f logs/miningcore-solo.log logs/api-solo.log
```

### 3. Monitor Specific Miner
```bash
# Create a custom monitoring script
WALLET="YOUR_WALLET_ADDRESS"

watch -n 10 "curl -s http://localhost:4000/api/pools/ergo-solo/miners/${WALLET} | \
jq '{hashrate: .hashrate, shares: .sharesPerSecond, balance: .pendingBalance}'"
```

This updates every 10 seconds showing hashrate, shares, and balance.

### 4. Real-time Connected Miners
```bash
watch -n 5 "curl -s http://localhost:4000/api/pools/ergo-solo | \
jq -r '.pool.poolStats | \"Connected Miners: \(.connectedMiners)\nPool Hashrate: \(.poolHashrate) H/s\"'"
```

Updates every 5 seconds.

## Web Browser Access

You can also access the API directly in your web browser:

- Pool Overview: http://localhost:4000/api/pools/ergo-solo
- Recent Blocks: http://localhost:4000/api/pools/ergo-solo/blocks
- Top Miners: http://localhost:4000/api/pools/ergo-solo/miners
- All Endpoints: http://localhost:4000/api/help
- Health Check: http://localhost:4000/api/health-check

## Remote Access

To access the API from another machine on your network, replace `localhost` with your server's IP address:

```bash
# Example: Your server IP is 192.168.1.100
curl http://192.168.1.100:4000/api/pools/ergo-solo
```

Your pool is already configured to accept connections from any interface (`listenAddress: "*"`).

### Security Considerations

Since the API is accessible from the network:
1. Consider setting up a firewall to restrict access to port 4000
2. The current rate limiting is set to 300 requests per minute
3. You can whitelist specific IPs in the config under `api.rateLimiting.ipWhitelist`

## Database Access

For advanced monitoring, you can also query the PostgreSQL database directly:

```bash
# Connect to database
docker exec -it miningcore-postgres psql -U miningcore -d miningcore

# Example queries:

# Get pool statistics
SELECT * FROM poolstats ORDER BY created DESC LIMIT 10;

# Get recent blocks
SELECT * FROM blocks ORDER BY created DESC LIMIT 10;

# Get miner balances
SELECT * FROM balances WHERE poolid = 'ergo-solo';

# Get recent shares
SELECT * FROM shares ORDER BY created DESC LIMIT 100;
```

## Integration with Monitoring Tools

### Prometheus/Grafana

You can scrape the API endpoints and create custom Grafana dashboards.

### Custom Dashboard

Build a web dashboard that polls the API endpoints and displays:
- Real-time pool hashrate
- Connected miners chart
- Blocks found timeline
- Payment history
- Miner leaderboard

### Alerting

Set up alerts for:
- Pool hashrate drops
- No blocks found in X hours
- Payment processor failures
- High pool effort (>200%)

Example alert script:
```bash
#!/bin/bash
HASHRATE=$(curl -s http://localhost:4000/api/pools/ergo-solo | jq '.pool.poolStats.poolHashrate')
if (( $(echo "$HASHRATE < 100000000" | bc -l) )); then
    echo "WARNING: Pool hashrate below 100 MH/s!" | mail -s "Pool Alert" your@email.com
fi
```

## Troubleshooting

### API Not Responding
```bash
# Check if Miningcore is running
docker-compose -f docker-compose.solo.yml ps

# Check API logs
tail -n 100 logs/api-solo.log

# Test health endpoint
curl http://localhost:4000/api/health-check
```

### No Data Showing
- Check if pool is actually mining (logs/miningcore-solo.log)
- Verify miners are connected
- Check database connection

### Rate Limiting Issues
If you see "Too Many Requests" errors:
- Current limit: 300 requests per minute
- Add your IP to whitelist in config
- Increase rate limits if needed

## Useful Tools

- **jq**: JSON processor for formatting API responses
- **watch**: Auto-refresh command output
- **curl**: Make HTTP requests
- **docker-compose**: Manage pool containers
- **psql**: Direct database access

## Example Monitoring Scripts

### Daily Summary Email
```bash
#!/bin/bash
# Save as: scripts/daily-summary.sh

API="http://localhost:4000"
POOL="ergo-solo"
OUTPUT="/tmp/pool-summary.txt"

{
    echo "ERGO SOLO POOL - DAILY SUMMARY"
    echo "=============================="
    echo ""
    curl -s "$API/api/pools/$POOL" | jq -r '
        .pool | 
        "Pool Hashrate: \(.poolStats.poolHashrate) H/s
        Connected Miners: \(.poolStats.connectedMiners)
        Total Blocks: \(.totalBlocks)
        Total Paid: \(.totalPaid) ERG"
    '
    echo ""
    echo "Recent Blocks:"
    curl -s "$API/api/pools/$POOL/blocks?page=0&pageSize=10" | jq -r '.[] | "  - Block \(.blockHeight): \(.reward) ERG"'
} > "$OUTPUT"

# Send email (requires mail configured)
# cat "$OUTPUT" | mail -s "Pool Daily Summary" your@email.com
cat "$OUTPUT"
```

### Miner Watchdog
```bash
#!/bin/bash
# Save as: scripts/miner-watchdog.sh
# Monitor if your miner is actively submitting shares

WALLET="YOUR_WALLET_ADDRESS"
MIN_HASHRATE=100000000  # 100 MH/s

CURRENT=$(curl -s "http://localhost:4000/api/pools/ergo-solo/miners/$WALLET" | jq '.hashrate')

if (( $(echo "$CURRENT < $MIN_HASHRATE" | bc -l) )); then
    echo "WARNING: Miner hashrate low: $CURRENT H/s"
    # Add notification logic here
fi
```

## Summary

As a pool operator, you have multiple ways to monitor your pool:

1. **API Endpoints** - Real-time data via HTTP
2. **Custom Scripts** - Automated monitoring and alerts  
3. **Log Files** - Detailed operational logs
4. **Database Queries** - Direct data access
5. **Web Browser** - Simple JSON viewing

The main tool is the REST API on port 4000, which provides comprehensive access to all pool data in JSON format.

For quick checks, use: `./scripts/check-pool-stats.sh`

For detailed analysis, query specific API endpoints or the database directly.







