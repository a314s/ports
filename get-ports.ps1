# PowerShell script to get port information and save it as JSON
[CmdletBinding()]
param (
    [Parameter()]
    [string]$OutputPath = "ports-data.json",
    
    [Parameter()]
    [ValidateSet('Unrestricted', 'RemoteSigned', 'AllSigned', 'Restricted')]
    [string]$ExecutionPolicy = 'RemoteSigned'
)

# Set error action preference to stop on any error
$ErrorActionPreference = "Stop"

# Function to write structured log messages
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = @{
        timestamp = $timestamp
        level = $Level
        message = $Message
    } | ConvertTo-Json
    
    Write-Output $logMessage
}

# Function to get process name from PID with enhanced error handling
function Get-ProcessNameFromPid {
    param (
        [Parameter(Mandatory=$true)]
        [int]$ProcessId
    )
    
    try {
        $process = Get-Process -Id $ProcessId -ErrorAction Stop
        return $process.Name
    }
    catch {
        Write-Log -Message "Failed to get process name for PID $ProcessId : $($_.Exception.Message)" -Level 'Warning'
        return "Unknown"
    }
}

try {
    Write-Log -Message "Starting port data collection"
    
    # Get all TCP connections with error handling
    try {
        $tcpConnections = Get-NetTCPConnection -ErrorAction Stop |
            Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess
        Write-Log -Message "Successfully retrieved TCP connections"
    }
    catch {
        Write-Log -Message "Failed to get TCP connections: $($_.Exception.Message)" -Level 'Error'
        throw
    }
    
    # Get all UDP endpoints with error handling
    try {
        $udpEndpoints = Get-NetUDPEndpoint -ErrorAction Stop |
            Select-Object LocalAddress, LocalPort, OwningProcess
        Write-Log -Message "Successfully retrieved UDP endpoints"
    }
    catch {
        Write-Log -Message "Failed to get UDP endpoints: $($_.Exception.Message)" -Level 'Error'
        throw
    }
    
    # Create an array to hold all port data
    $portsData = @()
    
    # Process TCP connections
    foreach ($conn in $tcpConnections) {
        try {
            $processName = Get-ProcessNameFromPid -ProcessId $conn.OwningProcess
            
            $portsData += [PSCustomObject]@{
                protocol = "TCP"
                localAddress = $conn.LocalAddress
                port = $conn.LocalPort
                remoteAddress = "$($conn.RemoteAddress):$($conn.RemotePort)"
                state = $conn.State
                pid = $conn.OwningProcess
                processName = $processName
                timestamp = (Get-Date -Format "o")
            }
        }
        catch {
            Write-Log -Message "Error processing TCP connection: $($_.Exception.Message)" -Level 'Warning'
        }
    }
    
    # Process UDP endpoints
    foreach ($endpoint in $udpEndpoints) {
        try {
            $processName = Get-ProcessNameFromPid -ProcessId $endpoint.OwningProcess
            
            $portsData += [PSCustomObject]@{
                protocol = "UDP"
                localAddress = $endpoint.LocalAddress
                port = $endpoint.LocalPort
                remoteAddress = "*:*"
                state = ""
                pid = $endpoint.OwningProcess
                processName = $processName
                timestamp = (Get-Date -Format "o")
            }
        }
        catch {
            Write-Log -Message "Error processing UDP endpoint: $($_.Exception.Message)" -Level 'Warning'
        }
    }
    
    # Convert to JSON and save to file with error handling
    try {
        $jsonContent = $portsData | ConvertTo-Json
        [System.IO.File]::WriteAllText($OutputPath, $jsonContent)
        Write-Log -Message "Successfully saved port data to $OutputPath"
    }
    catch {
        Write-Log -Message "Failed to save port data: $($_.Exception.Message)" -Level 'Error'
        throw
    }
    
    # Output statistics
    $stats = @{
        total = $portsData.Count
        tcp = ($portsData | Where-Object { $_.protocol -eq 'TCP' } | Measure-Object).Count
        udp = ($portsData | Where-Object { $_.protocol -eq 'UDP' } | Measure-Object).Count
        timestamp = (Get-Date -Format "o")
    } | ConvertTo-Json
    
    Write-Output $stats
}
catch {
    Write-Log -Message "Critical error: $($_.Exception.Message)" -Level 'Error'
    throw
}