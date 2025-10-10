// Admin Dashboard Configuration
const adminConfig = {
    ...config, // Inherit from main dashboard config
    passwordEnabled: false, // Set to true and configure password below
    password: '', // Set your password here (or leave empty if no password)
    sessionTimeout: 3600000, // 1 hour in milliseconds
};

// Authentication Functions
function authenticate() {
    const inputPassword = document.getElementById('auth-password').value;
    
    if (!adminConfig.passwordEnabled || adminConfig.password === '') {
        // No password required
        grantAccess();
        return;
    }
    
    if (inputPassword === adminConfig.password) {
        grantAccess();
        // Store session
        localStorage.setItem('adminSession', Date.now().toString());
    } else {
        alert('❌ Incorrect password');
        document.getElementById('auth-password').value = '';
    }
}

function skipAuth() {
    if (!adminConfig.passwordEnabled || adminConfig.password === '') {
        grantAccess();
    } else {
        alert('⚠️ Password is required for this dashboard');
    }
}

function grantAccess() {
    document.getElementById('auth-overlay').style.display = 'none';
    document.getElementById('dashboard-content').style.display = 'flex';
    initAdminDashboard();
}

function logout() {
    localStorage.removeItem('adminSession');
    location.reload();
}

function checkSession() {
    if (!adminConfig.passwordEnabled || adminConfig.password === '') {
        // No authentication required
        grantAccess();
        return;
    }
    
    const session = localStorage.getItem('adminSession');
    if (session) {
        const sessionTime = parseInt(session);
        const now = Date.now();
        
        if (now - sessionTime < adminConfig.sessionTimeout) {
            // Valid session
            grantAccess();
            return;
        } else {
            // Session expired
            localStorage.removeItem('adminSession');
        }
    }
    
    // Show auth overlay
    document.getElementById('auth-overlay').style.display = 'flex';
}

// Handle Enter key in password field
document.addEventListener('DOMContentLoaded', () => {
    const passwordInput = document.getElementById('auth-password');
    if (passwordInput) {
        passwordInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                authenticate();
            }
        });
    }
});

// Enhanced Admin Functions
async function fetchPoolHealth() {
    try {
        const response = await fetch(`${config.apiUrl}/health-check`);
        return response.ok;
    } catch (error) {
        return false;
    }
}

async function fetchAdminStats() {
    try {
        const response = await fetch(`${config.apiUrl}/admin/stats/gc`);
        if (!response.ok) return null;
        return await response.json();
    } catch (error) {
        console.error('Error fetching admin stats:', error);
        return null;
    }
}

