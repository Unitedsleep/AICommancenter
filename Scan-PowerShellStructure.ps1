# === PowerShell Folder Structure Scan ===

# Determine repository root and log location
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path $scriptRoot
$logPath = Join-Path $repoRoot 'Logs/PowerShell_TreeMap.txt'
$logDir = Split-Path $logPath
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Collect all paths under repository root
$structure = Get-ChildItem -Path $repoRoot -Recurse -Force -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName | Sort-Object

# Format paths into a visual tree
$seen = @{}
$tree = foreach ($path in $structure) {
    $parts = $path -split '\\'
    $relParts = $parts[3..($parts.Length - 1)]
    $line = ""
    for ($i = 0; $i -lt $relParts.Length; $i++) {
        $sub = ($parts[0..($i+3)] -join '\')
        if (-not $seen[$sub]) {
            $line += ('│   ' * $i) + '├── ' + $relParts[$i] + "`n"
            $seen[$sub] = $true
        }
    }
    $line
}

# Save output to log
$treeText = ($tree -join "")
$treeText | Set-Content -Path $logPath -Encoding UTF8

Write-Host "`n✅ PowerShell folder structure has been scanned and saved to:`n$logPath" -ForegroundColor Cyan
