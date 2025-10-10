#!/bin/bash

# GPU Setup Script for Ergo Mining
# Optimizes RTX 3090 for stable mining by reducing memory clock

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up GPU for Ergo Mining${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠️  This script needs sudo privileges${NC}"
    echo "Please run: sudo ./scripts/setup-gpu-mining.sh"
    exit 1
fi

echo -e "${BLUE}📊 Current GPU Status:${NC}"
nvidia-smi --query-gpu=index,name,temperature.gpu,power.draw,clocks.mem,clocks.gr --format=csv,noheader

echo ""
echo -e "${BLUE}⚙️  Applying optimal mining settings...${NC}"

# Enable persistence mode (better for mining)
nvidia-smi -pm 1
echo -e "${GREEN}✅ Persistence mode enabled${NC}"

# Set power limit (conservative for stability)
nvidia-smi -pl 240
echo -e "${GREEN}✅ Power limit set to 240W${NC}"

# Lock memory clock to safe level (much lower than max 9751)
nvidia-smi -lgc 1200,1200
echo -e "${GREEN}✅ Core clock locked to 1200 MHz${NC}"

nvidia-smi -lmc 8000,8000
echo -e "${GREEN}✅ Memory clock locked to 8000 MHz (down from 9501)${NC}"

echo ""
echo -e "${BLUE}📊 New GPU Status:${NC}"
nvidia-smi --query-gpu=index,name,temperature.gpu,power.draw,clocks.mem,clocks.gr --format=csv,noheader

echo ""
echo -e "${GREEN}🎉 GPU is ready for mining!${NC}"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "  • These settings persist until reboot"
echo "  • Monitor temps with: watch -n 1 nvidia-smi"
echo "  • If still unstable, try: sudo nvidia-smi -lmc 7500,7500"
echo ""
echo -e "${BLUE}🚀 Start mining with:${NC}"
echo "  ./scripts/start-mining.sh"
echo ""

