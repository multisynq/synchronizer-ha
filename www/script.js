// Multisynq Synchronizer Dashboard JavaScript

class SynchronizerDashboard {
  constructor() {
    this.socket = null
    this.reconnectAttempts = 0
    this.maxReconnectAttempts = 5
    this.reconnectDelay = 2000
    this.statsInterval = null
    this.startTime = Date.now()
    this.heartbeatInterval = null
    this.lastStatsReceived = 0
    this.lastManualRefresh = 0
    this.manualRefreshCooldown = 1000 // 1 second minimum between manual refreshes
    this.config = { syncName: 'Unknown', walletAddress: '', timestamp: 0 }
    this.isConnected = false

    this.init()
  }

  init() {
    this.bindElements()
    this.setupRefreshButton()
    this.loadConfig()
    this.resetStatsDisplay()
    this.connectWebSocket()
    this.startStatsUpdates()
    this.updateTimestamp()
    setInterval(() => this.updateTimestamp(), 1000)
  }

  bindElements() {
    // Connection status elements
    this.connectionStatus = document.getElementById('connectionStatus')
    this.connectionText = document.getElementById('connectionText')
    this.connectionInfo = document.getElementById('connectionInfo')
    this.debugInfo = document.getElementById('debugInfo')

    // Refresh button
    this.refreshButton = document.getElementById('refreshButton')

    // Metric elements
    this.syncName = document.getElementById('syncName')
    this.walletAddress = document.getElementById('walletAddress')
    this.activeSessions = document.getElementById('activeSessions')
    this.connectedUsers = document.getElementById('connectedUsers')
    this.syncLifePoints = document.getElementById('syncLifePoints')
    this.walletLifePoints = document.getElementById('walletLifePoints')
    this.uploadTraffic = document.getElementById('uploadTraffic')
    this.downloadTraffic = document.getElementById('downloadTraffic')
    this.lifetimeTraffic = document.getElementById('lifetimeTraffic')
    this.proxyStatus = document.getElementById('proxyStatus')
    this.uptime = document.getElementById('uptime')
    this.cpuUsage = document.getElementById('cpuUsage')
    this.memoryUsage = document.getElementById('memoryUsage')
    this.lastUpdate = document.getElementById('lastUpdate')
    this.version = document.getElementById('version')
  }

  setupRefreshButton() {
    if (this.refreshButton) this.refreshButton.addEventListener('click', () => this.manualRefresh())
  }

  async loadConfig() {
    try {
      console.log('🔧 Loading addon configuration...')
      const response = await fetch('/api/config')
      if (response.ok) {
        this.config = await response.json()
        console.log('✅ Config loaded:', this.config)
        this.updateConfigDisplay()
      } else {
        console.warn('⚠️ Could not load config from server')
      }
    } catch (error) {
      console.warn('⚠️ Error loading config:', error.message)
    }
  }

  updateConfigDisplay() {
    if (this.config.syncName && this.config.syncName !== 'Unknown') {
      this.syncName.textContent = this.config.syncName
    }
    if (this.config.walletAddress) {
      this.walletAddress.textContent = this.formatWalletAddress(this.config.walletAddress)
    }
  }

  resetStatsDisplay() {
    // Reset all dynamic stats to default values
    this.activeSessions.textContent = '0'
    this.connectedUsers.textContent = '0'
    this.syncLifePoints.textContent = '0'
    this.walletLifePoints.textContent = '0'
    this.uploadTraffic.textContent = '0 B'
    this.downloadTraffic.textContent = '0 B'
    this.lifetimeTraffic.textContent = '0 B'
    this.proxyStatus.textContent = '--'
    this.uptime.textContent = '--'
    this.cpuUsage.textContent = '--%'
    this.memoryUsage.textContent = '--%'

    // Set config-based values or defaults
    this.syncName.textContent = this.config.syncName || 'Unknown'
    this.walletAddress.textContent = this.config.walletAddress ? this.formatWalletAddress(this.config.walletAddress) : '--'
  }

  manualRefresh() {
    const now = Date.now()
    const timeSinceLastRefresh = now - this.lastManualRefresh

    if (timeSinceLastRefresh < this.manualRefreshCooldown) {
      // Show visual feedback that refresh is on cooldown
      this.showRefreshCooldown()
      return
    }

    this.lastManualRefresh = now

    // Visual feedback for successful refresh
    this.showRefreshAnimation()

    // Request stats immediately
    this.requestStats()
    console.log('Manual refresh triggered')
  }

