#!/usr/bin/with-contenv bashio

# Enable detailed debugging
set -x
set -e

# Enable bashio logging
bashio::log.info "====== MULTISYNQ SYNCHRONIZER ADDON STARTUP DIAGNOSTICS ======"
bashio::log.info "Starting Multisynq Synchronizer Add-on with enhanced debugging..."

# Log timestamp for debugging
bashio::log.info "Startup timestamp: $(date)"
bashio::log.info "Process ID: $$"

# Set environment variables for better Node.js compatibility
export NODE_ENV=production
export NODE_OPTIONS="--max-old-space-size=512"

# Function to handle crashes with detailed information
handle_crash() {
    bashio::log.fatal "====== CRASH DETECTED ======"
    bashio::log.fatal "Signal received: $1"
    bashio::log.fatal "Time: $(date)"
    bashio::log.fatal "PID: $$"
    bashio::log.fatal "Current working directory: $(pwd)"
    bashio::log.fatal "Environment variables:"
    env | grep -E "(NODE|PATH|HOME)" | while read line; do
        bashio::log.fatal "  $line"
    done
    bashio::log.fatal "Running processes:"
    ps aux | head -10 | while read line; do
        bashio::log.fatal "  $line"
    done
    bashio::log.fatal "Memory usage:"
    free -m | while read line; do
        bashio::log.fatal "  $line"
    done
    bashio::log.fatal "====== END CRASH INFO ======"
    exit 1
}

# Enhanced signal trapping
trap 'handle_crash SIGSEGV' SIGSEGV
trap 'handle_crash SIGABRT' SIGABRT  
trap 'handle_crash SIGBUS' SIGBUS
trap 'handle_crash SIGFPE' SIGFPE
trap 'handle_crash SIGILL' SIGILL

bashio::log.info "Signal handlers installed"

# Check system information with detailed diagnostics
bashio::log.info "====== SYSTEM DIAGNOSTICS ======"
bashio::log.info "Architecture: $(uname -m)"
bashio::log.info "Kernel: $(uname -r)"
bashio::log.info "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
bashio::log.info "Uptime: $(uptime)"
bashio::log.info "Available memory: $(free -h | grep '^Mem:')"
bashio::log.info "CPU info: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
bashio::log.info "Container environment variables:"
env | grep -E "(SUPERVISOR|BASHIO|ADDON)" | while read line; do
    bashio::log.info "  $line"
done

# Check filesystem permissions and space
bashio::log.info "====== FILESYSTEM DIAGNOSTICS ======"
bashio::log.info "Current working directory: $(pwd)"
bashio::log.info "Home directory: $HOME"
bashio::log.info "Disk space: $(df -h / | tail -1)"
bashio::log.info "Permissions on key directories:"
bashio::log.info "  /usr/bin: $(ls -ld /usr/bin)"
bashio::log.info "  /usr/lib: $(ls -ld /usr/lib)"
bashio::log.info "  /data: $(ls -ld /data || echo 'Not accessible')"

# Check Node.js installation status
bashio::log.info "====== NODE.JS DIAGNOSTICS ======"
bashio::log.info "Node.js binary location: $(which node || echo 'Not found')"
bashio::log.info "Node.js version: $(node --version 2>&1 || echo 'Not available')"
bashio::log.info "NPM binary location: $(which npm || echo 'Not found')"
bashio::log.info "NPM version: $(npm --version 2>&1 || echo 'Not available')"
bashio::log.info "Node.js binary details:"
if command -v node >/dev/null 2>&1; then
    ls -la $(which node) | while read line; do
        bashio::log.info "  $line"
    done
    bashio::log.info "Node.js binary type: $(file $(which node))"
fi

# Check Node.js modules directory
bashio::log.info "Node.js global modules directory:"
if [[ -d /usr/lib/node_modules ]]; then
    bashio::log.info "  /usr/lib/node_modules exists"
    bashio::log.info "  Contents: $(ls -la /usr/lib/node_modules | head -10 | tail -n +2 | awk '{print $9}' | tr '\n' ' ')"
else
    bashio::log.info "  /usr/lib/node_modules does not exist"
fi

# Check if synchronizer-cli is properly installed with detailed analysis
bashio::log.info "====== SYNCHRONIZER-CLI INSTALLATION DIAGNOSTICS ======"
bashio::log.info "Checking synchronizer-cli installation..."

