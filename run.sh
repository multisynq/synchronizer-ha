#!/bin/bash
ADDON_VERSION="1.2.0"
SYNQ_NAME_LENGTH=12
# DEPIN_ENDPOINT="wss://api.multisynq.io/depin"
DEPIN_ENDPOINT="prod" #local, dev, prod

echo "🚀 ————————————————————————————————————————————————————————— 🚀"
echo "🚀 ———————————— Multisynq Synchronizer Starting ———————————— 🚀"
echo "🚀 ————————————————————————————————————————————————————————— 🚀"
echo "├─ ⏰ $(date): Script started"
echo "├─ 📦 Home Assistant Addon Version: $ADDON_VERSION"
echo "├─ 🏗️ Architecture: $(uname -m)"
echo "├─ 💻 $(uname -a)"
echo "🚀 ————————————————————————————————————————————————————————— 🚀"

# Check if bashio is available and working
if command -v bashio >/dev/null 2>&1; then
  # Test if bashio logging actually works
  if bashio log info "Testing bashio logging" >/dev/null 2>&1; then
    echo "Bashio found and working at: $(which bashio)"
    BASHIO_AVAILABLE=true
  else
    echo "Bashio found but logging not working, using fallback methods"
    BASHIO_AVAILABLE=false
  fi
else
  echo "Bashio not available, will use fallback methods"
  BASHIO_AVAILABLE=false
fi

# Simple logging function with emojis (similar to simple-server.js)
logger() {
  local level="$1"
  local message="$2"
  local symbol=""
  
  case "$level" in
    "error")   symbol="❌ " ;;
    "success") symbol="✔️ " ;;
    "warning") symbol="⚠️ " ;;
    "space")   symbol="· " ;;
    *)         symbol="" ;;
  esac
  
  if [ "$BASHIO_AVAILABLE" = "true" ]; then
    bashio log "$level" "$message" 2>/dev/null || echo "$symbol$message" ${level == "error" ? ">&2" : ""}
  else
    if [ "$level" = "error" ]; then
      echo "$symbol$message" >&2
    else
      echo "$symbol$message"
    fi
  fi
}

log_info()    { logger "info" "$1";    }
log_error()   { logger "error" "$1";   }
log_success() { logger "success" "$1"; }
log_warning() { logger "warning" "$1"; }
log_space()   { logger "space" "$1"; }

# Check configuration file
echo "🔧 Configuration Check"
if [ -f "/data/options.json" ]; then
  log_success "Configuration file found:"
  cat /data/options.json
  echo ""
  
  # Try to read with jq if available
  if command -v jq >/dev/null 2>&1; then
    echo "Reading config with jq..."
    SYNQ_KEY=$(jq -r '.synq_key // ""' /data/options.json)
    WALLET_ADDRESS=$(jq -r '.wallet_address // ""' /data/options.json)
    LITE_MODE=$(jq -r '.lite_mode // false' /data/options.json)
    
    # Additional check for null values from jq
    if [ "$SYNQ_KEY" = "null" ]; then
      SYNQ_KEY=""
    fi
    if [ "$WALLET_ADDRESS" = "null" ]; then
      WALLET_ADDRESS=""
    fi
    if [ "$LITE_MODE" = "null" ]; then
      LITE_MODE="false"
    fi
  else
    echo "jq not available, trying bashio command..."
    if [ "$BASHIO_AVAILABLE" = "true" ]; then
      SYNQ_KEY=$(bashio config synq_key)
      WALLET_ADDRESS=$(bashio config wallet_address)
      LITE_MODE=$(bashio config lite_mode)
    else    echo "Neither jq nor bashio available for config reading"
    SYNQ_KEY=""
    WALLET_ADDRESS=""
    LITE_MODE="false"
    fi
  fi
else
  echo "No configuration file found at /data/options.json"
  SYNQ_KEY=""
  WALLET_ADDRESS=""
  LITE_MODE="false"
fi

# Generate or retrieve persistent synchronizer name
SYNC_NAME_FILE="/share/multisynq_sync_name.txt"
if [ -f "$SYNC_NAME_FILE" ]; then
  SYNC_NAME=$(cat "$SYNC_NAME_FILE")
  log_success "Using existing synchronizer name: $SYNC_NAME"
