# Multisynq Synchronizer Add-on Documentation

## Overview

The Multisynq Synchronizer add-on enables you to run a Multisynq Synchronizer directly from your Home Assistant instance, allowing you to participate in DePIN (Decentralized Physical Infrastructure Networks) and earn rewards by contributing your internet connection and computational resources.

## What is Multisynq?

Multisynq is a DePIN platform that allows users to earn rewards by contributing their internet connection and computational resources to a decentralized network. The synchronizer acts as a bridge between your local resources and the global Multisynq network.

## Prerequisites

Before installing this add-on, you'll need:

1. **Synq Key**: Obtain from the Multisynq platform after registration
2. **Wallet Address**: A cryptocurrency wallet address to receive rewards
3. **Stable Internet Connection**: Required for network participation
4. **Home Assistant Supervisor**: This is a Supervisor add-on

## Installation Steps

### 1. Add Repository
If you haven't already, add this repository to your Home Assistant Supervisor:

1. Go to **Supervisor** → **Add-on Store**
2. Click the menu (three dots) → **Repositories**
3. Add the repository URL: `https://github.com/multisynq/synchronizer-ha`
4. Click **Add**

### 2. Install Add-on
1. Find "Multisynq Synchronizer" in the add-on store
2. Click **Install**
3. Wait for installation to complete

### 3. Configure
1. Go to the **Configuration** tab
2. Fill in required fields:
   - **Synq Key**: Your key from Multisynq platform
   - **Wallet Address**: Your reward wallet address
3. Optionally configure:
   - **Sync Name**: Friendly name for identification
   - **Dashboard Port**: Default 3000
   - **Metrics Port**: Default 3001
   - **Dashboard Password**: For access protection
   - **Log Level**: Debugging verbosity

### 4. Start the Add-on
1. Go to the **Info** tab
2. Click **Start**
3. Check the **Log** tab for startup messages

## Configuration Reference

### Required Configuration

```yaml
synq_key: "your-synq-key-from-multisynq"
wallet_address: "your-crypto-wallet-address"
```

### Complete Configuration Example

```yaml
synq_key: "sk_1234567890abcdef..."
wallet_address: "0x1234567890123456789012345678901234567890"
sync_name: "Home Studio Synchronizer"
enable_web_dashboard: true
dashboard_port: 3000
metrics_port: 3001
dashboard_password: "MySecurePassword123"
auto_start: true
log_level: "info"
```

### Configuration Options Explained

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `synq_key` | string | *required* | Your unique Synq key from Multisynq platform |
| `wallet_address` | string | *required* | Wallet address for receiving rewards |
| `sync_name` | string | "Home Assistant Sync" | Friendly name for your synchronizer |
| `enable_web_dashboard` | boolean | true | Enable web dashboard for monitoring |
| `dashboard_port` | integer | 3000 | Port for web dashboard (1024-65535) |
| `metrics_port` | integer | 3001 | Port for metrics API (1024-65535) |
| `dashboard_password` | password | *none* | Optional password protection |
| `auto_start` | boolean | true | Automatically start synchronizer on add-on start |
| `log_level` | list | "info" | Logging level (debug/info/warning/error) |

## Using the Web Dashboard

### Accessing the Dashboard

Once the add-on is running, access the dashboard at:
```
http://[your-home-assistant-ip]:[dashboard_port]
```

Default URL: `http://[your-home-assistant-ip]:3000`

### Dashboard Features

#### Performance Metrics
- **Total Traffic**: Cumulative data transfer with smart formatting
- **Active Sessions**: Real-time session count
- **Traffic Rates**: Live incoming/outgoing traffic rates
- **User Count**: Connected users tracking

#### Quality of Service (QoS)
- **Overall Score**: Circular progress indicator with color coding:
  - 🟢 Green (80%+): Excellent performance
  - 🟡 Yellow (60-79%): Good performance
  - 🔴 Red (<60%): Needs attention
- **Individual Metrics**:
  - Reliability: Service stability percentage
  - Availability: Uptime percentage
  - Efficiency: Performance optimization score

#### System Information
- Service status indicators
- Configuration display (masked credentials)
- Platform and hostname details
- Quick action buttons

#### Live Logs
- Real-time system logs
- Syntax highlighting
- Auto-refresh capability

## API Reference

### Dashboard API (Default Port 3000)

#### GET /
Main dashboard web interface

#### GET /api/status
Returns system and service status
```json
{
  "service": "running",
  "container": "active",
  "uptime": "2h 30m",
  "version": "2.6.1"
}
```

