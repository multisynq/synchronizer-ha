let startTime = Date.now()

async function fetchStatus() {
  try {
    const [statusResponse, metricsResponse, performanceResponse] = await Promise.all([
      fetch('/api/status'),
      fetch('/api/metrics'),
      fetch('/api/performance'),
    ])

    if (!statusResponse.ok) {
      throw new Error(`HTTP ${statusResponse.status}: ${statusResponse.statusText}`)
    }

    const status = await statusResponse.json()
    const metrics = metricsResponse.ok ? await metricsResponse.json() : {}
    const performance = performanceResponse.ok ? await performanceResponse.json() : {}

    return { status, metrics, performance }
  } catch (error) {
    console.error('Failed to fetch status:', error)
    throw error
  }
}

function updateUI(data) {
  const { status, metrics, performance } = data

  const statusCard = document.getElementById('status-card')
  const statusDot = document.getElementById('status-dot')
  const statusText = document.getElementById('status-text')
  const syncName = document.getElementById('sync-name')
  const walletAddress = document.getElementById('wallet-address')
  const sessions = document.getElementById('sessions')
  const users = document.getElementById('users')
  const lifePoints = document.getElementById('life-points')
  const totalTraffic = document.getElementById('total-traffic')
  const qosScore = document.getElementById('qos-score')
  const connectionState = document.getElementById('connection-state')
  const uptime = document.getElementById('uptime')
  const lastCheck = document.getElementById('last-check')
  const errorMessage = document.getElementById('error-message')

  // Hide error message
  errorMessage.style.display = 'none'

  // Update status
  const isOnline = status.online
  statusCard.className = `status-card ${isOnline ? 'online' : 'offline'}`
  statusDot.className = `status-dot ${isOnline ? 'online' : 'offline'}`
  statusText.textContent = isOnline ? 'Online & Syncing' : 'Offline'

  // Update basic info
  syncName.textContent = status.syncName || 'Unknown'
  walletAddress.textContent = status.walletAddress
    ? `${status.walletAddress.slice(0, 8)}...${status.walletAddress.slice(-6)}`
    : 'Not configured'

  // Update metrics
  sessions.textContent = metrics.sessions || '0'
  users.textContent = metrics.users || '0'
  lifePoints.textContent = (metrics.syncLifePoints || 0).toLocaleString()
  totalTraffic.textContent = formatBytes(metrics.syncLifeTraffic || 0)

  // Update performance data
  if (performance.qos) {
    qosScore.textContent = `${performance.qos.score || 0}%`
  } else {
    qosScore.textContent = '-'
  }

  connectionState.textContent = metrics.proxyConnectionState || 'UNKNOWN'
  connectionState.style.color = metrics.proxyConnectionState === 'CONNECTED' ? '#4ade80' : '#fbbf24'

  // Calculate uptime
  const uptimeMs = Date.now() - startTime
  const uptimeSeconds = Math.floor(uptimeMs / 1000)
  const hours = Math.floor(uptimeSeconds / 3600)
  const minutes = Math.floor((uptimeSeconds % 3600) / 60)
  const seconds = uptimeSeconds % 60
  uptime.textContent = `${hours}h ${minutes}m ${seconds}s`

  lastCheck.textContent = new Date().toLocaleTimeString()
}

function formatBytes(bytes) {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
}

function showError(message) {
  const errorMessage = document.getElementById('error-message')
  errorMessage.textContent = message
  errorMessage.style.display = 'block'

  // Update UI to show offline state
  const statusCard = document.getElementById('status-card')
  const statusDot = document.getElementById('status-dot')
  const statusText = document.getElementById('status-text')

  statusCard.className = 'status-card offline'
  statusDot.className = 'status-dot offline'
  statusText.textContent = 'Connection Error'
}

async function refreshStatus() {
  const refreshBtn = document.getElementById('refresh-btn')
  refreshBtn.classList.add('loading')
  refreshBtn.textContent = 'Refreshing...'

  try {
    const data = await fetchStatus()
    updateUI(data)
  } catch (error) {
    showError(`Failed to connect to synchronizer: ${error.message}`)
  } finally {
    refreshBtn.classList.remove('loading')
    refreshBtn.textContent = 'Refresh Status'
  }
}

// Initial load
refreshStatus()

// Auto-refresh every 30 seconds
setInterval(refreshStatus, 30000)
