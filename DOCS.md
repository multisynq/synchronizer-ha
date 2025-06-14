# Home Assistant Add-on: Multisynq Synchronizer

_Run a Multisynq Synchronizer through your Home Assistant instance to participate in DePIN networks and earn rewards._

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fmultisynq%2Fsynchronizer-ha)

## About

Multisynq Synchronizer is a DePIN (Decentralized Physical Infrastructure Networks) node that allows you to participate in distributed computing networks and earn rewards. This Home Assistant add-on makes it easy to run a Multisynq Synchronizer directly from your Home Assistant instance.

### Features

- Easy setup through Home Assistant UI
- Automatic configuration management
- Web interface for monitoring (port 3333)
- Metrics endpoint for monitoring (port 9090)
- Supports multiple architectures (amd64, aarch64)

## Installation

1. Navigate in your Home Assistant frontend to **Settings** → **Add-ons** → **Add-on Store**.
2. Click the 3-dots menu at upper right **⋮** → **Repositories** and add this repository URL: `https://github.com/multisynq/synchronizer-ha`
3. Find the "Multisynq Synchronizer" add-on and click it.
4. Click on the "INSTALL" button.

## How to use

1. Configure your Synq Key and Wallet Address in the add-on configuration
2. Start the add-on
3. Access the web interface at `http://your-ha-ip:3333`
4. Monitor metrics at `http://your-ha-ip:9090`

## Configuration

Add-on configuration:

```yaml
synq_key: "your-synq-key-here"
wallet_address: "your-wallet-address-here"  
sync_name: "Home Assistant Synchronizer"
```

### Option: `synq_key`

Your Synq API key for authentication with the Multisynq network.

### Option: `wallet_address`

Your wallet address for receiving rewards.

### Option: `sync_name`

A custom name for your synchronizer node (optional).

## Support

Got questions?

- [Open an issue on GitHub][issue]
- [Community Forums][forum]

## Authors & contributors

The original setup of this repository is by [Miguel Matos][maintainer].

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
