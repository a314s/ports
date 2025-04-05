# PowerShell script to start a simple HTTP server using Python
# This helps avoid CORS issues when loading local JSON files

# Check if Python is installed
$pythonInstalled = $false

try {
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -match "Python") {
        $pythonInstalled = $true
        Write-Host "Found Python: $pythonVersion"
    }
} catch {
    Write-Host "Python not found in PATH"
}

try {
    $pythonVersion = py --version 2>&1
    if ($pythonVersion -match "Python") {
        $pythonInstalled = $true
        Write-Host "Found Python: $pythonVersion"
    }
} catch {
    if (-not $pythonInstalled) {
        Write-Host "Python not found with 'py' command either"
    }
}

if ($pythonInstalled) {
    # Try to start a Python HTTP server
    Write-Host "Starting HTTP server on port 8000..."
    Write-Host "Open your browser and navigate to: http://localhost:8000"
    Write-Host "Press Ctrl+C to stop the server"
    
    # Try different Python commands
    try {
        python -m http.server 8000
    } catch {
        try {
            py -m http.server 8000
        } catch {
            Write-Host "Failed to start Python HTTP server"
        }
    }
} else {
    # Fallback to a PowerShell-based solution
    Write-Host "Python not found. Using alternative approach..."
    
    # Create a simple HTML file that loads the JSON data directly
    $jsonContent = Get-Content -Path "ports-data.json" -Raw
    
    # Use single-quoted here-string to avoid PowerShell variable substitution
    $htmlContent = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Port Monitor Dashboard</title>
    <link rel="stylesheet" href="styles.css">
    <script>
        // Embed the JSON data directly to avoid CORS issues
        const portsDataJson = `$jsonContent`;
        window.portsDataFromFile = JSON.parse(portsDataJson);
    </script>
</head>
<body>
    <div class="container">
        <header>
            <h1>Port Monitor Dashboard</h1>
            <button id="refresh-btn" class="btn primary">Refresh</button>
        </header>
        
        <main>
            <div class="stats-container">
                <div class="stat-card">
                    <h3>Total Active Ports</h3>
                    <p id="total-ports">0</p>
                </div>
                <div class="stat-card">
                    <h3>TCP Connections</h3>
                    <p id="tcp-count">0</p>
                </div>
                <div class="stat-card">
                    <h3>UDP Connections</h3>
                    <p id="udp-count">0</p>
                </div>
            </div>

            <div class="filter-container">
                <input type="text" id="search-input" placeholder="Search by port, process, or address...">
                <select id="protocol-filter">
                    <option value="all">All Protocols</option>
                    <option value="tcp">TCP</option>
                    <option value="udp">UDP</option>
                </select>
                <select id="sort-by">
                    <option value="port">Sort by Port</option>
                    <option value="process">Sort by Process</option>
                    <option value="state">Sort by State</option>
                </select>
            </div>

            <div class="table-container">
                <table id="ports-table">
                    <thead>
                        <tr>
                            <th>Protocol</th>
                            <th>Local Address</th>
                            <th>Port</th>
                            <th>Remote Address</th>
                            <th>State</th>
                            <th>PID</th>
                            <th>Process</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="ports-list">
                        <!-- Port data will be inserted here -->
                    </tbody>
                </table>
            </div>

            <div id="loading-overlay">
                <div class="spinner"></div>
                <p>Loading port information...</p>
            </div>
        </main>

        <div id="notification" class="notification">
            <p id="notification-message"></p>
            <button id="close-notification">×</button>
        </div>

        <div id="confirmation-modal" class="modal">
            <div class="modal-content">
                <h2>Confirm Action</h2>
                <p id="confirmation-message"></p>
                <div class="modal-buttons">
                    <button id="cancel-action" class="btn secondary">Cancel</button>
                    <button id="confirm-action" class="btn danger">Confirm</button>
                </div>
            </div>
        </div>
    </div>

    <script>
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
            // Use the embedded data
            portsData = window.portsDataFromFile;
            updateStats();
            filterData();
            hideLoading();
            showNotification('Port data loaded successfully', 'success');
            
            setupEventListeners();
        });

        // Event Listeners
        function setupEventListeners() {
            refreshBtn.addEventListener('click', () => {
                showNotification('To refresh port data, run the PowerShell script again:<br>1. Run <code>./get-ports.ps1</code><br>2. Refresh this page', 'info', 10000);
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
                    <td><span class="protocol-badge \${port.protocol.toLowerCase()}">\${port.protocol}</span></td>
                    <td>\${port.localAddress}</td>
                    <td>\${port.port}</td>
                    <td>${port.remoteAddress}</td>
                    <td>\${port.state ? \`<span class="state-badge \${port.state.toLowerCase()}">\${port.state}</span>\` : '-'}</td>
                    <td>\${port.pid}</td>
                    <td>\${port.processName}</td>
                    <td>
                        <button class="action-btn kill-btn" data-pid="\${port.pid}">Kill Process</button>
                        <button class="action-btn info-btn" data-pid="\${port.pid}">Details</button>
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
        function confirmKillProcess() {
            if (!currentPidToKill) return;
            
            hideConfirmationModal();
            
            // Show instructions for killing the process
            showNotification(
                `To kill process with PID ${currentPidToKill}, run this command in PowerShell:
                <br><code>./kill-process.ps1 -ProcessId ${currentPidToKill}</code>
                <br>Then run <code>./get-ports.ps1</code> and refresh this page to update the data.`, 
                'info',
                15000 // Show for 15 seconds
            );
            
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
    </script>
</body>
</html>
"@

    # Save the HTML file
    $htmlContent | Out-File -FilePath "dashboard.html" -Encoding UTF8
    
    Write-Host "Created dashboard.html with embedded data"
    Write-Host "Open dashboard.html in your browser to view the port monitor"
    
    # Try to open the file automatically
    try {
        Start-Process "dashboard.html"
        Write-Host "Dashboard opened in your default browser"
    } catch {
        Write-Host "Please open dashboard.html manually in your browser"
    }
}