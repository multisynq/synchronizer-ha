# Installation and Testing Guide

This guide will help you install, configure, and test the Multisynq Synchronizer Home Assistant Add-on.

## Quick Start

### 1. Prerequisites

Before installing this add-on, ensure you have:

- **Home Assistant Supervisor** (not Home Assistant Core or Container)
- **Synq Key** from [Multisynq platform](https://multisynq.io)
- **Wallet Address** for receiving rewards
- **Stable internet connection**

### 2. Installation Methods

#### Method A: From Repository (Recommended)
1. In Home Assistant, go to **Supervisor** → **Add-on Store**
2. Click the menu (⋮) → **Repositories**
3. Add this repository URL: `https://github.com/multisynq/synchronizer-ha`
4. Find "Multisynq Synchronizer" and click **Install**

#### Method B: Local Development
```bash
# Clone this repository to your Home Assistant addons folder
cd /usr/share/hassio/addons/local/
git clone https://github.com/multisynq/synchronizer-ha.git
```

### 3. Configuration

#### Minimum Required Configuration
```yaml
synq_key: "your-synq-key-from-multisynq"
wallet_address: "your-crypto-wallet-address"
```

#### Full Configuration Example
```yaml
synq_key: "sk_1234567890abcdef..."
wallet_address: "0x1234567890123456789012345678901234567890"
sync_name: "My Home Assistant Sync"
enable_web_dashboard: true
dashboard_port: 3000
metrics_port: 3001
dashboard_password: "MySecurePassword"
auto_start: true
log_level: "info"
```

### 4. Starting the Add-on

1. Go to **Supervisor** → **Multisynq Synchronizer**
2. Click the **Configuration** tab and enter your settings
3. Click **Save**
4. Go to the **Info** tab and click **Start**
5. Monitor the **Log** tab for startup messages

### 5. Accessing the Dashboard

Once running, access the web dashboard at:
```
http://[your-home-assistant-ip]:3000
```

## Testing and Verification

### Check Add-on Status
1. **Log Tab**: Look for successful startup messages:
   ```
   [INFO] Starting Multisynq Synchronizer Add-on...
   [INFO] Configuration created successfully
   [INFO] Synq key validated successfully
   [INFO] Starting synchronizer container...
   [INFO] Starting web dashboard on port 3000...
   [INFO] Synchronizer add-on is running!
   ```

2. **Dashboard Access**: Navigate to `http://[HA-IP]:3000`
   - Should show performance metrics
   - QoS indicators should be visible
   - System information should display

3. **API Endpoints**: Test the metrics API:
   ```bash
   # Health check
   curl http://[HA-IP]:3001/health
   
   # Full metrics
   curl http://[HA-IP]:3001/metrics
   
   # Dashboard API status
   curl http://[HA-IP]:3000/api/status
   ```

### Performance Verification

#### Dashboard Metrics
- **Total Traffic**: Should show data transfer amounts
- **Active Sessions**: Should display current session count
- **QoS Score**: Should show percentage with color coding
- **System Status**: Should show "running" status

#### Expected QoS Ranges
- **🟢 Excellent (80%+)**: Optimal performance
- **🟡 Good (60-79%)**: Acceptable performance  
- **🔴 Poor (<60%)**: May need troubleshooting

### Troubleshooting Common Issues

#### Add-on Won't Start
```bash
# Check Home Assistant logs
ha addons logs multisynq_synchronizer

# Common issues:
# - Missing synq_key or wallet_address
# - Invalid synq_key format
# - Port conflicts
# - Network connectivity issues
```

#### Dashboard Not Accessible
1. **Port Check**: Ensure port 3000 isn't blocked
2. **Firewall**: Check Home Assistant firewall settings
3. **Network**: Verify Home Assistant is accessible
4. **Service Status**: Check if web service started successfully

#### Low Performance Scores
1. **Internet Speed**: Test your connection speed
2. **Network Stability**: Check for connection drops
3. **System Resources**: Monitor CPU/memory usage
4. **Geographic Location**: Some regions may have different performance

## Advanced Configuration

### Custom Ports
If default ports conflict with other services:
```yaml
dashboard_port: 8080
metrics_port: 8081
```

### Security Settings
For external access or enhanced security:
```yaml
dashboard_password: "StrongPassword123"
log_level: "warning"  # Reduce log verbosity
```

### Integration with Home Assistant

#### RESTful Sensors
Add to your `configuration.yaml`:
```yaml
sensor:
  - platform: rest
    name: "Multisynq QoS"
    resource: "http://localhost:3000/api/performance"
    value_template: "{{ value_json.qos.overall }}"
    unit_of_measurement: "%"
    scan_interval: 60
    
  - platform: rest
    name: "Multisynq Traffic"
    resource: "http://localhost:3000/api/performance"
    value_template: "{{ value_json.traffic.total }}"
    scan_interval: 300
```

#### Automation Example
```yaml
automation:
  - alias: "Notify when Multisynq QoS drops"
    trigger:
      platform: numeric_state
      entity_id: sensor.multisynq_qos
      below: 60
    action:
      service: notify.persistent_notification
      data:
        message: "Multisynq QoS has dropped below 60%"
        title: "Synchronizer Alert"
```

## Development and Customization

### Building Locally
```bash
# Build for specific architecture
docker build --build-arg BUILD_FROM="ghcr.io/home-assistant/amd64-base:3.19" \
             -t multisynq-synchronizer .

# Test run
docker run --rm -it \
  -p 3000:3000 -p 3001:3001 \
  -e SYNQ_KEY="your-key" \
  -e WALLET_ADDRESS="your-wallet" \
  multisynq-synchronizer
```

### Custom Configuration
Modify `config.yaml` to add new options:
```yaml
options:
  custom_option: "default_value"
schema:
  custom_option: str?
```

Update `run.sh` to use new options:
```bash
CUSTOM_OPTION=$(bashio::config 'custom_option')
```

## Monitoring and Maintenance

### Regular Checks
1. **Weekly**: Check QoS scores and performance metrics
2. **Monthly**: Review logs for any recurring issues
3. **Updates**: Keep add-on updated for latest features

### Log Analysis
```bash
# View recent logs
ha addons logs multisynq_synchronizer

# Watch live logs
ha addons logs multisynq_synchronizer -f

# Check for errors
ha addons logs multisynq_synchronizer | grep ERROR
```

### Performance Optimization
1. **Network**: Use wired connection if possible
2. **Resources**: Ensure adequate CPU/RAM for Home Assistant
3. **Updates**: Keep synchronizer-cli package updated
4. **Monitoring**: Set up alerting for performance drops

## Support and Resources

### Getting Help
- **Add-on Issues**: Open issues in this repository
- **Synchronizer Issues**: Visit [synchronizer-cli repo](https://github.com/multisynq/synchronizer-cli)
- **Home Assistant**: Check [HA Community](https://community.home-assistant.io)

### Useful Links
- [Multisynq Platform](https://multisynq.io)
- [Synchronizer CLI Documentation](https://www.npmjs.com/package/synchronizer-cli)
- [Home Assistant Add-on Development](https://developers.home-assistant.io/docs/add-ons/)

### Contributing
- Report bugs and request features
- Improve documentation
- Share configuration examples
- Submit pull requests for enhancements