else
  log_info "🎲 Generating new synchronizer name..."
  # Generate random hex string with configurable length
  RANDOM_HEX_BYTES=$((SYNQ_NAME_LENGTH / 2))  # 2 hex chars per byte
  
  if command -v openssl >/dev/null 2>&1; then
    RANDOM_SUFFIX=$(openssl rand -hex $RANDOM_HEX_BYTES)
  elif [ -f /dev/urandom ]; then
    RANDOM_SUFFIX=$(head -c $RANDOM_HEX_BYTES /dev/urandom | xxd -p)
  else
    # Fallback: use current timestamp and process ID, truncate to desired length
    RANDOM_SUFFIX=$(printf "%0${SYNQ_NAME_LENGTH}x" $(($(date +%s) * $$ % $((16**SYNQ_NAME_LENGTH)))))
  fi
  
  # Ensure the suffix is exactly the right length
  RANDOM_SUFFIX=${RANDOM_SUFFIX:0:$SYNQ_NAME_LENGTH}
  
  SYNC_NAME="ha-${RANDOM_SUFFIX}"
  log_success "Generated new synchronizer name: $SYNC_NAME (${SYNQ_NAME_LENGTH} char suffix)"
  
  # Save the name for future use
  echo "$SYNC_NAME" > "$SYNC_NAME_FILE"
  if [ $? -eq 0 ]; then
    log_success "💾 Synchronizer name saved to $SYNC_NAME_FILE"
  else
    log_error "Failed to save synchronizer name to $SYNC_NAME_FILE"
    log_warning "Name will be regenerated on next restart"
  fi
fi

# Create a comprehensive config file for the web dashboard
CONFIG_FILE="/share/multisynq_config.json"
log_info "📝 Creating dashboard config file at $CONFIG_FILE"

# Create config JSON with all necessary information
cat > "$CONFIG_FILE" << EOF
{
  "syncName": "$SYNC_NAME",
  "walletAddress": "$WALLET_ADDRESS",
  "synqKey": "${SYNQ_KEY:0:8}...",
  "liteMode": $LITE_MODE,
  "depinEndpoint": "$DEPIN_ENDPOINT",
  "addonVersion": "$ADDON_VERSION",
  "timestamp": $(date +%s),
  "configSource": "homeassistant"
}
EOF

if [ $? -eq 0 ]; then
  log_success "Dashboard config saved to $CONFIG_FILE"
  log_info "📄 Config contents:"
  cat "$CONFIG_FILE"
else
  log_error "Failed to save dashboard config to $CONFIG_FILE"
fi

echo "🔧 ───────────────── Configuration Summary ───────────────── 🔧"
echo "├─ 🔑 API Key:        ${SYNQ_KEY:0:8}... (${#SYNQ_KEY} chars)"
echo "├─ 💰 Wallet Address: ${WALLET_ADDRESS}"
echo "├─ 🏷️ Sync Name:      ${SYNC_NAME} (persistent)"
echo "├─ 🔄 Lite Mode:      ${LITE_MODE}"
echo "🔧 ────────────────────────────────────────────────────────── 🔧"
log_space

# Early validation feedback
if [ -z "$SYNQ_KEY" ] || [ "$SYNQ_KEY" = "" ]; then
  log_warning "SYNQ_KEY is missing or empty - addon will crash!"
fi
if [ -z "$WALLET_ADDRESS" ] || [ "$WALLET_ADDRESS" = "" ]; then
  log_warning "WALLET_ADDRESS is missing or empty - addon will crash!"
fi

# Validate required values - forcibly crash if missing or empty
if [ -z "$SYNQ_KEY" ] || [ "$SYNQ_KEY" = "" ]; then
  log_error "🛑 FATAL: API Key is required but not configured or is empty"
  log_error "🛑 FATAL: Please fill in your API Key in the Home Assistant addon configuration"
  log_error "🛑 FATAL: Get your API Key from https://multisynq.io"
  log_error "🛑 FATAL: Addon will now crash intentionally"
  exit 1
