#!/bin/bash

# Multisynq Synchronizer Add-on Test Script
# This script helps verify your add-on configuration and connectivity

set -e

echo "🚀 Multisynq Synchronizer Add-on Test Script"
echo "=============================================="
echo

# Configuration
ADDON_NAME="multisynq_synchronizer"
DEFAULT_DASHBOARD_PORT=3000
DEFAULT_METRICS_PORT=3001

# Get Home Assistant IP
if command -v ha &> /dev/null; then
    HA_IP=$(ha info --raw-json | jq -r '.data.homeassistant')
else
    HA_IP="localhost"
fi

echo "📋 Testing Configuration..."

# Test 1: Check if add-on is installed
echo -n "1. Checking if add-on is installed... "
if ha addons info "$ADDON_NAME" &>/dev/null; then
    echo "✅ Found"
else
    echo "❌ Not found"
    echo "   Please install the add-on first"
    exit 1
fi

# Test 2: Check if add-on is running
echo -n "2. Checking if add-on is running... "
ADDON_STATE=$(ha addons info "$ADDON_NAME" --raw-json | jq -r '.data.state')
if [ "$ADDON_STATE" = "started" ]; then
    echo "✅ Running"
else
    echo "❌ Not running (State: $ADDON_STATE)"
    echo "   Please start the add-on first"
    exit 1
fi

# Test 3: Get add-on configuration
echo -n "3. Reading add-on configuration... "
CONFIG=$(ha addons options "$ADDON_NAME" --raw-json | jq '.data.options')
DASHBOARD_PORT=$(echo "$CONFIG" | jq -r '.dashboard_port // 3000')
METRICS_PORT=$(echo "$CONFIG" | jq -r '.metrics_port // 3001')
SYNQ_KEY=$(echo "$CONFIG" | jq -r '.synq_key // empty')
WALLET_ADDRESS=$(echo "$CONFIG" | jq -r '.wallet_address // empty')
echo "✅ Read"

# Test 4: Validate required configuration
echo "4. Validating configuration:"
echo -n "   - Synq key configured... "
if [ -n "$SYNQ_KEY" ] && [ "$SYNQ_KEY" != "null" ]; then
    echo "✅ Yes"
else
    echo "❌ Missing"
    echo "     Please configure your synq_key in the add-on settings"
    exit 1
fi

echo -n "   - Wallet address configured... "
if [ -n "$WALLET_ADDRESS" ] && [ "$WALLET_ADDRESS" != "null" ]; then
    echo "✅ Yes"
else
    echo "❌ Missing"
    echo "     Please configure your wallet_address in the add-on settings"
    exit 1
fi

echo -n "   - Dashboard port: "
echo "$DASHBOARD_PORT ✅"
echo -n "   - Metrics port: "
echo "$METRICS_PORT ✅"

echo
echo "🌐 Testing Network Connectivity..."

# Test 5: Dashboard accessibility
echo -n "5. Testing dashboard accessibility... "
if curl -s -f "http://$HA_IP:$DASHBOARD_PORT" > /dev/null; then
    echo "✅ Accessible"
else
    echo "❌ Not accessible"
    echo "   Dashboard URL: http://$HA_IP:$DASHBOARD_PORT"
    echo "   Check if the add-on started successfully and ports are not blocked"
fi

# Test 6: Metrics API accessibility
echo -n "6. Testing metrics API... "
if curl -s -f "http://$HA_IP:$METRICS_PORT/health" > /dev/null; then
    echo "✅ Accessible"
else
    echo "❌ Not accessible"
    echo "   Metrics URL: http://$HA_IP:$METRICS_PORT"
fi

# Test 7: API endpoints
echo "7. Testing API endpoints:"

echo -n "   - Health check (/health)... "
HEALTH_RESPONSE=$(curl -s "http://$HA_IP:$METRICS_PORT/health" 2>/dev/null || echo "error")
if [ "$HEALTH_RESPONSE" != "error" ]; then
    echo "✅ Working"
else
    echo "❌ Failed"
fi

echo -n "   - Status API (/api/status)... "
STATUS_RESPONSE=$(curl -s "http://$HA_IP:$DASHBOARD_PORT/api/status" 2>/dev/null || echo "error")
if [ "$STATUS_RESPONSE" != "error" ]; then
    echo "✅ Working"
else
    echo "❌ Failed"
fi

echo -n "   - Performance API (/api/performance)... "
PERF_RESPONSE=$(curl -s "http://$HA_IP:$DASHBOARD_PORT/api/performance" 2>/dev/null || echo "error")
if [ "$PERF_RESPONSE" != "error" ]; then
    echo "✅ Working"
else
    echo "❌ Failed"
fi

echo
echo "📊 Current Status Information..."

if [ "$HEALTH_RESPONSE" != "error" ]; then
    echo "Health Status:"
    echo "$HEALTH_RESPONSE" | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE"
    echo
fi

if [ "$STATUS_RESPONSE" != "error" ]; then
    echo "Service Status:"
    echo "$STATUS_RESPONSE" | jq '.' 2>/dev/null || echo "$STATUS_RESPONSE"
    echo
fi

if [ "$PERF_RESPONSE" != "error" ]; then
    echo "Performance Metrics:"
    echo "$PERF_RESPONSE" | jq '.qos // empty' 2>/dev/null || echo "QoS data not available yet"
    echo
fi

echo "📝 Recent Add-on Logs (last 20 lines):"
echo "----------------------------------------"
ha addons logs "$ADDON_NAME" | tail -20

echo
echo "🎯 Quick Access URLs:"
echo "Dashboard: http://$HA_IP:$DASHBOARD_PORT"
echo "Metrics:   http://$HA_IP:$METRICS_PORT/metrics"
echo "Health:    http://$HA_IP:$METRICS_PORT/health"
echo

echo "✨ Test completed!"
echo
echo "💡 Tips:"
echo "- If QoS scores are low, check your internet connection speed and stability"
echo "- Monitor the add-on logs for any error messages"
echo "- Visit the dashboard URL above to see real-time performance metrics"
echo "- Performance metrics may take a few minutes to populate after startup"