# Check for binary in PATH
bashio::log.info "Checking for 'synchronize' command in PATH..."
if command -v synchronize >/dev/null 2>&1; then
    bashio::log.info "✓ synchronize command found in PATH"
    bashio::log.info "  Location: $(which synchronize)"
    bashio::log.info "  Permissions: $(ls -la $(which synchronize))"
    bashio::log.info "  File type: $(file $(which synchronize))"
else
    bashio::log.warning "✗ synchronize command not found in PATH"
fi

# Check for Node.js module installation
bashio::log.info "Checking for Node.js module installation..."
if [[ -d /usr/lib/node_modules/synchronizer-cli ]]; then
    bashio::log.info "✓ synchronizer-cli module directory found"
    bashio::log.info "  Location: /usr/lib/node_modules/synchronizer-cli"
    bashio::log.info "  Directory contents:"
    ls -la /usr/lib/node_modules/synchronizer-cli/ | head -10 | while read line; do
        bashio::log.info "    $line"
    done
    
    # Check for main entry point
    if [[ -f /usr/lib/node_modules/synchronizer-cli/index.js ]]; then
        bashio::log.info "✓ Main entry point found: index.js"
        bashio::log.info "  File permissions: $(ls -la /usr/lib/node_modules/synchronizer-cli/index.js)"
        bashio::log.info "  File type: $(file /usr/lib/node_modules/synchronizer-cli/index.js)"
        bashio::log.info "  First few lines of index.js:"
        head -5 /usr/lib/node_modules/synchronizer-cli/index.js | while read line; do
            bashio::log.info "    $line"
        done
    else
        bashio::log.warning "✗ Main entry point (index.js) not found"
    fi
    
    # Check package.json
    if [[ -f /usr/lib/node_modules/synchronizer-cli/package.json ]]; then
        bashio::log.info "✓ package.json found"
        bashio::log.info "  Package info:"
        cat /usr/lib/node_modules/synchronizer-cli/package.json | grep -E "(name|version|bin)" | while read line; do
            bashio::log.info "    $line"
        done
    else
        bashio::log.warning "✗ package.json not found"
    fi
else
    bashio::log.warning "✗ synchronizer-cli module directory not found"
fi

# Check for binary in common locations
bashio::log.info "Checking common binary locations..."
for location in /usr/bin/synchronize /usr/local/bin/synchronize /opt/synchronize; do
    if [[ -f "$location" ]]; then
        bashio::log.info "✓ Found binary at: $location"
        bashio::log.info "  Permissions: $(ls -la $location)"
        bashio::log.info "  File type: $(file $location)"
    else
        bashio::log.debug "✗ No binary at: $location"
    fi
done

# Attempt to create symlink if needed
bashio::log.info "====== ATTEMPTING SYNCHRONIZER-CLI SETUP ======"
if ! command -v synchronize >/dev/null 2>&1; then
    bashio::log.info "synchronizer-cli not found in PATH, attempting setup..."
    
    # Check if it exists in common locations
    if [[ -f /usr/bin/synchronize ]]; then
        bashio::log.info "Found synchronize binary at /usr/bin/synchronize"
        chmod +x /usr/bin/synchronize
        bashio::log.info "Made /usr/bin/synchronize executable"
    elif [[ -f /usr/lib/node_modules/synchronizer-cli/index.js ]]; then
        bashio::log.info "Found synchronizer-cli at /usr/lib/node_modules/synchronizer-cli/index.js"
        bashio::log.info "Creating symlink to make it available as 'synchronize'"
        ln -sf /usr/lib/node_modules/synchronizer-cli/index.js /usr/bin/synchronize
        chmod +x /usr/bin/synchronize
        bashio::log.info "Symlink created and made executable"
    else
        bashio::log.fatal "synchronizer-cli installation is completely missing!"
        bashio::log.fatal "Expected locations checked:"
        bashio::log.fatal "  - /usr/bin/synchronize"
        bashio::log.fatal "  - /usr/lib/node_modules/synchronizer-cli/index.js"
        exit 1
    fi
fi

bashio::log.info "Final synchronizer-cli location: $(which synchronize)"

# Test basic synchronizer-cli functionality with comprehensive testing
bashio::log.info "====== SYNCHRONIZER-CLI FUNCTIONALITY TESTING ======"
bashio::log.info "Testing synchronizer-cli basic functionality..."

# Check Node.js version compatibility
bashio::log.info "Testing Node.js version compatibility..."
bashio::log.info "Node.js version: $(node --version 2>&1 || echo 'Not available')"
bashio::log.info "NPM version: $(npm --version 2>&1 || echo 'Not available')"

