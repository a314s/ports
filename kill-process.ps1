# PowerShell script to kill a process by PID
param (
    [Parameter(Mandatory=$true)]
    [int]$ProcessId
)

try {
    # Get process information before killing
    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    
    if ($process) {
        $processName = $process.Name
        
        # Kill the process
        Stop-Process -Id $ProcessId -Force
        
        # Create result object
        $result = [PSCustomObject]@{
            success = $true
            message = "Process $processName (PID: $ProcessId) was successfully terminated"
        }
    }
    else {
        $result = [PSCustomObject]@{
            success = $false
            message = "Process with PID $ProcessId not found"
        }
    }
}
catch {
    $result = [PSCustomObject]@{
        success = $false
        message = "Error killing process with PID $ProcessId: $_"
    }
}

# Convert to JSON and output
$result | ConvertTo-Json