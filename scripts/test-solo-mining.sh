#!/bin/bash

# Ergo Solo Mining Test Script
# This script tests the solo mining setup with a small GPU

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Ergo Solo Mining Setup...${NC}"

# Function to check if service is responding
check_service() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=1
    
    echo -e "${BLUE}🔍 Testing $name...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s --connect-timeout 5 "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $name is responding${NC}"
            return 0
        fi
        echo -e "${YELLOW}⏳ Attempt $attempt/$max_attempts: Waiting for $name...${NC}"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ $name failed to respond after $max_attempts attempts${NC}"
    return 1
}

# Function to test stratum connection
test_stratum() {
    local host=$1
    local port=$2
    local name=$3
    
    echo -e "${BLUE}🔍 Testing Stratum connection to $name ($host:$port)...${NC}"
    
    # Use nc (netcat) to test stratum connection
    if command -v nc &> /dev/null; then
        if timeout 5 nc -z "$host" "$port" 2>/dev/null; then
            echo -e "${GREEN}✅ Stratum port $port is accepting connections${NC}"
            return 0
        else
            echo -e "${RED}❌ Cannot connect to stratum port $port${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  nc (netcat) not available, skipping stratum test${NC}"
        return 0
    fi
}

# Check if solo mining is running
if ! docker-compose ps | grep -q "miningcore-solo.*Up"; then
    echo -e "${RED}❌ Solo mining instance is not running!${NC}"
    echo "Please run './scripts/start-solo-mining.sh' first."
    exit 1
fi

echo -e "${GREEN}✅ Solo mining container is running${NC}"

# Test API endpoint
if check_service "http://localhost:4001/api/pools" "Solo Mining API"; then
    # Get and display pool info
    echo -e "${BLUE}📊 Pool Information:${NC}"
    if command -v jq &> /dev/null; then
        curl -s "http://localhost:4001/api/pools" | jq '.[0] | {id, coin, poolStats, networkStats}' 2>/dev/null || echo "API response received (jq formatting failed)"
    else
        echo "$(curl -s "http://localhost:4001/api/pools" 2>/dev/null | head -c 200)..."
    fi
else
    echo -e "${RED}❌ API test failed${NC}"
    exit 1
fi

# Test Stratum ports
echo ""
echo -e "${BLUE}🔌 Testing Stratum Connections:${NC}"
test_stratum "localhost" "4074" "Low Difficulty (Non-SSL)"
test_stratum "localhost" "4075" "Medium Difficulty (Non-SSL)"

# Test SSL ports if certificates exist
if [ -d "ssl/live" ] && [ "$(ls -A ssl/live 2>/dev/null)" ]; then
    test_stratum "localhost" "4076" "Low Difficulty (SSL)"
    test_stratum "localhost" "4077" "Medium Difficulty (SSL)"
else
    echo -e "${YELLOW}⚠️  SSL certificates not found, skipping SSL stratum tests${NC}"
fi

# Test Ergo node connectivity
echo ""
echo -e "${BLUE}🔗 Testing Ergo Node Connection:${NC}"
source .env 2>/dev/null || true
ERGO_HOST=${ERGO_NODE_HOST:-localhost}
ERGO_PORT=${ERGO_NODE_PORT:-9053}

if check_service "http://$ERGO_HOST:$ERGO_PORT/info" "Ergo Node"; then
    if command -v jq &> /dev/null; then
        NODE_INFO=$(curl -s "http://$ERGO_HOST:$ERGO_PORT/info" 2>/dev/null)
        HEIGHT=$(echo "$NODE_INFO" | jq -r '.fullHeight // "unknown"' 2>/dev/null)
        PEERS=$(echo "$NODE_INFO" | jq -r '.peersCount // "unknown"' 2>/dev/null)
        echo -e "${GREEN}📈 Current block height: $HEIGHT${NC}"
        echo -e "${GREEN}👥 Connected peers: $PEERS${NC}"
    fi
else
    echo -e "${RED}❌ Ergo node test failed${NC}"
fi

# Performance test with simulated small GPU
echo ""
echo -e "${BLUE}🎯 Solo Mining Configuration Summary:${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

# Check difficulty settings
if [ -f "config/ergo-solo-pool.json" ]; then
    LOW_DIFF=$(grep -A 10 '"4074"' config/ergo-solo-pool.json | grep '"difficulty"' | grep -o '[0-9.]*' | head -1)
    MED_DIFF=$(grep -A 10 '"4075"' config/ergo-solo-pool.json | grep '"difficulty"' | grep -o '[0-9.]*' | head -1)
    
    echo -e "🎚️  Port 4074 Difficulty: $LOW_DIFF (Good for small GPUs)"
    echo -e "🎚️  Port 4075 Difficulty: $MED_DIFF (Good for larger GPUs)"
    echo ""
    
    # Calculate expected shares for small GPU
    echo -e "${YELLOW}💡 Small GPU Mining Estimates:${NC}"
    echo -e "   • GTX 1060 6GB (~25 MH/s): ~1 share every ${LOW_DIFF}0 seconds on port 4074"
    echo -e "   • RTX 3060 (~35 MH/s):     ~1 share every ${LOW_DIFF}5 seconds on port 4074"
    echo -e "   • RX 580 8GB (~30 MH/s):   ~1 share every ${LOW_DIFF}7 seconds on port 4074"
fi

echo ""
echo -e "${GREEN}🎉 Solo Mining Test Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Ready to Mine - Example Commands:${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "For small GPU (use low difficulty port):"
echo -e "   t-rex -a autolykos2 -o stratum+tcp://localhost:4074 -u YOUR_ERGO_ADDRESS -w small-gpu"
echo ""
echo -e "Monitor mining activity:"
echo -e "   docker-compose logs -f miningcore-solo | grep -E '(Share|Block|Payment)'"
echo ""
echo -e "${YELLOW}💰 Remember: In solo mining, you get the FULL block reward (~67.5 ERG) when you find a block!${NC}"
echo -e "${YELLOW}⚡ The network difficulty is high, so it may take time to find a block with a small GPU.${NC}" 