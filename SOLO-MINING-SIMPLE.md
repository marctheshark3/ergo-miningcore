# Ergo Solo Mining - Simplified Setup

This guide provides a simplified setup for Ergo solo mining without the web infrastructure (nginx, SSL certificates, etc.).

## Overview

The simplified solo mining setup includes:
- **PostgreSQL database** for storing mining data
- **Miningcore instance** optimized for solo mining
- **No web interface** - access via API only
- **No SSL certificates** - basic stratum connections only

## Quick Start

### 1. Prerequisites

- Docker and Docker Compose installed
- Ergo node running and accessible
- Your Ergo wallet address ready

### 2. Setup Environment

```bash
# Copy the environment template
cp env.solo.template .env

# Edit the configuration
nano .env
```

Update the following in your `.env` file:
- `ERGO_NODE_HOST`: Your Ergo node host (default: localhost)
- `ERGO_NODE_PORT`: Your Ergo node port (default: 9053)
- `POSTGRES_PASSWORD`: Change the default database password

### 3. Configure Wallet Address

Edit `config/ergo-solo-simple.json` and update the wallet address:

```json
{
    "pools": [
        {
            "id": "ergo-solo",
            "address": "YOUR_ERGO_WALLET_ADDRESS_HERE",
            "rewardRecipients": [
                {
                    "address": "YOUR_ERGO_WALLET_ADDRESS_HERE",
                    "percentage": 0
                }
            ]
        }
    ]
}
```

### 4. Start Solo Mining

```bash
# Make the script executable (if not already)
chmod +x scripts/start-solo-simple.sh

# Start solo mining
./scripts/start-solo-simple.sh
```

## Connection Information

Once started, you can connect miners to:

### Stratum Ports
- **Low Difficulty**: `stratum+tcp://localhost:4074`
- **Medium Difficulty**: `stratum+tcp://localhost:4075`

### API Endpoints
- **Pool Stats**: `http://localhost:4001/api/pools/ergo-solo`
- **All Pools**: `http://localhost:4001/api/pools`

## Example Miner Commands

### T-Rex (NVIDIA)
```bash
t-rex -a autolykos2 -o stratum+tcp://localhost:4074 -u YOUR_ERGO_ADDRESS -w worker1
```

### TeamRedMiner (AMD)
```bash
teamredminer -a autolykos2 -o stratum+tcp://localhost:4074 -u YOUR_ERGO_ADDRESS -w worker1
```

### lolMiner
```bash
lolMiner -a AUTOLYKOS2 -p stratum+tcp://localhost:4074 -u YOUR_ERGO_ADDRESS.worker1
```

## Management Commands

### View Logs
```bash
docker-compose -f docker-compose.solo.yml logs -f miningcore-solo
```

### Stop Solo Mining
```bash
docker-compose -f docker-compose.solo.yml down
```

### Restart Services
```bash
docker-compose -f docker-compose.solo.yml restart miningcore-solo
```

### Update Configuration
```bash
# Stop services
docker-compose -f docker-compose.solo.yml down

# Edit config files
nano config/ergo-solo-simple.json

# Restart services
docker-compose -f docker-compose.solo.yml up -d
```

## Configuration Details

### Ports Used
- **4001**: API endpoint
- **4074**: Low difficulty stratum
- **4075**: Medium difficulty stratum
- **5432**: PostgreSQL database

### Volumes
- `postgres_data_solo`: Database persistence
- `miningcore_data_solo`: Miningcore data persistence
- `./logs`: Log files

### Network
- `miningcore-solo-network`: Isolated network for solo mining

## Troubleshooting

### Check Service Status
```bash
docker-compose -f docker-compose.solo.yml ps
```

### View All Logs
```bash
docker-compose -f docker-compose.solo.yml logs
```

### Check Database Connection
```bash
docker-compose -f docker-compose.solo.yml exec postgres psql -U miningcore -d miningcore
```

### Test Ergo Node Connection
```bash
curl http://YOUR_ERGO_NODE_HOST:YOUR_ERGO_NODE_PORT/info
```

## Differences from Full Setup

The simplified setup removes:
- ❌ Nginx web server
- ❌ SSL certificate management
- ❌ Web interface
- ❌ Load balancing
- ❌ Multiple miningcore instances
- ❌ SSL stratum ports

This results in:
- ✅ Faster startup
- ✅ Lower resource usage
- ✅ Simpler configuration
- ✅ Easier troubleshooting
- ✅ Focused on solo mining only

## Security Notes

1. **Change default passwords** in the `.env` file
2. **Use a dedicated wallet** for solo mining
3. **Keep your Ergo node secure** and up to date
4. **Monitor logs** for any suspicious activity

## Performance Tips

1. **Use appropriate difficulty** for your hashrate
2. **Monitor system resources** during mining
3. **Keep logs directory** on fast storage
4. **Regular database backups** for important data

## Support

For issues with the simplified solo mining setup:
1. Check the logs first
2. Verify Ergo node connectivity
3. Ensure wallet address is correct
4. Review configuration files

Happy solo mining! 🚀 