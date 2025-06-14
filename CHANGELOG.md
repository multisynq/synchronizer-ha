# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-06-14

### Added
- Initial release of Multisynq Synchronizer Home Assistant Add-on
- Integration with synchronizer-cli package (v2.6.1+)
- Web dashboard with real-time monitoring on configurable port (default: 3000)
- Metrics API server on configurable port (default: 3001)
- Support for all major architectures (amd64, aarch64, armv7, armhf, i386)
- Configurable sync name, dashboard password, and logging levels
- Automatic process monitoring and restart capabilities
- Persistent configuration storage in Home Assistant data directory
- Quality of Service (QoS) monitoring with color-coded indicators
- Performance metrics tracking (traffic, sessions, users)
- Secure credential handling with encrypted storage
- Docker container management for synchronizer process
- Health check endpoints for monitoring integration
- Comprehensive error handling and logging

### Features
- **Easy Configuration**: Simple setup through Home Assistant UI
- **Real-time Dashboard**: Live monitoring with performance metrics
- **API Integration**: RESTful APIs for status, metrics, and logs
- **Security**: Password protection for dashboard access
- **Monitoring**: Automatic service health checks and restarts
- **Multi-platform**: Support for ARM and x86 architectures
- **Persistent Data**: Configuration survives add-on restarts

### Configuration Options
- `synq_key`: Required Synq key from Multisynq platform
- `wallet_address`: Required wallet address for rewards
- `sync_name`: Optional friendly name (default: "Home Assistant Sync")
- `dashboard_port`: Dashboard port (default: 3000)
- `metrics_port`: Metrics API port (default: 3001)
- `dashboard_password`: Optional dashboard password protection
- `log_level`: Logging verbosity (debug|info|warning|error)
