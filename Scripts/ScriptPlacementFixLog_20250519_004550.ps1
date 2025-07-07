# ==========================================
# Script Placement Fixer – Audit Script
# Relocates misplaced scripts from Logs\ScriptAudit
# into the Tools or Scripts folder depending on purpose
# ==========================================

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $scriptRoot '..')).Path
)

$sourceDir = Join-Path $RepoRoot 'Logs/ScriptAudit'
$toolsDir  = Join-Path $RepoRoot 'Tools'
$scriptsDir = Join-Path $RepoRoot 'Scripts'

# Get all misplaced PS1 files
$misplacedScripts = Get-ChildItem -Path $sourceDir -Filter *.ps1 -File

foreach ($file in $misplacedScripts) {
    $targetDir = if ($file.Name -match "Logger|Ask-OpenAI|Transcribe") {
        $toolsDir
    } else {
        $scriptsDir
    }

    Move-Item -Path $file.FullName -Destination (Join-Path $targetDir $file.Name) -Force
    Write-Host "✅ Moved: $($file.Name) → $targetDir" -ForegroundColor Cyan
}

Write-Host "`n✔️ Script placement audit complete." -ForegroundColor Green
