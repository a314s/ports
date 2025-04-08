// DOM Elements
const refreshBtn = document.getElementById('refresh-btn');
const portsTable = document.getElementById('ports-table');
const portsList = document.getElementById('ports-list');
const totalPortsElement = document.getElementById('total-ports');
const tcpCountElement = document.getElementById('tcp-count');
const udpCountElement = document.getElementById('udp-count');
const searchInput = document.getElementById('search-input');
const protocolFilter = document.getElementById('protocol-filter');
const sortBySelect = document.getElementById('sort-by');
const loadingOverlay = document.getElementById('loading-overlay');
const notification = document.getElementById('notification');
const notificationMessage = document.getElementById('notification-message');
const closeNotificationBtn = document.getElementById('close-notification');
const confirmationModal = document.getElementById('confirmation-modal');
const confirmationMessage = document.getElementById('confirmation-message');
const cancelActionBtn = document.getElementById('cancel-action');
const confirmActionBtn = document.getElementById('confirm-action');

// State
let portsData = [];
let filteredData = [];
let currentPidToKill = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadPortsData();
    setupEventListeners();
});

// Load Ports Data
async function loadPortsData() {
    showLoading();
    
    try {
        // Try to load from API endpoint first (when using the Node.js server)
        const response = await fetch('/api/ports');
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('Received data:', data); // Debug log
        
        portsData = data;
        
        // Update UI
        updateStats();
        filterData();
        hideLoading();
        showNotification('Port data loaded successfully', 'success');
    } catch (error) {
        console.error('Error loading ports data:', error);
        hideLoading();
        showNotification('Failed to fetch port data. Please try again.', 'error');
    }
}

// Event Listeners
function setupEventListeners() {
    refreshBtn.addEventListener('click', () => {
        loadPortsData();
    });
    searchInput.addEventListener('input', filterData);
    protocolFilter.addEventListener('change', filterData);
    sortBySelect.addEventListener('change', filterData);
    closeNotificationBtn.addEventListener('click', hideNotification);
    cancelActionBtn.addEventListener('click', hideConfirmationModal);
    confirmActionBtn.addEventListener('click', confirmKillProcess);
}

// Update Statistics
function updateStats() {
    totalPortsElement.textContent = portsData.length;
    tcpCountElement.textContent = portsData.filter(port => port.protocol.toLowerCase() === 'tcp').length;
    udpCountElement.textContent = portsData.filter(port => port.protocol.toLowerCase() === 'udp').length;
}

// Filter and Sort Data
function filterData() {
    console.log('Filtering data, current portsData:', portsData); // Debug log
    
    const searchTerm = searchInput.value.toLowerCase();
    const protocolValue = protocolFilter.value;
    const sortBy = sortBySelect.value;
    
    // Filter
    filteredData = portsData.filter(port => {
        // Protocol filter
        if (protocolValue !== 'all' && port.protocol.toLowerCase() !== protocolValue) {
            return false;
        }
        
        // Search term
        return (
            port.port.toString().includes(searchTerm) ||
            port.processName.toLowerCase().includes(searchTerm) ||
            port.localAddress.toLowerCase().includes(searchTerm) ||
            port.remoteAddress.toLowerCase().includes(searchTerm) ||
            (port.state && port.state.toLowerCase().includes(searchTerm)) ||
            port.pid.toString().includes(searchTerm)
        );
    });
    
    // Sort
    filteredData.sort((a, b) => {
        switch (sortBy) {
            case 'port':
                return a.port - b.port;
            case 'process':
                return a.processName.localeCompare(b.processName);
            case 'state':
                return (a.state || '').localeCompare(b.state || '');
            default:
                return 0;
        }
    });
    
    renderPortsList();
}

// Render Ports List
function renderPortsList() {
    console.log('Rendering ports list, filtered data:', filteredData); // Debug log
    
    portsList.innerHTML = '';
    
    if (filteredData.length === 0) {
        portsList.innerHTML = `
            <tr>
                <td colspan="8" class="empty-state">
                    <p>No ports found matching your criteria</p>
                </td>
            </tr>
        `;
        return;
    }
    
    filteredData.forEach(port => {
        const row = document.createElement('tr');
        
        row.innerHTML = `
            <td><span class="protocol-badge ${port.protocol.toLowerCase()}">${port.protocol}</span></td>
            <td>${port.localAddress}</td>
            <td>${port.port}</td>
            <td>${port.remoteAddress}</td>
            <td>${port.state ? `<span class="state-badge ${port.state.toLowerCase()}">${port.state}</span>` : '-'}</td>
            <td>${port.pid}</td>
            <td>${port.processName}</td>
            <td>
                <button class="action-btn kill-btn" data-pid="${port.pid}">Kill Process</button>
                <button class="action-btn info-btn" data-pid="${port.pid}">Details</button>
            </td>
        `;
        
        portsList.appendChild(row);
    });
    
    // Add event listeners to buttons
    document.querySelectorAll('.kill-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const pid = btn.getAttribute('data-pid');
            const process = portsData.find(p => p.pid.toString() === pid);
            showKillConfirmation(process);
        });
    });
    
    document.querySelectorAll('.info-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const pid = btn.getAttribute('data-pid');
            const process = portsData.find(p => p.pid.toString() === pid);
            showProcessDetails(process);
        });
    });
}

// Show Kill Confirmation
function showKillConfirmation(process) {
    confirmationMessage.textContent = `Are you sure you want to kill the process "${process.processName}" (PID: ${process.pid}) using port ${process.port}?`;
    currentPidToKill = process.pid;
    confirmationModal.style.display = 'flex';
}

// Confirm Kill Process
async function confirmKillProcess() {
    if (!currentPidToKill) return;
    
    hideConfirmationModal();
    showLoading();
    
    try {
        const response = await fetch(`/api/kill/${currentPidToKill}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const result = await response.json();
        
        // Refresh the data
        await loadPortsData();
        
        hideLoading();
        showNotification(`Process with PID ${currentPidToKill} was successfully terminated`, 'success');
    } catch (error) {
        console.error('Error killing process:', error);
        hideLoading();
        showNotification(`Failed to kill process with PID ${currentPidToKill}. Please try again.`, 'error');
    }
    
    currentPidToKill = null;
}

// Show Process Details
function showProcessDetails(process) {
    showNotification(`
        <strong>Process Details:</strong><br>
        Name: ${process.processName}<br>
        PID: ${process.pid}<br>
        Protocol: ${process.protocol}<br>
        Port: ${process.port}<br>
        Local Address: ${process.localAddress}<br>
        Remote Address: ${process.remoteAddress}<br>
        State: ${process.state || 'N/A'}
    `, 'info', 10000);
}

// Show Loading Overlay
function showLoading() {
    loadingOverlay.style.display = 'flex';
}

// Hide Loading Overlay
function hideLoading() {
    loadingOverlay.style.display = 'none';
}

// Show Notification
function showNotification(message, type = 'info', duration = 5000) {
    notificationMessage.innerHTML = message;
    notification.className = 'notification show';
    
    if (type) {
        notification.classList.add(type);
    }
    
    // Auto-hide after specified duration
    setTimeout(hideNotification, duration);
}

// Hide Notification
function hideNotification() {
    notification.className = 'notification';
}

// Show Confirmation Modal
function showConfirmationModal() {
    confirmationModal.style.display = 'flex';
}

// Hide Confirmation Modal
function hideConfirmationModal() {
    confirmationModal.style.display = 'none';
}