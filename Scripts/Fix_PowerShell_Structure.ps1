# Fix PowerShell directory layout relative to the repository root
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $scriptRoot '..')).Path
)

# $RepoRoot now points to the repository root containing the Tools and Scripts folders

$PowerShellRoot = $RepoRoot
$BackupRoot = Join-Path $RepoRoot "Backup/PreStructureFix-$(Get-Date -Format 'yyyyMMdd_HHmm')"
$ValidFolders = @("Tools", "Data", "Logs", "Profile", "Modules", "Scripts", "AIModels", "Projects")

# Create backup folder
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
$MoveLog = @()

# Step 1: Backup and remove misplaced top-level folders
Get-ChildItem -Path $RepoRoot -Directory | Where-Object {
    $_.Name -ne "Backup"
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
