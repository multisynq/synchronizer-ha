#!/usr/bin/env node

const http = require('http')
const fs = require('fs')
const path = require('path')
const { spawn, execSync } = require('child_process')

// Global caching and rate limiting (following synchronizer-cli patterns)
let lastStatsRequestTime = 0
let lastStatsResult = null
let statsRequestInProgress = null
const STATS_REQUEST_COOLDOWN = 60 * 1000 // 60 seconds between ANY stats requests
const STATS_CACHE_DURATION = 60 * 1000 // Cache results for 60 seconds
const DASHBOARD_CACHE_DURATION = 30 * 1000 // Dashboard cache duration

// Global caching for all dashboard data to prevent redundant requests
let globalCache = {
  performance: { data: null, timestamp: 0 },
  points: { data: null, timestamp: 0 },
  status: { data: null, timestamp: 0 },
}

class StatusServer {
  constructor() {
    this.port = 8099
    this.syncProcess = null
    this.status = {
      online: false,
      syncName: 'Unknown',
      walletAddress: '',
      startTime: Date.now(),
      lastHeartbeat: null,
    }
    this.metrics = {
      sessions: 0,
      users: 0,
      bytesIn: 0,
      bytesOut: 0,
      syncLifePoints: 0,
      walletLifePoints: 0,
      syncLifeTraffic: 0,
      proxyConnectionState: 'UNKNOWN',
    }
    this.performance = {
      totalTraffic: 0,
      sessions: 0,
      users: 0,
      bytesIn: 0,
      bytesOut: 0,
      proxyConnectionState: 'UNKNOWN',
    }
    this.qos = {
      score: 0,
      availability: 2, // 0=100%, 1=67%, 2=33%
      reliability: 2,
      efficiency: 2,
      ratingsBlurbs: null,
    }
    this.wwwDir = '/app/www'
  }

  start() {
    const server = http.createServer((req, res) => this.handleRequest(req, res))
    server.listen(this.port, () => console.log(`[STATUS] Status server running on port ${this.port}`))

    // Start the monitoring
    this.startSynchronizerMonitoring()

    return server
  }

  handleRequest(req, res) {
    const url = new URL(req.url, `http://localhost:${this.port}`)

    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type')

    if (req.method === 'OPTIONS') {
      res.writeHead(200)
      res.end()
      return
    }

    if (url.pathname === '/api/status') this.handleStatusAPI(req, res)
    else if (url.pathname === '/api/metrics') this.handleMetricsAPI(req, res)
    else if (url.pathname === '/api/performance') this.handlePerformanceAPI(req, res)
    else if (url.pathname === '/api/points') this.handlePointsAPI(req, res)
    else if (url.pathname === '/') this.serveFile(res, 'index.html', 'text/html')
    else this.serveStaticFile(req, res, url.pathname)
  }

  handleStatusAPI(req, res) {
    res.writeHead(200, { 'Content-Type': 'application/json' })
    res.end(
      JSON.stringify({
        ...this.status,
        uptime: Date.now() - this.status.startTime,
      })
    )
  }

  handleMetricsAPI(req, res) {
    res.writeHead(200, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify(this.metrics || {}))
  }

  handlePerformanceAPI(req, res) {
    this.getPerformanceData()
      .then((data) => {
        res.writeHead(200, { 'Content-Type': 'application/json' })
        res.end(JSON.stringify(data))
      })
      .catch((error) => {
        console.error('[STATUS] Error getting performance data:', error)
        res.writeHead(500, { 'Content-Type': 'application/json' })
        res.end(JSON.stringify({ error: 'Internal server error' }))
      })
  }

  handlePointsAPI(req, res) {
    this.getPointsData()
      .then((data) => {
        res.writeHead(200, { 'Content-Type': 'application/json' })
        res.end(JSON.stringify(data))
      })
      .catch((error) => {
        console.error('[STATUS] Error getting points data:', error)
        res.writeHead(500, { 'Content-Type': 'application/json' })
        res.end(JSON.stringify({ error: 'Internal server error' }))
      })
  }

