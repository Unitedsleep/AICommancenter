# === PowerShell AI Command Center Profile ===

$env:PSModulePath = "X:\AICommandCenter\PowerShell\Modules;" + $env:PSModulePath

Get-ChildItem -Path "X:\AICommandCenter\PowerShell\Modules" -Directory | ForEach-Object {
    Import-Module $_.FullName -ErrorAction SilentlyContinue
}

. "X:\AICommandCenter\PowerShell\Tools\SessionLogger.ps1"
. "X:\AICommandCenter\PowerShell\Tools\Ask-OpenAI.ps1"

if (Test-Path "X:\AICommandCenter\PowerShell\Tools\Logging\Write-Log.ps1") {
    . "X:\AICommandCenter\PowerShell\Tools\Logging\Write-Log.ps1"
}

if (Test-Path "X:\AICommandCenter\PowerShell") {
    Set-Location "X:\AICommandCenter\PowerShell"
} elseif (Test-Path "$env:USERPROFILE\Documents") {
    Set-Location "$env:USERPROFILE\Documents"
} else {
    Set-Location "$HOME"
}

$realProfile = $PROFILE
$redirectLoader = @'
# Redirect profile loader to AI Command Center
if (Test-Path "X:\\AICommandCenter\\PowerShell\\Profile\\Microsoft.PowerShell_profile.ps1") {
    . "X:\\AICommandCenter\\PowerShell\\Profile\\Microsoft.PowerShell_profile.ps1"
}
'@

$redirectLoader | Set-Content -Path $realProfile -Encoding UTF8

Write-Host "`n✅ Boot profile now redirects to: X:\AICommandCenter\PowerShell\Profile\" -ForegroundColor Green

