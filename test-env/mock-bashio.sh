#!/bin/bash
# Mock bashio for local testing
# This simulates the bashio commands used in Home Assistant addons

# Mock config file path
CONFIG_FILE="/data/options.json"

# Create mock config if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p /data
    cat > "$CONFIG_FILE" << EOF
{
  "synq_key": "${SYNQ_KEY:-}",
  "wallet_address": "${WALLET_ADDRESS:-}",
  "sync_name": "${SYNC_NAME:-homeassistant-addon}",
  "depin_endpoint": "${DEPIN_ENDPOINT:-wss://api.multisynq.io/depin}"
}
EOF
fi

# Mock bashio::config function
bashio::config() {
    local key="$1"
    local default="$2"
    
    # Use jq to parse the config file
    if command -v jq >/dev/null 2>&1 && [ -f "$CONFIG_FILE" ]; then
        local value
        value=$(jq -r ".${key} // empty" "$CONFIG_FILE" 2>/dev/null)
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
        else
            echo "${default:-}"
        fi
    else
        # Fallback if jq is not available
        echo "${default:-}"
    fi
}

# Mock bashio logging functions
bashio::log.info() {
    echo "[INFO] $*"
}

bashio::log.error() {
    echo "[ERROR] $*" >&2
}

bashio::log.warning() {
    echo "[WARNING] $*"
}

bashio::log.debug() {
    echo "[DEBUG] $*"
}

# If called directly, export functions for sourcing
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Being executed directly
    if [ $# -gt 0 ]; then
        echo "Mock bashio executed with args: $*"
    fi
    export -f bashio::config
    export -f bashio::log.info
    export -f bashio::log.error
    export -f bashio::log.warning
    export -f bashio::log.debug
else
    # Being sourced - just make functions available
    : # No-op when sourced
fi