// Update Admin UI
function updateSystemStatus(pool, isApiResponding) {
    const poolStatus = document.getElementById('pool-status');
    const nodeStatus = document.getElementById('node-connection');
    const apiIndicator = document.getElementById('api-status');
    const nodeIndicator = document.getElementById('node-status');
    
    // Determine if pool is actually working based on data presence
    const poolIsWorking = pool && pool.networkStats && pool.networkStats.blockHeight > 0;
    const nodeIsConnected = pool && pool.networkStats && pool.networkStats.connectedPeers > 0;
    
    console.log('[Admin Status] pool:', !!pool, 'networkStats:', !!pool?.networkStats);
    console.log('[Admin Status] blockHeight:', pool?.networkStats?.blockHeight);
    console.log('[Admin Status] connectedPeers:', pool?.networkStats?.connectedPeers);
    console.log('[Admin Status] poolIsWorking:', poolIsWorking, 'nodeIsConnected:', nodeIsConnected);
    
    // Update Pool Status
    if (poolIsWorking) {
        poolStatus.innerHTML = '<span class="status-dot online"></span>Online';
        console.log('[Admin Status] Setting pool to ONLINE');
    } else if (isApiResponding) {
        poolStatus.innerHTML = '<span class="status-dot warning"></span>Starting...';
        console.log('[Admin Status] Setting pool to STARTING');
    } else {
        poolStatus.innerHTML = '<span class="status-dot offline"></span>Offline';
        console.log('[Admin Status] Setting pool to OFFLINE');
    }
    
    // Update Node Status
    if (nodeIsConnected) {
        nodeStatus.innerHTML = '<span class="status-dot online"></span>Connected';
        nodeIndicator.classList.add('online');
        nodeIndicator.classList.remove('offline');
        console.log('[Admin Status] Setting node to CONNECTED');
    } else if (poolIsWorking) {
        nodeStatus.innerHTML = '<span class="status-dot warning"></span>Syncing...';
        nodeIndicator.classList.remove('online');
        nodeIndicator.classList.remove('offline');
        console.log('[Admin Status] Setting node to SYNCING');
    } else {
        nodeStatus.innerHTML = '<span class="status-dot offline"></span>Disconnected';
        nodeIndicator.classList.add('offline');
        nodeIndicator.classList.remove('online');
        console.log('[Admin Status] Setting node to DISCONNECTED');
    }
    
    // Update API Indicator
    if (poolIsWorking) {
        apiIndicator.classList.add('online');
        apiIndicator.classList.remove('offline');
        console.log('[Admin Status] Setting API indicator to ONLINE');
    } else {
        apiIndicator.classList.add('offline');
        apiIndicator.classList.remove('online');
        console.log('[Admin Status] Setting API indicator to OFFLINE');
    }
}

function updateAdminPoolStats(pool) {
    if (!pool) return;
    
    // Basic stats (from parent dashboard.js)
    updatePoolStats(pool);
    
    // Additional admin stats
    const stats = pool.poolStats || {};
    const network = pool.networkStats || {};
    
    // Calculate pool network share
    if (stats.poolHashrate && network.networkHashrate) {
        const share = (stats.poolHashrate / network.networkHashrate * 100);
        document.getElementById('pool-network-share').textContent = `${share.toFixed(4)}%`;
    }
    
    // Valid/Invalid shares (placeholder - would need API extension)
    document.getElementById('valid-shares').textContent = '--';
    document.getElementById('invalid-shares').textContent = '--';
    document.getElementById('share-rate').textContent = `${(stats.sharesPerSecond || 0).toFixed(3)}/s`;
    
    // Performance metrics
    document.getElementById('avg-block-time').textContent = '120s (2m)';
    document.getElementById('pool-efficiency').textContent = pool.poolEffort ? `${(100 / pool.poolEffort * 100).toFixed(2)}%` : '--';
    
    // Expected blocks per day
    if (stats.poolHashrate && network.networkHashrate) {
        const blocksPerDay = (720 * (stats.poolHashrate / network.networkHashrate)); // 720 blocks per day
        document.getElementById('expected-blocks').textContent = blocksPerDay.toFixed(2);
    } else {
        document.getElementById('expected-blocks').textContent = '--';
    }
    
    document.getElementById('actual-blocks').textContent = '--'; // Would need 24h block count
    document.getElementById('luck-factor').textContent = '--';
}

function updateBlocksTable(blocks) {
    const tbody = document.getElementById('blocks-table-body');
    
    if (!blocks || blocks.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty-state">No blocks found</td></tr>';
        return;
    }
    
    tbody.innerHTML = blocks.map(block => `
        <tr class="fade-in">
            <td class="highlight-cyan">#${formatNumber(block.blockHeight)}</td>
            <td><span class="status-badge ${block.status.toLowerCase()}">${block.status}</span></td>
            <td class="highlight-yellow">${block.reward.toFixed(4)} ERG</td>
            <td>${block.effort ? block.effort.toFixed(2) + '%' : '--'}</td>
            <td class="mono">${formatTimeAgo(block.created)}</td>
            <td class="mono">${truncateAddress(block.miner || 'Unknown', 8, 6)}</td>
        </tr>
    `).join('');
}

