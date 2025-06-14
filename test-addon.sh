#!/bin/bash

# Local test script for the Home Assistant add-on
set -e

echo "🧪 Testing Multisynq Synchronizer Home Assistant Add-on"
echo "=================================================="

# Check if required parameters are provided
if [ $# -lt 2 ]; then
    echo "❌ Usage: $0 <SYNQ_KEY> <WALLET_ADDRESS> [SYNC_NAME]"
    echo "   Example: $0 'your-synq-key' 'your-wallet-address' 'Test Sync'"
    exit 1
fi

SYNQ_KEY="$1"
WALLET_ADDRESS="$2"
SYNC_NAME="${3:-Home Assistant Test Sync}"

echo "📝 Test Configuration:"
echo "   Synq Key: ${SYNQ_KEY:0:10}..."
echo "   Wallet: ${WALLET_ADDRESS:0:10}..."
echo "   Sync Name: $SYNC_NAME"
echo ""

# Build the add-on image
echo "🔨 Building add-on Docker image..."
# Use Home Assistant base image for testing
docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest -t ha-multisynq-test .

echo ""
echo "🚀 Running add-on test container..."
echo "   This will test the actual add-on behavior"
echo ""

# Create a mock bashio environment
docker run --rm \
    -e SYNQ_KEY="$SYNQ_KEY" \
    -e WALLET_ADDRESS="$WALLET_ADDRESS" \
    -e SYNC_NAME="$SYNC_NAME" \
    -p 3000:3000 \
    -p 3001:3001 \
    ha-multisynq-test /bin/bash -c "
        echo '🔍 Testing add-on environment...'
        
        # Mock bashio functions for testing
        bashio::log.info() { echo \"[INFO] \$*\"; }
        bashio::log.fatal() { echo \"[FATAL] \$*\"; }
        bashio::config() { 
            case \$1 in
                'synq_key') echo \"\$SYNQ_KEY\";;
                'wallet_address') echo \"\$WALLET_ADDRESS\";;
                'sync_name') echo \"\$SYNC_NAME\";;
            esac
        }
        
        # Export functions so they're available in the script
        export -f bashio::log.info
        export -f bashio::log.fatal
        export -f bashio::config
        
        echo '🧪 Running the add-on script...'
        echo ''
        
        # Run the actual run.sh script
        /run.sh
    "

echo ""
echo "✅ Add-on test completed!"
echo ""
echo "💡 If the test succeeded:"
echo "   1. Copy the simplified config: cp config-simple.yaml config.yaml"
echo "   2. Deploy to your Home Assistant add-on repository"
echo "   3. The web dashboard should be available at http://homeassistant.local:3000"
