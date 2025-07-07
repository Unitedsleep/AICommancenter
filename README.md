# AI Command Center

This repository collects various PowerShell tools and modules used for working with AI services and utilities. The scripts can query language models, transcribe audio or log information about a session. A few optional resources such as the Grok SDK are referenced but not included by default.

## Installing dependencies

1. **PowerShell 7+** – all scripts are written for modern PowerShell.
2. **Whisper CLI** – required for the `Transcribe-Audio.ps1` script. Install it with:
   ```bash
   pip install openai-whisper
   ```
3. **Chrome or Edge** – required for `Start-HeadlessBrowser.ps1`. The script checks
   common install locations based on your OS. Use `-BrowserPath` if it cannot find the executable.
4. Optionally clone the Grok SDK if you plan to use Grok:
   ```bash
   git clone https://github.com/xai-org/grok.git KnowledgeBase/GrokAI/grok-sdk
   ```

## Using the PowerShell profile

The repository includes a profile script at `Profile/Microsoft.PowerShell_profile.ps1`.
Copy this file to your PowerShell profile path (run `$PROFILE` in PowerShell to see the location) or invoke it manually to automatically load the modules and environment variables on startup.

## Environment variables

API keys are loaded from a `.env` file. An example file is provided at `Config/.env.example`. Copy it to `Config/.env` and fill in your keys. Scripts such as `AgentChatController_20250519_121655.ps1` and `Load-Env.ps1` expect this file:

```
OPENAI_API_KEY=<your OpenAI key>
GROK_API_KEY=<your Grok key>
```

Run `Tools/Load-Env.ps1` to import the variables into the current PowerShell session.

## Main tools

- **Ask-OpenAI.ps1** – Defines `Ask-OpenAI` which sends a prompt to OpenAI. Example:
  ```powershell
  . ./Tools/Ask-OpenAI.ps1
  Ask-OpenAI -Prompt "Hello"
  ```
- **AgentChatController_20250519_121655.ps1** – Dual API chat engine for OpenAI and Grok. It loads `Config/.env` automatically and can call either or both services:
  ```powershell
  ./Tools/AgentChatController_20250519_121655.ps1 -Query "How are you?" -Mode Both
  ```
- **Whisper/Transcribe-Audio.ps1** – Uses the Whisper CLI to convert audio files to text:
  ```powershell
  ./Tools/Whisper/Transcribe-Audio.ps1 -AudioPath path/to/file.mp3
  ```
- **Load-Env.ps1** – Explicitly load environment variables from `.env` if you need them in the current session:
  ```powershell
  ./Tools/Load-Env.ps1
  ```
- **SessionLogger.ps1** – Writes PowerShell version and timestamp to `Logs/SessionLog.csv`:
  ```powershell
  ./Tools/SessionLogger.ps1
  ```
- **Start-HeadlessBrowser.ps1** – Launches Chrome or Edge in headless mode. The
  script verifies the browser executable based on your OS. Provide a custom path
  with `-BrowserPath` if needed:
  ```powershell
  ./Tools/Start-HeadlessBrowser.ps1 -Url "https://example.com" -Edge
  ```

## Optional Grok SDK

The directory `KnowledgeBase/GrokAI/grok-sdk` previously referenced the [grok](https://github.com/xai-org/grok) project as a submodule. Clone it manually if needed:
```bash
git clone https://github.com/xai-org/grok.git KnowledgeBase/GrokAI/grok-sdk
```
Update it later with:
```bash
cd KnowledgeBase/GrokAI/grok-sdk
git pull
```