  showRefreshCooldown() {
    if (this.refreshButton) {
      this.refreshButton.style.opacity = '0.5'
      this.refreshButton.style.transform = 'scale(0.95)'
      setTimeout(() => {
        this.refreshButton.style.opacity = '1'
        this.refreshButton.style.transform = 'scale(1)'
      }, 200)
    }
  }

  showRefreshAnimation() {
    if (this.refreshButton) {
      this.refreshButton.style.transform = 'rotate(180deg)'
      setTimeout(() => (this.refreshButton.style.transform = 'rotate(0deg)'), 300)
    }
  }

  connectWebSocket() {
    try {
      // Try different possible WebSocket URLs
      const wsUrls = [`ws://${window.location.hostname}:3333`, `ws://localhost:3333`, `ws://127.0.0.1:3333`]

      const wsUrl = wsUrls[this.reconnectAttempts % wsUrls.length]
      console.log('Attempting to connect to:', wsUrl)

      this.socket = new WebSocket(wsUrl)

      // Set a connection timeout
      const connectionTimeout = setTimeout(() => {
        if (this.socket.readyState === WebSocket.CONNECTING) {
          console.error('WebSocket connection timeout after 5 seconds')
          this.socket.close()
        }
      }, 5000)

      this.socket.onopen = () => {
        clearTimeout(connectionTimeout)
        console.log('✅ WebSocket connected to:', wsUrl)
        this.isConnected = true
        this.updateConnectionStatus('connected')
        this.reconnectAttempts = 0
        this.requestStats()
        this.startHeartbeat()
      }

      this.socket.onmessage = (event) => {
        try {
          // console.log('📨 Raw WebSocket message received:', event.data)
          const data = JSON.parse(event.data)
          console.log('📊 Parsed message data:', data)
          this.handleMessage(data)
        } catch (error) {
          console.error('❌ Error parsing WebSocket message:', error)
          console.error('Raw data was:', event.data)
        }
      }

      this.socket.onclose = (event) => {
        clearTimeout(connectionTimeout)
        this.stopHeartbeat()
        this.isConnected = false
        console.error('🔌 WebSocket disconnected. Code:', event.code, 'Reason:', event.reason)
        this.updateConnectionStatus('disconnected')
        this.resetStatsDisplay() // Reset stats when disconnected
        this.scheduleReconnect()
      }

      this.socket.onerror = (error) => {
        clearTimeout(connectionTimeout)
        this.isConnected = false
        console.error('❌ WebSocket error:', error)
        this.updateConnectionStatus('error')
        this.resetStatsDisplay() // Reset stats on error
      }
    } catch (error) {
      console.error('❌ Error creating WebSocket:', error)
      this.updateConnectionStatus('error')
      this.scheduleReconnect()
    }
  }

  updateConnectionStatus(status) {
    const statusMap = {
      connected: { class: 'connected', text: 'Connected' },
      connecting: { class: 'connecting', text: 'Connecting...' },
      disconnected: { class: '', text: 'Disconnected' },
      error: { class: '', text: 'Connection Error' },
    }

    const statusInfo = statusMap[status] || statusMap.disconnected

    this.connectionStatus.className = `status-dot ${statusInfo.class}`
    this.connectionText.textContent = statusInfo.text

    // Show/hide connection info based on status
    if (this.connectionInfo) {
      if (status === 'connected') this.connectionInfo.style.display = 'none'
      else {
        this.connectionInfo.style.display = 'block'
        this.updateDebugInfo(status)
      }
    }
  }

  updateDebugInfo(status) {
    if (this.debugInfo) {
      const timestamp = new Date().toLocaleTimeString()
      let debugText = `[${timestamp}] Status: ${status}\n`

      if (this.socket) debugText += `WebSocket State: ${this.getWebSocketStateText(this.socket.readyState)}\n`
      else debugText += `WebSocket: Not initialized\n`

      debugText += `Reconnect attempts: ${this.reconnectAttempts}/${this.maxReconnectAttempts}\n`
      debugText += `Last stats received: ${this.lastStatsReceived ? new Date(this.lastStatsReceived).toLocaleTimeString() : 'Never'}`

      this.debugInfo.textContent = debugText
    }
  }

  getWebSocketStateText(state) {
    const states = {
      0: 'CONNECTING',
      1: 'OPEN',
      2: 'CLOSING',
      3: 'CLOSED',
    }
    return `${states[state] || 'UNKNOWN'}(${state})`
  }

