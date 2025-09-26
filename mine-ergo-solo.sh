#!/bin/bash

# DEPRECATED: Use the new separated scripts instead
# This is a legacy wrapper for backward compatibility

echo "⚠️  This script is deprecated. Please use the new separated scripts:"
echo ""
echo "To start the mining pool:"
echo "  ./scripts/start-pool.sh"
echo ""
echo "To start mining:"
echo "  ./scripts/start-mining.sh"
echo ""
echo "To check status:"
echo "  ./scripts/pool-status.sh"
echo ""
echo "To stop mining:"
echo "  ./scripts/stop-mining.sh"
echo ""
echo "To stop the pool:"
echo "  ./scripts/stop-pool.sh"
echo ""

read -p "Continue with old script anyway? (y/N): " continue_old
if [[ ! $continue_old =~ ^[Yy]$ ]]; then
    exit 0
fi

# Legacy functionality (preserved for compatibility)
POOL=localhost:4074
WALLET=9ehJZvPDgvCNNd2zTQHxnSpcCAtb1kHbEN1VAgeoRD5DPVApYkk.Capitol_Peak
POWER_LIMIT=275

cd "$(dirname "$0")"

./lolMiner --algo AUTOLYKOS2 --pool $POOL --user $WALLET $@ --pl $POWER_LIMIT
while [ $? -eq 42 ]; do
    sleep 10s
    ./lolMiner --algo AUTOLYKOS2 --pool $POOL --user $WALLET $@ --pl $POWER_LIMIT
done 