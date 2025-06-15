#!/bin/bash

# Test script to verify lite mode configuration parsing
echo "=== Testing Lite Mode Configuration ==="

# Create test configuration files
mkdir -p /tmp/test-data

# Test 1: Lite mode enabled
echo '{"synq_key": "test_key_123", "wallet_address": "0x123456789", "lite_mode": true}' > /tmp/test-data/options-lite.json

# Test 2: Lite mode disabled (default)
echo '{"synq_key": "test_key_456", "wallet_address": "0x987654321", "lite_mode": false}' > /tmp/test-data/options-full.json

# Test 3: Lite mode not specified (should default to false)
echo '{"synq_key": "test_key_789", "wallet_address": "0x111222333"}' > /tmp/test-data/options-default.json

# Function to test config parsing
test_config() {
  local config_file="$1"
  local expected_lite_mode="$2"
  local test_name="$3"
  
  echo "--- Testing: $test_name ---"
  echo "Config file: $config_file"
  
  if command -v jq >/dev/null 2>&1; then
    SYNQ_KEY=$(jq -r '.synq_key // ""' "$config_file")
    WALLET_ADDRESS=$(jq -r '.wallet_address // ""' "$config_file")
    LITE_MODE=$(jq -r '.lite_mode // false' "$config_file")
    
    # Handle null values
    if [ "$LITE_MODE" = "null" ]; then
      LITE_MODE="false"
    fi
    
    echo "  SYNQ_KEY: $SYNQ_KEY"
    echo "  WALLET_ADDRESS: $WALLET_ADDRESS"
    echo "  LITE_MODE: $LITE_MODE"
    
    if [ "$LITE_MODE" = "$expected_lite_mode" ]; then
      echo "  ✅ PASS: Lite mode correctly parsed as $LITE_MODE"
    else
      echo "  ❌ FAIL: Expected $expected_lite_mode, got $LITE_MODE"
    fi
  else
    echo "  ⚠️  jq not available for testing"
  fi
  
  echo ""
}

# Run tests
test_config "/tmp/test-data/options-lite.json" "true" "Lite mode enabled"
test_config "/tmp/test-data/options-full.json" "false" "Lite mode disabled"
test_config "/tmp/test-data/options-default.json" "false" "Lite mode not specified (default)"

# Cleanup
rm -rf /tmp/test-data

echo "=== Testing Complete ==="
