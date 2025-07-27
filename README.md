# Ergo Mining Pool Setup with Miningcore

> **📝 Note**: This repository is a specialized setup for Ergo mining pools. For the original Miningcore documentation covering all supported cryptocurrencies, see [README-original.md](README-original.md).

## Overview

This repository provides a complete Docker-based setup for running an Ergo (ERG) mining pool using Miningcore. The setup includes:

- **Miningcore**: High-performance mining pool software with Ergo support (supports load balancing)
- **PostgreSQL**: Database for share and payment tracking with automated backups
- **External Ergo Node**: Connects to your existing synced Ergo node
- **Nginx**: SSL termination and load balancing for secure connections
- **SSL Management**: Automated certificate generation and renewal
- **Data Persistence**: Critical protection for miners' balances and shares
- **Docker Compose**: Complete infrastructure orchestration

## 🏁 TL;DR - Get Started in 5 Minutes

**Prerequisites**: Linux server with Docker, existing synced Ergo node on port 9053

```bash
# 1. Clone and setup
git clone https://github.com/oliverw/miningcore && cd miningcore
cp env.template .env && chmod +x scripts/*.sh

# 2. Test your Ergo node connection
./scripts/test-ergo-connection.sh

# 3. Edit configuration (REQUIRED)
nano .env                      # Set domain, passwords, wallet address
nano config/ergo-pool.json     # Set pool wallet address (line ~150)

# 4. Generate SSL certificates
DOMAIN_NAME=your-domain.com LETSENCRYPT_EMAIL=admin@your-domain.com ./scripts/generate-ssl.sh

# 5. Start the pool
docker-compose up -d

# 6. Verify it's working
curl http://localhost:4000/api/pools
```

**Pool miners connect to**: `stratum+tcp://your-domain.com:4066`
**Solo miners connect to**: `stratum+tcp://your-domain.com:4074`

## 🎰 Solo Mining Quick Start

Want to mine for full block rewards? Try solo mining:

```bash
# Start solo mining (after completing setup above)
./scripts/start-solo-mining.sh

# Test your setup
./scripts/test-solo-mining.sh

# Connect your miner
t-rex -a autolykos2 -o stratum+tcp://localhost:4074 -u YOUR_ERGO_ADDRESS -w solo-miner
```

📚 **Full Solo Mining Guide**: See [SOLO-MINING.md](SOLO-MINING.md) for detailed documentation

---

## Features

- ✅ Full Ergo blockchain support with native implementation
- ✅ **Solo Mining Support** - Mine for full block rewards
- ✅ SSL/TLS encryption for secure miner connections
- ✅ Variable difficulty adjustment (vardiff)
- ✅ Multiple stratum ports (Pool: 4066-4069, Solo: 4074-4077)
- ✅ Real-time API for pool statistics
- ✅ Automated payment processing
- ✅ PPLNS (Pay Per Last N Shares) reward scheme + SOLO scheme
- ✅ PostgreSQL database with automatic schema setup
- ✅ Nginx reverse proxy with rate limiting
- ✅ Let's Encrypt SSL certificate automation
- ✅ Comprehensive logging and monitoring
- ✅ Docker containerization for easy deployment

## Prerequisites

- **Server**: Linux server (Ubuntu 20.04+ recommended)
- **Resources**: Minimum 4GB RAM, 100GB+ SSD storage
- **Network**: Public IP address with ports 80, 443, 4066-4073 open
- **Domain**: Domain name pointing to your server (for SSL certificates)
- **Docker**: Docker and Docker Compose installed
- **Ergo Node**: Existing synced Ergo node running on port 9053

## 🚀 Quick Start Guide

Follow these steps to get your Ergo mining pool running:

### Step 1: Initial Setup

```bash
# Clone this repository
git clone https://github.com/oliverw/miningcore
cd miningcore

# Create environment file from template
cp env.template .env

# Create necessary directories
mkdir -p config scripts ssl logs backups

# Make scripts executable
chmod +x scripts/*.sh
```

### Step 2: Test External Ergo Node Connection

**Before proceeding, ensure your existing Ergo node is running and synced:**

```bash
# Test your Ergo node connection
./scripts/test-ergo-connection.sh

# If this fails, make sure your Ergo node is:
# - Running on port 9053
# - Has API enabled in ergo.conf
# - Is fully synced with the network
```

### Step 3: Configure Environment Variables

**⚠️ REQUIRED**: Edit the `.env` file with your specific settings:

```bash
nano .env
```

**Essential settings you MUST change:**

```bash
# External Ergo Node (update if not localhost)
ERGO_NODE_HOST=localhost
ERGO_NODE_PORT=9053

# Domain and SSL (for production)
DOMAIN_NAME=your-mining-pool.com
LETSENCRYPT_EMAIL=admin@your-mining-pool.com

# Database security
POSTGRES_PASSWORD=your_secure_database_password_here

# Pool wallet (you must set this!)
POOL_ADDRESS=your_ergo_wallet_address_here
```

