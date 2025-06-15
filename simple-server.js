#!/usr/bin/env node

const http = require('http')
const fs = require('fs')
const path = require('path')

// Logger function similar to run.sh logging style
function log_info(   m=``)  { console.log(`${m}`     ) } //prettier-ignore
function log_space(  m=``)  { console.log(`· ${m}`   ) } //prettier-ignore
function log_error(  m=``)  { console.error(`❌ ${m}`) } //prettier-ignore
function log_success(m=``)  { console.log(`✔️ ${m}`  ) } //prettier-ignore
function log_warning(m=``)  { console.log(`⚠️  ${m}` ) } //prettier-ignore
function log_object(obj={}) { console.log(obj)         } //prettier-ignore

// Simple static file server with config endpoint
class SimpleServer {
  constructor() {
    this.port = process.env.PORT || 8099
    this.wwwDir = path.join(__dirname, 'www')
    this.config = this.loadConfig()
  }

  start() {
    const server = http.createServer((req, res) => this.handleRequest(req, res))

    server.listen(this.port, () => {
      log_info(`🚀 ────────────── Multisynq Dashboard Server ─────────────── 🚀`)
      log_info(`├─ 🌐 Dashboard: http://localhost:${this.port}`)
      log_info(`├─ 🔧 Config API: http://localhost:${this.port}/api/config`)
      log_info(`├─ 🐛 Debug API: http://localhost:${this.port}/api/debug`)
      log_info(`├─ 📁 Files: ${this.wwwDir}`)
      log_info('│')
      log_info('│  The dashboard connects to WebSocket on port 3333')
      log_info('│  Make sure the synchronizer is running and accepting WebSocket connections')
      log_info('│')
      log_info(`├─ 🔧 Environment: ${this.config.environment}`)
      log_info(`├─ 🏷️ Sync Name:   ${this.config.syncName}`)
      log_info(`├─ 💰 Wallet:      ${this.config.walletAddress ? this.config.walletAddress.substring(0, 8) + '...' : 'Not configured'}`)
      log_info(`🚀 ───────────────────────────────────────────────────────── 🚀`)
      log_space()
    })
  }

  handleRequest(req, res) {
    // Handle config API endpoint
    if (req.url === '/api/config') {
      res.writeHead(200, {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      })

      // Reload config on each request to get fresh data
      const freshConfig = this.loadConfig()
      res.end(JSON.stringify(freshConfig, null, 2))
      return
    }

    // Handle debug endpoint for troubleshooting
    if (req.url === '/api/debug') {
      res.writeHead(200, {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      })

      const debugInfo = {
        environment: {
          node_version: process.version,
          platform: process.platform,
          cwd: process.cwd(),
          env_hassio: process.env.HASSIO,
          env_port: process.env.PORT,
        },
        filesystem: {
          data_exists: fs.existsSync('/data'),
          share_exists: fs.existsSync('/share'),
          config_exists: fs.existsSync('/config'),
          addon_configs_exists: fs.existsSync('/addon_configs'),
          homeassistant_exists: fs.existsSync('/homeassistant'),
        },
        files: {
          data_options: fs.existsSync('/data/options.json'),
          share_syncname: fs.existsSync('/share/multisynq_sync_name.txt'),
          test_options: fs.existsSync(path.join(__dirname, 'test-data/options.json')),
          test_syncname: fs.existsSync(path.join(__dirname, 'test-data/multisynq_sync_name.txt')),
        },
        current_config: this.config,
      }

      res.end(JSON.stringify(debugInfo, null, 2))
      return
    }

    let filePath = req.url === '/' ? '/index.html' : req.url
    filePath = path.join(this.wwwDir, filePath)

    // Security check - prevent directory traversal
    if (!filePath.startsWith(this.wwwDir)) {
      res.writeHead(403)
      res.end('Forbidden')
      return
    }

    // Check if file exists
    if (!fs.existsSync(filePath)) {
      res.writeHead(404)
      res.end('Not Found')
      return
    }

    // Get file extension for content type
    const ext = path.extname(filePath)
    const contentType = this.getContentType(ext)

    // Read and serve file
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(500)
        res.end('Internal Server Error')
        return
      }

