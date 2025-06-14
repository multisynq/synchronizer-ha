#!/usr/bin/with-contenv bashio

# Exit on error
set -e

# Enable bashio logging
bashio::log.info "Starting Multisynq Synchronizer Add-on..."

# Get configuration
SYNQ_KEY=$(bashio::config 'synq_key')
WALLET_ADDRESS=$(bashio::config 'wallet_address')
SYNC_NAME=$(bashio::config 'sync_name')
AUTO_START=$(bashio::config 'auto_start')

# Web Dashboard configuration
ENABLE_WEB_DASHBOARD=$(bashio::config 'web_dashboard.enable')
DASHBOARD_PORT=$(bashio::config 'web_dashboard.port')
METRICS_PORT=$(bashio::config 'web_dashboard.metrics_port')
DASHBOARD_PASSWORD=$(bashio::config 'web_dashboard.password')

# Advanced configuration
LOG_LEVEL=$(bashio::config 'advanced.log_level')

# Check required configuration
if [[ -z "$SYNQ_KEY" ]]; then
    bashio::log.fatal "Synq key is required! Please configure it in the add-on settings."
    exit 1
fi

if [[ -z "$WALLET_ADDRESS" ]]; then
    bashio::log.fatal "Wallet address is required! Please configure it in the add-on settings."
    exit 1
fi

# Set log level
bashio::log.level "$LOG_LEVEL"

# Create config directory if it doesn't exist
mkdir -p /data/synchronizer-cli

# Set HOME to data directory so config is persistent
export HOME=/data

# Create configuration file
bashio::log.info "Creating synchronizer configuration..."
cat > /data/.synchronizer-cli/config.json << EOF
{
  "userName": "$SYNC_NAME",
  "key": "$SYNQ_KEY",
  "wallet": "$WALLET_ADDRESS",
  "secret": "$(openssl rand -hex 32)",
  "hostname": "$(hostname)",
  "syncHash": "$(echo -n "${SYNQ_KEY}${WALLET_ADDRESS}" | sha256sum | cut -d' ' -f1)",
  "depin": "wss://api.multisynq.io/depin",
  "launcher": "homeassistant-addon"
}
EOF

bashio::log.info "Configuration created successfully"

# Validate the synq key
bashio::log.info "Validating synq key..."
if ! synchronize validate-key "$SYNQ_KEY"; then
    bashio::log.error "Invalid synq key provided!"
    exit 1
fi

bashio::log.info "Synq key validated successfully"

# Check if auto start is enabled
if [[ "$AUTO_START" != "true" ]]; then
    bashio::log.info "Auto start is disabled. Synchronizer will not start automatically."
    bashio::log.info "You can manually start it through the web dashboard if enabled."
fi

# Start the synchronizer container in background (if auto start is enabled)
if [[ "$AUTO_START" == "true" ]]; then
    bashio::log.info "Starting synchronizer container..."
    synchronize start &
    SYNC_PID=$!
    
    # Wait a moment for the synchronizer to start
    sleep 10
else
    SYNC_PID=""
    bashio::log.info "Synchronizer not started automatically (auto_start disabled)"
fi

# Check if web dashboard should be enabled
if [[ "$ENABLE_WEB_DASHBOARD" == "true" ]]; then
    # Build web dashboard command
    WEB_CMD="synchronize web --port $DASHBOARD_PORT --metrics-port $METRICS_PORT"

    # Add password if configured
    if [[ -n "$DASHBOARD_PASSWORD" ]]; then
        bashio::log.info "Setting dashboard password..."
        echo "$DASHBOARD_PASSWORD" | synchronize set-password
        WEB_CMD="$WEB_CMD --password"
    fi

    # Start the web dashboard
    bashio::log.info "Starting web dashboard on port $DASHBOARD_PORT..."
    bashio::log.info "Metrics API available on port $METRICS_PORT"
    $WEB_CMD &
    WEB_PID=$!
else
    WEB_PID=""
    bashio::log.info "Web dashboard disabled in configuration"
fi

# Function to handle shutdown
shutdown() {
    bashio::log.info "Shutting down synchronizer..."
    if [[ -n "$SYNC_PID" ]]; then
        kill $SYNC_PID 2>/dev/null || true
    fi
    if [[ -n "$WEB_PID" ]]; then
        kill $WEB_PID 2>/dev/null || true
    fi
    exit 0
}

# Trap signals
trap shutdown SIGTERM SIGINT

# Wait for processes
bashio::log.info "Multisynq Synchronizer add-on is running!"
if [[ "$ENABLE_WEB_DASHBOARD" == "true" ]]; then
    bashio::log.info "Dashboard available at http://[HOST]:$DASHBOARD_PORT"
    bashio::log.info "Metrics API available at http://[HOST]:$METRICS_PORT"
fi
if [[ "$AUTO_START" == "true" ]]; then
    bashio::log.info "Synchronizer container is running"
else
    bashio::log.info "Synchronizer container not started (auto_start disabled)"
fi

# Keep the script running and monitor processes
while true; do
    # Check if synchronizer process is still running (only if auto start is enabled)
    if [[ "$AUTO_START" == "true" ]] && [[ -n "$SYNC_PID" ]] && ! kill -0 $SYNC_PID 2>/dev/null; then
        bashio::log.error "Synchronizer process died, restarting..."
        synchronize start &
        SYNC_PID=$!
        sleep 10
    fi
    
    # Check if web dashboard is still running (only if enabled)
    if [[ "$ENABLE_WEB_DASHBOARD" == "true" ]] && [[ -n "$WEB_PID" ]] && ! kill -0 $WEB_PID 2>/dev/null; then
        bashio::log.error "Web dashboard died, restarting..."
        $WEB_CMD &
        WEB_PID=$!
        sleep 5
    fi
    
    sleep 30
done