# Detailed Node.js version check
bashio::log.info "Performing detailed Node.js compatibility check..."
node -e "
const version = process.version.slice(1).split('.');
const major = parseInt(version[0]);
const minor = parseInt(version[1]);
console.log('Node.js version details:');
console.log('  Full version:', process.version);
console.log('  Major version:', major);
console.log('  Minor version:', minor);
console.log('  Platform:', process.platform);
console.log('  Architecture:', process.arch);
console.log('  V8 version:', process.versions.v8);
console.log('  UV version:', process.versions.uv);
if (major < 10) {
    console.error('ERROR: Node.js version too old. Need v10+, got:', process.version);
    process.exit(1);
} else {
    console.log('✓ Node.js version is compatible:', process.version);
}
" || bashio::log.error "Node.js version check failed!"

# Test if we can execute the synchronizer binary at all
bashio::log.info "====== INITIAL SYNCHRONIZER EXECUTION TESTS ======"
bashio::log.info "WARNING: The following tests may cause segfaults. Monitoring carefully..."

# Test 1: Check if the binary can be executed without crashing immediately
bashio::log.info "Test 1: Basic binary execution test..."
if command -v synchronize >/dev/null 2>&1; then
    bashio::log.info "Running basic execution test with timeout..."
    
    # Use strace if available to monitor system calls before crash
    if command -v strace >/dev/null 2>&1; then
        bashio::log.info "Using strace to monitor system calls..."
        bashio::log.info "Running: timeout 5 strace -f -e trace=execve,open,openat,read,write,mmap,munmap,segv synchronize --version"
        timeout 5 strace -f -e trace=execve,open,openat,read,write,mmap,munmap,segv synchronize --version 2>/tmp/strace_version.log || {
            local exit_code=$?
            bashio::log.warning "strace execution failed with code: $exit_code"
            bashio::log.info "Last 30 lines of strace output:"
            tail -30 /tmp/strace_version.log 2>/dev/null | while read line; do
                bashio::log.info "  $line"
            done
        }
    fi
    
    # Test with timeout to prevent infinite hangs
    bashio::log.info "Running version check with 10-second timeout..."
    timeout 10 synchronize --version >/tmp/version_output.log 2>&1 || {
        local exit_code=$?
        bashio::log.warning "Version check failed with exit code: $exit_code"
        bashio::log.info "Output from version check:"
        cat /tmp/version_output.log 2>/dev/null | while read line; do
            bashio::log.info "  $line"
        done
        
        # If this is a segfault, try to get more info
        if [[ $exit_code -eq 139 ]]; then
            bashio::log.error "SEGMENTATION FAULT detected in synchronize --version"
        elif [[ $exit_code -eq 124 ]]; then
            bashio::log.warning "Command timed out (possible hang)"
        fi
    }
else
    bashio::log.error "synchronize command still not available after setup attempts"
fi

# Test 2: Try help command
bashio::log.info "Test 2: Help command test..."
if command -v synchronize >/dev/null 2>&1; then
    bashio::log.info "Running help command with timeout..."
    timeout 5 synchronize --help >/tmp/help_output.log 2>&1 || {
        local exit_code=$?
        bashio::log.warning "Help command failed with exit code: $exit_code"
        bashio::log.info "Help output:"
        head -20 /tmp/help_output.log 2>/dev/null | while read line; do
            bashio::log.info "  $line"
        done
    }
fi

# Test 3: Try using gdb for crash analysis
bashio::log.info "Test 3: GDB crash analysis..."
if command -v gdb >/dev/null 2>&1 && command -v synchronize >/dev/null 2>&1; then
    bashio::log.info "Running GDB analysis with crash detection..."
    cat > /tmp/gdb_commands << 'EOF'
set confirm off
set pagination off
run --version
bt
info registers
quit
EOF
    
    timeout 15 gdb -batch -x /tmp/gdb_commands synchronize >/tmp/gdb_output.log 2>&1 || true
    bashio::log.info "GDB output (last 30 lines):"
    tail -30 /tmp/gdb_output.log 2>/dev/null | while read line; do
        bashio::log.info "  $line"
    done
fi

# Test 4: Try direct Node.js execution if available
bashio::log.info "Test 4: Direct Node.js execution test..."
if [[ -f /usr/lib/node_modules/synchronizer-cli/index.js ]]; then
    bashio::log.info "Testing direct Node.js execution of synchronizer-cli..."
    timeout 10 node /usr/lib/node_modules/synchronizer-cli/index.js --version >/tmp/node_version.log 2>&1 || {
        local exit_code=$?
        bashio::log.warning "Direct Node.js execution failed with code: $exit_code"
        bashio::log.info "Node.js execution output:"
        cat /tmp/node_version.log 2>/dev/null | while read line; do
            bashio::log.info "  $line"
        done
    }
