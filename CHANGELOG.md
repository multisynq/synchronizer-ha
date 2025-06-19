# Changelog

All notable changes to this project will be documented in this file.

## [1.2.1] - 2025-06-19

### Fixed
- **Internal Logging**: Fixed logging issue by updating depin endpoint argument from URL to environment identifier (prod)

## [1.2.0] - 2025-06-15

### New Feature - Web Dashboard Panel
- **Web Dashboard**: Added dedicated Home Assistant UI panel accessible via the add-on interface
- **Real-time Status**: Live status indicator showing if synchronizer is online/offline
- **Synchronizer Info**: Display synchronizer name, wallet address (masked), and uptime
- **Auto-refresh**: Dashboard automatically updates every 30 seconds
- **Modern UI**: Clean, responsive interface with status indicators and real-time updates
- **Integrated Monitoring**: Status server monitors synchronizer health and provides restart capability

### 🎨 Enhanced Logging & Configuration System
- **Emoji Logging**: Implemented consistent emoji-based logging across all components for improved readability
- **Centralized Configuration**: Added comprehensive configuration file creation in `/share/multisynq_config.json`
- **Logger Function**: Added standardized Logger function in simple-server.js with four core types (info, error, success, warning)
- **Bashio Error Suppression**: Fixed spamming bashio errors by adding proper error handling and fallback methods

### Added
- Web panel accessible at port 8099 with real-time synchronizer status
- Status API endpoint providing JSON status information
- Automatic synchronizer process monitoring and restart capability
- Visual status indicators (online/offline) with color-coded interface
- Uptime tracking and last-check timestamps
- **Lite Mode**: New configuration option to disable web UI and metrics tracking for minimal overhead
- **Port Descriptions**: Added comprehensive port legends and descriptions in configuration
- **Translation Support**: Enhanced configuration translations including lite mode and port descriptions
- 🚀 Emoji-enhanced startup messages and process indicators
- 🔧 Configuration loading with detailed path checking and fallback mechanisms
- 📄 File operation logging with success/failure indicators
- ✅ Success, ❌ Error, ⚠️ Warning, ℹ️ Info message categorization
- 💰 Wallet address, 🏷️ sync name, and 🔑 API key visual indicators
- 🌐 Network and 🐛 debug endpoint identification
- 📊 Enhanced debug API endpoint with comprehensive system information

### Fixed
- **WebSocket Dependency**: Added WebSocket (`ws`) package installation to resolve "Cannot find module 'ws'" error
- Responsive web design compatible with Home Assistant themes
- Bashio command errors no longer spam the logs with "No such file or directory" messages
- Configuration loading now properly handles missing files and provides clear error messages
- Logger function correctly handles undefined message types with graceful fallback

### Improved
- **Configuration Management**: Robust config file creation and reading from Home Assistant environment
- **Error Handling**: Better error suppression and fallback for bashio unavailability
- **Process Management**: Enhanced startup logging for both synchronizer and web server processes
- **Debug Information**: Comprehensive debug endpoint showing environment, filesystem, and configuration status
- **Development Support**: Improved fallback paths for development/testing environments

### Changed
- Synchronizer now runs through a status server wrapper for better monitoring (unless lite mode is enabled)
- Added webui configuration to Home Assistant add-on for direct panel access
- Enhanced error handling and process management
- Updated port configuration to include web panel port (8099)
- **Lite Mode**: When enabled, runs synchronizer directly without status server, web UI, or metrics collection
- **Port Configuration**: Added detailed descriptions for all ports (3333, 9090, 8099) with usage guidelines
- **Configuration Schema**: Enhanced with proper port descriptions and translation support
- Unified logging system between run.sh (bash) and simple-server.js (Node.js)
- Configuration file sharing between synchronizer startup and web dashboard
- Enhanced API endpoints for configuration and debug information

