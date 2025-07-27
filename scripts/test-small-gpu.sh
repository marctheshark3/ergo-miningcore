#!/bin/bash

# Small GPU Solo Mining Test Script
# This script tests solo mining specifically optimized for small GPUs with very low difficulty

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Small GPU Solo Mining Setup...${NC}"
echo -e "${YELLOW}This test uses extremely low difficulty settings perfect for validating with small GPUs${NC}"

# Check if test config exists
if [ ! -f "config/ergo-solo-test.json" ]; then
    echo -e "${RED}❌ Error: config/ergo-solo-test.json not found!${NC}"
    echo "The test configuration file is missing."
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Error: .env file not found!${NC}"
    echo "Please create a .env file from env.template and configure it."
    exit 1
fi

# Source environment variables
source .env

# Stop any running instances
echo -e "${BLUE}🛑 Stopping any running mining instances...${NC}"
docker-compose down > /dev/null 2>&1 || true

# Start test solo mining with custom config
echo -e "${BLUE}🚀 Starting small GPU test solo mining...${NC}"
docker run -d \
    --name ergo-test-solo \
    --network ergo-miningcore_miningcore-network \
    -p 4002:4000 \
    -p 4078:4078 \
    -p 4079:4079 \
    -v $(pwd)/config/ergo-solo-test.json:/app/config.json:ro \
    -v $(pwd)/logs:/app/logs \
    -e ERGO_NODE_HOST=${ERGO_NODE_HOST:-host.docker.internal} \
    -e ERGO_NODE_PORT=${ERGO_NODE_PORT:-9053} \
    --add-host=host.docker.internal:host-gateway \
    ergo-miningcore_miningcore-1:latest || {
        echo -e "${YELLOW}⚠️  Using fallback method...${NC}"
        
        # Fallback: Start with docker-compose but replace config
        cp config/ergo-solo-test.json config/ergo-solo-pool.json.backup
        mv config/ergo-solo-test.json config/ergo-solo-pool.json
        docker-compose --profile solo up -d
        mv config/ergo-solo-pool.json.backup config/ergo-solo-pool.json 2>/dev/null || true
    }

# Wait for service to start
echo -e "${BLUE}⏳ Waiting for test service to start...${NC}"
sleep 15

# Test if the service is responding
echo -e "${BLUE}🔍 Testing API endpoint...${NC}"
MAX_ATTEMPTS=30
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if curl -s --connect-timeout 5 "http://localhost:4002/api/pools" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Test solo mining API is responding${NC}"
        break
    fi
    echo -e "${YELLOW}⏳ Attempt $ATTEMPT/$MAX_ATTEMPTS: Waiting for API...${NC}"
    sleep 2
    ((ATTEMPT++))
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    echo -e "${RED}❌ Test solo mining failed to start${NC}"
    docker logs ergo-test-solo 2>/dev/null || docker-compose logs miningcore-solo
    exit 1
fi

# Display test configuration
echo ""
echo -e "${GREEN}🎯 Small GPU Test Configuration:${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "🔌 Test Stratum Ports:"
echo -e "   • Port 4078: Ultra-low difficulty (0.001) - Perfect for small GPUs"
echo -e "   • Port 4079: Low difficulty (0.005) - For slightly larger GPUs"
echo ""
echo -e "📊 API Endpoint: http://localhost:4002/api/pools"
echo ""

# Test stratum connections
echo -e "${BLUE}🔌 Testing Stratum Connections:${NC}"
for port in 4078 4079; do
    if command -v nc &> /dev/null; then
        if timeout 5 nc -z localhost $port 2>/dev/null; then
            echo -e "${GREEN}✅ Port $port is accepting connections${NC}"
        else
            echo -e "${RED}❌ Cannot connect to port $port${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  nc not available, skipping port test${NC}"
    fi
done

# Get pool information
echo ""
echo -e "${BLUE}📊 Pool Information:${NC}"
if command -v jq &> /dev/null; then
    POOL_INFO=$(curl -s "http://localhost:4002/api/pools" 2>/dev/null)
    echo "$POOL_INFO" | jq '.[0] | {id, coin, poolStats}' 2>/dev/null || echo "API response received (jq formatting failed)"
else
    echo "$(curl -s "http://localhost:4002/api/pools" 2>/dev/null | head -c 200)..."
fi

echo ""
echo -e "${GREEN}🎉 Small GPU Test Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Test Mining Commands:${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "Ultra-low difficulty (best for testing small GPUs):"
echo -e "   t-rex -a autolykos2 -o stratum+tcp://localhost:4078 -u YOUR_ERGO_ADDRESS -w test-gpu"
echo ""
echo -e "Low difficulty:"
echo -e "   t-rex -a autolykos2 -o stratum+tcp://localhost:4079 -u YOUR_ERGO_ADDRESS -w test-gpu"
echo ""
echo -e "${YELLOW}💡 Expected Results:${NC}"
echo -e "   • With ultra-low difficulty (0.001), even a GTX 1060 should submit shares every 5-10 seconds"
echo -e "   • You should see 'Share accepted' messages in the logs very frequently"
echo -e "   • This validates that your miner and pool are communicating correctly"
echo ""
echo -e "${BLUE}📋 Monitor Test Results:${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "Watch for shares:"
echo -e "   docker logs -f ergo-test-solo 2>/dev/null || docker-compose logs -f miningcore-solo"
echo ""
echo -e "Filter for important events:"
echo -e "   docker logs -f ergo-test-solo 2>&1 | grep -E '(Share|Client|Connected)'"
echo ""
echo -e "Stop test:"
echo -e "   docker stop ergo-test-solo && docker rm ergo-test-solo"
echo ""
echo -e "${YELLOW}🔬 This test configuration is ONLY for validation - not for actual mining!${NC}"
echo -e "${YELLOW}⚡ The difficulty is artificially low to ensure you see shares quickly${NC}" 