function updateMinersTable(miners) {
    const tbody = document.getElementById('miners-table-body');
    
    if (!miners || miners.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="empty-state">No active miners</td></tr>';
        return;
    }
    
    tbody.innerHTML = miners.map(miner => `
        <tr class="fade-in">
            <td class="mono">${truncateAddress(miner.miner, 12, 8)}</td>
            <td class="highlight-green">${formatHashrate(miner.hashrate)}</td>
            <td>${miner.workerCount || 1}</td>
            <td>${(miner.sharesPerSecond || 0).toFixed(3)}</td>
            <td>--</td>
        </tr>
    `).join('');
}

function updateAlerts(pool) {
    const alertsList = document.getElementById('alerts-list');
    const alerts = [];
    
    // Check if pool is working
    const poolIsWorking = pool && pool.networkStats && pool.networkStats.blockHeight > 0;
    
    if (poolIsWorking) {
        alerts.push({ type: 'success', message: '✓ Pool running normally' });
        
        // Check for miners
        if (pool.poolStats) {
            const minerCount = pool.poolStats.connectedMiners || 0;
            const hashrate = pool.poolStats.poolHashrate || 0;
            
            if (minerCount === 0 && hashrate === 0) {
                alerts.push({ type: 'info', message: 'ℹ Waiting for miners to connect' });
            } else if (minerCount > 0) {
                alerts.push({ type: 'success', message: `✓ ${minerCount} miner(s) connected` });
            }
            
            if (hashrate > 0) {
                alerts.push({ type: 'success', message: `✓ Pool hashrate: ${formatHashrate(hashrate)}` });
            }
        }
        
        // Check node peers
        if (pool.networkStats && pool.networkStats.connectedPeers) {
            alerts.push({ type: 'success', message: `✓ Node connected to ${pool.networkStats.connectedPeers} peers` });
        }
    } else {
        alerts.push({ type: 'error', message: '✗ Unable to retrieve pool data' });
        alerts.push({ type: 'info', message: 'ℹ Check if Miningcore is running: docker-compose ps' });
    }
    
    alertsList.innerHTML = alerts.map(alert => `
        <div class="alert-item alert-${alert.type}">${alert.message}</div>
    `).join('');
}

// System Monitoring Functions
async function fetchSystemDisk() {
    try {
        const response = await fetch('/api/admin/system/disk');
        if (!response.ok) return null;
        return await response.json();
    } catch (error) {
        console.error('Error fetching disk info:', error);
        return null;
    }
}

async function fetchSystemComponents() {
    try {
        const response = await fetch('/api/admin/system/components');
        if (!response.ok) return null;
        return await response.json();
    } catch (error) {
        console.error('Error fetching component sizes:', error);
        return null;
    }
}

async function fetchSystemPerformance() {
    try {
        const response = await fetch('/api/admin/system/performance');
        if (!response.ok) return null;
        return await response.json();
    } catch (error) {
        console.error('Error fetching performance metrics:', error);
        return null;
    }
}

async function fetchDockerStats() {
    try {
        const response = await fetch('/api/admin/system/docker');
        if (!response.ok) return null;
        return await response.json();
    } catch (error) {
        console.error('Error fetching Docker stats:', error);
        return null;
    }
}

