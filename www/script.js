// Multisynq Synchronizer Dashboard JavaScript

class SynchronizerDashboard {
  constructor() {
    this.socket = null
    this.reconnectAttempts = 0
    this.maxReconnectAttempts = 5
    this.reconnectDelay = 2000
    this.statsInterval = null
    this.startTime = Date.now()

    this.init()
  }

  init() {
    this.bindElements()
    this.connectWebSocket()
    this.startStatsUpdates()
    this.updateTimestamp()
    setInterval(() => this.updateTimestamp(), 1000)
  }

  bindElements() {
    // Connection status elements
    this.connectionStatus = document.getElementById('connectionStatus')
    this.connectionText = document.getElementById('connectionText')

    // Metric elements
    this.syncName = document.getElementById('syncName')
    this.walletAddress = document.getElementById('walletAddress')
    this.activeSessions = document.getElementById('activeSessions')
    this.connectedUsers = document.getElementById('connectedUsers')
    this.pointsEarned = document.getElementById('pointsEarned')
    this.uploadTraffic = document.getElementById('uploadTraffic')
    this.downloadTraffic = document.getElementById('downloadTraffic')
    this.latency = document.getElementById('latency')
    this.uptime = document.getElementById('uptime')
    this.cpuUsage = document.getElementById('cpuUsage')
    this.memoryUsage = document.getElementById('memoryUsage')
    this.lastUpdate = document.getElementById('lastUpdate')
    this.version = document.getElementById('version')
  }

