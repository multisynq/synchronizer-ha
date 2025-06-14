#!/bin/bash

echo "=== Multisynq Synchronizer Starting ==="
echo "$(date): Script started"

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
    SYNC_NAME=$(jq -r '.sync_name // "homeassistant-addon"' /data/options.json)
  else
    echo "jq not available, trying bashio command..."
    if [ "$BASHIO_AVAILABLE" = "true" ]; then
      SYNQ_KEY=$(bashio config synq_key)
      WALLET_ADDRESS=$(bashio config wallet_address)
      SYNC_NAME=$(bashio config sync_name)
    else
      echo "Neither jq nor bashio available for config reading"
      SYNQ_KEY=""
      WALLET_ADDRESS=""
      SYNC_NAME="homeassistant-addon"
    fi
  fi
else
  echo "No configuration file found at /data/options.json"
  SYNQ_KEY=""
  WALLET_ADDRESS=""
  SYNC_NAME="homeassistant-addon"
fi

echo "Configuration values:"
echo "  API Key: ${SYNQ_KEY:0:8}... (${#SYNQ_KEY} chars)"
echo "  Wallet Address: ${WALLET_ADDRESS}"
echo "  Sync Name: ${SYNC_NAME}"

# Validate required values
if [ -z "$SYNQ_KEY" ]; then
  log_error "API Key is required but not configured"
  log_error "Please fill in your API Key in the Home Assistant addon configuration"
  log_error "Get your API Key from https://multisynq.io"
  exit 1
fi

if [ -z "$WALLET_ADDRESS" ]; then
  log_error "Wallet Address is required but not configured"
  log_error "Please fill in your Wallet Address in the Home Assistant addon configuration"
  log_error "This is where you'll receive your rewards"
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
