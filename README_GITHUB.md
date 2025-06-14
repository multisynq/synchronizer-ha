# Multisynq Synchronizer Home Assistant Add-on

[![GitHub Release][releases-shield]][releases]
[![GitHub Activity][commits-shield]][commits]
[![License][license-shield]](LICENSE)

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armhf Architecture][armhf-shield]
![Supports armv7 Architecture][armv7-shield]
![Supports i386 Architecture][i386-shield]

Run a Multisynq Synchronizer through your Home Assistant instance to participate in DePIN (Decentralized Physical Infrastructure Networks) and earn rewards.

## About

This Home Assistant add-on enables you to run a Multisynq Synchronizer directly from your Home Assistant instance. By contributing your internet connection and computational resources to the Multisynq DePIN network, you can earn rewards while supporting decentralized infrastructure.

## Installation

### Method 1: Add Repository to Home Assistant

1. In Home Assistant, navigate to **Supervisor** → **Add-on Store**
2. Click the menu (⋮) in the top right corner
3. Select **Repositories**
4. Add this repository URL: `https://github.com/multisynq/synchronizer-ha`
5. Click **Add**
6. Find "Multisynq Synchronizer" in the store and click **Install**

### Method 2: Manual Installation

1. Clone this repository to your Home Assistant add-ons directory:
   ```bash
   cd /usr/share/hassio/addons/local/
   git clone https://github.com/multisynq/synchronizer-ha.git
   ```
2. Restart Home Assistant Supervisor
3. The add-on will appear in the Local Add-ons section

## Configuration

### Required Settings

You must configure these settings before starting the add-on:

- **synq_key**: Your Synq key from the Multisynq platform
- **wallet_address**: Your cryptocurrency wallet address for receiving rewards

### Optional Settings

- **sync_name**: Friendly name for your synchronizer instance
- **enable_web_dashboard**: Enable web dashboard for monitoring (default: true)
- **dashboard_port**: Port for the web dashboard (default: 3000)
- **metrics_port**: Port for the metrics API (default: 3001)
- **dashboard_password**: Password to protect dashboard access
- **auto_start**: Automatically start synchronizer on add-on start (default: true)
- **log_level**: Logging verbosity level (default: info)

### Example Configuration

```yaml
synq_key: "your-synq-key-here"
wallet_address: "your-wallet-address-here"
sync_name: "My Home Assistant Sync"
enable_web_dashboard: true
dashboard_port: 3000
metrics_port: 3001
dashboard_password: "secure-password"
auto_start: true
log_level: "info"
```

## Usage

1. **Configure**: Add your Synq key and wallet address in the add-on configuration
2. **Start**: Start the add-on from the Supervisor interface
3. **Monitor**: Access the web dashboard at `http://[your-ha-ip]:3000` (if enabled)
4. **Earn**: Your synchronizer will contribute to the DePIN network and earn rewards

## Features

- 🚀 **Easy Setup**: Simple configuration through Home Assistant UI
- 🔧 **Automatic Management**: Built-in process monitoring and restart capabilities
- 🌐 **Web Dashboard**: Real-time monitoring with performance metrics
- 📊 **Quality of Service**: Visual QoS indicators with color-coded status
- 🔐 **Secure Configuration**: Encrypted credential storage
- 📈 **Performance Metrics**: Traffic monitoring, session tracking, and user analytics
- 🏗️ **Multi-Architecture**: Support for ARM and x86 platforms
- ⚙️ **Flexible Configuration**: Enable/disable features as needed

## Documentation

- [Installation Guide](INSTALL.md) - Detailed installation and setup instructions
- [Configuration Reference](DOCS.md) - Complete configuration documentation
- [Changelog](CHANGELOG.md) - Version history and updates

## Support

For support and questions:

- **Add-on Issues**: [Open an issue](https://github.com/multisynq/synchronizer-ha/issues) in this repository
- **Synchronizer CLI**: Visit the [official synchronizer-cli repository](https://github.com/multisynq/synchronizer-cli)

## Contributing

Contributions are welcome! Please feel free to submit pull requests, report bugs, or suggest new features.

## License

This project is licensed under the Apache-2.0 License - see the [LICENSE](LICENSE) file for details.

## Maintainer

**Miguel Matos**  
Email: miguel.matos@multisynq.io  
GitHub: [@multisynq](https://github.com/multisynq)

---

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
[commits-shield]: https://img.shields.io/github/commit-activity/y/multisynq/synchronizer-ha.svg
[commits]: https://github.com/multisynq/synchronizer-ha/commits/main
[license-shield]: https://img.shields.io/github/license/multisynq/synchronizer-ha.svg
[releases-shield]: https://img.shields.io/github/release/multisynq/synchronizer-ha.svg
[releases]: https://github.com/multisynq/synchronizer-ha/releases
