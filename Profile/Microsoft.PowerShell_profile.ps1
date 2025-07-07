# === PowerShell AI Command Center Profile ===

# Determine repository root from $env:AICmdRoot or relative to this script
$repoRoot = if ($env:AICmdRoot) { $env:AICmdRoot } else { Resolve-Path (Join-Path $PSScriptRoot '..') }

$env:PSModulePath = (Join-Path $repoRoot 'Modules') + ';' + $env:PSModulePath

Get-ChildItem -Path (Join-Path $repoRoot 'Modules') -Directory | ForEach-Object {
    Import-Module $_.FullName -ErrorAction SilentlyContinue
}

. (Join-Path $repoRoot 'Tools' 'SessionLogger.ps1')
. (Join-Path $repoRoot 'Tools' 'Ask-OpenAI.ps1')

if (Test-Path (Join-Path $repoRoot 'Tools' 'Logging' 'Write-Log.ps1')) {
    . (Join-Path $repoRoot 'Tools' 'Logging' 'Write-Log.ps1')
}

if (Test-Path $repoRoot) {
    Set-Location $repoRoot
} elseif (Test-Path "$env:USERPROFILE\Documents") {
    Set-Location "$env:USERPROFILE\Documents"
} else {
    Set-Location "$HOME"
}

$realProfile = $PROFILE
$redirectLoader = @'
# Redirect profile loader to AI Command Center
if (Test-Path "$repoRoot\\Profile\\Microsoft.PowerShell_profile.ps1") {
    . "$repoRoot\\Profile\\Microsoft.PowerShell_profile.ps1"
}
'@

$redirectLoader | Set-Content -Path $realProfile -Encoding UTF8

Write-Host "`n✅ Boot profile now redirects to: $repoRoot\Profile\" -ForegroundColor Green

