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
WALLET=9ehJZvPDgvCNNd2zTQHxnSpcCAtb1kHbEN1VAgeoRD5DPVApYkk
WORKER=Capitol_Peak
POWER_LIMIT=275

# Miner executable (adjust path as needed)
MINER_PATH="./lolMiner"

#################################
##  End of user-editable part  ##
#################################

echo -e "${BLUE}⛏️  Starting Ergo Solo Mining...${NC}"

# Check if pool is running
echo -e "${BLUE}🔍 Checking if solo mining pool is running...${NC}"
if ! curl -s --connect-timeout 5 "http://localhost:4001/api/pools" > /dev/null; then
    echo -e "${RED}❌ Error: Solo mining pool is not running!${NC}"
    echo "Please start the pool first with: ./scripts/start-pool.sh"
    exit 1
fi

echo -e "${GREEN}✅ Solo mining pool is running${NC}"

# Check if miner exists
if [ ! -f "$MINER_PATH" ]; then
    echo -e "${RED}❌ Error: Miner not found at $MINER_PATH${NC}"
    echo "Please update MINER_PATH in this script or place lolMiner in the current directory."
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
echo -e "Miner:          $MINER_PATH"
echo ""

# Construct full user string
USER_STRING="$WALLET.$WORKER"

echo -e "${BLUE}🚀 Starting mining...${NC}"
echo -e "${YELLOW}💡 Press Ctrl+C to stop mining${NC}"
echo ""

# Change to script directory
cd "$(dirname "$0")/.."

# Start mining with auto-restart on exit code 42
$MINER_PATH --algo AUTOLYKOS2 --pool $POOL_HOST:$POOL_PORT --user $USER_STRING $@ --pl $POWER_LIMIT
while [ $? -eq 42 ]; do
    echo -e "${YELLOW}⚠️  Miner disconnected, restarting in 10 seconds...${NC}"
    sleep 10s
    $MINER_PATH --algo AUTOLYKOS2 --pool $POOL_HOST:$POOL_PORT --user $USER_STRING $@ --pl $POWER_LIMIT
done

echo -e "${GREEN}✅ Mining stopped${NC}"

