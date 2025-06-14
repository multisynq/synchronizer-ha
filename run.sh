#!/usr/bin/with-contenv bashio

set -e

bashio::log.info "Starting Multisynq Synchronizer Add-on..."

# Get required configuration from Home Assistant
SYNQ_KEY=$(bashio::config 'synq_key')
WALLET_ADDRESS=$(bashio::config 'wallet_address')
SYNC_NAME=$(bashio::config 'sync_name' 'Home Assistant Sync')

# Validate required configuration
if [[ -z "$SYNQ_KEY" ]]; then
    bashio::log.fatal "SYNQ_KEY is required! Please configure it in the add-on options."
    exit 1
fi

if [[ -z "$WALLET_ADDRESS" ]]; then
    bashio::log.fatal "WALLET_ADDRESS is required! Please configure it in the add-on options."
    exit 1
fi

bashio::log.info "Configuration loaded successfully"
bashio::log.info "Sync Name: $SYNC_NAME"

# Set working directory
cd /data

# Verify synchronizer-cli installation
bashio::log.info "Verifying synchronizer-cli installation..."
if ! command -v synchronize &> /dev/null; then
    bashio::log.fatal "synchronize command not found! Installation may have failed."
    exit 1
fi

bashio::log.info "Synchronizer CLI version: $(synchronize --version)"

# Deploy synchronizer using the official one-command deployment
bashio::log.info "Starting synchronizer with deploy command..."
synchronize deploy --key "$SYNQ_KEY" --wallet "$WALLET_ADDRESS" --name "$SYNC_NAME"

