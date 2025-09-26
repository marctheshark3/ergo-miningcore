#!/bin/bash

# Ergo Solo Mining Pool Stop Script
# This script stops the mining pool infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛑 Stopping Ergo Solo Mining Pool...${NC}"

# Stop the services
docker-compose -f docker-compose.solo.yml down

echo -e "${GREEN}✅ Solo mining pool stopped successfully!${NC}"

# Show status
echo ""
echo -e "${BLUE}📋 Useful Commands:${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "Start pool:         ./scripts/start-pool.sh"
echo -e "View logs:          docker-compose -f docker-compose.solo.yml logs"
echo -e "Clean up volumes:   docker-compose -f docker-compose.solo.yml down -v"
echo ""

