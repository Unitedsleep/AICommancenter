# PowerShell Script: Fix PowerShell AICommandCenter Directory Structure
# Authoritative structure: X:\AICommandCenter\PowerShell\
# This script moves all misplaced folders back into the correct hierarchy.

$Root = "X:\AICommandCenter"
$PowerShellRoot = "$Root\PowerShell"
$BackupRoot = "$Root\Backup\PreStructureFix-$(Get-Date -Format 'yyyyMMdd_HHmm')"
$ValidFolders = @("Tools", "Data", "Logs", "Profile", "Modules", "Scripts", "AIModels", "Projects")

# Create backup folder
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
$MoveLog = @()

# Step 1: Backup and remove misplaced top-level folders
Get-ChildItem -Path $Root -Directory | Where-Object {
    $_.Name -ne "PowerShell" -and $_.Name -ne "Backup"
} | ForEach-Object {
    $source = $_.FullName
    $destination = Join-Path $BackupRoot $_.Name
    Move-Item -Path $source -Destination $destination -Force
    $MoveLog += "🔁 Backed up: $source → $destination"
}

# Step 2: Reorganize from backup into correct PowerShell substructure
Get-ChildItem -Path $BackupRoot -Directory | ForEach-Object {
    $folderName = $_.Name
    $source = $_.FullName
    if ($ValidFolders -contains $folderName) {
        $target = Join-Path $PowerShellRoot $folderName
    } else {
        $target = Join-Path $PowerShellRoot\Tools $folderName
    }
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Move-Item -Path "$source\*" -Destination $target -Force
    $MoveLog += "✅ Moved: $source → $target"
}

# Step 3: Write log file
$logPath = "$PowerShellRoot\Logs\StructureFixLog-$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
$MoveLog | Out-File -FilePath $logPath -Encoding UTF8

Write-Host "`n✅ Structure fix complete. Log saved to:`n$logPath" -ForegroundColor Green
