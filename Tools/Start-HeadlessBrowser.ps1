param(
    [string]$Url = "https://example.com",
    [switch]$Edge
)

# Determine which browser to use
if ($Edge) {
    $browser = "msedge"
} else {
    $browser = "chrome"
}

# Build start info with headless flags
$arguments = "--headless=new --disable-gpu --window-size=1280,800 $Url"

try {
    Start-Process -FilePath $browser -ArgumentList $arguments
    Write-Host "✅ Launched $browser in headless mode." -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to launch $browser: $($_.Exception.Message)"
}
