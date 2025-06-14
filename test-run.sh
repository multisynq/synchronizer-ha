#!/bin/bash

set -e

echo "=== Testing synchronizer-cli installation ==="
echo "Node.js version: $(node --version)"
echo "NPM version: $(npm --version)"

echo ""
echo "=== Checking synchronizer-cli ==="
if command -v synchronize &> /dev/null; then
    echo "✅ synchronize command found at: $(which synchronize)"
    
    echo ""
    echo "=== Testing synchronize --version ==="
    synchronize --version || echo "❌ Failed to get version"
    
    echo ""
    echo "=== Testing synchronize --help ==="
    synchronize --help || echo "❌ Failed to get help"
    
    echo ""
    echo "=== Testing synchronize deploy with dummy values ==="
    # This should fail but not crash
    synchronize deploy --key "test-key" --wallet "test-wallet" --name "test" || echo "Expected to fail with invalid credentials"
    
else
    echo "❌ synchronize command not found"
    exit 1
fi

echo ""
echo "=== Test completed successfully! ==="