### Step 4: Configure Pool Settings

**⚠️ REQUIRED**: Edit the pool configuration:

```bash
nano config/ergo-pool.json
```

**Key settings to update:**

1. **Pool Wallet Address** (line ~150):
   ```json
   "address": "YOUR_ERGO_WALLET_ADDRESS_HERE"
   ```

2. **Pool Fee Settings** (line ~160):
   ```json
   "rewardRecipients": [
     {
       "address": "your_pool_fee_address",
       "percentage": 1.0
     }
   ]
   ```

3. **Ergo API Key** (line ~145 - if your node requires it):
   ```json
   "extra": {
     "apiKey": "your_api_key_here"
   }
   ```

### Step 5: Generate SSL Certificates

**For Production (recommended):**
```bash
# Set your domain and email, then generate Let's Encrypt certificates
DOMAIN_NAME=your-domain.com LETSENCRYPT_EMAIL=admin@your-domain.com ./scripts/generate-ssl.sh
```

**For Development/Testing:**
```bash
# Generate self-signed certificates
USE_LETSENCRYPT=false DOMAIN_NAME=localhost ./scripts/generate-ssl.sh
```

### Step 6: Start the Mining Pool

```bash
# Start the pool (single instance)
docker-compose up -d

# OR start with load balancing (dual instances)
docker-compose --profile scale up -d

# Check if everything is running
docker-compose ps

# View logs
docker-compose logs -f miningcore-1
```

### Step 7: Verify Pool is Working

```bash
# Check pool API
curl http://localhost:4000/api/pools

# Check pool stats
curl http://localhost:4000/api/pools/ergo

# Test miner connection (if you have a miner)
# Point your miner to: stratum+tcp://your-domain.com:4066
```

### Step 8: Set Up Automated Backups (Important!)

```bash
# Test backup manually
./scripts/backup-db.sh

# Add to crontab for daily backups at 2 AM
echo "0 2 * * * $(pwd)/scripts/backup-db.sh >/dev/null 2>&1" | crontab -

# Verify crontab
crontab -l
```

---

## 📋 Configuration Checklist

Make sure you've configured these essential items:

- [ ] **Ergo Node**: External node is running and accessible
- [ ] **Environment**: Updated `.env` with your domain and passwords  
- [ ] **Pool Address**: Set your Ergo wallet address in `config/ergo-pool.json`
- [ ] **Pool Fees**: Configured reward recipients and percentages
- [ ] **SSL Certificates**: Generated for your domain
- [ ] **Automated Backups**: Set up crontab for daily database backups
- [ ] **Firewall**: Opened ports 80, 443, 4066-4073
- [ ] **DNS**: Domain points to your server IP

---

## ⚡ Common Setup Issues & Solutions

**Problem**: `./scripts/test-ergo-connection.sh` fails
**Solution**: 
```bash
# Check if Ergo node is running
systemctl status ergo  # or whatever service name you use
curl http://localhost:9053/info

# Make sure API is enabled in your ergo.conf
grep "restApi" /path/to/ergo.conf
```

**Problem**: Docker containers won't start
**Solution**:
```bash
# Check logs for specific errors
docker-compose logs miningcore-1

# Common issues:
# - Wrong database password in .env
# - Missing wallet address in config/ergo-pool.json
# - Port conflicts (check with: netstat -tulpn | grep 4066)
```

**Problem**: Can't connect miners to pool
**Solution**:
```bash
# Check if stratum ports are open
sudo ufw status  # or iptables -L
telnet your-domain.com 4066

# Verify pool is accepting connections
docker-compose logs -f miningcore-1 | grep stratum
```

**Problem**: SSL certificate generation fails
**Solution**:
```bash
# Make sure DNS is pointing to your server
nslookup your-domain.com

# Check if ports 80/443 are available
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# For development, use self-signed certs
USE_LETSENCRYPT=false ./scripts/generate-ssl.sh
```

---

## External Ergo Node Configuration

This setup is designed to work with your **existing synced Ergo node** instead of running a separate containerized node.

### 1. Verify Your Ergo Node

Ensure your Ergo node is running and accessible:

```bash
# Check if your Ergo node is running
curl http://localhost:9053/info

# Verify API is enabled in your ergo.conf
grep "apiKeyHash" /path/to/your/ergo.conf
```

### 2. Configure External Node Connection

Edit `.env` file:

```bash
# External Ergo Node Configuration
ERGO_NODE_HOST=localhost        # or IP address of your Ergo node
ERGO_NODE_PORT=9053            # API port of your Ergo node
```