### Technical Details
- Status server built with Node.js HTTP server
- Automatic synchronizer process restart on failure
- CORS-enabled API for cross-origin requests
- Secure file serving with directory traversal protection
- **Lite Mode Implementation**: Conditional execution path in run.sh based on configuration
- **Port Management**: 
  - Port 3333: Synchronizer main communication (required)
  - Port 9090: Prometheus metrics endpoint (required)
  - Port 8099: Web dashboard and stats server (optional, customizable)
- **Configuration Parsing**: Enhanced jq and bashio support for boolean configuration options
- **Translation Infrastructure**: Comprehensive multilingual support for configuration options

## [1.1.2] - 2025-06-15

### 🔧 Maintenance Release
- **Code Review**: Routine code review and maintenance update
- **Documentation**: Updated documentation and configuration files
- **Stability**: Minor improvements for enhanced stability and performance

### Changed
- Version bump for maintenance and stability improvements
- Updated configuration files for better compatibility

## [1.1.1] - 2025-06-14

### 🎉 Stable Release - Working & Polished
- **Confirmed Working**: Add-on is now fully functional and stable
- **Documentation Cleanup**: Completely simplified README.md with clear, concise instructions
- **User-Friendly Configuration**: Improved error messages that guide users to Home Assistant UI
- **Hardcoded Constants**: DePIN endpoint is now a constant (`wss://api.multisynq.io/depin`) instead of configuration option
- **Better Error Handling**: Clear messages when API key or wallet address are missing, with helpful guidance
- **Streamlined Experience**: Removed unnecessary technical details and focused on what users need to know

### Added
- Clear error messages directing users to configure API key and wallet address in Home Assistant
- Links to multisynq.io for getting API keys
- Simplified installation and configuration instructions

### Changed
- README.md completely rewritten for clarity and simplicity
- DePIN endpoint is now hardcoded as a constant
- Error messages are more user-friendly and actionable
- Configuration instructions focus on the essentials

### Removed
- DePIN endpoint configuration option (now constant)
- Technical implementation details from README
- Unnecessary troubleshooting and manual testing sections

## [1.1.0] - 2024-12-14

### 🚀 External Docker Image Approach
- **Major Architecture Change**: Now uses the official `cdrakep/synqchronizer:latest` Docker image directly
- **Proper Argument Passing**: Configuration is passed as command-line arguments as expected by the synchronizer
- **Simplified Configuration**: Removed complex internal configuration in favor of standard synchronizer arguments
- **Official Image Benefits**: Automatically benefits from updates to the official synchronizer Docker image
- **Better Compatibility**: Ensures 100% compatibility with the official synchronizer implementation

### 🔧 Configuration Changes
- Simplified to just `synq_key`, `wallet_address`, `sync_name`, and `depin_endpoint`
- Removed internal reflector configuration options that are now handled by the external image
- Added proper command-line argument mapping: `--depin`, `--sync-name`, `--launcher`, `--key`, `--wallet`

### 🏗️ Technical Improvements
- Uses external Docker image instead of building custom implementation
- Eliminates potential compatibility issues with custom synchronizer code
- Reduces maintenance burden by leveraging official image updates
- Simpler and more reliable architecture

## [1.0.7] - 2024-12-19

### 🔧 Enhanced WebSocket Implementation  
- **Aligned with CLI Reference**: Updated synchronizer.js to closely match the official synchronizer-cli reference implementation
- **Improved Message Handling**: Added proper handling for different message types (stats, UPDATE_TALLIES, QUERY_WALLET_STATS, proxy-connected, registered, debug)
- **Enhanced Connection Logic**: Updated WebSocket connection setup to match CLI patterns with proper headers and timeouts
- **Better Stats Tracking**: Added comprehensive stats logging for sessions, users, points, and QoS metrics
- **Persistent Secret Generation**: Secret is now generated once and reused, matching CLI behavior for consistent sync hash
- **Improved Registration**: Updated registration flow to align with CLI's depin protocol patterns

### 🧹 Code Quality
- Enhanced error handling and logging throughout the WebSocket client
- Added proper connection state tracking (isRegistered, latestContainerData)
- Improved periodic updates system matching CLI's 30-second interval pattern
- Better alignment with CLI message format expectations

