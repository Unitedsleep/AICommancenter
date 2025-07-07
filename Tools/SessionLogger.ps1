# SessionLogger.ps1 — Logs PowerShell version and session start

# Determine repository root relative to this script
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logRoot = Join-Path $scriptRoot '..\Logs'
$logFile = Join-Path $logRoot 'SessionLog.csv'

# Ensure directory exists
if (-not (Test-Path $logRoot)) {
    New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
}

# Collect session info
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$psVersion = $PSVersionTable.PSVersion.ToString()

# Create header if file doesn't exist
if (-not (Test-Path $logFile)) {
    "Timestamp,PSVersion" | Out-File -FilePath $logFile
}

# Log session
"$timestamp,$psVersion" | Out-File -FilePath $logFile -Append
