# PowerShell script to kill a process by PID
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$ProcessId,
    
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

# Function to validate process access permissions
function Test-ProcessAccess {
    param (
        [Parameter(Mandatory=$true)]
        [System.Diagnostics.Process]$Process
    )
    
    try {
        # Check if the process is a system process
        $systemProcesses = @("System", "Registry", "Memory Compression", "Idle")
        if ($systemProcesses -contains $Process.ProcessName) {
            return $false
        }
        
        # Check if we have access to the process
        $handle = $Process.Handle
        return $true
    }
    catch {
        return $false
    }
}

try {
    Write-Log -Message "Attempting to terminate process with PID: $ProcessId"
    
    # Get process information before killing
    $process = Get-Process -Id $ProcessId -ErrorAction Stop
    
    if ($process) {
        $processName = $process.Name
        
        # Validate process access
        if (-not (Test-ProcessAccess -Process $process)) {
            Write-Log -Message "Access denied to process $processName (PID: $ProcessId)" -Level 'Error'
            $result = [PSCustomObject]@{
                success = $false
                message = "Access denied to process $processName (PID: $ProcessId)"
                timestamp = (Get-Date -Format "o")
                details = "Cannot terminate system or protected processes"
            }
        }
        else {
            # Kill the process
            Stop-Process -Id $ProcessId -Force -ErrorAction Stop
            Write-Log -Message "Successfully terminated process $processName (PID: $ProcessId)"
            
            # Create result object
            $result = [PSCustomObject]@{
                success = $true
                message = "Process $processName (PID: $ProcessId) was successfully terminated"
                timestamp = (Get-Date -Format "o")
                details = @{
                    processName = $processName
                    pid = $ProcessId
                    terminatedAt = (Get-Date -Format "o")
                }
            }
        }
    }
    else {
        Write-Log -Message "Process with PID $ProcessId not found" -Level 'Warning'
        $result = [PSCustomObject]@{
            success = $false
            message = "Process with PID $ProcessId not found"
            timestamp = (Get-Date -Format "o")
            details = "The specified process ID does not exist"
        }
    }
}
catch {
    Write-Log -Message "Error terminating process: $($_.Exception.Message)" -Level 'Error'
    $result = [PSCustomObject]@{
        success = $false
        message = "Error killing process with PID $ProcessId"
        timestamp = (Get-Date -Format "o")
        details = $_.Exception.Message
    }
}

# Convert to JSON and output
$result | ConvertTo-Json -Depth 10