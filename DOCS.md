# Home Assistant Add-on: Multisynq Synchronizer

_Run a Multisynq Synchronizer through your Home Assistant instance to participate in DePIN networks and earn rewards._

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fmultisynq%2Fsynchronizer-ha)

## About

Multisynq Synchronizer is a DePIN (Decentralized Physical Infrastructure Network) node that allows you to participate in the network and earn rewards. This Home Assistant add-on makes it easy to run a Multisynq Synchronizer directly from your Home Assistant instance.

### Features

- 🚀 Easy setup through Home Assistant UI
- 🔧 Automatic configuration management
- 🌐 Built-in web dashboard with real-time stats
- 📊 WebSocket connectivity for live monitoring
- 🏷️ Persistent synchronizer naming
- 💰 Wallet integration for reward tracking
- ⚡ Lite mode support for minimal resource usage
- 🐛 Debug endpoints for troubleshooting
- 🎨 Enhanced logging with emoji indicators
- 📱 Supports multiple architectures (amd64, aarch64)

## Installation

1. Navigate in your Home Assistant frontend to **Settings** → **Add-ons** → **Add-on Store**.
2. Click the 3-dots menu at upper right **⋮** → **Repositories** and add this repository URL: `https://github.com/multisynq/synchronizer-ha`
3. Find the "Multisynq Synchronizer" add-on and click it.
4. Click on the "INSTALL" button.

## How to use

1. Configure your Synq Key and Wallet Address in the add-on configuration
2. Start the add-on
3. Access the web dashboard at `http://<your-ha-ip>:8099` (full mode only)
4. Monitor your synchronizer's performance and earnings

### Web Dashboard

When running in full mode, the add-on provides a web dashboard that displays:

- 🏷️ Synchronizer name and status
- 💰 Wallet address and reward information
- 📊 Active sessions and connected users
- 📈 Traffic statistics and lifetime points
- 🔗 Proxy connection status
- ⏱️ Uptime and performance metrics

The dashboard connects to the synchronizer via WebSocket on port 3333 for real-time updates.

### Lite Mode

Enable lite mode in the configuration to run the synchronizer without the web dashboard, using minimal resources.

## Configuration

### Option: `synq_key` (required)

Your Synq API key for authentication with the Multisynq network.

**Note:** Get your API key from [https://multisynq.io](https://multisynq.io)

### Option: `wallet_address` (required)

Your wallet address for receiving rewards. This is where your earned tokens will be sent.

### Option: `lite_mode` (optional)

Enable lite mode to run the synchronizer without the web dashboard, using minimal system resources.

- Default: `false`
- Set to `true` for minimal resource usage

## API Endpoints

When running in full mode, the add-on provides several API endpoints:

### Configuration API
- **URL:** `http://<your-ha-ip>:8099/api/config`
- **Method:** GET
- **Description:** Returns the current synchronizer configuration

### Debug API
- **URL:** `http://<your-ha-ip>:8099/api/debug`
- **Method:** GET
- **Description:** Returns detailed system information for troubleshooting

## Logging

The add-on uses enhanced logging with emoji indicators for easy identification:

- 🚀 Startup and launch messages
- ✅ Success operations
- ❌ Error conditions
- ⚠️ Warning messages
- ℹ️ Informational messages
- 🔧 Configuration operations
- 📄 File operations
- 🌐 Network operations

## Troubleshooting

### Check Configuration
1. Verify your `synq_key` and `wallet_address` are correctly set
2. Use the debug API endpoint to check system status
3. Review the add-on logs for any error messages

### Dashboard Not Loading
1. Ensure the add-on is running in full mode (not lite mode)
2. Check that port 8099 is accessible from your network
3. Verify the synchronizer is running and WebSocket port 3333 is available

### Connection Issues
1. Check your network connectivity
2. Verify firewall settings allow outbound connections
3. Review the logs for connection error messages

## Support

Got questions?

- [Open an issue on GitHub][issue]
- [Community Forums][forum]

## Authors & contributors

The original setup of this repository is by [Miguel Matos @multisynq][maintainer].

## License

MIT License

Copyright (c) 2025 Multisynq

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[forum]: https://community.home-assistant.io
[issue]: https://github.com/multisynq/synchronizer-ha/issues
[maintainer]: https://github.com/multisynq
