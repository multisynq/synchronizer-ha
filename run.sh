#!/bin/bash

echo "=== Multisynq Synchronizer Starting ==="
echo "$(date): Script started"

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
        DEPIN_ENDPOINT="wss://api.multisynq.io/depin"
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
    DEPIN_ENDPOINT="wss://api.multisynq.io/depin"
fi

echo "Configuration values:"
echo "  SYNQ_KEY: ${SYNQ_KEY:0:8}... (${#SYNQ_KEY} chars)"
echo "  WALLET_ADDRESS: ${WALLET_ADDRESS}"
echo "  SYNC_NAME: ${SYNC_NAME}"
echo "  DEPIN_ENDPOINT: ${DEPIN_ENDPOINT}"

# Validate required values
if [ -z "$SYNQ_KEY" ]; then
    log_error "synq_key is required but not set"
    echo "Please configure synq_key in the addon configuration"
    exit 1
fi

if [ -z "$WALLET_ADDRESS" ]; then
    log_error "wallet_address is required but not set"
    echo "Please configure wallet_address in the addon configuration"
    exit 1
fi

log_info "Starting Multisynq Synchronizer..."
log_info "Sync Name: ${SYNC_NAME}"
log_info "Wallet: ${WALLET_ADDRESS}"
log_info "DePIN Endpoint: ${DEPIN_ENDPOINT}"

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