// Update System Resources Widget
function updateSystemResources(diskData, perfData) {
    if (diskData) {
        const usagePercent = diskData.usagePercent || 0;
        document.getElementById('disk-percent').textContent = `${usagePercent}%`;
        document.getElementById('disk-used').textContent = diskData.used || '--';
        document.getElementById('disk-total').textContent = diskData.total || '--';
        
        // Update progress bar
        const progressBar = document.getElementById('disk-progress');
        progressBar.style.width = `${usagePercent}%`;
        
        // Color based on usage
        progressBar.classList.remove('warning', 'critical');
        if (usagePercent >= 90) {
            progressBar.classList.add('critical');
        } else if (usagePercent >= 80) {
            progressBar.classList.add('warning');
        }
    }
    
    if (perfData && perfData.metrics) {
        const metrics = perfData.metrics;
        
        // CPU Usage
        if (metrics.cpuUsage !== undefined && metrics.cpuUsage !== 'N/A') {
            document.getElementById('cpu-usage').textContent = `${metrics.cpuUsage}%`;
        }
        
        // Memory Usage
        if (metrics.memory && metrics.memory !== 'N/A') {
            document.getElementById('memory-usage').textContent = 
                `${metrics.memory.usagePercent}% (${metrics.memory.used} / ${metrics.memory.total})`;
        }
        
        // Load Average
        if (metrics.loadAverage && metrics.loadAverage !== 'N/A') {
            document.getElementById('load-average').textContent = 
                `${metrics.loadAverage['1min']} ${metrics.loadAverage['5min']} ${metrics.loadAverage['15min']}`;
        }
    }
}

// Update Component Sizes Widget
function updateComponentSizes(diskData) {
    if (diskData && diskData.components) {
        const comp = diskData.components;
        document.getElementById('postgres-size').textContent = comp.postgresql || 'N/A';
        document.getElementById('node-size').textContent = comp.ergoNode || 'N/A';
        document.getElementById('logs-size').textContent = comp.logs || 'N/A';
        document.getElementById('backups-size').textContent = comp.backups || 'N/A';
    }
}

// Update Docker Containers Widget
function updateDockerContainers(dockerData) {
    const containersList = document.getElementById('docker-containers-list');
    
    if (dockerData && dockerData.containers && dockerData.containers.length > 0) {
        containersList.innerHTML = dockerData.containers.map(container => {
            const name = container.name || 'Unknown';
            const cpu = container.cpu || '0%';
            const memory = container.memory || 'N/A';
            
            return `
                <div class="stat-row">
                    <span class="stat-label">${name}:</span>
                    <span class="stat-value">
                        <span class="highlight-cyan">${cpu}</span> | 
                        <span class="highlight-green">${memory}</span>
                    </span>
                </div>
            `;
        }).join('');
    } else {
        containersList.innerHTML = '<div class="stat-row"><span class="stat-label">No containers running</span></div>';
    }
}

// Enhanced Alert System
function updateEnhancedAlerts(pool, diskData, perfData) {
    const alertsList = document.getElementById('alerts-list');
    const alerts = [];
    
    // Check if pool is working
    const poolIsWorking = pool && pool.networkStats && pool.networkStats.blockHeight > 0;
    
    if (poolIsWorking) {
        alerts.push({ type: 'success', message: '✓ Pool running normally' });
        
        // Check for miners
        if (pool.poolStats) {
            const minerCount = pool.poolStats.connectedMiners || 0;
            const hashrate = pool.poolStats.poolHashrate || 0;
            
            if (minerCount === 0 && hashrate === 0) {
                alerts.push({ type: 'info', message: 'ℹ Waiting for miners to connect' });
            } else if (minerCount > 0) {
                alerts.push({ type: 'success', message: `✓ ${minerCount} miner(s) connected` });
            }
            
            if (hashrate > 0) {
                alerts.push({ type: 'success', message: `✓ Pool hashrate: ${formatHashrate(hashrate)}` });
            }
        }
        
        // Check node peers
        if (pool.networkStats && pool.networkStats.connectedPeers) {
            alerts.push({ type: 'success', message: `✓ Node connected to ${pool.networkStats.connectedPeers} peers` });
        }
    } else {
        alerts.push({ type: 'error', message: '✗ Unable to retrieve pool data' });
        alerts.push({ type: 'info', message: 'ℹ Check if Miningcore is running: docker-compose ps' });
    }
    
    // Disk space alerts
    if (diskData && diskData.usagePercent !== undefined) {
        if (diskData.usagePercent >= 90) {
            alerts.push({ type: 'error', message: `⚠️ CRITICAL: Disk usage at ${diskData.usagePercent}%` });
        } else if (diskData.usagePercent >= 80) {
            alerts.push({ type: 'warning', message: `⚠️ WARNING: Disk usage at ${diskData.usagePercent}%` });
        }
    }
    
    // CPU alerts
    if (perfData && perfData.metrics && perfData.metrics.cpuUsage !== 'N/A') {
        if (perfData.metrics.cpuUsage >= 90) {
            alerts.push({ type: 'warning', message: `⚠️ High CPU usage: ${perfData.metrics.cpuUsage}%` });
        }
    }
    
    // Memory alerts
    if (perfData && perfData.metrics && perfData.metrics.memory !== 'N/A') {
        if (perfData.metrics.memory.usagePercent >= 90) {
            alerts.push({ type: 'warning', message: `⚠️ High memory usage: ${perfData.metrics.memory.usagePercent}%` });
        }
    }
    
    alertsList.innerHTML = alerts.map(alert => `
        <div class="alert-item alert-${alert.type}">${alert.message}</div>
    `).join('');
}

