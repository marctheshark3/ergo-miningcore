#!/bin/bash

# Ergo Solo Mining Pool Startup Script
# This script ONLY starts the mining pool infrastructure (database + miningcore)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Ergo Solo Mining Pool...${NC}"

# Check if required files exist
if [ ! -f "config/ergo-solo-simple.json" ]; then
    echo -e "${RED}❌ Error: config/ergo-solo-simple.json not found!${NC}"
    echo "Please make sure the solo mining configuration file exists."
    exit 1
fi

if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Error: .env file not found!${NC}"
    echo "Please create a .env file from env.template and configure it."
    exit 1
fi

# Source environment variables
source .env

# Validate critical environment variables
if [ -z "$ERGO_NODE_HOST" ] || [ -z "$ERGO_NODE_PORT" ]; then
    echo -e "${YELLOW}⚠️  Warning: ERGO_NODE_HOST or ERGO_NODE_PORT not set in .env${NC}"
    echo "Using defaults: localhost:9053"
fi

# Test Ergo node connection
echo -e "${BLUE}🔍 Testing Ergo node connection...${NC}"
if command -v curl &> /dev/null; then
    if curl -s --connect-timeout 5 "http://${ERGO_NODE_HOST:-localhost}:${ERGO_NODE_PORT:-9053}/info" > /dev/null; then
        echo -e "${GREEN}✅ Ergo node is accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  Warning: Cannot reach Ergo node at ${ERGO_NODE_HOST:-localhost}:${ERGO_NODE_PORT:-9053}${NC}"
        echo "Make sure your Ergo node is running and accessible."
        read -p "Continue anyway? (y/N): " continue_anyway
        if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Check if solo mining config has proper wallet address
echo -e "${BLUE}🔍 Validating solo mining configuration...${NC}"
POOL_ADDRESS=$(grep -o '"address": *"[^"]*"' config/ergo-solo-simple.json | head -1 | sed 's/"address": *"\([^"]*\)"/\1/')
if [ "$POOL_ADDRESS" = "9f6a8rtMMmCpFbZT45Hnkm7L8SHaGZcvwh1MkQdoMkRgHtbDqQq" ]; then
    echo -e "${YELLOW}⚠️  Warning: You are using the default wallet address!${NC}"
    echo "Please update the 'address' field in config/ergo-solo-simple.json with your own Ergo wallet address."
    read -p "Continue with default address? (y/N): " continue_default
    if [[ ! $continue_default =~ ^[Yy]$ ]]; then
        echo "Please edit config/ergo-solo-simple.json and set your wallet address, then run this script again."
        exit 1
    fi
fi

# Stop any running pool instances
echo -e "${BLUE}🛑 Stopping any running pool instances...${NC}"
docker-compose -f docker-compose.solo.yml down > /dev/null 2>&1 || true

# Start solo mining
echo -e "${BLUE}🚀 Starting solo mining pool...${NC}"
docker-compose -f docker-compose.solo.yml up --build -d

# Wait for services to be healthy
echo -e "${BLUE}⏳ Waiting for services to start...${NC}"
sleep 10

# Check if services are running
if docker-compose -f docker-compose.solo.yml ps | grep -q "miningcore-solo.*Up"; then
    echo -e "${GREEN}✅ Solo mining pool is running!${NC}"
    
    # Display connection information
    echo ""
    echo -e "${GREEN}🎯 Solo Mining Connection Information:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "🔌 Stratum (Non-SSL):"
    echo -e "   • Low Difficulty:    stratum+tcp://localhost:4074"
    echo -e "   • Medium Difficulty: stratum+tcp://localhost:4075"
    echo ""
    echo -e "📊 API Endpoint:        http://localhost:4001/api/pools"
    echo -e "📊 Pool Stats:          http://localhost:4001/api/pools/ergo-solo"
    echo ""
    echo -e "${YELLOW}💡 Note: In solo mining, you receive the FULL block reward when you find a block!${NC}"
    echo -e "${YELLOW}💡 Pool fee: 0% (configurable in config/ergo-solo-simple.json)${NC}"
    echo ""
    
    # Show next steps
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "Start mining:       ./scripts/start-mining.sh"
    echo -e "Stop mining:        ./scripts/stop-mining.sh"
    echo -e "Check pool status:  ./scripts/pool-status.sh"
    echo ""
    
    # Show logs command
    echo -e "${BLUE}📋 Useful Commands:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "View logs:          docker-compose -f docker-compose.solo.yml logs -f miningcore-solo"
    echo -e "Stop solo mining:   docker-compose -f docker-compose.solo.yml down"
    echo -e "Restart:            docker-compose -f docker-compose.solo.yml restart miningcore-solo"
    echo ""
else
    echo -e "${RED}❌ Failed to start solo mining pool!${NC}"
    echo "Check logs with: docker-compose -f docker-compose.solo.yml logs miningcore-solo"
    exit 1
fi

echo -e "${GREEN}🎉 Solo mining setup complete! Happy mining!${NC}" 