# How to View Your Pool Data - Simple Guide

## 🎯 TL;DR (Too Long, Didn't Read)

Your pool has a **REST API** running on **port 4000**. 

**Quickest way to see your pool data:**
```bash
./scripts/check-pool-stats.sh
```

**Or in your web browser, visit:**
```
http://localhost:4000/api/pools/ergo-solo
```

---

## 📊 Three Main Ways to View Pool Data

### 1. **Quick Script** (Recommended for Quick Checks)
```bash
./scripts/check-pool-stats.sh
```
Shows: Connected miners, hashrates, recent blocks, top miners

### 2. **API Endpoints** (For Real-time Data)
```bash
# Pool overview
curl http://localhost:4000/api/pools/ergo-solo | jq '.'

# Recent blocks
curl http://localhost:4000/api/pools/ergo-solo/blocks | jq '.'

# Top miners
curl http://localhost:4000/api/pools/ergo-solo/miners | jq '.'
```

### 3. **Log Files** (For Detailed Events)
```bash
# Main pool log
tail -f logs/miningcore-solo.log

# API access log
tail -f logs/api-solo.log
```

---

## 📱 View in Web Browser

Simply open these URLs in your browser (replace `localhost` with your server IP if accessing remotely):

| What You Want to See | URL |
|---------------------|-----|
| Pool overview & stats | http://localhost:4000/api/pools/ergo-solo |
| All available endpoints | http://localhost:4000/api/help |
| Health check | http://localhost:4000/api/health-check |
| Recent blocks | http://localhost:4000/api/pools/ergo-solo/blocks |
| Current miners | http://localhost:4000/api/pools/ergo-solo/miners |
| Pool performance graph data | http://localhost:4000/api/pools/ergo-solo/performance |

---

## 🔍 Most Common Queries

### "How many miners are connected?"
```bash
curl -s http://localhost:4000/api/pools/ergo-solo | jq '.pool.poolStats.connectedMiners'
```

### "What's my current pool hashrate?"
```bash
curl -s http://localhost:4000/api/pools/ergo-solo | jq '.pool.poolStats.poolHashrate'
```

### "Have I found any blocks?"
```bash
curl -s http://localhost:4000/api/pools/ergo-solo/blocks | jq 'length'
```

### "What's the total amount paid out?"
```bash
curl -s http://localhost:4000/api/pools/ergo-solo | jq '.pool.totalPaid'
```

### "Show me my miner's stats"
```bash
# Replace with your wallet address
WALLET="9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY"
curl -s "http://localhost:4000/api/pools/ergo-solo/miners/${WALLET}" | jq '.'
```

### "What's my pending balance?"
```bash
WALLET="9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY"
curl -s "http://localhost:4000/api/admin/pools/ergo-solo/miners/${WALLET}/getbalance"
```

---

## 🎬 Real-time Monitoring

### Watch miners count update every 5 seconds
```bash
watch -n 5 "curl -s http://localhost:4000/api/pools/ergo-solo | \
jq -r '.pool.poolStats | \"Miners: \(.connectedMiners) | Hashrate: \(.poolHashrate) H/s\"'"
```

### Watch for new blocks
```bash
watch -n 30 "curl -s http://localhost:4000/api/pools/ergo-solo/blocks?page=0&pageSize=5 | \
jq -r '.[] | \"Block \(.blockHeight): \(.status)\"'"
```

### Live log following
```bash
tail -f logs/miningcore-solo.log | grep -E 'share|block|payment'
```

---

## 📊 Your Current Pool Status

Let me show you what your pool looks like right now:

**Pool Configuration:**
- Pool ID: `ergo-solo`
- Mining Ports: `4074` (0.01 difficulty), `4075` (0.1 difficulty)
- API Port: `4000`
- Payment Scheme: `SOLO` (winner takes all)
- Minimum Payment: `0.1 ERG`
- Pool Address: `9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY`

**Current Status (as of last check):**
- Connected Miners: 0 (pool is running, waiting for connections)
- Pool Hashrate: 0 H/s
- Network Hashrate: ~4.65 TH/s
- Total Blocks Found: 0
- Total Paid: 0 ERG

**Top Miners (last 24 hours):**
1. `9fAxNSFbekcUxiSW7mtbjM39KHg3F5mcjePnu7658D8EXnS88UY` - 409 MH/s
2. `9ehJZvPDgvCNNd2zTQHxnSpcCAtb1kHbEN1VAgeoRD5DPVApYkk` - 346 MH/s

---

## 🔧 Troubleshooting

### "The API isn't responding"
```bash
# Check if pool is running
docker-compose -f docker-compose.solo.yml ps

# If not running, start it
docker-compose -f docker-compose.solo.yml up -d

# Check health
curl http://localhost:4000/api/health-check
```

### "I can't access from another computer"
```bash
# Check if firewall allows port 4000
sudo ufw status

# If blocked, allow it
sudo ufw allow 4000/tcp
```

Then use your server's IP instead of localhost:
```bash
curl http://YOUR_SERVER_IP:4000/api/pools/ergo-solo
```

### "I want pretty formatted output"
Install `jq` if you don't have it:
```bash
sudo apt-get install jq
```

Then pipe API responses through it:
```bash
curl -s http://localhost:4000/api/pools/ergo-solo | jq '.'
```

---

## 📚 Documentation Files

I've created comprehensive guides for you:

1. **`QUICK-REFERENCE.md`** - Quick command reference card
2. **`POOL-MONITORING-GUIDE.md`** - Complete monitoring guide
3. **`VIEW-POOL-DATA.md`** - This file (simple overview)

---

## 💡 Quick Tips

1. **Bookmark** the API help page: http://localhost:4000/api/help
2. **Run the status script** regularly: `./scripts/check-pool-stats.sh`
3. **Monitor logs** when miners first connect: `tail -f logs/miningcore-solo.log`
4. **Check health endpoint** to verify pool is running: http://localhost:4000/api/health-check
5. **Use `jq`** for readable JSON output: `curl ... | jq '.'`

---

## 🚀 Next Steps

1. **Start mining** - Point your miners to your pool
2. **Monitor connections** - Watch `logs/miningcore-solo.log`
3. **Check API regularly** - Use the quick script or browser
4. **Set up monitoring** - Create automated alerts
5. **Share pool info** - Let miners know your endpoints

---

## ❓ Need Help?

- View all API endpoints: `curl http://localhost:4000/api/help`
- Check logs: `tail -f logs/miningcore-solo.log`
- Read full guide: `POOL-MONITORING-GUIDE.md`
- Quick reference: `QUICK-REFERENCE.md`

---

**Remember**: Your API is on port **4000**, your pool is ID **ergo-solo**, and miners connect on ports **4074/4075**.

Happy mining! ⛏️







