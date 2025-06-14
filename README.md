# Multisynq Synchronizer Home Assistant Add-on

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

## About

Multisynq is a decentralized physical infrastructure (DePIN) network that allows you to earn rewards by contributing your unused bandwidth.

Visit [multisynq.io](https://multisynq.io) to learn more about the platform, get your API key, and join the network.

## Installation

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fmultisynq%2Fsynchronizer-ha)

## Configuration

After installing the add-on, you need to configure it with your Multisynq credentials:

1. Go to the add-on configuration tab
2. Fill in your **Synq Key** (get this from [https://startsynqing.com/](https://startsynqing.com/))
3. Fill in your **Wallet Address** (for receiving rewards)
4. Optionally, set a custom **Sync Name** for your synchronizer
5. Save the configuration and start the add-on

The add-on will not start without a valid API key and wallet address.


## Support

For issues and support: [Open a Ticket](https://github.com/multisynq/synchronizer-ha/issues)

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg


## Manual Testing
```
docker build -f Dockerfile.test -t multisynq-synchronizer:test-with-bashio .
docker run --rm -e SYNQ_KEY="..." -e WALLET_ADDRESS="..." -e SYNC_NAME="..." multisynq-synchronizer:test-with-bashio