  serveFile(res, filename, contentType) {
    const filePath = path.join(this.wwwDir, filename)

    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404, { 'Content-Type': 'text/plain' })
        res.end('File not found')
        return
      }

      res.writeHead(200, { 'Content-Type': contentType })
      res.end(data)
    })
  }

  serveStaticFile(req, res, pathname) {
    const filePath = path.join(this.wwwDir, pathname)

    // Security check - prevent directory traversal
    if (!filePath.startsWith(this.wwwDir)) {
      res.writeHead(403, { 'Content-Type': 'text/plain' })
      res.end('Forbidden')
      return
    }

    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404, { 'Content-Type': 'text/plain' })
        res.end('Not found')
        return
      }

      const ext = path.extname(filePath)
      const contentType = this.getContentType(ext)

      res.writeHead(200, { 'Content-Type': contentType })
      res.end(data)
    })
  }

  getContentType(ext) {
    const types = {
      '.html': 'text/html',
      '.css': 'text/css',
      '.js': 'application/javascript',
      '.json': 'application/json',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.ico': 'image/x-icon',
    }
    return types[ext] || 'text/plain'
  }

  startSynchronizerMonitoring() {
    // Read config from environment or files
    this.loadConfig()

    // Start the actual synchronizer process
    this.startSynchronizer()

    // Check process health every 30 seconds
    setInterval(() => this.checkSynchronizerHealth(), 30000)

    // Update metrics from container stats every 30 seconds
    setInterval(async () => {
      try {
        const containerStats = await this.getContainerStats()
        if (containerStats) this.updateMetricsFromContainerStats(containerStats)
      } catch (error) {
        console.log('[STATUS] Error updating metrics:', error.message)
      }
    }, 30000)
  }

  loadConfig() {
    // Load sync name from environment first (set by run.sh)
    if (process.env.SYNC_NAME) {
      this.status.syncName = process.env.SYNC_NAME
      console.log('[STATUS] Using sync name from environment:', this.status.syncName)
    } else {
      // Fallback: try to load from persistent file locations
      const syncNameFiles = [
        '/share/multisynq_sync_name.txt', // Primary location used by run.sh
        '/data/sync_name.txt', // Fallback location
      ]

      for (const syncNameFile of syncNameFiles) {
        try {
          if (fs.existsSync(syncNameFile)) {
            this.status.syncName = fs.readFileSync(syncNameFile, 'utf8').trim()
            console.log(`[STATUS] Loaded sync name from ${syncNameFile}:`, this.status.syncName)
            break
          }
        } catch (error) {
          console.log(`[STATUS] Could not load sync name from ${syncNameFile}:`, error.message)
        }
      }
    }

    // Load wallet address from environment
    this.status.walletAddress = process.env.WALLET_ADDRESS || ''
  }

  startSynchronizer() {
    const syncName = this.status.syncName
    const apiKey = process.env.SYNQ_KEY
    const walletAddress = process.env.WALLET_ADDRESS
    const depinEndpoint = process.env.DEPIN_ENDPOINT || 'wss://api.multisynq.io/depin'

    if (!apiKey || !walletAddress) {
      console.log('[STATUS] Missing required configuration, synchronizer not started')
      return
    }

    const args = [
      '/usr/src/synchronizer/wrapper.js',
      '--sync-name',
      syncName,
      '--key',
      apiKey,
      '--wallet',
      walletAddress,
      '--depin',
      depinEndpoint,
    ]

    console.log('[STATUS] Starting synchronizer process...')
    this.syncProcess = spawn('node', args, {
      stdio: ['pipe', 'pipe', 'pipe'],
      env: process.env,
    })

    this.syncProcess.stdout.on('data', (data) => {
      const output = data.toString().trim()
      console.log(`[SYNC] ${output}`)
      this.status.lastHeartbeat = Date.now()

      // Parse metrics from synchronizer output
      this.parseMetricsFromOutput(output)
    })

    this.syncProcess.stderr.on('data', (data) => {
      const output = data.toString().trim()
      console.error(`[SYNC ERROR] ${output}`)

      // Also try to parse metrics from error output
      this.parseMetricsFromOutput(output)
    })

    this.syncProcess.on('close', (code) => {
      console.log(`[STATUS] Synchronizer process exited with code ${code}`)
      this.status.online = false

      // Restart after 5 seconds if it wasn't intentionally stopped
      if (code !== 0) {
        setTimeout(() => {
          console.log('[STATUS] Restarting synchronizer...')
          this.startSynchronizer()
        }, 5000)
      }
    })

    this.status.online = true
    this.status.lastHeartbeat = Date.now()
  }

  checkSynchronizerHealth() {
    if (!this.syncProcess) {
      this.status.online = false
      return
    }

    // Check if process is still running
    try {
      process.kill(this.syncProcess.pid, 0)

      // Check if we've had recent output (heartbeat)
      const timeSinceHeartbeat = Date.now() - (this.status.lastHeartbeat || 0)
      this.status.online = timeSinceHeartbeat < 60000 // 1 minute timeout
    } catch (error) {
      this.status.online = false
      this.syncProcess = null
    }
  }

  parseMetricsFromOutput(output) {
    try {
      // Look for JSON objects with metrics data
      const jsonMatch = output.match(/\{.*"syncLifePoints".*\}/)
      if (jsonMatch) {
        const metricsData = JSON.parse(jsonMatch[0])
        this.updateMetrics(metricsData)
        return
      }

      // Look for UPDATE_TALLIES messages from registry
      const updateTalliesMatch = output.match(/\{.*"what":\s*"UPDATE_TALLIES".*\}/)
      if (updateTalliesMatch) {
        const talliesData = JSON.parse(updateTalliesMatch[0])
        this.updateMetrics(talliesData)
        return
      }

      // Parse individual metric lines
      const pointsMatch = output.match(/points?[:\s]+(\d+)/i)
      const trafficMatch = output.match(/traffic[:\s]+(\d+)/i)
      const sessionsMatch = output.match(/sessions?[:\s]+(\d+)/i)
      const usersMatch = output.match(/users?[:\s]+(\d+)/i)

      if (pointsMatch || trafficMatch || sessionsMatch || usersMatch) {
        const updates = {}
        if (pointsMatch) updates.syncLifePoints = parseInt(pointsMatch[1])
        if (trafficMatch) updates.syncLifeTraffic = parseInt(trafficMatch[1])
        if (sessionsMatch) updates.sessions = parseInt(sessionsMatch[1])
        if (usersMatch) updates.users = parseInt(usersMatch[1])

        this.updateMetrics(updates)
      }
    } catch (error) {
      // Ignore parsing errors, continue with other methods
    }
  }

  updateMetrics(data) {
    console.log('[STATUS] Updating metrics:', data)

    // Update metrics object
    if (data.sessions !== undefined) this.metrics.sessions = data.sessions
    if (data.users !== undefined) this.metrics.users = data.users
    if (data.bytesIn !== undefined) this.metrics.bytesIn = data.bytesIn
    if (data.bytesOut !== undefined) this.metrics.bytesOut = data.bytesOut
    if (data.syncLifePoints !== undefined) this.metrics.syncLifePoints = data.syncLifePoints
    if (data.walletLifePoints !== undefined) this.metrics.walletLifePoints = data.walletLifePoints
    if (data.syncLifeTraffic !== undefined) this.metrics.syncLifeTraffic = data.syncLifeTraffic
    if (data.proxyConnectionState !== undefined) this.metrics.proxyConnectionState = data.proxyConnectionState

    // Update performance data
    this.performance = {
      totalTraffic: this.metrics.syncLifeTraffic || this.metrics.bytesIn + this.metrics.bytesOut || 0,
      sessions: this.metrics.sessions || 0,
      users: this.metrics.users || 0,
      bytesIn: this.metrics.bytesIn || 0,
      bytesOut: this.metrics.bytesOut || 0,
      proxyConnectionState: this.metrics.proxyConnectionState || 'UNKNOWN',
    }

    // Update QoS data
    if (data.availability !== undefined) this.qos.availability = data.availability
    if (data.reliability !== undefined) this.qos.reliability = data.reliability
    if (data.efficiency !== undefined) this.qos.efficiency = data.efficiency
    if (data.ratingsBlurbs !== undefined) this.qos.ratingsBlurbs = data.ratingsBlurbs

    // Calculate QoS score (40% base + 10% for each point under 2)
    const availabilityRating = this.qos.availability
    const reliabilityRating = this.qos.reliability
    const efficiencyRating = this.qos.efficiency
    this.qos.score = 40 + 10 * (2 - availabilityRating + (2 - reliabilityRating) + (2 - efficiencyRating))

    // Determine if earning based on connection state and activity
    const isEarning = this.metrics.proxyConnectionState === 'CONNECTED' || this.metrics.sessions > 0 || this.metrics.users > 0

    this.status.online = isEarning || this.metrics.proxyConnectionState !== 'UNKNOWN'
  }

  updateMetricsFromContainerStats(containerStats) {
    console.log('[STATUS] Updating metrics from container stats')

    // Update metrics object
    this.metrics.sessions = containerStats.sessions || 0
    this.metrics.users = containerStats.users || 0
    this.metrics.bytesIn = containerStats.bytesIn || 0
    this.metrics.bytesOut = containerStats.bytesOut || 0
    this.metrics.syncLifePoints = containerStats.syncLifePoints || 0
    this.metrics.walletLifePoints = containerStats.walletLifePoints || 0
    this.metrics.syncLifeTraffic = containerStats.syncLifeTraffic || 0
    this.metrics.proxyConnectionState = containerStats.proxyConnectionState || 'UNKNOWN'

    // Update performance data
    this.performance = {
      totalTraffic: this.metrics.syncLifeTraffic || this.metrics.bytesIn + this.metrics.bytesOut || 0,
      sessions: this.metrics.sessions || 0,
      users: this.metrics.users || 0,
      bytesIn: this.metrics.bytesIn || 0,
      bytesOut: this.metrics.bytesOut || 0,
      proxyConnectionState: this.metrics.proxyConnectionState || 'UNKNOWN',
    }

    // Update QoS data
    this.qos.availability = containerStats.availability !== undefined ? containerStats.availability : 2
    this.qos.reliability = containerStats.reliability !== undefined ? containerStats.reliability : 2
    this.qos.efficiency = containerStats.efficiency !== undefined ? containerStats.efficiency : 2
    this.qos.ratingsBlurbs = containerStats.ratingsBlurbs || null

    // Calculate QoS score
    this.qos.score = 40 + 10 * (2 - this.qos.availability + (2 - this.qos.reliability) + (2 - this.qos.efficiency))

    // Update status
    const isEarning = containerStats.isEarningPoints || this.metrics.proxyConnectionState === 'CONNECTED'
    this.status.online = isEarning || this.metrics.proxyConnectionState !== 'UNKNOWN'
  }

  async collectMetrics() {
    // This method is now replaced by the robust getContainerStats() approach
    // but kept for backward compatibility
    try {
      const containerStats = await this.getContainerStats()
      if (containerStats) this.updateMetricsFromContainerStats(containerStats)
    } catch (error) {
      console.log('[STATUS] Error collecting metrics:', error.message)
    }
  }

  parsePrometheusMetrics(metricsText) {
    try {
      console.log('[STATUS] Parsing Prometheus metrics...')

      const extractMetricValue = (metricName) => {
        const lines = metricsText.split('\n')
        for (const line of lines) {
          if (line.startsWith(metricName) && !line.startsWith('#')) {
            const parts = line.split(' ')
            if (parts.length >= 2) return parseFloat(parts[1]) || 0
          }
        }
        return null
      }

      // Extract known metrics
      const connections = extractMetricValue('reflector_connections')
      const sessions = extractMetricValue('reflector_sessions')
      const messages = extractMetricValue('reflector_messages')

      if (connections !== null || sessions !== null) {
        const stats = {
          users: connections || 0,
          sessions: sessions || 0,
          messages: messages || 0,
          isEarning: (connections > 0 || sessions > 0),
          proxyConnectionState: (connections > 0 || sessions > 0) ? 'CONNECTED' : 'UNKNOWN',
          dataSource: 'http_metrics'
        }

        console.log('[STATUS] Parsed metrics from Prometheus data:', stats)
        return stats
      }

      return null
    } catch (error) {
      console.log('[STATUS] Error parsing Prometheus metrics:', error.message)
      return null
    }
  }

  /**
   * Get latest container stats using log parsing and HTTP metrics
   */
  async getContainerStats() {
    try {
      const now = Date.now()

      // Check cache first
      if (lastStatsResult && now - lastStatsRequestTime < STATS_CACHE_DURATION) return lastStatsResult

      // Rate limiting
      if (lastStatsRequestTime > 0 && now - lastStatsRequestTime < STATS_REQUEST_COOLDOWN) return lastStatsResult || null

      // Prevent race conditions
      if (statsRequestInProgress) return await statsRequestInProgress

      console.log('[STATUS] Making fresh stats request...')

      statsRequestInProgress = (async () => {
        try {
          // Find running synchronizer container
          const containerNames = ['synchronizer-cli', 'synchronizer-nightly']
          let containerName = null

          for (const name of containerNames) {
            try {
              const psOutput = execSync(`docker ps --filter name=${name} --format "{{.Names}}"`, {
                encoding: 'utf8',
                stdio: 'pipe',
              })

              if (psOutput.includes(name)) {
                containerName = name
                break
              }
            } catch (error) {
              continue
            }
          }

          if (!containerName) {
            console.log('[STATUS] No synchronizer container running')
            return null
          }

          // Get container uptime
          const inspectOutput = execSync(`docker inspect ${containerName} --format "{{.State.StartedAt}}"`, {
            encoding: 'utf8',
            stdio: 'pipe',
          })

          const startTime = new Date(inspectOutput.trim())
          const uptimeMs = Date.now() - startTime.getTime()
          const uptimeHours = uptimeMs / (1000 * 60 * 60)

          // Try HTTP metrics first, then fall back to log parsing
          let realStats = await this.tryHttpMetrics(containerName)
          
          if (!realStats) {
            console.log('[STATUS] HTTP metrics failed, parsing logs')
            realStats = await this.parseContainerLogs(containerName)
          }

          if (realStats) {
            const result = {
              bytesIn: realStats.bytesIn || 0,
              bytesOut: realStats.bytesOut || 0,
              sessions: realStats.sessions || 0,
              users: realStats.users || 0,
              syncLifePoints: realStats.syncLifePoints || 0,
              syncLifeTraffic: realStats.syncLifeTraffic || realStats.bytesIn + realStats.bytesOut || 0,
              walletLifePoints: realStats.walletLifePoints || 0,
              walletBalance: realStats.walletBalance || 0,
              availability: realStats.availability !== undefined ? realStats.availability : 2,
              reliability: realStats.reliability !== undefined ? realStats.reliability : 2,
              efficiency: realStats.efficiency !== undefined ? realStats.efficiency : 2,
              ratingsBlurbs: realStats.ratingsBlurbs || null,
              proxyConnectionState: realStats.proxyConnectionState || 'UNKNOWN',
              uptimeHours: uptimeHours,
              isEarningPoints: realStats.isEarning || false,
              hasRealStats: true,
              containerStartTime: startTime.toISOString(),
              dataSource: realStats.dataSource || 'log_parsing',
            }

            console.log(
              `[STATUS] Stats retrieved: ${result.dataSource}, Points: ${result.walletLifePoints}, Traffic: ${result.syncLifeTraffic}`
            )
            return result
          }

          return null
        } finally {
          statsRequestInProgress = null
        }
      })()

      const result = await statsRequestInProgress
      lastStatsRequestTime = now
      lastStatsResult = result

      return result
    } catch (error) {
      console.log(`[STATUS] Error in getContainerStats: ${error.message}`)
      statsRequestInProgress = null
      return lastStatsResult || null
    }
  }

  /**
   * Try to get metrics from HTTP endpoint
   */
  async tryHttpMetrics(containerName) {
    try {
      // Get container IP address
      let containerIP = 'localhost'
      
      try {
        const inspectOutput = execSync(
          `docker inspect ${containerName} --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}"`,
          {
            encoding: 'utf8',
            stdio: 'pipe',
          }
        ).trim()

        if (inspectOutput && inspectOutput !== '<no value>') {
          containerIP = inspectOutput
        }
      } catch (error) {
        // Use localhost as fallback
      }

      // Try to fetch Prometheus metrics
      const options = {
        hostname: containerIP,
        port: 9090,
        path: '/metrics',
        method: 'GET',
        timeout: 5000
      }

      return new Promise((resolve) => {
        const req = http.request(options, (res) => {
          let data = ''
          
          res.on('data', (chunk) => {
            data += chunk
          })
          
          res.on('end', () => {
            const metrics = this.parsePrometheusMetrics(data)
            if (metrics) {
              metrics.dataSource = 'http_metrics'
              resolve(metrics)
            } else {
              resolve(null)
            }
          })
        })
        
        req.on('error', () => {
          resolve(null)
        })
        
        req.on('timeout', () => {
          req.destroy()
          resolve(null)
        })
        
        req.end()
      })

    } catch (error) {
      console.log(`[STATUS] HTTP metrics error: ${error.message}`)
      return null
    }
  }

  /**
   * Parse container logs for stats (fallback)
   */
  async parseContainerLogs(containerName) {
    try {
      const logsOutput = execSync(`docker logs ${containerName} --tail 100`, {
        encoding: 'utf8',
        stdio: 'pipe',
        timeout: 10000,
      })

      const isEarning =
        logsOutput.includes('proxy-connected') ||
        logsOutput.includes('registered') ||
        logsOutput.includes('session') ||
        logsOutput.includes('traffic') ||
        logsOutput.includes('stats')

      let realStats = null
      const logLines = logsOutput.split('\n')

      for (const line of logLines.reverse()) {
        try {
          // Look for JSON stats
          const jsonMatch = line.match(/\{.*"syncLifePoints".*\}/)
          if (jsonMatch) {
            const statsData = JSON.parse(jsonMatch[0])
            if (statsData.syncLifePoints !== undefined || statsData.walletLifePoints !== undefined) {
              realStats = { ...statsData, isEarning }
              break
            }
          }

          // Look for UPDATE_TALLIES
          const updateTalliesMatch = line.match(/\{.*"what":\s*"UPDATE_TALLIES".*\}/)
          if (updateTalliesMatch) {
            const talliesData = JSON.parse(updateTalliesMatch[0])
            if (talliesData.walletPoints !== undefined) {
              realStats = realStats || { isEarning }
              realStats.walletLifePoints = talliesData.walletPoints
              realStats.syncLifePoints = talliesData.lifePoints || realStats.syncLifePoints
              realStats.syncLifeTraffic = talliesData.lifeTraffic || realStats.syncLifeTraffic
            }
          }
        } catch (parseError) {
          continue
        }
      }

      return realStats
    } catch (error) {
      console.log(`[STATUS] Could not parse container logs: ${error.message}`)
      return null
    }
  }

  /**
   * Get performance data using cache-aware approach
   */
  async getPerformanceData() {
    const now = Date.now()

    // PRIORITY 1: Fresh container stats data
    const containerStats = await this.getContainerStats()
    if (containerStats && containerStats.hasRealStats) {
      let performance = {
        totalTraffic: containerStats.syncLifeTraffic || containerStats.bytesIn + containerStats.bytesOut || 0,
        sessions: containerStats.sessions || 0,
        users: containerStats.users || 0,
        demoSessions: containerStats.demoSessions || 0,
        bytesIn: containerStats.bytesIn || 0,
        bytesOut: containerStats.bytesOut || 0,
        proxyConnectionState: containerStats.proxyConnectionState || 'UNKNOWN',
      }

      // QoS calculations
      const availability = containerStats.availability !== undefined ? containerStats.availability : 2
      const reliability = containerStats.reliability !== undefined ? containerStats.reliability : 2
      const efficiency = containerStats.efficiency !== undefined ? containerStats.efficiency : 2

      const score = 40 + 10 * (2 - availability + (2 - reliability) + (2 - efficiency))

      let qos = {
        score: score,
        reliability: reliability,
        availability: availability,
        efficiency: efficiency,
        ratingsBlurbs: containerStats.ratingsBlurbs || null,
      }

      const result = {
        timestamp: new Date().toISOString(),
        performance,
        qos,
      }

      // Cache the result
      globalCache.performance = {
        data: result,
        timestamp: now,
      }

      return result
    }

    // PRIORITY 2: Use cached data if recent
    if (globalCache.performance.data && now - globalCache.performance.timestamp < DASHBOARD_CACHE_DURATION) {
      return globalCache.performance.data
    }

    // PRIORITY 3: Generate fallback data
    let performance = {
      totalTraffic: 0,
      sessions: 0,
      users: 0,
      demoSessions: 0,
      bytesIn: 0,
      bytesOut: 0,
      proxyConnectionState: 'UNKNOWN',
    }

    let qos = {
      score: 5,
      reliability: 10,
      availability: 0,
      efficiency: 5,
      ratingsBlurbs: null,
    }

    const result = {
      timestamp: new Date().toISOString(),
      performance,
      qos,
    }

    globalCache.performance = {
      data: result,
      timestamp: now,
    }

    return result
  }

  /**
   * Get points data using cache-aware approach
   */
  async getPointsData() {
    const now = Date.now()

    // PRIORITY 1: Fresh WebSocket data overrides cache
    const containerStats = await this.getContainerStats()
    if (containerStats && containerStats.hasWebSocketData) {
      const walletLifePoints = containerStats.walletLifePoints || 0
      const syncLifePoints = containerStats.syncLifePoints || 0
      const walletBalance = containerStats.walletBalance || 0

      const result = {
        timestamp: new Date().toISOString(),
        points: {
          total: walletLifePoints + syncLifePoints,
          daily: 0,
          weekly: 0,
          monthly: 0,
          streak: 0,
          rank: 'N/A',
          multiplier: 'N/A',
        },
        syncLifePoints: syncLifePoints,
        walletLifePoints: walletLifePoints,
        walletBalance: walletBalance,
        source: 'websocket_priority',
        containerUptime: `${(containerStats.uptimeHours || 0).toFixed(1)} hours`,
        isEarning: containerStats.isEarningPoints,
        connectionState: containerStats.proxyConnectionState,
      }

      globalCache.points = {
        data: result,
        timestamp: now,
      }

      return result
    }

    // PRIORITY 2: Use cached data if recent
    if (globalCache.points.data && !globalCache.points.data.error && now - globalCache.points.timestamp < DASHBOARD_CACHE_DURATION) {
      return globalCache.points.data
    }

    // PRIORITY 3: Container stats fallback
    if (containerStats && containerStats.hasRealStats) {
      const walletLifePoints = containerStats.walletLifePoints || 0
      const syncLifePoints = containerStats.syncLifePoints || 0
      const walletBalance = containerStats.walletBalance || 0

      const result = {
        timestamp: new Date().toISOString(),
        points: {
          total: walletLifePoints + syncLifePoints,
          daily: 0,
          weekly: 0,
          monthly: 0,
          streak: 0,
          rank: 'N/A',
          multiplier: 'N/A',
        },
        syncLifePoints: syncLifePoints,
        walletLifePoints: walletLifePoints,
        walletBalance: walletBalance,
        source: 'container_stats',
        containerUptime: `${(containerStats.uptimeHours || 0).toFixed(1)} hours`,
        isEarning: containerStats.isEarningPoints,
        connectionState: containerStats.proxyConnectionState,
      }

      globalCache.points = {
        data: result,
        timestamp: now,
      }

      return result
    }

    // PRIORITY 4: Error fallback
    const result = {
      timestamp: new Date().toISOString(),
      points: {
        total: 0,
        daily: 0,
        weekly: 0,
        monthly: 0,
        streak: 0,
        rank: 'N/A',
        multiplier: '1.0',
      },
      syncLifePoints: null,
      walletLifePoints: null,
      walletBalance: null,
      error: 'Synchronizer container not running - start it first',
      fallback: true,
    }

    globalCache.points = {
      data: result,
      timestamp: now,
    }

    return result
  }
}

// Start the status server
const statusServer = new StatusServer()
statusServer.start()

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('[STATUS] Received SIGTERM, shutting down gracefully...')
  if (statusServer.syncProcess) statusServer.syncProcess.kill('SIGTERM')
  process.exit(0)
})

process.on('SIGINT', () => {
  console.log('[STATUS] Received SIGINT, shutting down gracefully...')
  if (statusServer.syncProcess) statusServer.syncProcess.kill('SIGINT')
  process.exit(0)
})