#### GET /api/logs
Returns recent system logs
```json
{
  "logs": [
    {
      "timestamp": "2025-06-14T10:30:00Z",
      "level": "info",
      "message": "Synchronizer started successfully"
    }
  ]
}
```

#### GET /api/performance
Returns performance metrics and QoS data
```json
{
  "traffic": {
    "total": "1.2GB",
    "rate_in": "150KB/s",
    "rate_out": "75KB/s"
  },
  "sessions": {
    "active": 12,
    "users": 8
  },
  "qos": {
    "overall": 85,
    "reliability": 92,
    "availability": 88,
    "efficiency": 76
  }
}
```

### Metrics API (Default Port 3001)

#### GET /metrics
Comprehensive system metrics in JSON format

#### GET /health
Health check endpoint for monitoring
```json
{
  "status": "healthy",
  "timestamp": "2025-06-14T10:30:00Z",
  "uptime": 9000
}
```

## Troubleshooting

### Common Issues

#### Add-on Won't Start
1. **Check Configuration**: Ensure synq_key and wallet_address are provided
2. **Check Logs**: Look for error messages in the add-on logs
3. **Port Conflicts**: Ensure configured ports aren't used by other services

#### Invalid Synq Key
- Verify the key is correctly copied from Multisynq platform
- Check for extra spaces or characters
- Ensure the key is still valid and not expired

#### Dashboard Not Accessible
1. **Check Firewall**: Ensure the dashboard port is accessible
2. **Port Configuration**: Verify the port isn't blocked or in use
3. **Service Status**: Check if the add-on is running successfully

#### Low Performance Scores
- **Internet Connection**: Ensure stable, high-speed internet
- **System Resources**: Check CPU and memory usage
- **Network Quality**: Test connection stability and latency

### Log Analysis

#### Startup Logs
Look for these messages during startup:
```
[INFO] Creating synchronizer configuration...
[INFO] Synq key validated successfully
[INFO] Starting synchronizer container...
[INFO] Starting web dashboard on port 3000...
```

#### Error Messages
Common error patterns:
- `Invalid synq key`: Check key configuration
- `Port already in use`: Change port configuration
- `Docker connection failed`: Check Docker service

### Performance Optimization

#### Network Optimization
- Use wired connection instead of Wi-Fi when possible
- Ensure sufficient bandwidth allocation
- Minimize network congestion during peak usage

#### System Optimization
- Allocate adequate resources to Home Assistant
- Monitor system load and memory usage
- Keep the add-on updated to latest version

## Security Considerations

### Credential Protection
- Dashboard can be password protected
- Synq key is masked in the web interface
- Configuration stored securely in Home Assistant data directory

### Network Security
- Dashboard runs on local network by default
- Use strong passwords if exposing dashboard externally
- Consider firewall rules for external access

### Best Practices
- Regular monitoring of performance metrics
- Keep add-on updated for security patches
- Use strong, unique passwords for dashboard access
- Monitor logs for unusual activity

## Advanced Usage

### Integration with Home Assistant

#### Automation Examples
You can create automations based on add-on status:

```yaml
# Automation to notify when synchronizer goes offline
automation:
  - alias: "Synchronizer Status Monitor"
    trigger:
      platform: state
      entity_id: sensor.multisynq_status
      to: "offline"
    action:
      service: notify.mobile_app
      data:
        message: "Multisynq Synchronizer has gone offline"
```

#### Sensor Integration
Monitor metrics through Home Assistant sensors:

```yaml
# RESTful sensor for QoS score
sensor:
  - platform: rest
    name: "Multisynq QoS Score"
    resource: "http://localhost:3000/api/performance"
    value_template: "{{ value_json.qos.overall }}"
    unit_of_measurement: "%"
```

### External Monitoring
Set up external monitoring using the health check endpoint:

```bash
# Simple health check script
curl -f http://your-ha-ip:3001/health || echo "Synchronizer unhealthy"
```

## Support and Community

### Getting Help
- **Add-on Issues**: Open issues in the add-on repository
- **Synchronizer CLI Issues**: Visit [synchronizer-cli repository](https://github.com/multisynq/synchronizer-cli)
- **Multisynq Platform**: Contact official Multisynq support

### Contributing
- Report bugs and suggest features
- Contribute to documentation
- Share configuration examples and tips

### Resources
- [Multisynq Platform](https://multisynq.io)
- [Synchronizer CLI Documentation](https://www.npmjs.com/package/synchronizer-cli)
- [Home Assistant Add-on Development](https://developers.home-assistant.io/docs/add-ons/)

## License

This add-on is licensed under the Apache-2.0 license. The synchronizer-cli package is also licensed under Apache-2.0.
