# ======================================
# Start-HeadlessBrowser.ps1 — Cross-platform launcher
# ======================================

param(
    [string]$Url = "https://example.com",
    [switch]$Edge,
    [string]$BrowserPath
)

# Determine which browser to use
$browser = if ($Edge) { "msedge" } else { "chrome" }

# Build candidate paths based on OS
$candidates = @()
if ($BrowserPath) {
    $candidates += $BrowserPath
}

# Look for executable in PATH first
$command = Get-Command $browser -ErrorAction SilentlyContinue
if ($command) { $candidates += $command.Source }

if ($IsWindows) {
    if ($browser -eq "msedge") {
        $candidates += "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
        $candidates += "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe"
    } else {
        $candidates += "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
        $candidates += "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
    }
} elseif ($IsMacOS) {
    if ($browser -eq "msedge") {
        $candidates += '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge'
    } else {
        $candidates += '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
    }
}

# Select the first valid path
$browserExe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $browserExe) {
    Write-Error "❌ $browser executable not found. Specify a path with -BrowserPath."
    return
}

# Build start info with headless flags
$arguments = "--headless=new --disable-gpu --window-size=1280,800 $Url"

try {
    Start-Process -FilePath $browserExe -ArgumentList $arguments
    Write-Host "✅ Launched $browserExe in headless mode." -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to launch ${browserExe}: $($_.Exception.Message)"
}