**Important**: The mining pool will connect to your existing Ergo node using Docker's `host.docker.internal` which maps to your host system.

## Data Persistence & Backup Protection

🚨 **CRITICAL**: This setup ensures miners never lose their balances during container updates or restarts.

### Persistent Data Volumes

The following data is automatically persisted:

- **PostgreSQL Database**: All miners' shares, balances, and payment history
- **SSL Certificates**: Let's Encrypt certificates and renewals
- **Logs**: All mining pool operational logs
- **Miningcore Data**: Internal pool state and configuration

### Automated Database Backups

```bash
# Create a backup manually
./scripts/backup-db.sh

# Set up automated daily backups (add to crontab)
0 2 * * * /path/to/your/mining-pool/scripts/backup-db.sh >/dev/null 2>&1

# Restore from backup if needed
./scripts/restore-db.sh ./backups/miningcore_backup_20231215_143022.sql.gz
```

## Load Balancing Configuration

For high availability, you can run multiple Miningcore instances:

### 1. Enable Secondary Instance

```bash
# Start with load balancing
docker-compose --profile scale up -d

# This starts both miningcore-1 and miningcore-2
```

### 2. Port Configuration

**Primary Instance (miningcore-1):**
- API: 4000
- Stratum: 4066, 4067, 4068 SSL, 4069 SSL

**Secondary Instance (miningcore-2):**
- API: 4001
- Stratum: 4070, 4071, 4072 SSL, 4073 SSL

### 3. Nginx Load Balancing

The nginx configuration automatically balances between instances:
- Primary instance handles normal load
- Secondary instance acts as backup (failover)
- Remove `backup` from nginx.conf for active load balancing

### 2. Continue with Configuration

After following the Quick Start Guide above, your pool should be running. The remaining sections below provide detailed information about:

- Advanced configuration options
- Mining connection details  
- API endpoints and monitoring
- Troubleshooting and maintenance
- Security considerations

## Detailed Configuration

### Pool Configuration (`config/ergo-pool.json`)

#### Essential Settings

```json
{
  "pools": [{
    "address": "9fRusQZ4xkRPtaiwBFcUxJZKLhJSC8MLs8M7M2eQZq7LxjRGJsX",
    "rewardRecipients": [
      {
        "address": "your_pool_fee_address",
        "percentage": 1.0
      }
    ]
  }]
}
```

#### Mining Ports

| Port | SSL | Difficulty | Description |
|------|-----|------------|-------------|
| 4066 | No  | 0.1        | Low difficulty for small miners |
| 4067 | No  | 1.0        | Medium difficulty for regular miners |
| 4068 | Yes | 0.1        | SSL low difficulty |
| 4069 | Yes | 1.0        | SSL medium difficulty |

#### Variable Difficulty (VarDiff)

```json
"varDiff": {
  "minDiff": 0.0001,
  "maxDiff": 1000000,
  "targetTime": 15,
  "retargetTime": 90,
  "variancePercent": 30
}
```

### Ergo Node Configuration (`config/ergo.conf`)

#### API Access

```hocon
scorex {
  restApi {
    apiKeyHash = "your_api_key_hash_here"
    bindAddress = "0.0.0.0:9053"
  }
}
```

#### Mining Settings

```hocon
node {
  mining = true
  useExternalMiner = true
  stateType = "utxo"
}
```

### Database Schema

The PostgreSQL database automatically creates these tables:

- **shares**: Mining share submissions
- **blocks**: Found blocks and confirmations
- **balances**: Miner account balances
- **payments**: Payment transaction records
- **poolstats**: Pool performance statistics
- **minerstats**: Individual miner statistics

## Mining Connection

### Stratum URLs

- **Non-SSL**: `stratum+tcp://your-domain.com:4066`
- **SSL**: `stratum+ssl://your-domain.com:4068`

### Example Miner Configuration

#### T-Rex (NVIDIA)
```bash
t-rex -a autolykos2 -o stratum+tcp://your-domain.com:4066 -u YOUR_ERGO_ADDRESS -w worker1
```

#### TeamRedMiner (AMD)
```bash
teamredminer -a autolykos2 -o stratum+tcp://your-domain.com:4066 -u YOUR_ERGO_ADDRESS -w worker1
```

#### lolMiner
```bash
lolMiner -a AUTOLYKOS2 -p stratum+tcp://your-domain.com:4066 -u YOUR_ERGO_ADDRESS.worker1
```

## API Endpoints

### Pool Statistics
```
GET https://your-domain.com/api/pools
GET https://your-domain.com/api/pools/ergo
GET https://your-domain.com/api/pools/ergo/miners
```

### Miner Statistics
```
GET https://your-domain.com/api/pools/ergo/miners/YOUR_ADDRESS
GET https://your-domain.com/api/pools/ergo/miners/YOUR_ADDRESS/payments
```