fi

if [ -z "$WALLET_ADDRESS" ] || [ "$WALLET_ADDRESS" = "" ]; then
  log_error "🛑 FATAL: Wallet Address is required but not configured or is empty"
  log_error "🛑 FATAL: Please fill in your Wallet Address in the Home Assistant addon configuration"
  log_error "🛑 FATAL: This is where you'll receive your rewards"
  log_error "🛑 FATAL: Addon will now crash intentionally"
  exit 1
fi

echo "🎉 Configuration validation passed! 🎉"

# Export environment variables for the status server
export SYNQ_KEY="$SYNQ_KEY"
export WALLET_ADDRESS="$WALLET_ADDRESS"
export SYNC_NAME="$SYNC_NAME"
export DEPIN_ENDPOINT="$DEPIN_ENDPOINT"

# Check if lite mode is enabled
if [ "$LITE_MODE" = "true" ]; then
  log_info "⚡ Lite mode enabled - starting synchronizer directly without web panel"
  
  # Start synchronizer directly without status server
  if [ -f "/usr/src/synchronizer/wrapper.js" ]; then
    log_success "Found synchronizer wrapper, starting directly"
    
    # Build arguments
    ARGS=(
      "--sync-name" "$SYNC_NAME"
      "--key" "$SYNQ_KEY"
      "--wallet" "$WALLET_ADDRESS"
      "--depin" "$DEPIN_ENDPOINT"
    )
    
    log_info "Starting synchronizer with arguments: ${ARGS[*]}"
    exec node /usr/src/synchronizer/wrapper.js "${ARGS[@]}"
  else
    log_error "Synchronizer wrapper not found at /usr/src/synchronizer/wrapper.js"
    exit 1
  fi
else
  log_info "🌐 Full mode enabled - starting synchronizer and web panel"
  
  # Check for the synchronizer first
  if [ ! -f "/usr/src/synchronizer/wrapper.js" ]; then
    log_error "Synchronizer wrapper not found at /usr/src/synchronizer/wrapper.js"
    exit 1
  fi
  
  # Build synchronizer arguments
  SYNC_ARGS=(
    "--sync-name" "$SYNC_NAME"
    "--key" "$SYNQ_KEY"
    "--wallet" "$WALLET_ADDRESS"
    "--depin" "$DEPIN_ENDPOINT"
  )
  
  log_info "🚀 Starting synchronizer with arguments: ${SYNC_ARGS[*]}"
  
  # Start the synchronizer in the background
  node /usr/src/synchronizer/wrapper.js "${SYNC_ARGS[@]}" &
  SYNC_PID=$!
  
  log_success "Synchronizer started with PID: $SYNC_PID"
  
  # Check for the simple web server
  if [ -f "/app/simple-server.js" ]; then
    log_success "Found simple web server, starting dashboard on port 8099"
    
    # Start the simple web server for dashboard
    node /app/simple-server.js &
    SERVER_PID=$!
    
    log_info "🌐 Web dashboard started with PID: $SERVER_PID"
    
    # Function to handle shutdown gracefully
    cleanup() {
      log_info "🛑 Shutting down services..."
      if kill -0 $SYNC_PID 2>/dev/null; then
        log_info "├─ Stopping synchronizer (PID: $SYNC_PID)"
        kill $SYNC_PID
      fi
      if kill -0 $SERVER_PID 2>/dev/null; then
        log_info "├─ Stopping web server (PID: $SERVER_PID)"
        kill $SERVER_PID
      fi
      echo "└─ 🏁 All services stopped cleanly 🏁"
      log_space
      exit 0
    }
    
    # Set up signal handlers
    trap cleanup SIGTERM SIGINT
    
    log_info "👁️  Monitoring both processes..."
    # Wait for both processes
    wait $SYNC_PID $SERVER_PID
  else
    log_error "simple-server.js not found at /app/"
    log_info "🔧 Running synchronizer only (no web dashboard)"
    
    # Wait for the synchronizer process
    log_info "👁️  Monitoring synchronizer process..."
    wait $SYNC_PID
  fi
fi
