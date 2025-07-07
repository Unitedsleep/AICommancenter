# === PowerShell AI Command Center Profile ===
# This script holds the definitive profile logic. The previous
# `Microsoft.PowerShell_profile.txt` has been removed.

# Determine repository root relative to this profile
$profileDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $profileDir '..')

# Update module path and import any modules found under Modules
$env:PSModulePath = "$repoRoot\Modules;" + $env:PSModulePath

Get-ChildItem -Path "$repoRoot\Modules" -Directory | ForEach-Object {
    Import-Module $_.FullName -ErrorAction SilentlyContinue
}

# Load environment variables and utilities
. "$repoRoot\Tools\Load-Env.ps1"
. "$repoRoot\Tools\SessionLogger.ps1"
. "$repoRoot\Tools\Ask-OpenAI.ps1"
. "$repoRoot\Tools\Start-HeadlessBrowser.ps1"
# Start in the repository root by default
Set-Location $repoRoot

$realProfile = $PROFILE
$redirectLoader = @'
# Redirect profile loader to AI Command Center
if (Test-Path "$repoRoot\\Profile\\Microsoft.PowerShell_profile.ps1") {
    . "$repoRoot\\Profile\\Microsoft.PowerShell_profile.ps1"
}
'@

$redirectLoader | Set-Content -Path $realProfile -Encoding UTF8

Write-Host "`n✅ Boot profile now redirects to: $repoRoot\Profile\" -ForegroundColor Green

