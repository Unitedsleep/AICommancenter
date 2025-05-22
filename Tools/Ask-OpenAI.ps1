function Ask-OpenAI {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )

    # 🔐 Pull API key from environment
    $apiKey = $env:OPENAI_API_KEY
    if (-not $apiKey) {
        Write-Error "❌ OPENAI_API_KEY is not set. Load your .env file or set it manually in the environment."
        return
    }

    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type"  = "application/json"
    }

    $body = @{
        model = "gpt-4"
        messages = @(
            @{ role = "system"; content = "You are a helpful assistant." }
            @{ role = "user"; content = $Prompt }
        )
        temperature = 0.7
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body $body
        $response.choices[0].message.content
    } catch {
        Write-Error "❌ Failed to reach OpenAI: $($_.Exception.Message)"
    }
}
