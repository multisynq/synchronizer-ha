# Multisynq Synchronizer Home Assistant Add-on

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

✅ **Status: External Docker Image Approach (v1.1.0)**

This add-on now uses the official `cdrakep/synqchronizer` Docker image directly, providing a more reliable and up-to-date synchronizer experience.

## About

Run a Multisynq Synchronizer through your Home Assistant instance to participate in DePIN networks and earn rewards. This add-on leverages the official synchronizer Docker image maintained by the Multisynq team.

## Installation

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fmultisynq%2Fsynchronizer-ha)

**Or manually:**
1. In Home Assistant, go to **Supervisor** → **Add-on Store**
2. Click the menu (⋮) and select **Repositories**
3. Add: `https://github.com/multisynq/synchronizer-ha`
4. Install "Multisynq Synchronizer"

## Configuration

**Required:**
- `Synq Key`: Your Synq key from Multisynq
- `Wallet Address`: Your wallet address for rewards

**Optional:**
- `Sync Name`: Friendly name for your synchronizer (default: "homeassistant-addon")
- `DePIN Endpoint`: DePIN network endpoint (default: "wss://api.multisynq.io/depin")

## Features

- **External Docker Image**: Uses the official `cdrakep/synqchronizer:latest` image
- **Proper Argument Passing**: Passes configuration as command-line arguments as expected by the synchronizer
- **Port Mapping**: Exposes ports 3333 (WebSocket CLI) and 9090 (HTTP metrics)
- **Automatic Updates**: Benefits from updates to the official Docker image

## How It Works

This add-on:
1. Uses the official `cdrakep/synqchronizer:latest` Docker image as a base
2. Maps Home Assistant configuration options to synchronizer command-line arguments
3. Starts the synchronizer with the proper arguments: `--depin`, `--sync-name`, `--launcher`, `--key`, `--wallet`

## Logs and Monitoring

- Check the add-on logs for synchronizer status and connection information
- Port 3333 is exposed for WebSocket CLI communication
- Port 9090 is exposed for HTTP metrics (if supported by the synchronizer)

## Troubleshooting

1. **Check logs**: View add-on logs for connection and startup issues
2. **Verify configuration**: Ensure synq_key and wallet_address are correctly set
3. **Network connectivity**: Ensure Home Assistant can reach the DePIN endpoint

## Getting Your Synq Key

1. Visit [multisynq.io](https://multisynq.io) to get your Synq key
2. You'll also need a cryptocurrency wallet address for rewards

## Example Configuration

```yaml
synq_key: "your-synq-key-here"
wallet_address: "your-wallet-address-here"
sync_name: "my-homeassistant-sync"
depin_endpoint: "wss://api.multisynq.io/depin"
```

## Support

For issues and support:
- **GitHub Issues**: [multisynq/synchronizer-ha](https://github.com/multisynq/synchronizer-ha/issues)
- **CLI Documentation**: [synchronizer-cli repository](https://github.com/multisynq/synchronizer-cli)
- **Platform**: [multisynq.io](https://multisynq.io)

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg


## Manual Testing
```
docker build -f Dockerfile.test -t multisynq-synchronizer:test-with-bashio .
docker run --rm -e SYNQ_KEY="..." -e WALLET_ADDRESS="..." -e SYNC_NAME="..." multisynq-synchronizer:test-with-bashio
```