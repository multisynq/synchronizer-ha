#!/bin/bash

# Multisynq Synchronizer Add-on Test Script
# This script helps verify your add-on configuration and debug segfault issues

set -e

echo "🚀 Multisynq Synchronizer Add-on Test & Debug Script"
echo "===================================================="
echo

# Configuration
ADDON_NAME="multisynq_synchronizer"
DEFAULT_DASHBOARD_PORT=3000
DEFAULT_METRICS_PORT=3001

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Get Home Assistant IP
if command -v ha &> /dev/null; then
    HA_IP=$(ha info --raw-json | jq -r '.data.homeassistant' 2>/dev/null || echo "localhost")
else
    HA_IP="localhost"
fi

echo "🔍 System Information"
echo "--------------------"
echo "Home Assistant IP: $HA_IP"
echo "Date: $(date)"
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
echo

echo "📋 Testing Add-on Installation & Status..."
echo "----------------------------------------"

# Test 1: Check if add-on is installed
echo -n "1. Checking if add-on is installed... "
if command -v ha &> /dev/null && ha addons info "$ADDON_NAME" &>/dev/null; then
    print_success "Found"
else
    print_error "Not found or ha command not available"
    print_info "This test requires Home Assistant CLI (ha command)"
    echo "   If running outside Home Assistant, this is expected"
fi

# Test 2: Check if add-on is running
echo -n "2. Checking if add-on is running... "
if command -v ha &> /dev/null; then
    ADDON_STATE=$(ha addons info "$ADDON_NAME" --raw-json 2>/dev/null | jq -r '.data.state' 2>/dev/null || echo "unknown")
    if [ "$ADDON_STATE" = "started" ]; then
        print_success "Running"
    else
        print_error "Not running (State: $ADDON_STATE)"
        echo "   Please start the add-on first"
    fi
else
    print_info "Skipping (ha command not available)"
fi

# Test 3: Get add-on configuration
echo -n "3. Reading add-on configuration... "
if command -v ha &> /dev/null; then
    CONFIG=$(ha addons options "$ADDON_NAME" --raw-json 2>/dev/null | jq '.data.options' 2>/dev/null || echo '{}')
    DASHBOARD_PORT=$(echo "$CONFIG" | jq -r '.web_dashboard.port // 3000' 2>/dev/null || echo "3000")
    METRICS_PORT=$(echo "$CONFIG" | jq -r '.web_dashboard.metrics_port // 3001' 2>/dev/null || echo "3001")
    print_success "Configuration read"
else
    DASHBOARD_PORT="3000"
    METRICS_PORT="3001"
    print_info "Using default ports (ha command not available)"
fi

echo

echo "🔧 Testing Synchronizer-CLI Installation..."
echo "-------------------------------------------"

# Test 4: Check Node.js installation
echo -n "4. Checking Node.js installation... "
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Found Node.js $NODE_VERSION"
else
    print_error "Node.js not found"
    exit 1
fi

# Test 5: Check NPM installation
echo -n "5. Checking NPM installation... "
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_success "Found NPM $NPM_VERSION"
else
    print_warning "NPM not found (may not be critical)"
fi

# Test 6: Check synchronizer-cli binary
echo -n "6. Checking synchronizer-cli binary... "
if command -v synchronize &> /dev/null; then
    SYNC_LOCATION=$(which synchronize)
    print_success "Found at $SYNC_LOCATION"
else
    print_error "synchronize command not found"
fi

# Test 7: Check synchronizer-cli Node.js module
echo -n "7. Checking synchronizer-cli Node.js module... "
if [ -f "/usr/lib/node_modules/synchronizer-cli/index.js" ]; then
    print_success "Found Node.js module"
    MODULE_PERMISSIONS=$(ls -la /usr/lib/node_modules/synchronizer-cli/index.js | awk '{print $1}')
    echo "   Permissions: $MODULE_PERMISSIONS"
else
    print_error "Node.js module not found"
fi

echo

echo "⚡ Testing Synchronizer-CLI Functionality (SEGFAULT DEBUGGING)..."
echo "================================================================"

# Test 8: Basic synchronizer-cli execution test
echo "8. Testing basic synchronizer-cli execution..."
print_warning "This test may cause segmentation faults!"