fi

bashio::log.info "====== END SYNCHRONIZER EXECUTION TESTS ======"
bashio::log.info "Continuing with configuration setup..."

# Get configuration with detailed logging
bashio::log.info "====== CONFIGURATION READING ======"
bashio::log.info "Reading addon configuration..."

bashio::log.info "Reading main configuration values..."
SYNQ_KEY=$(bashio::config 'synq_key')
WALLET_ADDRESS=$(bashio::config 'wallet_address')
SYNC_NAME=$(bashio::config 'sync_name')
AUTO_START=$(bashio::config 'auto_start')

bashio::log.info "Reading web dashboard configuration..."
ENABLE_WEB_DASHBOARD=$(bashio::config 'web_dashboard.enable')
DASHBOARD_PORT=$(bashio::config 'web_dashboard.port')
METRICS_PORT=$(bashio::config 'web_dashboard.metrics_port')
DASHBOARD_PASSWORD=$(bashio::config 'web_dashboard.password')

bashio::log.info "Reading advanced configuration..."
LOG_LEVEL=$(bashio::config 'advanced.log_level')

# Log configuration (redacting sensitive info)
bashio::log.info "Configuration summary:"
bashio::log.info "  Synq key: $(echo "$SYNQ_KEY" | sed 's/./*/g')"
bashio::log.info "  Wallet address: $(echo "$WALLET_ADDRESS" | sed 's/\(.\{6\}\).*/\1.../')"
bashio::log.info "  Sync name: $SYNC_NAME"
bashio::log.info "  Auto start: $AUTO_START"
bashio::log.info "  Web dashboard enabled: $ENABLE_WEB_DASHBOARD"
bashio::log.info "  Dashboard port: $DASHBOARD_PORT"
bashio::log.info "  Metrics port: $METRICS_PORT"
bashio::log.info "  Dashboard password: $(if [[ -n "$DASHBOARD_PASSWORD" ]]; then echo "SET"; else echo "NOT SET"; fi)"
bashio::log.info "  Log level: $LOG_LEVEL"

# Check required configuration with detailed validation
bashio::log.info "====== CONFIGURATION VALIDATION ======"
bashio::log.info "Validating required configuration..."

if [[ -z "$SYNQ_KEY" ]]; then
    bashio::log.fatal "Synq key is required! Please configure it in the add-on settings."
    bashio::log.fatal "This should be set in the addon configuration under 'synq_key'"
    exit 1
fi

if [[ -z "$WALLET_ADDRESS" ]]; then
    bashio::log.fatal "Wallet address is required! Please configure it in the add-on settings."
    bashio::log.fatal "This should be set in the addon configuration under 'wallet_address'"
    exit 1
fi

bashio::log.info "✓ Required configuration values are present"

# Set log level early for better debugging
bashio::log.info "Setting log level to: $LOG_LEVEL"
bashio::log.level "$LOG_LEVEL"

# Set HOME to data directory so config is persistent
bashio::log.info "====== DIRECTORY SETUP ======"
export HOME=/data
bashio::log.info "Setting HOME directory to: $HOME"

# Create .synchronizer-cli directory if it doesn't exist
bashio::log.info "Setting up configuration directory..."
mkdir -p /data/.synchronizer-cli
bashio::log.info "Created configuration directory: /data/.synchronizer-cli"
bashio::log.info "Directory permissions: $(ls -ld /data/.synchronizer-cli)"

# Create configuration file with enhanced logging
bashio::log.info "====== CONFIGURATION FILE CREATION ======"
bashio::log.info "Creating synchronizer configuration..."
CONFIG_FILE="/data/.synchronizer-cli/config.json"
bashio::log.info "Configuration file path: $CONFIG_FILE"

# Generate secret and hash
bashio::log.info "Generating cryptographic values..."
SECRET=$(openssl rand -hex 32)
HOSTNAME=$(hostname)
SYNC_HASH=$(echo -n "${SYNQ_KEY}${WALLET_ADDRESS}" | sha256sum | cut -d' ' -f1)

bashio::log.info "Generated values:"
bashio::log.info "  Secret: $(echo "$SECRET" | sed 's/./*/g')"
bashio::log.info "  Hostname: $HOSTNAME"
bashio::log.info "  Sync hash: $SYNC_HASH"

