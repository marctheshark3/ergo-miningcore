#!/bin/bash

# Test script to verify Ergo node connectivity
# This tests the connection from both host and inside Docker container perspective

echo "=== Testing Ergo Node Connection ==="
echo "Testing from host machine..."

# Test from host machine
echo "1. Testing localhost:9053..."
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "api_key: hello" \
  -d '{"jsonrpc":"2.0","method":"info","params":[],"id":1}' \
  http://localhost:9053 && echo " ✓ Host localhost connection OK" || echo " ✗ Host localhost connection failed"

echo "2. Testing 127.0.0.1:9053..."
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "api_key: hello" \
  -d '{"jsonrpc":"2.0","method":"info","params":[],"id":1}' \
  http://127.0.0.1:9053 && echo " ✓ Host 127.0.0.1 connection OK" || echo " ✗ Host 127.0.0.1 connection failed"

echo ""
echo "Testing from inside Docker container..."

# Test from inside Docker container (simulating miningcore perspective)
echo "3. Testing host.docker.internal:9053 from container..."
docker run --rm --add-host=host.docker.internal:host-gateway curlimages/curl:latest \
  curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "api_key: hello" \
  -d '{"jsonrpc":"2.0","method":"info","params":[],"id":1}' \
  http://host.docker.internal:9053 && echo " ✓ Container connection OK" || echo " ✗ Container connection failed"

echo ""
echo "=== Connection Test Complete ==="
echo "If all tests pass, your miningcore should be able to connect to the Ergo node."
echo "If tests fail, check:"
echo "  - Ergo node is running and listening on 0.0.0.0:9053"
echo "  - Firewall allows connections on port 9053"
echo "  - API key 'hello' is correctly configured in ergo.conf"