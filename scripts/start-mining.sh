#!/bin/bash

# Ergo Solo Mining Start Script
# This script starts mining to the local solo pool

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#################################
## Begin of user-editable part ##
#################################

# Pool configuration
POOL_HOST=localhost
POOL_PORT=4074  # Low difficulty port (change to 4075 for medium difficulty)

# Mining configuration  
# Using your Ergo node wallet address (rewards go here in solo mining)
WALLET=9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY
WORKER=Capitol_Peak
POWER_LIMIT=300

# Miner executable (adjust path as needed)
# Using T-Rex instead of lolMiner (better compatibility with RTX 3090)
MINER_PATH="./t-rex"

#################################
##  End of user-editable part  ##
#################################

echo -e "${BLUE}⛏️  Starting Ergo Solo Mining...${NC}"

# Check if pool is running
echo -e "${BLUE}🔍 Checking if solo mining pool is running...${NC}"
if ! curl -s --connect-timeout 5 "http://localhost:4000/api/pools" > /dev/null; then
    echo -e "${RED}❌ Error: Solo mining pool is not running!${NC}"
    echo "Please start the pool first with: ./scripts/start-pool.sh"
    exit 1
fi

echo -e "${GREEN}✅ Solo mining pool is running${NC}"

# Check if miner exists
if [ ! -f "$MINER_PATH" ]; then
    echo -e "${RED}❌ Error: T-Rex miner not found at $MINER_PATH${NC}"
    echo "Please download T-Rex miner from: https://github.com/trexminer/T-Rex/releases"
    echo "Extract it to the current directory and ensure the binary is named 't-rex'"
    exit 1
fi

# Display mining information
echo ""
echo -e "${GREEN}⛏️  Mining Configuration:${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "Pool:           $POOL_HOST:$POOL_PORT"
echo -e "Wallet:         $WALLET"
echo -e "Worker:         $WORKER"
echo -e "Power Limit:    ${POWER_LIMIT}W"
echo -e "Miner:          T-Rex v0.26.8 (Autolykos2)"
echo ""

echo -e "${BLUE}🚀 Starting mining...${NC}"
echo -e "${YELLOW}💡 Press Ctrl+C to stop mining${NC}"
echo ""

# Change to script directory
cd "$(dirname "$0")/.."

# Start mining with T-Rex (different syntax than lolMiner)
# T-Rex automatically reconnects on disconnection
$MINER_PATH -a autolykos2 \
    -o stratum+tcp://$POOL_HOST:$POOL_PORT \
    -u $WALLET \
    -w $WORKER \
    --api-bind-http 127.0.0.1:4067 \
    $@

echo -e "${GREEN}✅ Mining stopped${NC}"

