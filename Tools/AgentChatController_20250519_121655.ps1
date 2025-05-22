# ========================================
# 🧠 AgentChatController — Dual API Chat Engine
# Supports OpenAI + Grok via natural language prompts
# Requires: .env with OPENAI_API_KEY and GROK_API_KEY
# ========================================

$envPath = "X:\AICommandCenter\PowerShell\Config\.env"

# === Load API keys from .env file ===
if (-not (Test-Path $envPath)) {
    Write-Error "❌ Missing `Config\.env` file at $envPath"
    return
}

Get-Content $envPath | ForEach-Object {
    if ($_ -match "^\s*([^=]+?)\s*=\s*(.+)$") {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

# === Parse arguments ===
param(
    [Parameter(Mandatory=$true)]
    [string]$Query,

    [ValidateSet("OpenAI", "Grok", "Both")]
    [string]$Mode = "Both"
)

function Call-OpenAI {
    param($prompt)
    $apiKey = $env:OPENAI_API_KEY
    if (-not $apiKey) { Write-Error "❌ OPENAI_API_KEY not found."; return }
    $body = @{
        model = "gpt-4"
        messages = @(@{ role = "user"; content = $prompt })
    } | ConvertTo-Json -Depth 3

    Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
        -Method POST -Headers @{ Authorization = "Bearer $apiKey" } `
        -Body $body -ContentType "application/json"
}

function Call-Grok {
    param($prompt)
    $apiKey = $env:GROK_API_KEY
    if (-not $apiKey) { Write-Error "❌ GROK_API_KEY not found."; return }
    $body = @{ prompt = $prompt } | ConvertTo-Json

    Invoke-RestMethod -Uri "https://api.grok.com/chat" `
        -Method POST -Headers @{ Authorization = "Bearer $apiKey" } `
        -Body $body -ContentType "application/json"
}

# === Dispatch Mode ===
switch ($Mode) {
    "OpenAI" {
        Write-Host "`n🔷 OpenAI says:`n"
        Call-OpenAI -prompt $Query
    }
    "Grok" {
        Write-Host "`n🟣 Grok says:`n"
        Call-Grok -prompt $Query
    }
    "Both" {
        Write-Host "`n🔷 OpenAI says:`n"
        Call-OpenAI -prompt $Query
        Write-Host "`n🟣 Grok says:`n"
        Call-Grok -prompt $Query
    }
}
