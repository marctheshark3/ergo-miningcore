# Ergo Miningcore Pool

A comprehensive, production-ready mining pool implementation for Ergo cryptocurrency, based on the powerful [Miningcore](https://github.com/oliverw/miningcore) framework. Supports both solo mining and public pool configurations with enterprise-grade features.

## 🚀 Features

### Solo Mining
- ✅ **Simple Setup**: Perfect for individual miners
- ✅ **Low Resource Usage**: Minimal overhead  
- ✅ **Direct Rewards**: 100% of block rewards go to the miner
- ✅ **Variable Difficulty**: Multiple ports for different hardware

### Public Pool
- ✅ **Enterprise Ready**: Full-featured public mining pool
- ✅ **SSL/TLS Support**: Secure encrypted connections
- ✅ **Load Balancing**: Nginx reverse proxy with high availability
- ✅ **Payment Systems**: PPLNS, PROP, and other schemes
- ✅ **Real-time API**: RESTful API with WebSocket notifications
- ✅ **Redis Caching**: High-performance data caching
- ✅ **Monitoring**: Comprehensive health checks and metrics

### General Features
- 🔄 **Auto Database Init**: Automatic PostgreSQL schema creation
- 🛡️ **Security**: Advanced banning, rate limiting, and DDoS protection
- 📊 **Analytics**: Detailed statistics and reporting
- 🔧 **Management Tools**: Comprehensive CLI management interface
- 📧 **Notifications**: Email alerts for important events
- 🔐 **SSL Automation**: Automatic Let's Encrypt integration

## 📋 Requirements

- **Docker** & **Docker Compose**
- **Ergo Node** (running and synced)
- **Domain** (for public pools)
- **SSL Certificate** (automated with Let's Encrypt)

### System Requirements
- **CPU**: 2+ cores recommended
- **RAM**: 4GB+ (8GB+ for public pools)
- **Storage**: 50GB+ SSD space
- **Network**: Stable internet connection

## ⚡ Quick Start

### Solo Mining (Simple Setup)

Perfect for individual miners who want to mine directly to their own wallet:

```bash
# 1. Clone and enter directory
git clone <repository-url>
cd ergo-miningcore

# 2. Copy and configure environment
cp env.solo.template .env
# Edit .env with your settings

# 3. Start solo mining pool
./scripts/pool-manager.sh start solo

# 4. Connect your miner
# Low difficulty:  stratum+tcp://localhost:4074
# High difficulty: stratum+tcp://localhost:4075
```

### Public Pool (Full Setup)

For running a public mining pool with all enterprise features:

```bash
# 1. Clone and configure
git clone <repository-url>
cd ergo-miningcore

# 2. Set up environment
cp env.template .env
# Edit .env with your domain and email

# 3. Generate SSL certificates
./scripts/generate-ssl.sh your-domain.com

# 4. Start public pool
./scripts/pool-manager.sh start public

# 5. Your pool is ready!
# Web interface: https://your-domain.com
# API: https://your-domain.com/api/pools
```

## 🔧 Configuration

### Environment Files

#### Solo Mining (`.env`)
```bash
# Ergo Node Configuration
ERGO_NODE_HOST=host.docker.internal
ERGO_NODE_PORT=9053

# Database
POSTGRES_PASSWORD=your_secure_password

# Stratum Ports
SOLO_STRATUM_PORT_1=4074  # Low difficulty
SOLO_STRATUM_PORT_2=4075  # High difficulty
```

#### Public Pool (`.env`)
```bash
# Domain & SSL
POOL_DOMAIN=your-pool.com
LETSENCRYPT_EMAIL=admin@your-pool.com

# Database
POSTGRES_PASSWORD=very_secure_password

# Pool Settings
POOL_FEE_PERCENT=1.0
MINIMUM_PAYMENT=1.0

# Email Notifications
SMTP_HOST=smtp.your-provider.com
SMTP_USER=noreply@your-pool.com
ADMIN_EMAIL=admin@your-pool.com
```

### Pool Configuration

#### Solo Pool Config (`config/ergo-solo-simple.json`)
```json
{
  "pools": [{
    "id": "ergo-solo",
    "payoutScheme": "SOLO",
    "minimumPayment": 0.1,
    "ports": {
      "4074": {"difficulty": 0.01},
      "4075": {"difficulty": 0.1}
    }
  }]
}
```

#### Public Pool Config (`config/ergo-public-pool.json`)
```json
{
  "pools": [{
    "id": "ergo-public",
    "payoutScheme": "PPLNS",
    "minimumPayment": 1.0,
    "ports": {
      "4444": {"difficulty": 0.1},
      "5555": {"difficulty": 1.0},
      "7777": {"difficulty": 10.0, "tls": true},
      "8888": {"difficulty": 100.0, "tls": true}
    }
  }]
}
```

## 🎮 Management

### Pool Manager CLI

The `pool-manager.sh` script provides comprehensive pool management:

```bash
# Start pools
./scripts/pool-manager.sh start solo     # Start solo mining
./scripts/pool-manager.sh start public  # Start public pool

# Monitor
./scripts/pool-manager.sh status        # Show detailed status
./scripts/pool-manager.sh logs          # View all logs
./scripts/pool-manager.sh health        # Run health checks

# Maintenance
./scripts/pool-manager.sh update        # Update containers
./scripts/pool-manager.sh backup        # Create backup
./scripts/pool-manager.sh restart       # Restart services

# SSL Management
./scripts/pool-manager.sh ssl generate your-domain.com
./scripts/pool-manager.sh ssl renew
./scripts/pool-manager.sh ssl check
```

### Service Management

```bash
# Manual Docker Compose commands
docker-compose -f docker-compose.solo.yml up -d    # Solo
docker-compose -f docker-compose.yml up -d         # Public

# View logs
docker-compose logs -f miningcore
docker-compose logs -f nginx

# Check service health
docker-compose ps
```

## 🔌 Mining Connections

### Solo Mining Ports
- **4074**: Low difficulty (0.01) - Good for small miners
- **4075**: High difficulty (0.1) - Good for larger miners

### Public Pool Ports
- **4444**: Standard (0.1 difficulty) - Non-SSL
- **5555**: Medium (1.0 difficulty) - Non-SSL  
- **7777**: High (10.0 difficulty) - SSL encrypted
- **8888**: Extreme (100.0 difficulty) - SSL encrypted

### Miner Configuration Examples

#### lolMiner
```bash
# Solo mining
./lolMiner --algo AUTOLYKOS2 --pool localhost:4074 --user YOUR_WALLET_ADDRESS

# Public pool
./lolMiner --algo AUTOLYKOS2 --pool your-domain.com:4444 --user YOUR_WALLET_ADDRESS
```

#### T-Rex
```bash
# Solo mining
t-rex -a autolykos2 -o stratum+tcp://localhost:4074 -u YOUR_WALLET_ADDRESS

# Public pool SSL
t-rex -a autolykos2 -o stratum+ssl://your-domain.com:7777 -u YOUR_WALLET_ADDRESS
```

## 📊 Monitoring & API

### API Endpoints

```bash
# Pool information
GET /api/pools                    # List all pools
GET /api/pools/{poolId}          # Pool details
GET /api/pools/{poolId}/stats    # Pool statistics

# Miner information  
GET /api/pools/{poolId}/miners             # Active miners
GET /api/pools/{poolId}/miners/{address}   # Miner details

# Blocks and payments
GET /api/pools/{poolId}/blocks    # Found blocks
GET /api/pools/{poolId}/payments  # Payment history
```

### Web Interface

- **Solo**: http://localhost:4000/api/pools
- **Public**: https://your-domain.com

### Metrics & Monitoring

Prometheus metrics available at `/metrics` endpoint for integration with monitoring systems like Grafana.

## 🔒 Security

### SSL/TLS Configuration

#### Let's Encrypt (Recommended)
```bash
# Automatic certificate generation
export POOL_DOMAIN=your-pool.com
export LETSENCRYPT_EMAIL=admin@your-pool.com
./scripts/generate-ssl.sh
```

#### Self-Signed (Development)
```bash
# Generate self-signed certificates
./scripts/generate-ssl.sh localhost
```

### Security Features

- **Rate Limiting**: API and connection rate limits
- **DDoS Protection**: Multiple layers of protection
- **Secure Headers**: HSTS, CSP, and other security headers
- **Input Validation**: Comprehensive request validation
- **Encrypted Storage**: Sensitive data encryption

## 💾 Database

### Automatic Initialization

The database schema is automatically created on first startup with all required tables:

- `shares` - Mining share records
- `blocks` - Discovered blocks  
- `balances` - Miner balances
- `payments` - Payment history
- `poolstats` - Pool statistics
- `minerstats` - Individual miner stats

### Backup & Restore

```bash
# Create backup
./scripts/pool-manager.sh backup

# Manual database backup
docker exec postgres pg_dump -U miningcore miningcore > backup.sql

# Restore database
docker exec -i postgres psql -U miningcore miningcore < backup.sql
```

## 🚨 Troubleshooting

### Common Issues

#### Connection Refused
```bash
# Check Ergo node status
curl -H "api_key: hello" http://localhost:9053

# Check if node is listening on all interfaces
netstat -tlnp | grep :9053
```

#### Database Issues
```bash
# Check database connection
docker exec postgres psql -U miningcore -c "\\dt"

# Recreate database tables
docker exec postgres psql -U miningcore miningcore < scripts/init-db.sql
```

#### SSL Certificate Problems
```bash
# Check certificate status
./scripts/pool-manager.sh ssl check

# Regenerate certificates
./scripts/pool-manager.sh ssl generate your-domain.com
```

### Log Locations

```bash
logs/miningcore-solo.log    # Solo pool logs
logs/miningcore-public.log  # Public pool logs
logs/api-solo.log          # Solo API logs
logs/api-public.log        # Public API logs
logs/nginx/                # Nginx access/error logs
```

### Health Checks

```bash
# Comprehensive system check
./scripts/pool-manager.sh health

# Check individual services
docker-compose ps
curl http://localhost:4000/api/pools
```

## 🔄 Updates & Maintenance

### Regular Maintenance

```bash
# Update containers
./scripts/pool-manager.sh update

# Renew SSL certificates (automated)
./scripts/renew-certs.sh

# Create backups
./scripts/pool-manager.sh backup

# Clean up system
./scripts/pool-manager.sh cleanup
```

### Version Updates

```bash
# Pull latest changes
git pull origin main

# Rebuild containers
docker-compose build --pull

# Restart services
./scripts/pool-manager.sh restart
```

## 📈 Performance Tuning

### Database Optimization

```sql
-- Optimize PostgreSQL for mining pool workload
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
```

### System Optimization

```bash
# Increase file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Optimize network settings
echo "net.core.somaxconn = 8192" >> /etc/sysctl.conf
sysctl -p
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check this README and the [SETUP-SUMMARY.md](SETUP-SUMMARY.md)
- **Issues**: Report bugs via GitHub Issues
- **Discord**: Join our mining community
- **Email**: Contact admin@your-pool.com

## 💝 Donations

Support the development of this mining pool:

**Ergo**: `9f6a8rtMMmCpFbZT45Hnkm7L8SHaGZcvwh1MkQdoMkRgHtbDqQq`

## 🔗 Links

- **Ergo Platform**: https://ergoplatform.org
- **Miningcore**: https://github.com/oliverw/miningcore
- **Ergo Explorer**: https://explorer.ergoplatform.com
- **Mining Software**: See [miners list](docs/miners.md)

---

*Built with ❤️ for the Ergo community*