      res.writeHead(200, { 'Content-Type': contentType })
      res.end(data)
    })
  }

  getContentType(ext) {
    const types = {
      '.html': 'text/html',
      '.css': 'text/css',
      '.js': 'text/javascript',
      '.json': 'application/json',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.gif': 'image/gif',
      '.svg': 'image/svg+xml',
    }
    return types[ext] || 'text/plain'
  }

  loadConfig() {
    const config = {
      syncName: 'Unknown',
      walletAddress: '',
      timestamp: Date.now(),
      environment: 'unknown',
    }

    try {
      log_info(`🔧 Configuration Loading`)
      log_info(`📁 Current working directory: ${process.cwd()}`)

      // First, try to read the comprehensive config file created by run.sh
      const mainConfigPath = '/share/multisynq_config.json'
      const testConfigPath = path.join(__dirname, 'test-data/multisynq_config.json')

      let configPath = mainConfigPath
      if (!fs.existsSync(configPath)) configPath = testConfigPath

      log_info(`📄 Checking main config file: ${configPath}`)

      if (fs.existsSync(configPath)) {
        const configContent = fs.readFileSync(configPath, 'utf8')
        log_info(`📄 Main config file content: ${configContent}`)
        const mainConfig = JSON.parse(configContent)

        // Merge the config data
        Object.assign(config, mainConfig)
        config.environment = configPath.includes('test-data') ? 'development' : 'homeassistant'

        log_success(`Main config loaded from: ${configPath}`)
        log_info(`🔑 Available config keys: ${Object.keys(mainConfig).join(', ')}`)

        log_info('🔧 Final Configuration')
        log_info('Loaded config:')
        log_object({
          syncName: config.syncName,
          walletAddress: config.walletAddress ? `${config.walletAddress.substring(0, 8)}...` : 'Not set',
          configSource: config.configSource,
          addonVersion: config.addonVersion,
          environment: config.environment,
          timestamp: new Date(config.timestamp * 1000).toISOString(),
        })
        return config
      }

      log_warning('Main config file not found, trying fallback methods...')

      // Fallback to individual file reading
      // Home Assistant paths
      const haPaths = {
        options: '/data/options.json',
        syncName: '/share/multisynq_sync_name.txt',
        config: '/config',
        addon: '/addon_configs',
      }

      // Development/test paths
      const devPaths = {
        options: path.join(__dirname, 'test-data/options.json'),
        syncName: path.join(__dirname, 'test-data/multisynq_sync_name.txt'),
      }

      // Check if we're in Home Assistant environment
      const isHomeAssistant = fs.existsSync('/data') || fs.existsSync('/share') || process.env.HASSIO === 'true'
      config.environment = isHomeAssistant ? 'homeassistant' : 'development'
      config.configSource = 'fallback'

      log_info(`🔧 Environment detected: ${config.environment}`)

      // Try to read from Home Assistant options.json first
      let optionsPath = haPaths.options
      if (!fs.existsSync(optionsPath)) optionsPath = devPaths.options

      log_info(`📄 Checking options file: ${optionsPath}`)
      if (fs.existsSync(optionsPath)) {
        const optionsContent = fs.readFileSync(optionsPath, 'utf8')
        log_info(`📄 Options file content: ${optionsContent}`)
        const options = JSON.parse(optionsContent)
        config.walletAddress = options.wallet_address || options.walletAddress || ''
        config.synqKey = options.synq_key ? `${options.synq_key.substring(0, 8)}...` : ''
        config.liteMode = options.lite_mode || false
        log_success(`Config loaded from: ${optionsPath}`)
        log_info(`🔑 Available options keys: ${Object.keys(options).join(', ')}`)
      } else log_error(`Options file not found at: ${optionsPath}`)

      // Try to read the persistent sync name
      let syncNamePath = haPaths.syncName
      if (!fs.existsSync(syncNamePath)) syncNamePath = devPaths.syncName

      log_info(`📄 Checking sync name file: ${syncNamePath}`)
      if (fs.existsSync(syncNamePath)) {
        config.syncName = fs.readFileSync(syncNamePath, 'utf8').trim()
        log_success(`Sync name loaded from: ${syncNamePath}`)
      } else log_error(`Sync name file not found at: ${syncNamePath}`)

      // Try additional Home Assistant locations
      if (isHomeAssistant) {
        const additionalPaths = [
          '/homeassistant/options.json',
          '/addon_configs/local_multisynq_synchronizer/options.json',
          '/config/addons_config/local_multisynq_synchronizer.json',
        ]

        for (const additionalPath of additionalPaths) {
          if (fs.existsSync(additionalPath)) {
            log_info(`📋 Found additional config at: ${additionalPath}`)
            try {
              const additionalConfig = JSON.parse(fs.readFileSync(additionalPath, 'utf8'))
              if (additionalConfig.wallet_address && !config.walletAddress) {
                config.walletAddress = additionalConfig.wallet_address
                log_success('Wallet address loaded from additional path')
              }
            } catch (e) {
              log_warning(`Could not parse additional config: ${e.message}`)
            }
          }
        }
      }

      log_info(`🔧 ────────────────── Final Configuration ────────────────── 🔧`)
      log_info('Loaded config:')
      log_object({
        syncName: config.syncName,
        walletAddress: config.walletAddress ? `${config.walletAddress.substring(0, 8)}...` : 'Not set',
        configSource: config.configSource,
        environment: config.environment,
        timestamp: new Date(config.timestamp).toISOString(),
      })
      log_info(`🔧 ───────────────────────────────────────────────────────── 🔧`)
    } catch (error) {
      log_error(`Error loading addon config: ${error.message}`)
      log_error(`Stack trace: ${error.stack}`)
      config.configSource = 'error'
    }

    return config
  }
}

// Start the server
if (require.main === module) {
  const server = new SimpleServer()
  server.start()
}

module.exports = SimpleServer