# Generate configuration with error handling and detailed logging
bashio::log.info "Writing configuration file..."
cat > "$CONFIG_FILE" << EOF || {
    bashio::log.fatal "Failed to create configuration file!"
    bashio::log.fatal "Check disk space and permissions for: $CONFIG_FILE"
    exit 1
}
{
  "userName": "$SYNC_NAME",
  "key": "$SYNQ_KEY",
  "wallet": "$WALLET_ADDRESS",
  "secret": "$SECRET",
  "hostname": "$HOSTNAME",
  "syncHash": "$SYNC_HASH",
  "depin": "wss://api.multisynq.io/depin",
  "launcher": "homeassistant-addon"
}
EOF

bashio::log.info "✓ Configuration file created successfully"
bashio::log.info "Configuration file size: $(du -h "$CONFIG_FILE" | cut -f1)"
bashio::log.debug "Configuration file permissions: $(ls -la "$CONFIG_FILE")"
bashio::log.info "✓ Configuration file created successfully"
bashio::log.info "Configuration file size: $(du -h "$CONFIG_FILE" | cut -f1)"
bashio::log.debug "Configuration file permissions: $(ls -la "$CONFIG_FILE")"

# Validate the synq key with better error handling and detailed logging
bashio::log.info "====== SYNQ KEY VALIDATION ======"
bashio::log.info "Validating synq key format..."
bashio::log.info "Note: Skipping synchronizer-cli validation due to potential segfault issues"
bashio::log.info "Performing local format validation instead"