# Test with version command
echo -n "   - Testing 'synchronize --version'... "
if command -v synchronize &> /dev/null; then
    if timeout 10 synchronize --version >/tmp/test_version.log 2>&1; then
        print_success "Success"
        echo "     Output: $(cat /tmp/test_version.log | head -1)"
    else
        EXIT_CODE=$?
        print_error "Failed (exit code: $EXIT_CODE)"
        if [ $EXIT_CODE -eq 139 ]; then
            print_error "SEGMENTATION FAULT DETECTED!"
        elif [ $EXIT_CODE -eq 124 ]; then
            print_warning "Command timed out"
        fi
        echo "     Output:"
        cat /tmp/test_version.log | head -5 | sed 's/^/       /'
    fi
else
    print_error "synchronize command not available"
fi

# Test with help command
echo -n "   - Testing 'synchronize --help'... "
if command -v synchronize &> /dev/null; then
    if timeout 5 synchronize --help >/tmp/test_help.log 2>&1; then
        print_success "Success"
    else
        EXIT_CODE=$?
        print_error "Failed (exit code: $EXIT_CODE)"
        if [ $EXIT_CODE -eq 139 ]; then
            print_error "SEGMENTATION FAULT DETECTED!"
        fi
    fi
else
    print_error "synchronize command not available"
fi

# Test 9: Direct Node.js execution
echo "9. Testing direct Node.js execution..."
if [ -f "/usr/lib/node_modules/synchronizer-cli/index.js" ]; then
    echo -n "   - Testing direct Node.js execution... "
    if timeout 10 node /usr/lib/node_modules/synchronizer-cli/index.js --version >/tmp/test_node.log 2>&1; then
        print_success "Success"
        echo "     Output: $(cat /tmp/test_node.log | head -1)"
    else
        EXIT_CODE=$?
        print_error "Failed (exit code: $EXIT_CODE)"
        if [ $EXIT_CODE -eq 139 ]; then
            print_error "SEGMENTATION FAULT IN NODE.JS EXECUTION!"
        fi
        echo "     Output:"
        cat /tmp/test_node.log | head -5 | sed 's/^/       /'
    fi
else
    print_error "Node.js module not available for testing"
fi

echo

echo "🔍 Advanced Debugging Information..."
echo "-----------------------------------"

# Test 10: System call tracing (if strace is available)
if command -v strace &> /dev/null && command -v synchronize &> /dev/null; then
    echo "10. Running strace analysis..."
    print_info "Tracing system calls for segfault analysis..."
    
    timeout 10 strace -f -e trace=execve,open,openat,mmap,munmap,segv synchronize --version >/tmp/strace_debug.log 2>&1 || true
    
    echo "    Last 10 lines of strace output:"
    tail -10 /tmp/strace_debug.log 2>/dev/null | sed 's/^/      /' || echo "      (No strace output)"
else
    echo "10. Strace not available - skipping system call analysis"
fi

# Test 11: GDB analysis (if gdb is available)
if command -v gdb &> /dev/null && command -v synchronize &> /dev/null; then
    echo "11. Running GDB crash analysis..."
    print_info "Analyzing potential crashes with GDB..."
    
    cat > /tmp/gdb_test_commands << 'EOF'
set confirm off
set pagination off
run --version
bt
info registers
quit
EOF
    
    timeout 15 gdb -batch -x /tmp/gdb_test_commands synchronize >/tmp/gdb_debug.log 2>&1 || true
    
    echo "    GDB analysis summary:"
    if grep -q "SIGSEGV" /tmp/gdb_debug.log; then
        print_error "Segmentation fault confirmed by GDB"
        echo "    Stack trace:"
        grep -A 5 "SIGSEGV\|#0" /tmp/gdb_debug.log | head -5 | sed 's/^/      /'
    else
        print_info "No segmentation fault detected in GDB"
    fi
else
    echo "11. GDB not available - skipping crash analysis"
fi

echo

echo "📊 Test Summary & Recommendations..."
echo "-----------------------------------"

# Provide recommendations based on test results
print_info "Based on the test results:"

if [ -f "/tmp/test_version.log" ] && grep -q "segmentation fault\|Segmentation fault" /tmp/test_version.log; then
    print_error "Segmentation fault confirmed in synchronizer-cli"
    echo "   Recommendations:"
    echo "   1. Set auto_start to false in addon configuration"
    echo "   2. Use web dashboard only mode"
    echo "   3. Try manual start via dashboard after addon is running"
fi

if [ -f "/tmp/test_node.log" ] && ! grep -q "segmentation fault\|Segmentation fault" /tmp/test_node.log; then
    print_success "Direct Node.js execution appears to work"
    echo "   Recommendation: The addon should use Node.js direct execution"
fi

echo
print_info "Test completed. Check the logs above for any segmentation faults."
print_info "If segfaults are detected, consider disabling auto_start in the addon configuration."
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
