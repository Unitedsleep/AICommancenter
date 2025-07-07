param (
    [string]$AudioPath,
    [string]$SourceUrl
)

# Determine repository root relative to this script
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$defaultInputDir = Join-Path $scriptRoot '..\Data\RawAudio'
$transcriptDir   = Join-Path $scriptRoot '..\Data\Transcripts'

# Create required folders if missing
foreach ($dir in @($defaultInputDir, $transcriptDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# If a SourceUrl is given, download it
if ($SourceUrl) {
    $filename = [System.IO.Path]::GetFileName($SourceUrl)
    $downloadPath = Join-Path $defaultInputDir $filename
    Invoke-WebRequest -Uri $SourceUrl -OutFile $downloadPath -UseBasicParsing
    $AudioPath = $downloadPath
}

# Use most recent audio file from default folder if none specified
if (-not $AudioPath) {
    $AudioPath = Get-ChildItem -Path $defaultInputDir -Include *.mp3,*.wav -File -Recurse |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 |
        Select-Object -ExpandProperty FullName

    if (-not $AudioPath) {
        Write-Error "❌ No audio files found in: $defaultInputDir"
        return
    }
}

# Confirm file exists
if (-not (Test-Path $AudioPath)) {
    Write-Error "❌ Audio file not found: $AudioPath"
    return
}

# Setup output path
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($AudioPath)
$outPath = Join-Path $transcriptDir "$baseName.txt"

# Check if Whisper is installed
if (-not (Get-Command "whisper" -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Whisper is not installed or not in PATH."
    return
}

# Run Whisper CLI
whisper "$AudioPath" --model medium --output_format txt --output_dir $transcriptDir

# Confirm output
if (Test-Path $outPath) {
    Write-Host "✅ Transcription complete. Output saved to:`n$outPath" -ForegroundColor Green
} else {
    Write-Warning "⚠️ Transcription may have failed. No output found."
}
