// Dashboard Configuration
const config = {
    apiUrl: '/api',  // Use relative URL - proxied through dashboard server
    poolId: 'ergo-solo',
    refreshInterval: 10000, // 10 seconds
    chartMaxDataPoints: 24,
};

// State Management
const state = {
    hashrates: [],
    shares: [],
    chart: null,
    hashrateSparkline: null,
    sharesSparkline: null,
};

// Utility Functions
function formatHashrate(hashrate) {
    if (!hashrate || hashrate === 0) return '0 H/s';
    
    const units = ['H/s', 'KH/s', 'MH/s', 'GH/s', 'TH/s', 'PH/s'];
    let unitIndex = 0;
    let value = hashrate;
    
    while (value >= 1000 && unitIndex < units.length - 1) {
        value /= 1000;
        unitIndex++;
    }
    
    return `${value.toFixed(2)} ${units[unitIndex]}`;
}

function formatNumber(num) {
    if (!num) return '0';
    return num.toLocaleString('en-US', { maximumFractionDigits: 2 });
}

function formatDifficulty(diff) {
    if (!diff) return '--';
    if (diff >= 1e12) return (diff / 1e12).toFixed(2) + 'T';
    if (diff >= 1e9) return (diff / 1e9).toFixed(2) + 'G';
    if (diff >= 1e6) return (diff / 1e6).toFixed(2) + 'M';
    if (diff >= 1e3) return (diff / 1e3).toFixed(2) + 'K';
    return diff.toFixed(2);
}

function formatTimeAgo(timestamp) {
    if (!timestamp) return '--';
    const now = new Date();
    const then = new Date(timestamp);
    const seconds = Math.floor((now - then) / 1000);
    
    if (seconds < 60) return `${seconds}s ago`;
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    return `${Math.floor(seconds / 86400)}d ago`;
}

function truncateAddress(address, start = 10, end = 8) {
    if (!address || address.length <= start + end) return address;
    return `${address.substring(0, start)}...${address.substring(address.length - end)}`;
}

// API Functions
async function fetchPoolData() {
    try {
        const response = await fetch(`${config.apiUrl}/pools/${config.poolId}`);
        if (!response.ok) throw new Error('Failed to fetch pool data');
        const data = await response.json();
        return data.pool;
    } catch (error) {
        console.error('Error fetching pool data:', error);
        updateApiStatus(false);
        return null;
    }
}

async function fetchBlocks() {
    try {
        const response = await fetch(`${config.apiUrl}/pools/${config.poolId}/blocks?page=0&pageSize=10`);
        if (!response.ok) throw new Error('Failed to fetch blocks');
        return await response.json();
    } catch (error) {
        console.error('Error fetching blocks:', error);
        return [];
    }
}

async function fetchMiners() {
    try {
        const response = await fetch(`${config.apiUrl}/pools/${config.poolId}/miners?page=0&pageSize=10`);
        if (!response.ok) throw new Error('Failed to fetch miners');
        return await response.json();
    } catch (error) {
        console.error('Error fetching miners:', error);
        return [];
    }
}

