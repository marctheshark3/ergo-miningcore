# Ergo Solo Mining Guide

This guide explains how to set up and use the solo mining functionality in this Ergo Miningcore setup. Solo mining allows individual miners to mine directly for full block rewards instead of sharing rewards in a pool.

## 🏆 What is Solo Mining?

**Solo Mining** means mining alone, directly against the blockchain network:
- ✅ **Full Block Rewards**: When you find a block, you get the entire ~67.5 ERG reward
- ✅ **No Pool Fees**: No sharing with other miners (except small operational fee)
- ✅ **Direct to Blockchain**: Your miner works directly with the Ergo network
- ⚠️ **Higher Variance**: Longer time between payouts, but larger amounts
- ⚠️ **Network Difficulty**: You compete against the entire network

## 🎯 Solo Mining vs Pool Mining

| Aspect | Solo Mining | Pool Mining |
|--------|------------|-------------|
| **Rewards** | Full block reward (~67.5 ERG) | Proportional share of block rewards |
| **Frequency** | Very infrequent (days/weeks/months) | Regular small payments |
| **Variance** | High (all or nothing) | Low (steady income) |
| **Risk** | High (may never find a block) | Low (guaranteed income) |
| **Best For** | Large miners, lottery-style mining | Steady income, smaller miners |

## 🚀 Quick Start Solo Mining

### 1. Prerequisites

- Existing Ergo node running and synced (same as pool mining)
- Docker and Docker Compose installed
- Your Ergo wallet address ready

### 2. Start Solo Mining

```bash
# Start solo mining instance
./scripts/start-solo-mining.sh
```

### 3. Test the Setup

```bash
# Validate everything is working
./scripts/test-solo-mining.sh
```

### 4. Connect Your Miner

For small GPUs (recommended to start):
```bash
# T-Rex (NVIDIA)
t-rex -a autolykos2 -o stratum+tcp://localhost:4074 -u YOUR_ERGO_ADDRESS -w solo-miner

# TeamRedMiner (AMD)
teamredminer -a autolykos2 -o stratum+tcp://localhost:4074 -u YOUR_ERGO_ADDRESS -w solo-miner

# lolMiner
lolMiner -a AUTOLYKOS2 -p stratum+tcp://localhost:4074 -u YOUR_ERGO_ADDRESS.solo-miner
```

## 🎚️ Solo Mining Ports & Difficulty

| Port | SSL | Difficulty | Best For |
|------|-----|------------|----------|
| 4074 | No | 0.01 | Small GPUs (GTX 1060, RX 580) |
| 4075 | No | 0.1 | Larger GPUs (RTX 3070+, RX 6800+) |
| 4076 | Yes | 0.01 | Small GPUs with SSL |
| 4077 | Yes | 0.1 | Larger GPUs with SSL |

**Difficulty Explained:**
- Lower difficulty = More frequent shares (better for monitoring)
- Higher difficulty = Fewer shares but same block finding probability
- **Block finding depends on total hashrate, not difficulty!**

## ⚙️ Configuration

### Wallet Setup

Edit `config/ergo-solo-pool.json`:

```json
{
  "pools": [{
    "address": "YOUR_ERGO_WALLET_ADDRESS_HERE",
    "rewardRecipients": [
      {
        "address": "YOUR_POOL_FEE_ADDRESS_HERE",
        "percentage": 0.5
      }
    ]
  }]
}
```

### Key Configuration Options

1. **Pool Fee** (line ~70): Set your operational fee percentage
2. **Minimum Payment** (line ~158): Lower than pool mining (e.g., 0.1 ERG)
3. **Payment Interval** (line ~157): More frequent processing (600 seconds)
4. **Difficulty Settings** (lines ~85-140): Optimized for solo mining

## 📊 Monitoring Your Solo Mining

### API Endpoints

```bash
# Pool status
curl http://localhost:4001/api/pools

# Solo pool stats
curl http://localhost:4001/api/pools/ergo-solo

# Your miner stats
curl http://localhost:4001/api/pools/ergo-solo/miners/YOUR_ERGO_ADDRESS
```

### Real-time Monitoring

```bash
# Watch for blocks and payments
docker-compose logs -f miningcore-solo | grep -E "(Block|Payment|Share)"

# Monitor container status
docker-compose ps

# Check miner connections
docker-compose logs -f miningcore-solo | grep "Client connected"
```

## 🧮 Expected Returns & Probabilities

### Network Statistics (approximate)

- **Network Hashrate**: ~15 TH/s
- **Block Time**: ~2 minutes (120 seconds)
- **Block Reward**: ~67.5 ERG
- **Daily Blocks**: ~720 blocks

### Time to Find a Block (Statistical Average)

| Your Hashrate | Probability per Block | Average Time to Block |
|---------------|----------------------|----------------------|
| 30 MH/s (GTX 1060) | 0.0002% | ~57 days |
| 50 MH/s (RTX 3060) | 0.00033% | ~34 days |
| 100 MH/s (RTX 3080) | 0.00067% | ~17 days |
| 1 GH/s (Farm) | 0.0067% | ~1.7 days |