## [1.0.6] - 2025-06-14

### 🔄 Complete Rewrite - Direct WebSocket Connection
- **Removed synchronizer-cli dependency**: CLI required Docker access which isn't available in HA add-ons
- **New Node.js WebSocket client**: Direct connection to `wss://api.multisynq.io/depin`
- **Minimal dependencies**: Only requires `ws` WebSocket library
- **Automatic startup**: Container automatically starts synchronizer on launch
- **Pure HA configuration**: No hardcoded values, requires user configuration

### Added
- **synchronizer.js**: New Node.js application with direct WebSocket implementation
- **Auto-configuration**: Reads settings from Home Assistant `/data/options.json`
- **Robust reconnection**: Handles network interruptions with exponential backoff
- **Real-time logging**: Full visibility into connection status and activity
- **Graceful shutdown**: Proper cleanup on container stop/restart
- **Configuration validation**: Clear error messages for missing/invalid settings

### Changed
- **Dockerfile**: Simplified to only install Node.js, copy files, and run synchronizer
- **config.yaml**: Empty defaults - users must provide their own synq_key and wallet_address
- **Architecture**: From shell script wrapper to pure Node.js application

### Removed
- All shell scripts (run.sh, test-*.sh) - no longer needed
- Legacy configuration files (config-simple.yaml, Dockerfile.test)
- Documentation files (DEPLOYMENT_GUIDE.md, DOCS.md, SUMMARY.md)
- Docker client dependencies and privileged access requirements
- **Hardcoded configuration values** - users must configure in Home Assistant

### Technical Implementation
- Direct WebSocket connection with proper headers and authentication
- Sync hash generation using crypto (hostname + secret + sync name)
- Message handling for tasks, pings, points, and status updates
- Keep-alive mechanism with 30-second intervals
- Error handling and automatic reconnection (max 10 attempts)

### Configuration Requirements
Users must configure in Home Assistant Settings > Add-ons > Configuration:
- **synq_key**: Your Multisynq API key (required)
- **wallet_address**: Your wallet address for rewards (required)
- **sync_name**: Custom name for your sync node (optional, defaults to "My Multisynq Sync")

### Benefits
- **Zero Docker dependency**: Perfect for Home Assistant environment
- **Minimal resource usage**: Only Node.js + WebSocket library
- **Automatic operation**: Starts immediately when add-on is installed
- **Clean architecture**: Single-purpose, well-documented codebase
- **User-specific configuration**: No shared or hardcoded credentials
- **Production ready**: Robust error handling and logging

## [1.0.5] - 2025-06-14

### 🎉 Major Simplification
- **Removed Docker Dependency**: Completely eliminated Docker client and Docker API requirements
- **Direct CLI Approach**: Now installs and runs `synchronizer-cli` directly using Node.js

### Added
- Node.js (v16+) and npm installation in Dockerfile
- Global installation of `synchronizer-cli` package
- Direct synchronizer command execution with proper argument handling
- Node.js version validation (ensures v10+ requirement)
- Web dashboard configuration support with port mapping
- Password protection for web dashboard
- Configurable log levels (debug, info, warn, error)

### Changed
- **Dockerfile**: Replaced Docker client with Node.js and npm installation
- **run.sh**: Complete rewrite to use synchronizer CLI directly instead of Docker containers
- **config.yaml**: Removed Docker-related privileges, devices, and API access; added proper port mapping
- Version bumped to 1.0.5

### Removed
- Docker client dependency
- Docker API access requirements
- Docker socket mounting
- Privileged access (SYS_ADMIN, NET_ADMIN)
- AppArmor disable requirement
- Complex Docker container management

### Benefits
- **Simpler Architecture**: Direct process execution without containerization overhead
- **Better Home Assistant Integration**: Standard add-on without special privileges
- **Reduced Resource Usage**: No Docker-in-Docker complexity
- **Improved Reliability**: Eliminates Docker API access issues
- **Cleaner Configuration**: Standard Home Assistant add-on structure

