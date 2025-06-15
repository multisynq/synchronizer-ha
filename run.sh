#!/bin/bash

echo "=== Multisynq Synchronizer Starting ==="
echo "$(date): Script started"
echo "System: $(uname -a)"
echo "Architecture: $(uname -m)"

VERSION=$(grep -oP '"version":\s*"\K[^"]+' /app/package.json)
echo "Home Assistant Addon Version: $VERSION"
echo ""

DEPIN_ENDPOINT="wss://api.multisynq.io/depin"

# Check if bashio is available as a command
if command -v bashio >/dev/null 2>&1; then
  echo "Bashio found at: $(which bashio)"
  BASHIO_AVAILABLE=true
else
  echo "Bashio not available, will use fallback methods"
  BASHIO_AVAILABLE=false
fi

# Simple logging function
log_info() {
  if [ "$BASHIO_AVAILABLE" = "true" ]; then
    bashio log info "$1"
  else
    echo "[INFO] $1"
  fi
}

log_error() {
  if [ "$BASHIO_AVAILABLE" = "true" ]; then
    bashio log error "$1"
  else
    echo "[ERROR] $1" >&2
  fi
}

# Check configuration file
echo "=== Configuration Check ==="
if [ -f "/data/options.json" ]; then
  echo "Configuration file found:"
  cat /data/options.json
  echo "---"
  
  # Try to read with jq if available
  if command -v jq >/dev/null 2>&1; then
    echo "Reading config with jq..."
    SYNQ_KEY=$(jq -r '.synq_key // ""' /data/options.json)
    WALLET_ADDRESS=$(jq -r '.wallet_address // ""' /data/options.json)
    
    # Additional check for null values from jq
    if [ "$SYNQ_KEY" = "null" ]; then
      SYNQ_KEY=""
    fi
    if [ "$WALLET_ADDRESS" = "null" ]; then
      WALLET_ADDRESS=""
    fi
  else
    echo "jq not available, trying bashio command..."
    if [ "$BASHIO_AVAILABLE" = "true" ]; then
      SYNQ_KEY=$(bashio config synq_key)
      WALLET_ADDRESS=$(bashio config wallet_address)
    else    echo "Neither jq nor bashio available for config reading"
    SYNQ_KEY=""
    WALLET_ADDRESS=""
    fi
  fi
else
  echo "No configuration file found at /data/options.json"
  SYNQ_KEY=""
  WALLET_ADDRESS=""
fi

# Generate or retrieve persistent synchronizer name
SYNC_NAME_FILE="/share/multisynq_sync_name.txt"
if [ -f "$SYNC_NAME_FILE" ]; then
  SYNC_NAME=$(cat "$SYNC_NAME_FILE")
  echo "Using existing synchronizer name: $SYNC_NAME"
else
  # Generate random 12-character hex string
  if command -v openssl >/dev/null 2>&1; then
    RANDOM_SUFFIX=$(openssl rand -hex 6)
  elif [ -f /dev/urandom ]; then
    RANDOM_SUFFIX=$(head -c 6 /dev/urandom | xxd -p)
  else
    # Fallback: use current timestamp and process ID
    RANDOM_SUFFIX=$(printf "%012x" $(($(date +%s) * $$ % 16777215)))
  fi
  
  SYNC_NAME="ha-${RANDOM_SUFFIX}"
  echo "Generated new synchronizer name: $SYNC_NAME"
  
  # Save the name for future use
  echo "$SYNC_NAME" > "$SYNC_NAME_FILE"
  if [ $? -eq 0 ]; then
    echo "Synchronizer name saved to $SYNC_NAME_FILE"
  else
    log_error "Failed to save synchronizer name to $SYNC_NAME_FILE"
    log_error "Name will be regenerated on next restart"
  fi
fi

echo "Configuration values:"
echo "  API Key: ${SYNQ_KEY:0:8}... (${#SYNQ_KEY} chars)"
echo "  Wallet Address: ${WALLET_ADDRESS}"
echo "  Sync Name: ${SYNC_NAME} (persistent)"

# Early validation feedback
if [ -z "$SYNQ_KEY" ] || [ "$SYNQ_KEY" = "" ]; then
  echo "WARNING: SYNQ_KEY is missing or empty - addon will crash!"
fi
if [ -z "$WALLET_ADDRESS" ] || [ "$WALLET_ADDRESS" = "" ]; then
  echo "WARNING: WALLET_ADDRESS is missing or empty - addon will crash!"
fi

# Validate required values - forcibly crash if missing or empty
if [ -z "$SYNQ_KEY" ] || [ "$SYNQ_KEY" = "" ]; then
  log_error "FATAL: API Key is required but not configured or is empty"
  log_error "FATAL: Please fill in your API Key in the Home Assistant addon configuration"
  log_error "FATAL: Get your API Key from https://multisynq.io"
  log_error "FATAL: Addon will now crash intentionally"
  exit 1
fi

if [ -z "$WALLET_ADDRESS" ] || [ "$WALLET_ADDRESS" = "" ]; then
  log_error "FATAL: Wallet Address is required but not configured or is empty"
  log_error "FATAL: Please fill in your Wallet Address in the Home Assistant addon configuration"
  log_error "FATAL: This is where you'll receive your rewards"
  log_error "FATAL: Addon will now crash intentionally"
  exit 1
fi

log_info "Starting Multisynq Synchronizer..."
log_info "Sync Name: ${SYNC_NAME}"
log_info "Wallet: ${WALLET_ADDRESS}"

# Check for the synchronizer
if [ -f "/usr/src/synchronizer/wrapper.js" ]; then
  log_info "Found synchronizer wrapper"
  
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