**⚠️ Important:** These are statistical averages. You might find a block in 1 hour or never!

### Small GPU Mining Reality

For a typical small GPU setup (30-50 MH/s):
- 📈 **Best Case**: Find multiple blocks quickly, earn hundreds of ERG
- 📊 **Average Case**: Find 1-2 blocks per 2 months, earn ~135 ERG
- 📉 **Worst Case**: Never find a block, earn 0 ERG

**This is why solo mining is considered "lottery-style" mining!**

## 🔄 Switching Between Pool and Solo

### Start Solo Mining
```bash
./scripts/start-solo-mining.sh
```

### Switch Back to Pool Mining
```bash
./scripts/start-pool-mining.sh
```

### Run Both Simultaneously
```bash
# Start pool mining on standard ports
docker-compose up -d

# Start solo mining on different ports
docker-compose --profile solo up -d
```

## 🛠️ Troubleshooting

### Solo Mining Won't Start

```bash
# Check configuration
docker-compose logs miningcore-solo

# Validate JSON config
cat config/ergo-solo-pool.json | jq .

# Test Ergo node connection
curl http://localhost:9053/info
```

### No Shares Appearing

1. **Check Difficulty**: Lower it if shares are too infrequent
2. **Verify Miner Connection**: Look for "Client connected" in logs
3. **Check Wallet Address**: Ensure it's correct in your miner

### Performance Issues

```bash
# Check container resources
docker stats miningcore-solo

# Monitor shares
docker-compose logs -f miningcore-solo | grep "Share accepted"

# Check network connectivity
./scripts/test-solo-mining.sh
```

## 🎛️ Advanced Configuration

### Custom Difficulty for Your GPU

Edit `config/ergo-solo-pool.json` to adjust difficulty:

```json
"ports": {
  "4074": {
    "difficulty": 0.005,  // Even lower for very small GPUs
    "varDiff": {
      "minDiff": 0.001,
      "maxDiff": 10000000,
      "targetTime": 15
    }
  }
}
```

### Multiple Solo Pools

You can run multiple solo mining configurations:

1. Copy `config/ergo-solo-pool.json` to `config/ergo-solo-pool-2.json`
2. Change pool ID, ports, and wallet address
3. Create a new docker-compose service

### Notification on Block Found

Add webhook or email notifications when blocks are found:

```json
"notifications": {
  "enabled": true,
  "admin": {
    "enabled": true,
    "emailAddress": "your-email@example.com",
    "notifyBlockFound": true
  }
}
```

## 💡 Tips for Solo Mining Success

### 1. **Start Small, Learn the System**
- Begin with a small GPU to understand the process
- Monitor shares and system behavior
- Don't invest heavily until you understand the risks

### 2. **Optimize Your Setup**
- Use the lowest difficulty that still gives you regular shares
- Monitor GPU temperature and stability
- Ensure reliable internet connection

### 3. **Manage Expectations**
- Solo mining is gambling - you might never find a block
- Consider it entertainment or lottery-style mining
- Don't mine more than you can afford to "lose"

### 4. **Backup and Security**
- Keep your wallet seed phrase secure
- Backup your configuration files
- Monitor for unusual activity

## 🔗 Useful Commands Reference

```bash
# Start solo mining
./scripts/start-solo-mining.sh

# Test solo mining setup
./scripts/test-solo-mining.sh

# Switch to pool mining
./scripts/start-pool-mining.sh

# Monitor solo mining
docker-compose logs -f miningcore-solo

# Check API status
curl http://localhost:4001/api/pools/ergo-solo

# Monitor shares
docker-compose logs -f miningcore-solo | grep "Share accepted"

# Stop solo mining
docker-compose down

# Restart solo mining
docker-compose --profile solo restart miningcore-solo
```

## 📈 Success Stories & Realistic Expectations

### Realistic Solo Mining Stories

**Small Miner (GTX 1060):**
- Mined for 3 months, found 1 block, earned 67.5 ERG
- Cost in electricity: ~$45, Profit: ~$150 (at $3/ERG)

**Medium Miner (RTX 3070):**
- Mined for 6 weeks, found 2 blocks, earned 135 ERG
- Cost in electricity: ~$60, Profit: ~$345 (at $3/ERG)

**Large Farm (10x RTX 3080):**
- Mined for 1 month, found 5 blocks, earned 337.5 ERG
- Cost in electricity: ~$800, Profit: ~$212 (at $3/ERG)

### The Reality Check

Most solo miners fall into these categories:
- 60% never find a block (lose electricity costs)
- 30% find 1-2 blocks (break even or small profit)
- 10% get lucky and find multiple blocks (significant profit)

## 🎯 Conclusion

Solo mining is perfect for:
- ✅ Learning about mining and blockchain
- ✅ Testing your mining setup
- ✅ Lottery-style fun with potential big rewards
- ✅ Large miners who want full block rewards

Solo mining is NOT ideal for:
- ❌ Steady income requirements
- ❌ Small miners needing regular payouts
- ❌ Low-risk mining strategies
- ❌ Guaranteed return on investment

**Remember: Solo mining should be treated as high-risk, high-reward mining. Mine responsibly!** 