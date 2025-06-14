# Multisynq Synchronizer Add-on

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield] ![Supports i386 Architecture][i386-shield]

Run a Multisynq Synchronizer through your Home Assistant instance to participate in DePIN (Decentralized Physical Infrastructure Networks) and earn rewards.

## About

This add-on enables you to run a Multisynq Synchronizer directly from your Home Assistant instance, allowing you to participate in DePIN networks and earn rewards by contributing your internet connection and computational resources.

### Features

- 🚀 **Easy Setup**: Simple configuration through Home Assistant UI
- 🔧 **Docker Management**: Automatic Docker container management
- 🌐 **Web Dashboard**: Real-time monitoring with performance metrics
- 📊 **Quality of Service Monitoring**: Visual QoS indicators with color-coded status
- 🔐 **Secure Configuration**: Encrypted credential storage
- 📈 **Performance Metrics**: Traffic monitoring, session tracking, and user analytics
- 🔄 **Auto-restart**: Automatic process monitoring and restart capabilities

## Installation

1. Add this repository to your Home Assistant Supervisor
2. Install the "Multisynq Synchronizer" add-on
3. Configure your Synq key and wallet address (see Configuration section)
4. Start the add-on

## Configuration

### Required Settings

- **synq_key**: Your Synq key from the Multisynq platform (required)
- **wallet_address**: Your wallet address for receiving rewards (required)

### Optional Settings

- **sync_name**: A friendly name for your synchronizer instance (default: "Home Assistant Sync")
- **enable_web_dashboard**: Enable the web dashboard for monitoring (default: true)
- **dashboard_port**: Port for the web dashboard (default: 3000, only if web dashboard enabled)
- **metrics_port**: Port for the metrics API (default: 3001, only if web dashboard enabled)
- **dashboard_password**: Password to protect the web dashboard (optional)
- **auto_start**: Automatically start the synchronizer when the add-on starts (default: true)
- **log_level**: Logging level (debug, info, warning, error - default: info)

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

## Getting Your Credentials

1. **Synq Key**: Visit the Multisynq platform to obtain your Synq key
2. **Wallet Address**: Use your cryptocurrency wallet address where you want to receive rewards

## Usage

Once configured and started:

1. **Web Dashboard**: Access the monitoring dashboard at `http://[your-ha-ip]:3000`
2. **Metrics API**: Access raw metrics at `http://[your-ha-ip]:3001/metrics`
3. **Health Check**: Check health status at `http://[your-ha-ip]:3001/health`

### Dashboard Features

- **Performance Metrics**: Real-time traffic, sessions, and user monitoring
- **Quality of Service**: Visual QoS scoring with color-coded indicators
- **System Information**: Service status and configuration details
- **API Documentation**: Built-in endpoint documentation
- **Live Logs**: Real-time system logs with syntax highlighting

### API Endpoints

#### Dashboard Server (Port 3000)
- `GET /` - Main dashboard interface
- `GET /api/status` - System and service status JSON
- `GET /api/logs` - Recent system logs JSON
- `GET /api/performance` - Performance metrics and QoS data

#### Metrics Server (Port 3001)
- `GET /metrics` - Comprehensive system metrics JSON
- `GET /health` - Health check endpoint

## Support

For issues related to:
- **Add-on functionality**: Open an issue in the [GitHub repository](https://github.com/multisynq/synchronizer-ha)
- **Synchronizer CLI**: Visit the [official repository](https://github.com/multisynq/synchronizer-cli)

## Changelog & Releases

### 1.0.0
- Initial release
- Full synchronizer-cli integration
- Web dashboard with real-time monitoring
- Automatic process management and restart
- Persistent configuration storage

## License

This add-on is licensed under the Apache-2.0 license.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
