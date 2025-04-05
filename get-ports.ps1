# PowerShell script to get port information and save it as JSON

# Function to get process name from PID
function Get-ProcessNameFromPid {
    param (
        [Parameter(Mandatory=$true)]
        [int]$ProcessId
    )
    
    try {
        $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        if ($process) {
            return $process.Name
        }
        else {
            return "Unknown"
        }
    }
    catch {
        return "Unknown"
    }
}

# Get all TCP connections
$tcpConnections = Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess

# Get all UDP endpoints
$udpEndpoints = Get-NetUDPEndpoint | Select-Object LocalAddress, LocalPort, OwningProcess

# Create an array to hold all port data
$portsData = @()

# Process TCP connections
foreach ($conn in $tcpConnections) {
    $processName = Get-ProcessNameFromPid -ProcessId $conn.OwningProcess
    
    $portsData += [PSCustomObject]@{
        protocol = "TCP"
        localAddress = $conn.LocalAddress
        port = $conn.LocalPort
        remoteAddress = "$($conn.RemoteAddress):$($conn.RemotePort)"
        state = $conn.State
        pid = $conn.OwningProcess
        processName = $processName
    }
}

# Process UDP endpoints
foreach ($endpoint in $udpEndpoints) {
    $processName = Get-ProcessNameFromPid -ProcessId $endpoint.OwningProcess
    
    $portsData += [PSCustomObject]@{
        protocol = "UDP"
        localAddress = $endpoint.LocalAddress
        port = $endpoint.LocalPort
        remoteAddress = "*:*"
        state = ""
        pid = $endpoint.OwningProcess
        processName = $processName
    }
}

# Convert to JSON and save to file
$portsData | ConvertTo-Json | Out-File -FilePath "ports-data.json" -Encoding UTF8

Write-Host "Port data has been saved to ports-data.json"
Write-Host "Total ports: $($portsData.Count)"
Write-Host "TCP connections: $($portsData | Where-Object { $_.protocol -eq 'TCP' } | Measure-Object).Count"
Write-Host "UDP endpoints: $($portsData | Where-Object { $_.protocol -eq 'UDP' } | Measure-Object).Count"