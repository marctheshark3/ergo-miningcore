#!/bin/bash

# Ergo Mining Pool Setup Script
# Automates the initial configuration and deployment

set -e

echo "=================================================="
echo "🚀 Ergo Mining Pool Setup"
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}❌ This script should not be run as root${NC}"
   exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    echo "Visit: https://docs.docker.com/engine/install/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✅ Docker and Docker Compose are installed${NC}"

# Create environment file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${BLUE}📝 Creating environment configuration...${NC}"
    cp env.template .env
    echo -e "${YELLOW}⚠️  Please edit .env file with your specific settings before continuing${NC}"
    echo "Key settings to change:"
    echo "  - DOMAIN_NAME"
    echo "  - LETSENCRYPT_EMAIL"
    echo "  - ERGO_API_KEY"
    echo "  - ERGO_WALLET_PASSWORD"
    echo "  - POOL_ADDRESS"
    echo "  - POSTGRES_PASSWORD"
    echo ""
    read -p "Press Enter after editing .env file to continue..."
fi

# Load environment variables
source .env

echo -e "${BLUE}📂 Creating directory structure...${NC}"
mkdir -p {config,scripts,ssl,logs}
mkdir -p ssl/{live,archive,renewal}
mkdir -p logs/nginx

echo -e "${BLUE}🔧 Setting up configuration files...${NC}"

# Update domain in nginx config
if [ -f config/nginx.conf ]; then
    sed -i "s/your-domain.com/$DOMAIN_NAME/g" config/nginx.conf
    echo -e "${GREEN}✅ Updated nginx configuration${NC}"
fi

# Update domain in pool config
if [ -f config/ergo-pool.json ]; then
    sed -i "s/your-domain.com/$DOMAIN_NAME/g" config/ergo-pool.json
    echo -e "${GREEN}✅ Updated pool configuration${NC}"
fi

# Generate API key hash for Ergo node
if [ ! -z "$ERGO_API_KEY" ]; then
    API_KEY_HASH=$(echo -n "$ERGO_API_KEY" | sha256sum | cut -d' ' -f1)
    sed -i "s/324dcf027dd4a30a932c441f365a25e86b173defa4b8e58948253471b81b72cf/$API_KEY_HASH/g" config/ergo.conf
    echo -e "${GREEN}✅ Updated Ergo node API key${NC}"
fi

echo -e "${BLUE}🔐 Setting up SSL certificates...${NC}"

# Generate SSL certificates
if [ "$USE_LETSENCRYPT" = "true" ]; then
    echo -e "${YELLOW}📜 Generating Let's Encrypt certificates...${NC}"
    echo "You will need to complete DNS verification manually."
    ./scripts/generate-ssl.sh
else
    echo -e "${YELLOW}📜 Generating self-signed certificates for testing...${NC}"
    USE_LETSENCRYPT=false ./scripts/generate-ssl.sh
fi

echo -e "${BLUE}🐳 Building Docker image...${NC}"
docker build -t ergo-miningcore .

echo -e "${BLUE}🚀 Starting services...${NC}"
docker-compose up -d

echo -e "${GREEN}✅ Services started successfully!${NC}"

# Wait for services to initialize
echo -e "${BLUE}⏳ Waiting for services to initialize...${NC}"
sleep 30

# Check service health
echo -e "${BLUE}🔍 Checking service health...${NC}"

# Check if containers are running
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ Docker containers are running${NC}"
else
    echo -e "${RED}❌ Some containers failed to start${NC}"
    docker-compose ps
fi

# Check database connection
if docker-compose exec -T postgres pg_isready -U miningcore > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database is ready${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
fi

# Check miningcore API
if curl -s http://localhost:4000/api/pools > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Miningcore API is responding${NC}"
else
    echo -e "${YELLOW}⚠️  Miningcore API not yet ready (this is normal during initial sync)${NC}"
fi

echo ""
echo "=================================================="
echo -e "${GREEN}🎉 Ergo Mining Pool Setup Complete!${NC}"
echo "=================================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. 📊 Monitor logs:"
echo "   docker-compose logs -f miningcore"
echo ""
echo "2. 🔧 Check pool status:"
echo "   curl http://localhost:4000/api/pools"
echo ""
echo "3. 💰 Configure your Ergo wallet in the node"
echo ""
echo "4. 🔗 Mining connection details:"
echo "   • Non-SSL: stratum+tcp://$DOMAIN_NAME:4066"
echo "   • SSL:     stratum+ssl://$DOMAIN_NAME:4068"
echo ""
echo "5. 🌐 API endpoints:"
echo "   • Pool stats: https://$DOMAIN_NAME/api/pools/ergo"
echo "   • Miners:     https://$DOMAIN_NAME/api/pools/ergo/miners"
echo ""
echo "6. 📖 Read the complete documentation:"
echo "   cat ergo-miningcore.md"
echo ""
echo "=================================================="
echo -e "${BLUE}🔧 Useful Commands:${NC}"
echo ""
echo "# View all logs"
echo "docker-compose logs -f"
echo ""
echo "# Restart miningcore"
echo "docker-compose restart miningcore"
echo ""
echo "# Stop all services"
echo "docker-compose down"
echo ""
echo "# Start all services"
echo "docker-compose up -d"
echo ""
echo "=================================================="
echo -e "${GREEN}Happy Mining! 🚀${NC}"
echo "==================================================" 