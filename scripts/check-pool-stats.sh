#!/bin/bash

# Miningcore Pool Statistics Viewer
# Usage: ./check-pool-stats.sh

API_URL="http://localhost:4000"
POOL_ID="ergo-solo"

echo "=================================="
echo "  ERGO SOLO POOL STATISTICS"
echo "=================================="
echo ""

# Get pool info
echo "📊 Pool Overview:"
curl -s "${API_URL}/api/pools/${POOL_ID}" | jq -r '
.pool | 
"Pool ID: \(.poolId)
Status: \(.poolStats.connectedMiners) miners connected
Network Hashrate: \(.networkStats.networkHashrate // "N/A") H/s
Pool Hashrate: \(.poolStats.poolHashrate // 0) H/s
Total Blocks: \(.totalBlocks // 0)
Total Paid: \(.totalPaid // 0) ERG
Last Block: \(.lastPoolBlockTime // "Never")"
' 2>/dev/null || echo "Error fetching pool data"

echo ""
echo "=================================="
echo ""

# Get recent blocks
echo "🎯 Recent Blocks (Last 5):"
curl -s "${API_URL}/api/pools/${POOL_ID}/blocks?page=0&pageSize=5" | jq -r '
.[] | 
"Block \(.blockHeight): \(.status) - \(.reward) ERG - \(.created)"
' 2>/dev/null || echo "No blocks found"

echo ""
echo "=================================="
echo ""

# Get top miners
echo "⛏️  Top Miners:"
curl -s "${API_URL}/api/pools/${POOL_ID}/miners?page=0&pageSize=5" | jq -r '
.[] | 
"Miner: \(.miner[0:20])... 
  Hashrate: \(.hashrate) H/s
  Shares: \(.sharesPerSecond // 0)/s"
' 2>/dev/null || echo "No miners found"

echo ""
echo "=================================="
echo ""

# Health check
echo "💚 Pool Health:"
curl -s "${API_URL}/api/health-check"
echo ""

echo ""
echo "For more details, visit: http://localhost:4000/api/help"


