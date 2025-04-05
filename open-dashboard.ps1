# PowerShell script to open the dashboard in the default browser

# First, check if ports-data.json exists
if (-not (Test-Path -Path "ports-data.json")) {
    Write-Host "ports-data.json not found. Running get-ports.ps1 to generate it..."
    
    # Run the get-ports.ps1 script to generate the ports-data.json file
    try {
        & .\get-ports.ps1
        Write-Host "Port data generated successfully."
    }
    catch {
        Write-Host "Error generating port data: $_"
        Write-Host "Please run get-ports.ps1 manually before opening the dashboard."
        exit 1
    }
}

# Open the dashboard.html file in the default browser
try {
    Write-Host "Opening dashboard in your default browser..."
    Start-Process "dashboard.html"
    Write-Host "Dashboard opened successfully."
    
    Write-Host "`nInstructions:"
    Write-Host "1. To refresh port data, run: .\get-ports.ps1"
    Write-Host "2. To kill a process, run: .\kill-process.ps1 -ProcessId <PID>"
    Write-Host "3. After killing a process, run .\get-ports.ps1 again and refresh the browser"
}
catch {
    Write-Host "Error opening dashboard: $_"
    Write-Host "Please open dashboard.html manually in your browser."
}