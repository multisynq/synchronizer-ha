# Multisynq Synchronizer Home Assistant Add-on

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armhf Architecture][armhf-shield]
![Supports armv7 Architecture][armv7-shield]
![Supports i386 Architecture][i386-shield]

Run a Multisynq Synchronizer through your Home Assistant instance to participate in DePIN networks and earn rewards.

## Quick Installation

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
- `Synchronizer Name`: Friendly name for your synchronizer
- `Auto Start Synchronizer`: Start automatically when add-on starts (default: true)

**Web Dashboard** (optional section):
- `Enable Dashboard`: Enable web interface for monitoring (default: true)
- `Dashboard Port`: Port for web interface (default: 3000)
- `Metrics API Port`: Port for metrics API (default: 3001)
- `Dashboard Password`: Optional password protection

**Advanced Settings** (optional section):
- `Log Level`: Logging verbosity for debugging (default: info)

## ⚠️ Important - Segmentation Fault Issues

Some users may experience segmentation faults with synchronizer-cli. If the add-on crashes:

### Recommended Safe Configuration:
```yaml
synq_key: "your-key-here"
wallet_address: "your-wallet-here"
auto_start: false          # Disable to avoid crashes
web_dashboard:
  enable: true             # Use for manual control
  port: 3000
advanced:
  log_level: "debug"       # Enable detailed logging
```

### Debugging Commands:
```bash
# Access container
docker exec -it addon_multisynq_synchronizer bash

# Run installation test
/test_installation.sh

# Run debug analysis
./debug.sh

# Manual start script
/start_manual.sh

# Check synchronizer status
synchronize status

# View synchronizer logs
synchronize logs

# Test manually
node /usr/lib/node_modules/synchronizer-cli/index.js --version
```

## Getting Started

1. Get your Synq key from [multisynq.io](https://multisynq.io)
2. Configure the add-on with your key and wallet address
3. Start the add-on
4. Monitor at `http://[your-ha-ip]:3000` (if dashboard enabled)

## More Information

- **Platform Details**: [multisynq.io](https://multisynq.io)
- **CLI Documentation**: [synchronizer-cli repository](https://github.com/multisynq/synchronizer-cli)
- **Support**: [GitHub Issues](https://github.com/multisynq/synchronizer-ha/issues)

---

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
