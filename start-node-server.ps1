# PowerShell script to find Node.js and start the server

# Function to find Node.js executable
function Find-NodeJs {
    # Check common installation paths
    $commonPaths = @(
        "C:\Program Files\nodejs\node.exe",
        "C:\Program Files (x86)\nodejs\node.exe",
        "$env:APPDATA\npm\node.exe",
        "$env:ProgramFiles\nodejs\node.exe",
        "$env:ProgramFiles(x86)\nodejs\node.exe",
        "$env:LOCALAPPDATA\Programs\nodejs\node.exe"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Try to find node in the PATH
    try {
        $nodePath = (Get-Command node -ErrorAction SilentlyContinue).Source
        if ($nodePath) {
            return $nodePath
        }
    } catch {
        # Ignore errors
    }
    
    # Search for node.exe in Program Files
    $nodeExes = Get-ChildItem -Path "C:\Program Files" -Recurse -Filter "node.exe" -ErrorAction SilentlyContinue
    if ($nodeExes.Count -gt 0) {
        return $nodeExes[0].FullName
    }
    
    $nodeExes = Get-ChildItem -Path "C:\Program Files (x86)" -Recurse -Filter "node.exe" -ErrorAction SilentlyContinue
    if ($nodeExes.Count -gt 0) {
        return $nodeExes[0].FullName
    }
    
    return $null
}

# Function to find npm executable
function Find-Npm {
    # Check common installation paths
    $commonPaths = @(
        "C:\Program Files\nodejs\npm.cmd",
        "C:\Program Files (x86)\nodejs\npm.cmd",
        "$env:APPDATA\npm\npm.cmd",
        "$env:ProgramFiles\nodejs\npm.cmd",
        "$env:ProgramFiles(x86)\nodejs\npm.cmd",
        "$env:LOCALAPPDATA\Programs\nodejs\npm.cmd"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Try to find npm in the PATH
    try {
        $npmPath = (Get-Command npm -ErrorAction SilentlyContinue).Source
        if ($npmPath) {
            return $npmPath
        }
    } catch {
        # Ignore errors
    }
    
    # Search for npm.cmd in Program Files
    $npmCmds = Get-ChildItem -Path "C:\Program Files" -Recurse -Filter "npm.cmd" -ErrorAction SilentlyContinue
    if ($npmCmds.Count -gt 0) {
        return $npmCmds[0].FullName
    }
    
    $npmCmds = Get-ChildItem -Path "C:\Program Files (x86)" -Recurse -Filter "npm.cmd" -ErrorAction SilentlyContinue
    if ($npmCmds.Count -gt 0) {
        return $npmCmds[0].FullName
    }
    
    return $null
}

# Find Node.js
$nodePath = Find-NodeJs
if (-not $nodePath) {
    Write-Host "Node.js not found. Please install Node.js and try again." -ForegroundColor Red
    exit 1
}

Write-Host "Found Node.js at: $nodePath" -ForegroundColor Green

# Find npm
$npmPath = Find-Npm
if (-not $npmPath) {
    Write-Host "npm not found. Please install Node.js and try again." -ForegroundColor Red
    exit 1
}

Write-Host "Found npm at: $npmPath" -ForegroundColor Green

# Check if express and cors are installed
$packageJsonPath = Join-Path -Path $PSScriptRoot -ChildPath "package.json"
if (Test-Path $packageJsonPath) {
    Write-Host "Found package.json" -ForegroundColor Green
    
    # Check if node_modules exists
    $nodeModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "node_modules"
    if (-not (Test-Path $nodeModulesPath)) {
        Write-Host "Installing dependencies..." -ForegroundColor Yellow
        & $npmPath install
    } else {
        # Check if express and cors are installed
        $expressPath = Join-Path -Path $nodeModulesPath -ChildPath "express"
        $corsPath = Join-Path -Path $nodeModulesPath -ChildPath "cors"
        
        if (-not (Test-Path $expressPath) -or -not (Test-Path $corsPath)) {
            Write-Host "Installing dependencies..." -ForegroundColor Yellow
            & $npmPath install
        } else {
            Write-Host "Dependencies already installed" -ForegroundColor Green
        }
    }
} else {
    Write-Host "package.json not found. Installing express and cors..." -ForegroundColor Yellow
    & $npmPath install express cors
}

# Start the server
Write-Host "`nStarting the server..." -ForegroundColor Cyan
Write-Host "The dashboard will be available at: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server`n" -ForegroundColor Cyan

# Run the server
& $nodePath server.js

# Note: The script will continue running until the server is stopped