// UI Update Functions
function updatePoolStats(pool) {
    if (!pool) return;
    
    const stats = pool.poolStats || {};
    const network = pool.networkStats || {};
    
    // Helper function to safely update element
    function safeUpdate(id, value) {
        const element = document.getElementById(id);
        if (element) element.textContent = value;
    }
    
    // Pool Stats - check if elements exist (they don't on admin page)
    safeUpdate('connected-miners', stats.connectedMiners || 0);
    safeUpdate('pool-hashrate', formatHashrate(stats.poolHashrate));
    safeUpdate('shares-per-second', (stats.sharesPerSecond || 0).toFixed(3));
    safeUpdate('total-blocks', pool.totalBlocks || 0);
    safeUpdate('total-paid', `${(pool.totalPaid || 0).toFixed(4)} ERG`);
    safeUpdate('pool-effort', `${(pool.poolEffort || 0).toFixed(2)}%`);
    
    // Network Stats
    safeUpdate('network-type', network.networkType || 'mainnet');
    safeUpdate('block-height', formatNumber(network.blockHeight));
    safeUpdate('network-hashrate', formatHashrate(network.networkHashrate));
    safeUpdate('network-difficulty', formatDifficulty(network.networkDifficulty));
    safeUpdate('connected-peers', network.connectedPeers || '--');
    safeUpdate('last-network-block', formatTimeAgo(network.lastNetworkBlockTime));
    
    // Pool Address
    safeUpdate('pool-address', pool.address || 'Loading...');
    
    // Update gauge
    updateEffortGauge(pool.poolEffort || 0);
    
    // Calculate time to block (only if element exists)
    const timeToBlockEl = document.getElementById('time-to-block');
    if (timeToBlockEl) {
        if (stats.poolHashrate && network.networkHashrate) {
            const networkShare = stats.poolHashrate / network.networkHashrate;
            const avgBlockTime = 120; // 2 minutes in seconds
            const expectedSeconds = avgBlockTime / networkShare;
            const expectedHours = expectedSeconds / 3600;
            
            let timeText;
            if (expectedHours < 1) {
                timeText = `${(expectedHours * 60).toFixed(0)} minutes`;
            } else if (expectedHours < 24) {
                timeText = `${expectedHours.toFixed(1)} hours`;
            } else {
                timeText = `${(expectedHours / 24).toFixed(1)} days`;
            }
            
            timeToBlockEl.textContent = timeText;
        } else {
            timeToBlockEl.textContent = 'calculating...';
        }
    }
    
    // Update sparklines
    state.hashrates.push(stats.poolHashrate || 0);
    state.shares.push(stats.sharesPerSecond || 0);
    
    if (state.hashrates.length > 50) state.hashrates.shift();
    if (state.shares.length > 50) state.shares.shift();
    
    updateSparklines();
    
    // Update chart
    updateHashrateChart(stats.poolHashrate || 0);
}

function updateEffortGauge(effort) {
    const gauge = document.getElementById('gauge-fill');
    const text = document.getElementById('gauge-text');
    
    // Only update if elements exist (public dashboard only)
    if (!gauge || !text) return;
    
    // Calculate gauge arc (180 degrees = 100%)
    const percentage = Math.min(effort, 200); // Cap at 200%
    const angle = (percentage / 200) * 180;
    const radius = 80;
    const circumference = Math.PI * radius;
    const offset = circumference - (angle / 180) * circumference;
    
    // Set gauge color based on effort
    let color;
    if (effort < 50) color = '#00ff00';
    else if (effort < 100) color = '#ffff00';
    else if (effort < 150) color = '#ff8800';
    else color = '#ff0040';
    
    gauge.style.stroke = color;
    gauge.style.strokeDasharray = `${circumference} ${circumference}`;
    gauge.style.strokeDashoffset = offset;
    
    text.textContent = `${effort.toFixed(1)}%`;
    text.style.fill = color;
}

function updateBlocksList(blocks) {
    const container = document.getElementById('blocks-list');
    
    // Only update if element exists (public dashboard only)
    if (!container) return;
    
    if (!blocks || blocks.length === 0) {
        container.innerHTML = '<div class="empty-state">No blocks found yet. Keep mining!</div>';
        return;
    }
    
    container.innerHTML = blocks.map(block => `
        <div class="block-item ${block.status.toLowerCase()} fade-in">
            <div class="block-info">
                <div>
                    <span class="block-height">Block #${formatNumber(block.blockHeight)}</span>
                    <span class="block-status ${block.status.toLowerCase()}">${block.status}</span>
                </div>
                <div class="block-reward">${block.reward.toFixed(4)} ERG</div>
                <div class="block-time">${formatTimeAgo(block.created)}</div>
            </div>
        </div>
    `).join('');
}

function updateMinersList(miners) {
    const container = document.getElementById('miners-list');
    
    // Only update if element exists (public dashboard only)
    if (!container) return;
    
    if (!miners || miners.length === 0) {
        container.innerHTML = '<div class="empty-state">No active miners</div>';
        return;
    }
    
    container.innerHTML = miners.map(miner => `
        <div class="miner-item fade-in">
            <div class="miner-address">${truncateAddress(miner.miner, 16, 12)}</div>
            <div class="miner-stats">
                <span class="miner-hashrate">${formatHashrate(miner.hashrate)}</span>
                <span class="miner-shares">${(miner.sharesPerSecond || 0).toFixed(3)} shares/s</span>
            </div>
        </div>
    `).join('');
}

