#!/usr/bin/with-contenv bashio

# Multisynq Synchronizer Debug Script
# This script helps debug segfault issues with synchronizer-cli

echo "🔍 Multisynq Synchronizer Debug Mode"
echo "===================================="
echo

# Enable detailed debugging
set -x

# Environment information
echo "🌍 Environment Information:"
echo "Timestamp: $(date)"
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Memory: $(free -h | grep '^Mem:')"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
echo

# Node.js diagnostics
echo "📦 Node.js Diagnostics:"
echo "Node.js version: $(node --version)"
echo "Node.js location: $(which node)"
echo "Node.js binary info: $(file $(which node))"
echo "NPM version: $(npm --version 2>/dev/null || echo 'Not available')"
echo

# Check Node.js libraries
echo "📚 Node.js Dependencies:"
if command -v ldd >/dev/null 2>&1; then
    echo "Libraries linked to Node.js:"
    ldd $(which node) 2>/dev/null | head -10 || echo "Cannot analyze libraries with ldd"
elif command -v readelf >/dev/null 2>&1; then
    echo "Binary dependencies (readelf):"
    readelf -d $(which node) 2>/dev/null | head -10 || echo "Cannot analyze with readelf"
else
    echo "No binary analysis tools available (ldd/readelf missing)"
    echo "Node.js binary type: $(file $(which node))"
fi
echo

# Synchronizer-cli diagnostics
echo "🔧 Synchronizer-CLI Diagnostics:"

# Check binary
if command -v synchronize >/dev/null 2>&1; then
    echo "✓ synchronize command found: $(which synchronize)"
    echo "Binary info: $(file $(which synchronize))"
    echo "Permissions: $(ls -la $(which synchronize))"
else
    echo "✗ synchronize command not found in PATH"
fi

# Check Node.js module
if [[ -f /usr/lib/node_modules/synchronizer-cli/index.js ]]; then
    echo "✓ Node.js module found: /usr/lib/node_modules/synchronizer-cli/index.js"
    echo "Module permissions: $(ls -la /usr/lib/node_modules/synchronizer-cli/index.js)"
    echo "Module info: $(file /usr/lib/node_modules/synchronizer-cli/index.js)"
    
    # Check package.json
    if [[ -f /usr/lib/node_modules/synchronizer-cli/package.json ]]; then
        echo "Package info:"
        jq -r '.name, .version, .description' /usr/lib/node_modules/synchronizer-cli/package.json 2>/dev/null || cat /usr/lib/node_modules/synchronizer-cli/package.json | head -10
    fi
else
    echo "✗ Node.js module not found"
fi
echo

# Test execution methods
echo "⚡ Testing Execution Methods:"

# Test 1: Direct synchronize command
echo "Test 1: Direct synchronize command"
if command -v synchronize >/dev/null 2>&1; then
    echo "Running: timeout 5 synchronize --version"
    timeout 5 synchronize --version 2>&1 || {
        local exit_code=$?
        echo "Exit code: $exit_code"
        if [[ $exit_code -eq 139 ]]; then
            echo "❌ SEGMENTATION FAULT DETECTED!"
        elif [[ $exit_code -eq 124 ]]; then
            echo "⏰ TIMEOUT"
        fi
    }
else
    echo "Skipping (command not available)"
fi
echo

# Test 2: Direct Node.js execution
echo "Test 2: Direct Node.js execution"
if [[ -f /usr/lib/node_modules/synchronizer-cli/index.js ]]; then
    echo "Running: timeout 5 node /usr/lib/node_modules/synchronizer-cli/index.js --version"
    timeout 5 node /usr/lib/node_modules/synchronizer-cli/index.js --version 2>&1 || {
        local exit_code=$?
        echo "Exit code: $exit_code"
        if [[ $exit_code -eq 139 ]]; then
            echo "❌ SEGMENTATION FAULT IN NODE.JS!"
        elif [[ $exit_code -eq 124 ]]; then
            echo "⏰ TIMEOUT"
        fi
    }
else
    echo "Skipping (module not available)"
fi
echo

# Test 3: Help command
echo "Test 3: Help command test"
if command -v synchronize >/dev/null 2>&1; then
    echo "Running: timeout 3 synchronize --help"
    timeout 3 synchronize --help 2>&1 | head -5 || {
        local exit_code=$?
        echo "Exit code: $exit_code"
        if [[ $exit_code -eq 139 ]]; then
            echo "❌ SEGMENTATION FAULT IN HELP!"
        fi
    }
else
    echo "Skipping (command not available)"
fi
echo

# Advanced debugging
echo "🔬 Advanced Debugging:"

# Test with strace if available
if command -v strace >/dev/null 2>&1 && command -v synchronize >/dev/null 2>&1; then
    echo "Running strace analysis..."
    echo "Command: timeout 10 strace -f -e trace=execve,mmap,munmap,segv synchronize --version"
    timeout 10 strace -f -e trace=execve,mmap,munmap,segv synchronize --version 2>/tmp/debug_strace.log || true
    echo "Last 20 lines of strace:"
    tail -20 /tmp/debug_strace.log | sed 's/^/  /'
else
    echo "Strace analysis not available"
fi
echo

# Test with gdb if available
if command -v gdb >/dev/null 2>&1 && command -v synchronize >/dev/null 2>&1; then
    echo "Running GDB analysis..."
    cat > /tmp/debug_gdb_commands << 'EOF'
set confirm off
set pagination off
run --version
bt
info registers
quit
EOF
    
    echo "Command: timeout 15 gdb -batch -x /tmp/debug_gdb_commands synchronize"
    timeout 15 gdb -batch -x /tmp/debug_gdb_commands synchronize >/tmp/debug_gdb.log 2>&1 || true
    
    if grep -q "SIGSEGV" /tmp/debug_gdb.log; then
        echo "❌ GDB confirms segmentation fault:"
        grep -A 10 "SIGSEGV" /tmp/debug_gdb.log | head -10 | sed 's/^/  /'
    else
        echo "✓ No segmentation fault detected by GDB"
    fi
else
    echo "GDB analysis not available"
fi

echo
echo "🎯 Debug Summary:"
echo "=================="
echo "1. If segmentation faults are detected, set auto_start=false"
echo "2. If Node.js direct execution works, the addon will use that method"
echo "3. If both methods fail, only web dashboard mode may work"
echo "4. Check Home Assistant logs for more details"
echo
echo "Debug completed at: $(date)"