  connectWebSocket() {
    try {
      // Try different possible WebSocket URLs
      const wsUrls = [`ws://${window.location.hostname}:3333`, `ws://localhost:3333`, `ws://127.0.0.1:3333`]

      const wsUrl = wsUrls[0] // Start with the first URL
      console.log('Attempting to connect to:', wsUrl)

      this.socket = new WebSocket(wsUrl)

      this.socket.onopen = () => {
        console.log('WebSocket connected')
        this.updateConnectionStatus('connected')
        this.reconnectAttempts = 0
        this.requestStats()
      }

      this.socket.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data)
          this.handleMessage(data)
        } catch (error) {
          console.error('Error parsing WebSocket message:', error)
        }
      }

      this.socket.onclose = () => {
        console.log('WebSocket disconnected')
        this.updateConnectionStatus('disconnected')
        this.scheduleReconnect()
      }

      this.socket.onerror = (error) => {
        console.error('WebSocket error:', error)
        this.updateConnectionStatus('error')
      }
    } catch (error) {
      console.error('Error creating WebSocket:', error)
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
  }

  scheduleReconnect() {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++
      this.updateConnectionStatus('connecting')

      setTimeout(() => {
        console.log(`Reconnection attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts}`)
        this.connectWebSocket()
      }, this.reconnectDelay * this.reconnectAttempts)
    } else {
      console.log('Max reconnection attempts reached')
      this.updateConnectionStatus('error')
    }
  }

  requestStats() {
    if (this.socket && this.socket.readyState === WebSocket.OPEN) {
      this.socket.send(JSON.stringify({ what: 'stats' }))
    }
  }

  startStatsUpdates() {
    // Request stats every 5 seconds
    this.statsInterval = setInterval(() => {
      this.requestStats()
    }, 5000)
  }

  handleMessage(data) {
    try {
      // Handle different message types
      if (data.type === 'stats' || data.stats) {
        this.updateStats(data.stats || data)
      } else if (data.synchronizer_name || data.wallet || data.sessions !== undefined) {
        // Direct stats format
        this.updateStats(data)
      } else {
        console.log('Received message:', data)
      }
    } catch (error) {
      console.error('Error handling message:', error)
    }
  }

  updateStats(stats) {
    try {
      // Update synchronizer name
      if (stats.synchronizer_name || stats.name) {
        this.syncName.textContent = stats.synchronizer_name || stats.name || 'Unknown'
      }

      // Update wallet address
      if (stats.wallet || stats.wallet_address) {
        const wallet = stats.wallet || stats.wallet_address
        this.walletAddress.textContent = this.formatWalletAddress(wallet)
      }

      // Update sessions
      if (stats.sessions !== undefined || stats.active_sessions !== undefined) {
        this.activeSessions.textContent = stats.sessions || stats.active_sessions || 0
      }

      // Update users
      if (stats.users !== undefined || stats.connected_users !== undefined) {
        this.connectedUsers.textContent = stats.users || stats.connected_users || 0
      }

      // Update points
      if (stats.points !== undefined || stats.points_earned !== undefined) {
        this.pointsEarned.textContent = this.formatNumber(stats.points || stats.points_earned || 0)
      }

      // Update traffic
      if (stats.traffic) {
        this.uploadTraffic.textContent = this.formatBytes(stats.traffic.upload || 0)
        this.downloadTraffic.textContent = this.formatBytes(stats.traffic.download || 0)
      } else {
        if (stats.upload_traffic !== undefined) {
          this.uploadTraffic.textContent = this.formatBytes(stats.upload_traffic)
        }
        if (stats.download_traffic !== undefined) {
          this.downloadTraffic.textContent = this.formatBytes(stats.download_traffic)
        }
      }

      // Update latency
      if (stats.latency !== undefined) {
        this.latency.textContent = `${stats.latency} ms`
      }

      // Update uptime
      if (stats.uptime !== undefined) {
        this.uptime.textContent = this.formatUptime(stats.uptime)
      }

      // Update system stats
      if (stats.system) {
        if (stats.system.cpu !== undefined) {
          this.cpuUsage.textContent = `${Math.round(stats.system.cpu)}%`
        }
        if (stats.system.memory !== undefined) {
          this.memoryUsage.textContent = `${Math.round(stats.system.memory)}%`
        }
      } else {
        if (stats.cpu_usage !== undefined) {
          this.cpuUsage.textContent = `${Math.round(stats.cpu_usage)}%`
        }
        if (stats.memory_usage !== undefined) {
          this.memoryUsage.textContent = `${Math.round(stats.memory_usage)}%`
        }
      }

      // Update version if provided
      if (stats.version) {
        this.version.textContent = stats.version
      }

      console.log('Stats updated:', stats)
    } catch (error) {
      console.error('Error updating stats:', error)
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

    if (days > 0) {
      return `${days}d ${hours}h`
    } else if (hours > 0) {
      return `${hours}h ${minutes}m`
    } else {
      return `${minutes}m`
    }
  }

  updateTimestamp() {
    const now = new Date()
    this.lastUpdate.textContent = now.toLocaleTimeString()
  }

  destroy() {
    if (this.socket) {
      this.socket.close()
    }
    if (this.statsInterval) {
      clearInterval(this.statsInterval)
    }
  }
}

// Mock data for testing when WebSocket is not available
const mockStats = {
  synchronizer_name: 'Demo Synchronizer',
  wallet: '0x1234567890abcdef1234567890abcdef12345678',
  sessions: 3,
  users: 15,
  points: 1247,
  traffic: {
    upload: 156789456,
    download: 892345678,
  },
  latency: 42,
  uptime: 7263,
  system: {
    cpu: 23.5,
    memory: 67.2,
  },
  version: '1.2.0',
}

// Initialize dashboard when page loads
document.addEventListener('DOMContentLoaded', () => {
  const dashboard = new SynchronizerDashboard()

  // For testing purposes, you can uncomment the following lines to use mock data
  // setTimeout(() => {
  //     dashboard.updateStats(mockStats);
  // }, 2000);

  // Clean up on page unload
  window.addEventListener('beforeunload', () => {
    dashboard.destroy()
  })
})

// Export for potential external use
window.SynchronizerDashboard = SynchronizerDashboard