  scheduleReconnect() {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++
      this.updateConnectionStatus('connecting')

      const delay = Math.min(this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1), 30000)

      setTimeout(() => {
        console.log(`Reconnection attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts} (delay: ${delay}ms)`)
        this.connectWebSocket()
      }, delay)
    } else {
      console.log('Max reconnection attempts reached. Will retry in 60 seconds...')
      this.updateConnectionStatus('error')

      // Reset attempts after a longer delay and try again
      setTimeout(() => {
        console.log('Restarting connection attempts...')
        this.reconnectAttempts = 0
        this.connectWebSocket()
      }, 60000)
    }
  }

  async requestStats() {
    if (this.socket && this.socket.readyState === WebSocket.OPEN) {
      try {
        // Visual feedback that request is being sent
        this.showRequestingStats()

        const request = { what: 'stats' }
        console.log('📤 Sending stats request:', JSON.stringify(request))

        // Send the stats request
        this.socket.send(JSON.stringify(request))

        console.log('✅ Stats request sent successfully')
      } catch (error) {
        console.error('❌ Error sending stats request:', error)
        console.error('WebSocket state:', this.socket.readyState)
      }
    } else {
      const state = this.socket ? this.socket.readyState : 'null'
      console.warn('⚠️ WebSocket not connected, cannot request stats. State:', state)
      console.warn('WebSocket states: CONNECTING=0, OPEN=1, CLOSING=2, CLOSED=3')
    }
  }

  showRequestingStats() {
    // Add a subtle animation to indicate stats are being requested
    if (this.refreshButton) {
      this.refreshButton.style.opacity = '0.7'
      setTimeout(() => {
        if (this.refreshButton) this.refreshButton.style.opacity = '1'
      }, 500)
    }
  }

  startStatsUpdates() {
    // Request stats every 60 seconds (1 minute)
    this.statsInterval = setInterval(() => {
      console.log('Automatic stats refresh (60s interval)')
      this.requestStats()
    }, 60000)

    // Refresh config every 5 minutes to pick up any changes
    setInterval(() => {
      console.log('Refreshing config...')
      this.loadConfig()
    }, 300000)
  }

  handleMessage(data) {
    try {
      this.lastStatsReceived = Date.now()
      console.log('🔄 Processing message. Type check:', {
        hasWhat: data.hasOwnProperty('what'),
        whatValue: data.what,
        hasValue: data.hasOwnProperty('value'),
        dataKeys: Object.keys(data),
      })

      // Handle the specific stats response format
      if (data.what === 'stats' && data.value) {
        console.log('📊 Processing stats data:', data.value)
        this.updateStats(data.value)
      } else if (data.what === 'stats' && !data.value) {
        console.error('❌ Stats response missing value field:', data)
      } else if (data.synchronizer_name || data.wallet || data.sessions !== undefined) {
        console.log('📊 Processing fallback stats format:', data)
        this.updateStats(data)
      } else console.log('ℹ️ Received unhandled message:', data)
    } catch (error) {
      console.error('❌ Error handling message:', error)
      console.error('Message data:', data)
    }
  }

  startHeartbeat() {
    // Check for received stats every 30 seconds
    this.heartbeatInterval = setInterval(() => {
      const timeSinceLastStats = Date.now() - this.lastStatsReceived
      if (timeSinceLastStats > 30000) {
        console.log('No stats received for 30 seconds, connection may be stale')
        if (this.socket && this.socket.readyState === WebSocket.OPEN) this.requestStats()
      }
    }, 30000)
  }

  stopHeartbeat() {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval)
      this.heartbeatInterval = null
    }
  }

  updateStats(stats) {
    try {
      console.log('🔧 Updating stats with data:', stats)

      // Update sessions (from the stats response)
      if (stats.sessions !== undefined) {
        console.log('📊 Sessions:', stats.sessions)
        this.activeSessions.textContent = stats.sessions
      }

      // Update users (from the stats response)
      if (stats.users !== undefined) {
        console.log('👥 Users:', stats.users)
        this.connectedUsers.textContent = stats.users
      }

      // Update points earned (using syncLifePoints from the response)
      if (stats.syncLifePoints !== undefined) {
        console.log('⭐ Sync Life Points:', stats.syncLifePoints)
        this.syncLifePoints.textContent = this.formatNumber(stats.syncLifePoints)
      }
      if (stats.walletLifePoints !== undefined) {
        console.log('💳 Wallet Life Points:', stats.walletLifePoints)
        this.walletLifePoints.textContent = this.formatNumber(stats.walletLifePoints)
      }

      // Update traffic (using bytesIn and bytesOut)
      if (stats.bytesOut !== undefined) {
        console.log('📤 Bytes Out:', stats.bytesOut)
        this.uploadTraffic.textContent = this.formatBytes(stats.bytesOut)
      }
      if (stats.bytesIn !== undefined) {
        console.log('📥 Bytes In:', stats.bytesIn)
        this.downloadTraffic.textContent = this.formatBytes(stats.bytesIn)
      }
      if (stats.syncLifeTraffic !== undefined) {
        console.log('📈 Lifetime Traffic:', stats.syncLifeTraffic)
        this.lifetimeTraffic.textContent = this.formatBytes(stats.syncLifeTraffic)
      }

      // Update proxy connection state
      if (stats.proxyConnectionState) {
        console.log('🔗 Proxy State:', stats.proxyConnectionState)
        this.proxyStatus.textContent = stats.proxyConnectionState
      }

      // Update wallet balance if available
      if (stats.walletBalance !== null && stats.walletBalance !== undefined) {
        console.log('💰 Wallet Balance:', stats.walletBalance)
      }

      // Calculate and display uptime based on current time and start time
      if (stats.now) {
        const uptimeSeconds = Math.floor((stats.now - this.startTime) / 1000)
        console.log('⏱️ Uptime:', uptimeSeconds, 'seconds')
        this.uptime.textContent = this.formatUptime(uptimeSeconds)
      }

      // Display quality metrics (availability, reliability, efficiency)
      if (stats.availability !== undefined) {
        console.log('🎯 Availability:', (stats.availability * 100).toFixed(1) + '%')
      }
      if (stats.reliability !== undefined) {
        console.log('🔒 Reliability:', (stats.reliability * 100).toFixed(1) + '%')
      }
      if (stats.efficiency !== undefined) {
        console.log('⚡ Efficiency:', (stats.efficiency * 100).toFixed(1) + '%')
      }

      // Set config-based values (these don't come from WebSocket stats)
      this.syncName.textContent = this.config.syncName || 'Unknown'
      this.walletAddress.textContent = this.config.walletAddress ? this.formatWalletAddress(this.config.walletAddress) : '--'

      // Set system values that we don't have from the stats
      this.cpuUsage.textContent = '--%'
      this.memoryUsage.textContent = '--%'

      console.log('✅ Stats update completed successfully')
    } catch (error) {
      console.error('❌ Error updating stats:', error)
      console.error('Stats data was:', stats)
    }
  }

  formatWalletAddress(address) {
    if (!address) return '--'
    if (address.length <= 16) return address
    return `${address.substring(0, 8)}...${address.substring(address.length - 8)}`
  }

  formatBytes(bytes) {
    if (bytes === 0 || bytes === undefined) return '0 B'

    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))

    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`
  }

  formatNumber(num) {
    if (num === undefined || num === null) return '0'
    return num.toLocaleString()
  }

  formatUptime(seconds) {
    if (!seconds) return '--'

    const days = Math.floor(seconds / 86400)
    const hours = Math.floor((seconds % 86400) / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)

    if (days > 0) return `${days}d ${hours}h`
    else if (hours > 0) return `${hours}h ${minutes}m`
    else return `${minutes}m`
  }

  updateTimestamp() {
    const now = new Date()
    this.lastUpdate.textContent = now.toLocaleTimeString()
  }

  destroy() {
    this.stopHeartbeat()
    if (this.socket) this.socket.close()
    if (this.statsInterval) clearInterval(this.statsInterval)
  }
}

// Mock data for testing when WebSocket is not available (matches the actual stats format)
const mockStats = {
  what: 'stats',
  value: {
    now: 1750011708853,
    sessions: 0,
    demoSessions: 0,
    users: 0,
    bytesOut: 0,
    bytesIn: 0,
    proxyConnectionState: 'CONNECTED',
    syncLifeTraffic: 123123123,
    syncLifePoints: 9999,
    walletLifePoints: 999999,
    walletBalance: null,
    ratingsTimepoint: 0,
    availability: 0,
    reliability: 0,
    efficiency: 0,
  },
}

// Initialize dashboard when page loads
document.addEventListener('DOMContentLoaded', () => {
  const dashboard = new SynchronizerDashboard()
  window.addEventListener('beforeunload', () => dashboard.destroy()) // Clean up on page unload
})

// Export for potential external use
window.SynchronizerDashboard = SynchronizerDashboard
