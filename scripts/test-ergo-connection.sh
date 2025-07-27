#!/bin/bash

# Ergo Node Connection Test Script
# Verifies external Ergo node is accessible before starting mining pool

set -e

# Configuration
ERGO_HOST=${ERGO_NODE_HOST:-"localhost"}
ERGO_PORT=${ERGO_NODE_PORT:-"9053"}
ERGO_URL="http://$ERGO_HOST:$ERGO_PORT"

echo "=================================================="
echo "🔍 Testing Ergo Node Connection"
echo "=================================================="
echo "Host: $ERGO_HOST"
echo "Port: $ERGO_PORT"
echo "URL: $ERGO_URL"
echo "=================================================="

# Test basic connectivity
echo "1️⃣ Testing basic connectivity..."
if curl -s --connect-timeout 5 "$ERGO_URL/info" > /dev/null; then
    echo "✅ Connection successful"
else
    echo "❌ Cannot connect to Ergo node at $ERGO_URL"
    echo "💡 Troubleshooting:"
    echo "   - Ensure Ergo node is running: systemctl status ergo"
    echo "   - Check if API is enabled in ergo.conf"
    echo "   - Verify port $ERGO_PORT is not blocked by firewall"
    echo "   - Check if node is synced: curl $ERGO_URL/info | jq .fullHeight"
    exit 1
fi

# Test API endpoints
echo "2️⃣ Testing API endpoints..."

# Test /info endpoint
INFO_RESPONSE=$(curl -s "$ERGO_URL/info" || echo "ERROR")
if [ "$INFO_RESPONSE" = "ERROR" ]; then
    echo "❌ /info endpoint failed"
    exit 1
else
    echo "✅ /info endpoint working"
    
    # Extract key information
    HEIGHT=$(echo "$INFO_RESPONSE" | jq -r '.fullHeight // "unknown"')
    SYNCED=$(echo "$INFO_RESPONSE" | jq -r '.isMining // false')
    PEERS=$(echo "$INFO_RESPONSE" | jq -r '.peersCount // 0')
    
    echo "   📊 Block Height: $HEIGHT"
    echo "   🔄 Peers: $PEERS"
    echo "   ⛏️ Mining: $SYNCED"
fi

# Test /wallet/addresses endpoint
WALLET_RESPONSE=$(curl -s "$ERGO_URL/wallet/addresses" 2>/dev/null || echo "ERROR")
if [ "$WALLET_RESPONSE" = "ERROR" ]; then
    echo "⚠️ /wallet/addresses endpoint failed (wallet may not be initialized)"
else
    echo "✅ /wallet/addresses endpoint working"
fi

# Test /peers/all endpoint
PEERS_RESPONSE=$(curl -s "$ERGO_URL/peers/all" 2>/dev/null || echo "ERROR")
if [ "$PEERS_RESPONSE" = "ERROR" ]; then
    echo "⚠️ /peers/all endpoint failed"
else
    echo "✅ /peers/all endpoint working"
fi

# Check if node is fully synced
echo "3️⃣ Checking sync status..."
if [ "$HEIGHT" != "unknown" ] && [ "$HEIGHT" -gt 0 ]; then
    # Get network height from explorer (fallback check)
    NETWORK_HEIGHT=$(curl -s "https://api.ergoplatform.com/api/v1/networkState" | jq -r '.height // 0' 2>/dev/null || echo "0")
    
    if [ "$NETWORK_HEIGHT" -gt 0 ]; then
        HEIGHT_DIFF=$((NETWORK_HEIGHT - HEIGHT))
        if [ "$HEIGHT_DIFF" -lt 10 ]; then
            echo "✅ Node appears to be synced (within 10 blocks)"
            echo "   📊 Local: $HEIGHT, Network: $NETWORK_HEIGHT"
        else
            echo "⚠️ Node may not be fully synced"
            echo "   📊 Local: $HEIGHT, Network: $NETWORK_HEIGHT, Diff: $HEIGHT_DIFF blocks"
        fi
    else
        echo "⚠️ Cannot verify sync status (explorer unavailable)"
    fi
else
    echo "❌ Cannot determine node height"
    exit 1
fi

# Performance test
echo "4️⃣ Testing API performance..."
START_TIME=$(date +%s%N)
curl -s "$ERGO_URL/info" > /dev/null
END_TIME=$(date +%s%N)
RESPONSE_TIME=$(((END_TIME - START_TIME) / 1000000)) # Convert to milliseconds

if [ "$RESPONSE_TIME" -lt 1000 ]; then
    echo "✅ API response time: ${RESPONSE_TIME}ms (excellent)"
elif [ "$RESPONSE_TIME" -lt 5000 ]; then
    echo "✅ API response time: ${RESPONSE_TIME}ms (good)"
else
    echo "⚠️ API response time: ${RESPONSE_TIME}ms (slow - may affect mining performance)"
fi

echo "=================================================="
echo "✅ Ergo node connection test completed successfully!"
echo "🚀 Ready to start mining pool"
echo "=================================================="

# Optional: Test from within Docker network
echo "5️⃣ Testing Docker connectivity..."
if command -v docker >/dev/null 2>&1; then
    # Test connectivity from a temporary container
    if docker run --rm --add-host=host.docker.internal:host-gateway curlimages/curl:latest \
       curl -s --connect-timeout 5 "http://host.docker.internal:$ERGO_PORT/info" > /dev/null; then
        echo "✅ Docker container can reach Ergo node"
    else
        echo "❌ Docker container cannot reach Ergo node"
        echo "💡 This may be a Docker networking issue"
        echo "   Try adding '--network host' to docker run command"
        exit 1
    fi
else
    echo "⚠️ Docker not available for connectivity test"
fi

echo "=================================================="
echo "🎉 All tests passed! Mining pool is ready to start."
echo "==================================================" 