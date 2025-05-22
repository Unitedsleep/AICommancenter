# =====================================
# Load-Env.ps1 — Import .env to $env:
# =====================================
$envFile = "X:\AICommandCenter\PowerShell\Config\.env"

if (-not (Test-Path $envFile)) {
    Write-Error "❌ .env file not found: $envFile"
    return
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*#") { return }  # Ignore comment lines
    if ($_ -match "^\s*$") { return }  # Ignore blank lines
    if ($_ -match "^\s*(.+?)\s*=\s*(.+)\s*$") {
        $key = $matches[1]
        $value = $matches[2]
        [System.Environment]::SetEnvironmentVariable($key, $value, "Process")
        Write-Host "✔️ Loaded: $key" -ForegroundColor Gray
    }
}
Write-Host "`n✅ Environment variables loaded from .env" -ForegroundColor Green