// Admin Dashboard Update Function
async function updateAdminDashboard() {
    try {
        console.log('[Admin] Fetching data...');
        const [poolResponse, blocks, miners, isHealthy, adminStats, diskData, componentData, perfData, dockerData] = await Promise.all([
            fetchPoolData(),
            fetchBlocks(),
            fetchMiners(),
            fetchPoolHealth(),
            fetchAdminStats(),
            fetchSystemDisk(),
            fetchSystemComponents(),
            fetchSystemPerformance(),
            fetchDockerStats()
        ]);
        
        console.log('[Admin] Pool data received:', poolResponse);
        
        // Extract pool from response (API returns {pool: {...}})
        const pool = poolResponse;
        
        // Update system status based on actual pool data
        const isApiResponding = isHealthy || (pool !== null);
        console.log('[Admin] Updating status - pool exists:', !!pool, 'API responding:', isApiResponding);
        
        updateSystemStatus(pool, isApiResponding);
        
        if (pool) {
            updateAdminPoolStats(pool);
            
            // Update database status based on pool data presence
            document.getElementById('db-status').innerHTML = '<span class="status-dot online"></span>Healthy';
        } else {
            // If no pool data, database might be unreachable
            document.getElementById('db-status').innerHTML = '<span class="status-dot warning"></span>Unknown';
        }
        
        updateBlocksTable(blocks);
        updateMinersTable(miners);
        
        // Update system monitoring widgets
        updateSystemResources(diskData, perfData);
        updateComponentSizes(diskData);
        updateDockerContainers(dockerData);
        updateEnhancedAlerts(pool, diskData, perfData);
        
        updateLastUpdateTime();
        
        console.log('[Admin] Dashboard updated successfully');
        
    } catch (error) {
        console.error('[Admin] Error updating dashboard:', error);
        updateSystemStatus(null, false);
        document.getElementById('db-status').innerHTML = '<span class="status-dot offline"></span>Error';
    }
}

// Chart Controls
function setupChartControls() {
    const chartBtns = document.querySelectorAll('.chart-btn');
    chartBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            chartBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            const range = this.getAttribute('data-range');
            console.log(`Chart range changed to: ${range}`);
            // Would implement chart data refresh here
        });
    });
}

// Quick Action Functions
function refreshDashboard() {
    console.log('Refreshing dashboard...');
    updateAdminDashboard();
}

function viewLogs() {
    // Would implement log viewer modal here
    alert('📄 Log viewer would open here. Check logs/miningcore-solo.log on the server.');
}

// Initialize Admin Dashboard
function initAdminDashboard() {
    console.log('Initializing admin dashboard...');
    
    // Set up chart controls
    setupChartControls();
    
    // Initial update
    updateAdminDashboard();
    
    // Set up auto-refresh
    setInterval(updateAdminDashboard, config.refreshInterval);
    
    console.log('Admin dashboard initialized');
}

// Check session on page load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', checkSession);
} else {
    checkSession();
}

