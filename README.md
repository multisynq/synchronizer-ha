# Multisynq Synchronizer Home Assistant Add-on

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

## About

Multisynq is a decentralized physical infrastructure (DePIN) network that allows you to earn rewards by contributing your unused bandwidth.

This Home Assistant add-on makes it easy to run a Multisynq synchronizer and monitor your earnings directly from your Home Assistant dashboard.

## Quick Start

1. **Get Your Credentials**
   - Visit [startsynqing.com](https://startsynqing.com/) to get your Synq Key
   - Have your wallet address ready for receiving rewards

2. **Install the Add-on**
   
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fmultisynq%2Fsynchronizer-ha)

3. **Configure**
   - Enter your **Synq Key** 
   - Enter your **Wallet Address**
   - Save and start the add-on

4. **Monitor**
   - Click "OPEN WEB UI" to view your earnings dashboard
   - Check the add-on logs for status updates

## Configuration Options

| Option | Required | Description |
|--------|----------|-------------|
| `synq_key` | Yes | Your API key from startsynqing.com |
| `wallet_address` | Yes | Your wallet address for receiving rewards |
| `lite_mode` | No | Enable for minimal resource usage (disables web dashboard) |

## Need Help?

- Check the add-on logs for troubleshooting information
- Visit [multisynq.io](https://multisynq.io) for platform documentation
- Review the [DOCS.md](DOCS.md) file for detailed technical information

This add-on includes a built-in web dashboard that provides real-time status monitoring:

- 🌐 **Real-time Status**: See if your synchronizer is online and actively syncing
- 🏷️ **Synchronizer Details**: View your synchronizer name, wallet address, and uptime
- 📊 **Live Metrics**: Monitor active sessions, connected users, and traffic statistics
- 💰 **Reward Tracking**: View sync life points, wallet life points, and lifetime traffic
- 🔗 **Connection Status**: Monitor proxy connection state and WebSocket connectivity
- ⏱️ **Performance Metrics**: Track uptime, availability, reliability, and efficiency
- 🔄 **Auto-refresh**: Dashboard updates automatically every 60 seconds with manual refresh option
- 🚀 **Direct Access**: Click "OPEN WEB UI" in the Home Assistant add-on interface

### API Endpoints

The web dashboard also provides API endpoints for integration:

- **Configuration API**: `http://<your-ha-ip>:8099/api/config` - Returns current synchronizer configuration
- **Debug API**: `http://<your-ha-ip>:8099/api/debug` - Provides detailed system information for troubleshooting

### Enhanced Logging

The add-on features emoji-enhanced logging for improved readability:

- 🚀 Startup and process launch messages
- ✅ Successful operations and configurations
- ❌ Error conditions and failures
- ⚠️ Warning messages and potential issues
- ℹ️ General information and status updates
- 🔧 Configuration operations and loading
- 📄 File operations and path checking
- 🌐 Network operations and connections

This makes it easy to quickly scan logs and identify different types of messages at a glance.

## Development

### Local vs Production Configuration

This addon supports two configuration modes:

#### Local Development Mode (Default)
- Builds the Docker image locally from the `Dockerfile`
- Uses the current `config.yaml` configuration 
- No need to fetch from Docker registry

#### Production Mode
- Pulls pre-built images from `ghcr.io/multisynq/{arch}-synchronizer-ha`
- Used for published addon versions

### Switching Between Modes

Use the provided script to switch configurations:

```bash
# Switch to local development mode (builds from Dockerfile)
./switch-config.sh local

# Switch to production mode (pulls from registry)
./switch-config.sh production

# Check current mode
./switch-config.sh
```

When developing locally, the addon will automatically build from your local `Dockerfile` without needing to fetch from the GitHub Container Registry.

## Manual Testing (Dev/Debug only)
```
docker build -f Dockerfile.test -t multisynq-synchronizer:test-with-bashio .
docker run --rm -e SYNQ_KEY="..." -e WALLET_ADDRESS="..." multisynq-synchronizer:test-with-bashio
````

## Support

For issues and support: [Open a Ticket](https://github.com/multisynq/synchronizer-ha/issues)

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
