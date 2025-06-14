#!/bin/bash

# Test script to run the synchronizer locally using Home Assistant base image
set -e

echo "Building test Docker image using Home Assistant Raspberry Pi base..."
echo "This simulates the exact environment your add-on will run in on a Raspberry Pi"

# Use the same base image as Home Assistant on Raspberry Pi (ARM64)
docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/aarch64-base:latest -t multisynq-test .

echo "Testing synchronizer-cli installation on Home Assistant base..."
docker run --rm multisynq-test /bin/bash -c "
    echo '=== Home Assistant Environment Test ==='
    echo 'Architecture:' \$(uname -m)
    echo 'OS Info:' \$(cat /etc/os-release | head -3)
    echo 'Node.js version:' \$(node --version)
    echo 'NPM version:' \$(npm --version)
    echo ''
    echo '=== Testing synchronizer-cli ==='
    which synchronize || echo 'synchronize command not found'
    synchronize --version || echo 'Failed to get version'
    echo ''
    echo '=== Testing bashio availability (Home Assistant specific) ==='
    if command -v bashio &> /dev/null; then
        echo '✅ bashio found - Home Assistant environment confirmed'
    else
        echo '⚠️  bashio not found - this is expected in base image without add-on runtime'
    fi
    echo ''
    echo '=== Testing deploy command with dummy credentials ==='
    timeout 10s synchronize deploy --key 'test-key' --wallet 'test-wallet' --name 'test' || echo 'Expected timeout/failure with dummy credentials'
"

echo "Test completed!"
echo ""
echo "🏠 This test uses the exact same base image as Home Assistant on Raspberry Pi"
echo "🔧 If this works, your add-on should work identically on your Raspberry Pi"
echo "📦 Base image: ghcr.io/home-assistant/aarch64-base:latest"
