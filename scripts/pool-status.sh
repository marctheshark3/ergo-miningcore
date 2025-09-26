#!/bin/bash

# Ergo Solo Mining Pool Status Script
# This script checks the status of the mining pool and connected miners

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Ergo Solo Mining Pool Status${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"

# Check if Docker containers are running
echo -e "${BLUE}🐳 Docker Container Status:${NC}"
if docker-compose -f docker-compose.solo.yml ps --services --filter "status=running" | grep -q .; then
    docker-compose -f docker-compose.solo.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    echo ""
else
    echo -e "${RED}❌ No containers running${NC}"
    echo -e "${YELLOW}💡 Start the pool with: ./scripts/start-pool.sh${NC}"
    echo ""
    exit 1
fi

# Check API endpoint
echo -e "${BLUE}🌐 API Status:${NC}"
if curl -s --connect-timeout 5 "http://localhost:4001/api/pools" > /dev/null; then
    echo -e "${GREEN}✅ API is accessible at http://localhost:4001${NC}"
    
    # Get pool information
    echo ""
    echo -e "${BLUE}⛏️  Pool Information:${NC}"
    POOL_INFO=$(curl -s "http://localhost:4001/api/pools" 2>/dev/null || echo "[]")
    
    if [ "$POOL_INFO" != "[]" ] && [ ! -z "$POOL_INFO" ]; then
        echo "$POOL_INFO" | python3 -m json.tool 2>/dev/null || echo "$POOL_INFO"
    else
        echo -e "${YELLOW}⚠️  No pool data available${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📈 Pool Stats:${NC}"
    POOL_STATS=$(curl -s "http://localhost:4001/api/pools/ergo-solo" 2>/dev/null || echo "{}")
    
    if [ "$POOL_STATS" != "{}" ] && [ ! -z "$POOL_STATS" ]; then
        echo "$POOL_STATS" | python3 -m json.tool 2>/dev/null || echo "$POOL_STATS"
    else
        echo -e "${YELLOW}⚠️  No pool stats available${NC}"
    fi
    
else
    echo -e "${RED}❌ API is not accessible${NC}"
fi

echo ""

# Check mining processes
echo -e "${BLUE}⛏️  Mining Processes:${NC}"
MINING_PIDS=$(pgrep -f "lolMiner.*AUTOLYKOS2" 2>/dev/null || true)

if [ ! -z "$MINING_PIDS" ]; then
    echo -e "${GREEN}✅ Mining processes found:${NC}"
    for pid in $MINING_PIDS; do
        PROCESS_INFO=$(ps -p $pid -o pid,cmd --no-headers 2>/dev/null || echo "Process not found")
        echo "  PID $PROCESS_INFO"
    done
else
    echo -e "${YELLOW}⚠️  No mining processes running${NC}"
    echo -e "${YELLOW}💡 Start mining with: ./scripts/start-mining.sh${NC}"
fi

echo ""
echo -e "${BLUE}📋 Available Commands:${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "Start pool:         ./scripts/start-pool.sh"
echo -e "Stop pool:          ./scripts/stop-pool.sh" 
echo -e "Start mining:       ./scripts/start-mining.sh"
echo -e "Stop mining:        ./scripts/stop-mining.sh"
echo -e "View pool logs:     docker-compose -f docker-compose.solo.yml logs -f miningcore-solo"
echo -e "View all logs:      docker-compose -f docker-compose.solo.yml logs"
echo ""

