#!/bin/bash

# Start Ergo Pool Dashboard
# This script starts the web server for the pool dashboard

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DASHBOARD_DIR="$PROJECT_ROOT/dashboard"
SERVER_SCRIPT="$DASHBOARD_DIR/server.py"
PORT=8888

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
CYAN='\033[0;36m'

echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}    Ergo Solo Mining Pool - Dashboard Startup${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is not installed${NC}"
    echo -e "${YELLOW}   Install it with: sudo apt-get install python3${NC}"
    exit 1
fi

# Check if dashboard directory exists
if [ ! -d "$DASHBOARD_DIR" ]; then
    echo -e "${RED}❌ Dashboard directory not found: $DASHBOARD_DIR${NC}"
    exit 1
fi

# Check if server script exists
if [ ! -f "$SERVER_SCRIPT" ]; then
    echo -e "${RED}❌ Server script not found: $SERVER_SCRIPT${NC}"
    exit 1
fi

# Check if port is already in use
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}⚠️  Port $PORT is already in use${NC}"
    echo -e "${YELLOW}   Attempting to stop existing server...${NC}"
    lsof -ti:$PORT | xargs kill -9 2>/dev/null
    sleep 2
    
    # Check again
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${RED}❌ Failed to free port $PORT. Please stop the service manually:${NC}"
        echo -e "${YELLOW}   sudo lsof -ti:$PORT | xargs kill -9${NC}"
        exit 1
    fi
fi

# Check if API is accessible
echo -e "${CYAN}🔍 Checking Miningcore API...${NC}"
if curl -s -f http://localhost:4000/api/health-check > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Miningcore API is accessible on port 4000${NC}"
else
    echo -e "${YELLOW}⚠️  Miningcore API not responding on port 4000${NC}"
    echo -e "${YELLOW}   Dashboard will work but data may not load${NC}"
    echo -e "${YELLOW}   Make sure your pool is running!${NC}"
fi

echo ""
echo -e "${CYAN}🚀 Starting dashboard server...${NC}"
echo ""

# Start the server
cd "$DASHBOARD_DIR" || exit 1
python3 "$SERVER_SCRIPT"

