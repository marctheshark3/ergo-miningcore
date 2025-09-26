#!/bin/bash

# Ergo Solo Mining Stop Script
# This script stops mining processes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛑 Stopping Ergo Mining...${NC}"

# Find and kill lolMiner processes
PIDS=$(pgrep -f "lolMiner.*AUTOLYKOS2" 2>/dev/null || true)

if [ -z "$PIDS" ]; then
    echo -e "${YELLOW}⚠️  No mining processes found${NC}"
else
    echo -e "${BLUE}🔍 Found mining processes: $PIDS${NC}"
    
    # Send SIGTERM first (graceful shutdown)
    echo -e "${BLUE}📤 Sending SIGTERM to mining processes...${NC}"
    for pid in $PIDS; do
        kill -TERM $pid 2>/dev/null || true
    done
    
    # Wait a moment for graceful shutdown
    sleep 5
    
    # Check if processes are still running
    REMAINING_PIDS=$(pgrep -f "lolMiner.*AUTOLYKOS2" 2>/dev/null || true)
    
    if [ ! -z "$REMAINING_PIDS" ]; then
        echo -e "${YELLOW}⚠️  Processes still running, sending SIGKILL...${NC}"
        for pid in $REMAINING_PIDS; do
            kill -KILL $pid 2>/dev/null || true
        done
        sleep 2
    fi
    
    # Final check
    FINAL_CHECK=$(pgrep -f "lolMiner.*AUTOLYKOS2" 2>/dev/null || true)
    if [ -z "$FINAL_CHECK" ]; then
        echo -e "${GREEN}✅ All mining processes stopped successfully${NC}"
    else
        echo -e "${RED}❌ Some processes may still be running: $FINAL_CHECK${NC}"
    fi
fi

echo ""
echo -e "${BLUE}📋 Useful Commands:${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "Start mining:       ./scripts/start-mining.sh"
echo -e "Check pool status:  ./scripts/pool-status.sh"
echo -e "Stop pool:          ./scripts/stop-pool.sh"
echo ""

