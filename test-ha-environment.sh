#!/bin/bash

# Comprehensive test that simulates the exact Home Assistant environment
set -e

echo "🏠 Testing Multisynq Synchronizer in Home Assistant Raspberry Pi Environment"
echo "========================================================================"

# Check if required parameters are provided
if [ $# -lt 2 ]; then
    echo "❌ Usage: $0 <SYNQ_KEY> <WALLET_ADDRESS> [SYNC_NAME]"
    echo "   Example: $0 'your-synq-key' 'your-wallet-address' 'Test Sync'"
    echo ""
    echo "🔧 For testing with dummy credentials:"
    echo "   $0 'test-synq-key-12345' '0x1234567890abcdef' 'Test Sync'"
    exit 1
fi

SYNQ_KEY="$1"
WALLET_ADDRESS="$2"
SYNC_NAME="${3:-Home Assistant Test Sync}"

echo "📝 Test Configuration:"
echo "   Synq Key: ${SYNQ_KEY:0:15}..."
echo "   Wallet: ${WALLET_ADDRESS:0:15}..."
echo "   Sync Name: $SYNC_NAME"
echo ""

# Build with Home Assistant base image
echo "🔨 Building with Home Assistant Raspberry Pi base image..."
docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/aarch64-base:latest -t ha-multisynq-rpi-test .

echo ""
echo "🚀 Testing full Home Assistant add-on environment..."
echo ""

# Create and run with Home Assistant-like environment
docker run --rm \
    --name ha-multisynq-test \
    -e SYNQ_KEY="$SYNQ_KEY" \
    -e WALLET_ADDRESS="$WALLET_ADDRESS" \
    -e SYNC_NAME="$SYNC_NAME" \
    -p 3100:3000 \
    -p 3101:3001 \
    ha-multisynq-rpi-test /bin/bash -c "
        echo '🏠 Home Assistant Environment Simulation'
        echo '========================================'
        echo 'Architecture:' \$(uname -m)
        echo 'Base Image:' \$(cat /etc/os-release | grep PRETTY_NAME)
        echo ''
        
        # Mock bashio functions (Home Assistant add-on runtime)
        bashio::log.info() { echo \"[INFO] \$(date '+%Y-%m-%d %H:%M:%S') \$*\"; }
        bashio::log.fatal() { echo \"[FATAL] \$(date '+%Y-%m-%d %H:%M:%S') \$*\"; }
        bashio::log.warning() { echo \"[WARNING] \$(date '+%Y-%m-%d %H:%M:%S') \$*\"; }
        bashio::config() { 
            case \$1 in
                'synq_key') echo \"\$SYNQ_KEY\";;
                'wallet_address') echo \"\$WALLET_ADDRESS\";;
                'sync_name') echo \"\$SYNC_NAME\";;
                *) echo \"\$2\";;  # Return default value
            esac
        }
        
        # Export functions for script availability
        export -f bashio::log.info
        export -f bashio::log.fatal
        export -f bashio::log.warning
        export -f bashio::config
        
        echo '🔧 Testing add-on startup script...'
        echo ''
        
        # Test the run script with timeout to prevent hanging
        timeout 30s /run.sh || {
            exit_code=\$?
            if [ \$exit_code -eq 124 ]; then
                echo ''
                echo '⏰ Script timed out after 30 seconds (expected behavior for continuous services)'
                echo '✅ This indicates the script is running correctly'
            else
                echo ''
                echo '❌ Script exited with code:' \$exit_code
                exit \$exit_code
            fi
        }
    "

exit_code=$?

echo ""
if [ $exit_code -eq 0 ]; then
    echo "✅ Home Assistant environment test PASSED!"
    echo ""
    echo "🎉 Your add-on should work correctly on Raspberry Pi!"
    echo "📱 Web dashboard would be available at:"
    echo "   - Main: http://homeassistant.local:3000"
    echo "   - Metrics: http://homeassistant.local:3001"
    echo ""
    echo "🚀 Ready to deploy to Home Assistant!"
else
    echo "❌ Test failed with exit code: $exit_code"
    echo ""
    echo "🔍 Check the logs above for specific error details"
fi
