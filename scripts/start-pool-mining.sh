#!/bin/bash

# Ergo Pool Mining Startup Script
# This script starts the Miningcore instance in regular pool mining mode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏊 Starting Ergo Pool Mining...${NC}"

# Check if required files exist
if [ ! -f "config/ergo-pool.json" ]; then
    echo -e "${RED}❌ Error: config/ergo-pool.json not found!${NC}"
    echo "Please make sure the pool mining configuration file exists."
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

# Check if pool config has proper wallet address
echo -e "${BLUE}🔍 Validating pool mining configuration...${NC}"
POOL_ADDRESS=$(grep -o '"address": *"[^"]*"' config/ergo-pool.json | head -1 | sed 's/"address": *"\([^"]*\)"/\1/')
if [ "$POOL_ADDRESS" = "9fRusQZ4xkRPtaiwBFcUxJZKLhJSC8MLs8M7M2eQZq7LxjRGJsX" ]; then
    echo -e "${YELLOW}⚠️  Warning: You are using the default wallet address!${NC}"
    echo "Please update the 'address' field in config/ergo-pool.json with your own Ergo wallet address."
    read -p "Continue with default address? (y/N): " continue_default
    if [[ ! $continue_default =~ ^[Yy]$ ]]; then
        echo "Please edit config/ergo-pool.json and set your wallet address, then run this script again."
        exit 1
    fi
fi

# Stop any running instances
echo -e "${BLUE}🛑 Stopping any running mining instances...${NC}"
docker-compose down > /dev/null 2>&1 || true

# Start pool mining
echo -e "${BLUE}🚀 Starting pool mining...${NC}"
docker-compose up -d

# Wait for services to be healthy
echo -e "${BLUE}⏳ Waiting for services to start...${NC}"
sleep 10

# Check if services are running
if docker-compose ps | grep -q "miningcore-1.*Up"; then
    echo -e "${GREEN}✅ Pool mining is running!${NC}"
    
    # Display connection information
    echo ""
    echo -e "${GREEN}🎯 Pool Mining Connection Information:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "🔌 Stratum (Non-SSL):"
    echo -e "   • Low Difficulty:    stratum+tcp://localhost:4066"
    echo -e "   • Medium Difficulty: stratum+tcp://localhost:4067"
    echo ""
    echo -e "🔒 Stratum (SSL):"
    echo -e "   • Low Difficulty:    stratum+ssl://localhost:4068"
    echo -e "   • Medium Difficulty: stratum+ssl://localhost:4069"
    echo ""
    echo -e "📊 API Endpoint:        http://localhost:4000/api/pools"
    echo -e "📊 Pool Stats:          http://localhost:4000/api/pools/ergo"
    echo ""
    echo -e "${YELLOW}💡 Note: In pool mining, rewards are shared among all miners based on contributed work!${NC}"
    echo -e "${YELLOW}💡 Payment scheme: PPLNS (Pay Per Last N Shares)${NC}"
    echo ""
    
    # Show example miner commands
    echo -e "${BLUE}📋 Example Miner Commands:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "T-Rex (NVIDIA):"
    echo -e "   t-rex -a autolykos2 -o stratum+tcp://localhost:4066 -u YOUR_ERGO_ADDRESS -w worker1"
    echo ""
    echo -e "TeamRedMiner (AMD):"
    echo -e "   teamredminer -a autolykos2 -o stratum+tcp://localhost:4066 -u YOUR_ERGO_ADDRESS -w worker1"
    echo ""
    echo -e "lolMiner:"
    echo -e "   lolMiner -a AUTOLYKOS2 -p stratum+tcp://localhost:4066 -u YOUR_ERGO_ADDRESS.worker1"
    echo ""
    
    # Check if load balancing is enabled
    if docker-compose ps | grep -q "miningcore-2.*Up"; then
        echo -e "${GREEN}🔄 Load balancing is active with secondary instance on ports 4070-4073${NC}"
    else
        echo -e "${BLUE}💡 To enable load balancing: docker-compose --profile scale up -d${NC}"
    fi
    
    # Show logs command
    echo -e "${BLUE}📋 Useful Commands:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "View logs:          docker-compose logs -f miningcore-1"
    echo -e "Stop pool mining:   docker-compose down"
    echo -e "Restart:            docker-compose restart miningcore-1"
    echo -e "Enable scaling:     docker-compose --profile scale up -d"
    echo ""
else
    echo -e "${RED}❌ Failed to start pool mining!${NC}"
    echo "Check logs with: docker-compose logs miningcore-1"
    exit 1
fi

echo -e "${GREEN}🎉 Pool mining setup complete! Happy mining!${NC}" 