### Example API Response
```json
{
  "id": "ergo",
  "coin": {
    "type": "ERG",
    "algorithm": "autolykos2"
  },
  "poolStats": {
    "connectedMiners": 45,
    "poolHashrate": 1250000000,
    "sharesPerSecond": 12.5
  },
  "networkStats": {
    "networkHashrate": 15000000000000,
    "networkDifficulty": 1180591620717411303424,
    "blockHeight": 845231
  }
}
```

## Operations

### Starting/Stopping Services

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart miningcore

# View logs
docker-compose logs -f miningcore
docker-compose logs -f ergo-node
```

### SSL Certificate Renewal

```bash
# Check certificate status
./scripts/renew-certs.sh

# Automated renewal (add to crontab)
0 0 * * 0 /path/to/scripts/renew-certs.sh
```

### Database Management

```bash
# Access database
docker-compose exec postgres psql -U miningcore -d miningcore

# Backup database
docker-compose exec postgres pg_dump -U miningcore miningcore > backup.sql

# Monitor database size
docker-compose exec postgres psql -U miningcore -d miningcore -c "
SELECT schemaname,tablename,pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size 
FROM pg_tables WHERE schemaname='public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```

### Monitoring and Logs

```bash
# Pool performance
curl https://your-domain.com/api/pools/ergo

# Container health
docker-compose ps

# Resource usage
docker stats

# Log monitoring
tail -f logs/miningcore.log
tail -f logs/nginx/access.log
```

## Troubleshooting

### Common Issues

#### Miningcore Won't Start
```bash
# Check configuration
docker-compose logs miningcore

# Validate JSON config
cat config/ergo-pool.json | jq .

# Check database connection
docker-compose exec postgres psql -U miningcore -d miningcore -c "SELECT version();"
```

#### Ergo Node Sync Issues
```bash
# Check node status
curl -H "api_key: your_api_key" http://localhost:9053/info

# View node logs
docker-compose logs ergo-node

# Check peer connections
curl -H "api_key: your_api_key" http://localhost:9053/peers/connected
```

#### SSL Certificate Issues
```bash
# Check certificate validity
openssl x509 -in ssl/live/your-domain.com/cert.pem -text -noout

# Test SSL connection
openssl s_client -connect your-domain.com:443

# Regenerate certificates
./scripts/generate-ssl.sh
```

#### Database Performance
```bash
# Check slow queries
docker-compose exec postgres psql -U miningcore -d miningcore -c "
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC LIMIT 10;
"

# Optimize database
docker-compose exec postgres psql -U miningcore -d miningcore -c "VACUUM ANALYZE;"
```

### Performance Tuning

#### Pool Optimization
- Increase `maxActiveJobs` for high block rates
- Tune `blockRefreshInterval` based on network conditions
- Adjust `jobRebroadcastTimeout` for network latency

#### Database Optimization
- Implement table partitioning for large share tables
- Regular database maintenance and vacuuming
- Monitor and optimize slow queries

#### Node Optimization
- Use SSD storage for blockchain data
- Allocate sufficient RAM (8GB+ recommended)
- Optimize network connectivity

## Security Considerations

### Network Security
- Firewall configuration (only open necessary ports)
- DDoS protection and rate limiting
- Regular security updates

### Application Security
- Strong passwords for all components
- API key rotation
- SSL/TLS encryption for all connections
- Regular backup procedures

### Wallet Security
- Secure wallet seed storage
- Multi-signature wallet implementation
- Regular balance monitoring
- Cold storage for pool reserves

## Maintenance

### Regular Tasks
- Monitor pool performance and hashrate
- Check miner connections and payments
- Update software components
- Backup database and configurations
- Monitor SSL certificate expiration
- Review logs for errors or issues

### Updates
```bash
# Update miningcore
git pull origin master
docker-compose build --no-cache miningcore
docker-compose up -d miningcore

# Update Ergo node
docker-compose pull ergo-node
docker-compose up -d ergo-node
```

## Support and Resources

- **Miningcore Documentation**: https://github.com/oliverw/miningcore/wiki
- **Ergo Platform**: https://ergoplatform.org/
- **Discord Community**: [Ergo Discord](https://discord.gg/ergo-platform)
- **Mining Software**: [T-Rex](https://github.com/trexminer/T-Rex), [TeamRedMiner](https://github.com/todxx/teamredminer), [lolMiner](https://github.com/Lolliedieb/lolMiner-releases)

## License

This project is based on Miningcore, which is licensed under the MIT License. See the original [LICENSE](LICENSE) file for details.

---

**Disclaimer**: Running a mining pool involves significant technical complexity and financial responsibility. Ensure you understand all aspects of pool operation, including legal compliance, security, and financial management, before operating a production pool. 