function updateHashrateChart(currentHashrate) {
    const ctx = document.getElementById('hashrate-chart');
    if (!ctx) return;
    
    const now = new Date();
    const label = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    
    if (!state.chart) {
        state.chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [label],
                datasets: [{
                    label: 'Pool Hashrate',
                    data: [currentHashrate],
                    borderColor: '#00ffaa',
                    backgroundColor: 'rgba(0, 255, 170, 0.1)',
                    borderWidth: 2,
                    tension: 0.4,
                    fill: true,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        labels: {
                            color: '#00ffaa',
                            font: {
                                family: 'Courier New, monospace'
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        ticks: { color: '#a0a0b0' },
                        grid: { color: 'rgba(255, 255, 255, 0.1)' }
                    },
                    y: {
                        ticks: { 
                            color: '#a0a0b0',
                            callback: (value) => formatHashrate(value)
                        },
                        grid: { color: 'rgba(255, 255, 255, 0.1)' }
                    }
                }
            }
        });
    } else {
        // Update existing chart
        state.chart.data.labels.push(label);
        state.chart.data.datasets[0].data.push(currentHashrate);
        
        // Keep only last N data points
        if (state.chart.data.labels.length > config.chartMaxDataPoints) {
            state.chart.data.labels.shift();
            state.chart.data.datasets[0].data.shift();
        }
        
        state.chart.update('none'); // Update without animation for performance
    }
}

function updateSparklines() {
    // Hashrate sparkline
    const hashrateCanvas = document.getElementById('hashrate-sparkline');
    if (hashrateCanvas) {
        const ctx = hashrateCanvas.getContext('2d');
        drawSparkline(ctx, state.hashrates, '#00ffaa');
    }
    
    // Shares sparkline
    const sharesCanvas = document.getElementById('shares-sparkline');
    if (sharesCanvas) {
        const ctx = sharesCanvas.getContext('2d');
        drawSparkline(ctx, state.shares, '#ff0080');
    }
}

function drawSparkline(ctx, data, color) {
    if (!data || data.length === 0) return;
    
    const canvas = ctx.canvas;
    const width = canvas.width;
    const height = canvas.height;
    
    ctx.clearRect(0, 0, width, height);
    
    const max = Math.max(...data, 1);
    const min = Math.min(...data, 0);
    const range = max - min || 1;
    
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.beginPath();
    
    data.forEach((value, index) => {
        const x = (index / (data.length - 1)) * width;
        const y = height - ((value - min) / range) * height;
        
        if (index === 0) {
            ctx.moveTo(x, y);
        } else {
            ctx.lineTo(x, y);
        }
    });
    
    ctx.stroke();
}

function updateApiStatus(isOnline) {
    const indicator = document.getElementById('api-status');
    // Only update if element exists (public dashboard only)
    if (!indicator) return;
    
    if (isOnline) {
        indicator.classList.add('online');
        indicator.classList.remove('offline');
    } else {
        indicator.classList.add('offline');
        indicator.classList.remove('online');
    }
}

function updateLastUpdateTime() {
    const element = document.getElementById('last-update-time');
    // Only update if element exists (public dashboard only)
    if (!element) return;
    
    const now = new Date();
    const timeString = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
    element.textContent = timeString;
}

// Main Update Function
async function updateDashboard() {
    try {
        const [pool, blocks, miners] = await Promise.all([
            fetchPoolData(),
            fetchBlocks(),
            fetchMiners()
        ]);
        
        if (pool) {
            updatePoolStats(pool);
            updateApiStatus(true);
        }
        
        updateBlocksList(blocks);
        updateMinersList(miners);
        updateLastUpdateTime();
        
    } catch (error) {
        console.error('Error updating dashboard:', error);
        updateApiStatus(false);
    }
}

// Initialize Dashboard
function initDashboard() {
    console.log('Initializing dashboard...');
    
    // Initial update
    updateDashboard();
    
    // Set up auto-refresh
    setInterval(updateDashboard, config.refreshInterval);
    
    console.log(`Dashboard initialized. Auto-refresh every ${config.refreshInterval / 1000}s`);
}

// Start when DOM is ready (but NOT on admin page)
function autoInit() {
    // Don't auto-init on admin page (admin.js will handle initialization)
    if (document.getElementById('admin-panel')) {
        console.log('Admin page detected - skipping dashboard.js auto-init');
        return;
    }
    
    initDashboard();
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', autoInit);
} else {
    autoInit();
}

