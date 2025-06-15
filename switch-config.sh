#!/bin/bash

# Script to switch between local and production addon configurations

ADDON_DIR="$(dirname "$0")"
CONFIG_FILE="$ADDON_DIR/config.yaml"
LOCAL_CONFIG="$ADDON_DIR/config.local.yaml"
PRODUCTION_CONFIG="$ADDON_DIR/config.production.yaml"

usage() {
    echo "Usage: $0 [local|production]"
    echo "  local      - Use local build configuration (builds from Dockerfile)"
    echo "  production - Use production configuration (pulls from ghcr.io)"
    echo ""
    echo "Current configuration:"
    if grep -q "^image:" "$CONFIG_FILE" 2>/dev/null && ! grep -q "^# image:" "$CONFIG_FILE" 2>/dev/null; then
        echo "  Mode: production (pulls from registry)"
    else
        echo "  Mode: local (builds from Dockerfile)"
    fi
}

case "$1" in
    "local")
        if [ -f "$PRODUCTION_CONFIG" ]; then
            # Create local config by commenting out the image line
            sed 's/^image:/#image:/' "$PRODUCTION_CONFIG" > "$CONFIG_FILE"
            echo "Switched to local build configuration"
            echo "Home Assistant will now build the addon from the local Dockerfile"
        else
            echo "Error: config.production.yaml not found"
            exit 1
        fi
        ;;
    "production")
        if [ -f "$PRODUCTION_CONFIG" ]; then
            cp "$PRODUCTION_CONFIG" "$CONFIG_FILE"
            echo "Switched to production configuration"
            echo "Home Assistant will now pull the addon image from ghcr.io"
        else
            echo "Error: config.production.yaml not found"
            exit 1
        fi
        ;;
    *)
        usage
        exit 1
        ;;
esac