# Basic format validation for synq key
bashio::log.info "Checking synq key length..."
if [[ ${#SYNQ_KEY} -lt 10 ]]; then
    bashio::log.error "Synq key appears to be too short (${#SYNQ_KEY} characters, minimum 10)"
    bashio::log.error "Please check your synq key and try again."
    exit 1
fi
bashio::log.info "✓ Synq key length is acceptable (${#SYNQ_KEY} characters)"

bashio::log.info "Checking synq key character format..."
if [[ ! "$SYNQ_KEY" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    bashio::log.error "Synq key contains invalid characters"
    bashio::log.error "Valid characters are: a-z, A-Z, 0-9, underscore, hyphen"
    bashio::log.error "Please check your synq key and try again."
    exit 1
fi
bashio::log.info "✓ Synq key character format is valid"

bashio::log.info "✓ Synq key format validation passed"

# Check if auto start is enabled with detailed logging
bashio::log.info "====== AUTO START CONFIGURATION ======"
bashio::log.info "Checking auto start configuration..."
bashio::log.info "Auto start setting: $AUTO_START"

if [[ "$AUTO_START" != "true" ]]; then
    bashio::log.info "Auto start is disabled. Synchronizer will not start automatically."
    bashio::log.info "You can manually start it through the web dashboard if enabled."
    bashio::log.info "This is the safer option to avoid potential crashes during startup."
fi

# Start the synchronizer container in background (if auto start is enabled)
if [[ "$AUTO_START" == "true" ]]; then
    bashio::log.info "====== SYNCHRONIZER STARTUP ATTEMPT ======"
    bashio::log.info "Auto start is enabled - attempting to start synchronizer..."
    bashio::log.warning "This may cause segmentation faults - monitoring carefully..."
    
    # Pre-execution checks
    bashio::log.info "Pre-execution environment check:"
    bashio::log.info "  Working directory: $(pwd)"
    bashio::log.info "  HOME directory: $HOME"
    bashio::log.info "  Config file exists: $(test -f "$CONFIG_FILE" && echo "YES" || echo "NO")"
    bashio::log.info "  Available memory: $(free -m | grep '^Mem:' | awk '{print $7}')MB free"
    
    # Choose execution method with extensive logging
    if [[ -f /usr/lib/node_modules/synchronizer-cli/index.js ]]; then
        bashio::log.info "✓ Using direct Node.js execution method (safer)"
        bashio::log.info "Command: node /usr/lib/node_modules/synchronizer-cli/index.js start"
        bashio::log.info "About to execute Node.js directly..."
        
        # Execute with comprehensive monitoring
        set +e  # Temporarily disable exit on error
        bashio::log.info "Starting Node.js process..."
        timeout 60 node /usr/lib/node_modules/synchronizer-cli/index.js start > /tmp/start_output.log 2>&1 &
        SYNC_PID=$!
        bashio::log.info "Node.js process started with PID: $SYNC_PID"
        set -e  # Re-enable exit on error
    else
        bashio::log.info "Fallback to synchronize command method"
        bashio::log.warning "This method is more likely to cause segfaults!"
        bashio::log.info "Command: synchronize start"
        bashio::log.info "About to execute synchronize command..."
        
        # Execute with comprehensive monitoring
        set +e  # Temporarily disable exit on error
        bashio::log.info "Starting synchronize process..."
        timeout 60 synchronize start > /tmp/start_output.log 2>&1 &
        SYNC_PID=$!
        bashio::log.info "Synchronize process started with PID: $SYNC_PID"
        set -e  # Re-enable exit on error
    fi
    
    # Monitor the process startup
    bashio::log.info "Monitoring process startup for 10 seconds..."
    for i in {1..10}; do
        sleep 1
        if ! kill -0 $SYNC_PID 2>/dev/null; then
            bashio::log.error "Process died after $i seconds!"
            break
        fi
        bashio::log.debug "Process still running after $i seconds..."
    done
    
    # Check final status
    if ! kill -0 $SYNC_PID 2>/dev/null; then
        bashio::log.error "====== SYNCHRONIZER STARTUP FAILED ======"
        bashio::log.error "Synchronizer failed to start!"
        bashio::log.error "Process output:"
        cat /tmp/start_output.log | while read line; do
            bashio::log.error "  $line"
        done
        
        # Try to get exit status
        wait $SYNC_PID || {
            local exit_code=$?
            bashio::log.error "Process exit code: $exit_code"
            if [[ $exit_code -eq 139 ]]; then
                bashio::log.error "EXIT CODE 139 = SEGMENTATION FAULT"
            elif [[ $exit_code -eq 124 ]]; then
                bashio::log.error "EXIT CODE 124 = TIMEOUT"
            fi
        }
        
        bashio::log.warning "Continuing without synchronizer auto-start"
        bashio::log.warning "You can try starting it manually via the web dashboard"
        SYNC_PID=""
    else
        bashio::log.info "✓ Synchronizer started successfully!"
        bashio::log.info "Process is running with PID: $SYNC_PID"
        bashio::log.info "Waiting additional 5 seconds for stability..."
        sleep 5  # Additional wait for stability
        
        if ! kill -0 $SYNC_PID 2>/dev/null; then
            bashio::log.warning "Process died during stability wait"
            SYNC_PID=""
        else
            bashio::log.info "✓ Process confirmed stable"
        fi
    fi
else
    SYNC_PID=""
    bashio::log.info "Synchronizer not started automatically (auto_start disabled)"
fi

# Check if web dashboard should be enabled with detailed logging
bashio::log.info "====== WEB DASHBOARD SETUP ======"
bashio::log.info "Web dashboard configuration:"
bashio::log.info "  Enabled: $ENABLE_WEB_DASHBOARD"
bashio::log.info "  Port: $DASHBOARD_PORT"
bashio::log.info "  Metrics port: $METRICS_PORT"
bashio::log.info "  Password protection: $(if [[ -n "$DASHBOARD_PASSWORD" ]]; then echo "ENABLED"; else echo "DISABLED"; fi)"

if [[ "$ENABLE_WEB_DASHBOARD" == "true" ]]; then
    bashio::log.info "Setting up web dashboard..."
    
    # Build web dashboard command using direct Node.js execution if possible
    if [[ -f /usr/lib/node_modules/synchronizer-cli/index.js ]]; then
        bashio::log.info "✓ Using direct Node.js execution for web dashboard"
        WEB_CMD="node /usr/lib/node_modules/synchronizer-cli/index.js web --port $DASHBOARD_PORT --metrics-port $METRICS_PORT"
    else
        bashio::log.info "Using synchronize command for web dashboard"
        WEB_CMD="synchronize web --port $DASHBOARD_PORT --metrics-port $METRICS_PORT"
    fi

    # Add password if configured
    if [[ -n "$DASHBOARD_PASSWORD" ]]; then
        bashio::log.info "Setting dashboard password..."
        if command -v synchronize >/dev/null 2>&1; then
            bashio::log.info "Attempting to set password via synchronize command..."
            echo "$DASHBOARD_PASSWORD" | synchronize set-password || {
                bashio::log.warning "Failed to set password via synchronize command"
                bashio::log.warning "This might be due to the segfault issues"
            }
        else
            bashio::log.warning "synchronize command not available for password setting"
        fi
        WEB_CMD="$WEB_CMD --password"
    fi

    # Start the web dashboard with detailed monitoring
    bashio::log.info "Starting web dashboard..."
    bashio::log.info "Command: $WEB_CMD"
    bashio::log.info "Dashboard will be available on port $DASHBOARD_PORT"
    bashio::log.info "Metrics API will be available on port $METRICS_PORT"
    
    set +e  # Temporarily disable exit on error
    bashio::log.info "Executing web dashboard startup..."
    $WEB_CMD > /tmp/web_output.log 2>&1 &
    WEB_PID=$!
    bashio::log.info "Web dashboard process started with PID: $WEB_PID"
    set -e  # Re-enable exit on error
    
    # Wait a moment to check if it started successfully
    bashio::log.info "Monitoring web dashboard startup..."
    sleep 3
    
    if ! kill -0 $WEB_PID 2>/dev/null; then
        bashio::log.error "====== WEB DASHBOARD STARTUP FAILED ======"
        bashio::log.error "Web dashboard failed to start!"
        bashio::log.error "Output:"
        cat /tmp/web_output.log | while read line; do
            bashio::log.error "  $line"
        done
        
        # Try to get exit status
        wait $WEB_PID || {
            local exit_code=$?
            bashio::log.error "Web dashboard exit code: $exit_code"
            if [[ $exit_code -eq 139 ]]; then
                bashio::log.error "WEB DASHBOARD SEGMENTATION FAULT"
            fi
        }
        
        bashio::log.warning "Continuing without web dashboard"
        WEB_PID=""
    else
        bashio::log.info "✓ Web dashboard started successfully!"
        bashio::log.info "Dashboard PID: $WEB_PID"
        bashio::log.info "Access URL: http://[your-home-assistant-ip]:$DASHBOARD_PORT"
        bashio::log.info "Metrics URL: http://[your-home-assistant-ip]:$METRICS_PORT"
    fi
else
    WEB_PID=""
    bashio::log.info "Web dashboard disabled in configuration"
fi

# Function to handle shutdown with detailed logging
shutdown() {
    bashio::log.info "====== SHUTDOWN SEQUENCE ======"
    bashio::log.info "Shutting down synchronizer addon..."
    bashio::log.info "Timestamp: $(date)"
    
    if [[ -n "$SYNC_PID" ]]; then
        bashio::log.info "Terminating synchronizer process (PID: $SYNC_PID)..."
        kill $SYNC_PID 2>/dev/null || true
        sleep 2
        if kill -0 $SYNC_PID 2>/dev/null; then
            bashio::log.warning "Synchronizer process still running, forcing termination..."
            kill -9 $SYNC_PID 2>/dev/null || true
        fi
    fi
    
    if [[ -n "$WEB_PID" ]]; then
        bashio::log.info "Terminating web dashboard process (PID: $WEB_PID)..."
        kill $WEB_PID 2>/dev/null || true
        sleep 2
        if kill -0 $WEB_PID 2>/dev/null; then
            bashio::log.warning "Web dashboard process still running, forcing termination..."
            kill -9 $WEB_PID 2>/dev/null || true
        fi
    fi
    
    bashio::log.info "Shutdown complete"
    exit 0
}

# Trap signals with enhanced logging
bashio::log.info "Setting up signal handlers..."
trap shutdown SIGTERM SIGINT

# Final status summary
bashio::log.info "====== STARTUP COMPLETE - STATUS SUMMARY ======"
bashio::log.info "Multisynq Synchronizer add-on startup complete!"
bashio::log.info "Status summary:"

if [[ "$ENABLE_WEB_DASHBOARD" == "true" ]]; then
    if [[ -n "$WEB_PID" ]]; then
        bashio::log.info "✓ Web Dashboard: RUNNING (PID: $WEB_PID)"
        bashio::log.info "  - Dashboard URL: http://[HOST]:$DASHBOARD_PORT"
        bashio::log.info "  - Metrics API: http://[HOST]:$METRICS_PORT"
    else
        bashio::log.info "✗ Web Dashboard: FAILED TO START"
    fi
else
    bashio::log.info "- Web Dashboard: DISABLED"
fi

if [[ "$AUTO_START" == "true" ]]; then
    if [[ -n "$SYNC_PID" ]]; then
        bashio::log.info "✓ Synchronizer: RUNNING (PID: $SYNC_PID)"
    else
        bashio::log.info "✗ Synchronizer: FAILED TO START"
    fi
else
    bashio::log.info "- Synchronizer: DISABLED (auto_start=false)"
fi

bashio::log.info "====== ENTERING MONITORING LOOP ======"

# Keep the script running and monitor processes with enhanced debugging
LOOP_COUNTER=0
while true; do
    LOOP_COUNTER=$((LOOP_COUNTER + 1))
    
    # Log periodic status every 10 loops (5 minutes)
    if [[ $((LOOP_COUNTER % 10)) -eq 0 ]]; then
        bashio::log.info "====== PERIODIC STATUS CHECK (Loop $LOOP_COUNTER) ======"
        bashio::log.info "Timestamp: $(date)"
        bashio::log.info "Memory usage: $(free -m | grep '^Mem:' | awk '{print $3"MB used, "$7"MB free"}')"
        bashio::log.info "System load: $(uptime | awk -F'load average:' '{print $2}')"
        
        if [[ -n "$SYNC_PID" ]]; then
            bashio::log.info "Synchronizer process status: RUNNING (PID: $SYNC_PID)"
        else
            bashio::log.info "Synchronizer process status: NOT RUNNING"
        fi
        
        if [[ -n "$WEB_PID" ]]; then
            bashio::log.info "Web dashboard status: RUNNING (PID: $WEB_PID)"
        else
            bashio::log.info "Web dashboard status: NOT RUNNING"
        fi
    fi
    
    # Check if synchronizer process is still running (only if auto start is enabled)
    if [[ "$AUTO_START" == "true" ]] && [[ -n "$SYNC_PID" ]] && ! kill -0 $SYNC_PID 2>/dev/null; then
        bashio::log.error "====== SYNCHRONIZER PROCESS DIED ======"
        bashio::log.error "Synchronizer process died unexpectedly!"
        bashio::log.error "Previous PID: $SYNC_PID"
        bashio::log.error "Time: $(date)"
        bashio::log.error "Attempting restart..."
        
        # Try to get exit status and output
        if [[ -f /tmp/start_output.log ]]; then
            bashio::log.error "Last output from synchronizer:"
            tail -20 /tmp/start_output.log | while read line; do
                bashio::log.error "  $line"
            done
        fi
        
        # Attempt restart with detailed logging
        bashio::log.info "Restarting synchronizer process..."
        set +e
        if [[ -f /usr/lib/node_modules/synchronizer-cli/index.js ]]; then
            bashio::log.info "Using Node.js direct execution for restart"
            timeout 60 node /usr/lib/node_modules/synchronizer-cli/index.js start > /tmp/restart_output.log 2>&1 &
        else
            bashio::log.info "Using synchronize command for restart"
            timeout 60 synchronize start > /tmp/restart_output.log 2>&1 &
        fi
        SYNC_PID=$!
        bashio::log.info "Restart attempt PID: $SYNC_PID"
        set -e
        
        # Monitor restart
        sleep 10
        if ! kill -0 $SYNC_PID 2>/dev/null; then
            bashio::log.error "Failed to restart synchronizer!"
            bashio::log.error "Restart output:"
            cat /tmp/restart_output.log | while read line; do
                bashio::log.error "  $line"
            done
            SYNC_PID=""
            bashio::log.warning "Synchronizer will remain stopped until manual intervention"
        else
            bashio::log.info "✓ Synchronizer restarted successfully"
        fi
    fi
    
    # Check if web dashboard is still running (only if enabled)
    if [[ "$ENABLE_WEB_DASHBOARD" == "true" ]] && [[ -n "$WEB_PID" ]] && ! kill -0 $WEB_PID 2>/dev/null; then
        bashio::log.error "====== WEB DASHBOARD PROCESS DIED ======"
        bashio::log.error "Web dashboard died unexpectedly!"
        bashio::log.error "Previous PID: $WEB_PID"
        bashio::log.error "Time: $(date)"
        bashio::log.error "Attempting restart..."
        
        # Try to get exit status and output
        if [[ -f /tmp/web_output.log ]]; then
            bashio::log.error "Last output from web dashboard:"
            tail -20 /tmp/web_output.log | while read line; do
                bashio::log.error "  $line"
            done
        fi
        
        # Attempt restart
        bashio::log.info "Restarting web dashboard..."
        set +e
        $WEB_CMD > /tmp/web_restart_output.log 2>&1 &
        WEB_PID=$!
        bashio::log.info "Web dashboard restart PID: $WEB_PID"
        set -e
        
        # Monitor restart
        sleep 5
        if ! kill -0 $WEB_PID 2>/dev/null; then
            bashio::log.error "Failed to restart web dashboard!"
            bashio::log.error "Restart output:"
            cat /tmp/web_restart_output.log | while read line; do
                bashio::log.error "  $line"
            done
            WEB_PID=""
            bashio::log.warning "Web dashboard will remain stopped until manual intervention"
        else
            bashio::log.info "✓ Web dashboard restarted successfully"
        fi
    fi
    
    # Sleep for 30 seconds before next check
    sleep 30
done