### Migration Notes
- Existing users can simply update to v1.0.5 - no configuration changes needed
- Web dashboard and metrics ports remain the same (3000/3001)
- All user configuration options are preserved

## [1.0.3] - 2025-06-14

### 🔄 Simplified Configuration Management
- **Enhanced Documentation**: Added comprehensive documentation with clear deployment guidelines
- **Simplified Docker Setup**: Streamlined Dockerfile for better local testing and development
- **Configuration Validation**: Improved configuration file structure and validation
- **User Experience Focus**: Cleaned up add-on presentation for better user adoption

### Added
- Enhanced README.md with better testing instructions and manual commands
- Simplified configuration options focusing on essential settings
- Improved error messages and user guidance
- Better documentation links and support resources

### Changed
- Simplified Dockerfile to focus on essential Node.js and npm installation
- Updated configuration management for better reliability
- Improved container image metadata and labeling
- Enhanced run script with better error handling

### Removed
- Unnecessary debug scripts and complex troubleshooting tools
- Redundant configuration files that complicated setup
- Overly technical documentation that confused users

### Technical Details
- Streamlined Docker image building process
- Better Node.js version management and validation
- Simplified synchronizer-cli installation process
- Improved container startup and configuration handling

## [1.0.2] - 2025-06-14

### 🐛 Improved Docker Testing and Configuration
- **Better Docker Local Testing**: Enhanced Docker setup for improved local development and testing
- **Simplified Configuration**: Removed advanced configuration options that were causing confusion
- **Enhanced Documentation**: Updated description to better reflect DePIN network participation
- **Streamlined Setup**: Simplified add-on configuration for better user experience

### Added
- Enhanced Dockerfile.test for better testing environment
- Simple configuration template (config-simple.yaml) for basic setups
- Better documentation links including synchronizer-cli repository
- Improved manual testing commands and debugging instructions

### Changed
- **Dockerfile**: Significantly simplified from complex Node.js installation to basic setup
- **config.yaml**: Updated version to 1.0.2 and improved description
- **README.md**: Added manual testing instructions and better command examples
- Removed complex Node.js architecture detection and installation scripts

### Removed
- Complex Node.js version validation and architecture-specific installation
- Advanced debugging and verification scripts that were over-engineering the setup
- Unnecessary npm configuration and cache management

### Technical Improvements
- Simplified Docker image build process reducing complexity
- Better container metadata and maintainer information
- Cleaner run script execution without excessive validation
- More reliable add-on startup and configuration handling

## [1.0.4] - 2025-06-14

### Known Issues
- **Docker API Limitation**: Home Assistant OS restricts Docker API access for add-ons, preventing the synchronizer from functioning properly
- Add-on provides detailed error messaging and alternative solutions when Docker access fails

### Added
- Comprehensive error messaging explaining Docker API limitations
- **DEPLOYMENT_GUIDE.md** with alternative installation methods
- Enhanced debugging information for Docker socket access
- Clear guidance for SSH-based installation and external Docker host setup

### Changed
- Updated documentation to clearly explain current limitations
- Improved error handling with actionable troubleshooting steps
- Enhanced README with status warnings and alternative solutions

### Alternative Solutions Documented
1. **SSH Installation**: Direct installation via `synchronizer-cli` package (requires `apk add nodejs npm`)
2. **Direct Docker**: No npm required - run synchronizer container directly
3. **External Docker Host**: Running on separate system with Home Assistant integration
4. **Container/Core Mode**: For non-OS Home Assistant installations
5. **Home Assistant REST Integration**: Monitor synchronizer via REST sensors

### Technical Details
- Add-on attempts multiple Docker socket locations for compatibility
- Provides detailed Docker environment diagnostics
- Graceful failure with comprehensive user guidance
- Direct Docker method bypasses npm requirement entirely
- Home Assistant REST sensor integration for monitoring
- Version updated to reflect current status

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
