# AI Command Center

This repository collects various PowerShell tools and modules used for working with AI services and utilities. The scripts can query language models, transcribe audio or log information about a session. A few optional resources such as the Grok SDK are referenced but not included by default.

## Repository Structure

- **Tools/** – stand-alone utilities such as `AgentChatController`, `Load-Env`, `SessionLogger`, and the `Whisper` folder.
- **Scripts/** – helper scripts for reorganizing files and other maintenance tasks.
- **Profile/** – the PowerShell profile script used by this repo.
- **Logs/** – output from the logger and other audit scripts.
- **KnowledgeBase/** – optional documentation and third‑party resources (e.g., Grok SDK).

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

## Environment setup

1. Copy `Config/.env.example` to `Config/.env` and populate it with your personal API keys.
2. Load the variables in a PowerShell session:
   ```powershell
   ./Tools/Load-Env.ps1
   ```
3. Run the repository profile script **once**:
   ```powershell
   ./Profile/Microsoft.PowerShell_profile.ps1
   ```
   This overwrites your regular `$PROFILE` with a small loader that points to
   `Profile/Microsoft.PowerShell_profile.ps1`, so all helper functions load
   automatically in future sessions.

The `.env` file is required by scripts such as `AgentChatController_20250519_121655.ps1` and should contain:

```
OPENAI_API_KEY=<your OpenAI key>
GROK_API_KEY=<your Grok key>
```

## Main tools

- **Ask-OpenAI.ps1** – Defines `Ask-OpenAI` which sends a prompt to OpenAI. Example:
  ```powershell
  . ./Tools/Ask-OpenAI.ps1
  Ask-OpenAI -Prompt "Hello"
  ```
- **AgentChatController_20250519_121655.ps1** – Chat engine that uses GPT‑4 via the OpenAI chat completion API and optionally the Grok service. Use `-Mode` (`OpenAI`, `Grok` or `Both`) to choose which API to query. The script loads `Config/.env` automatically:
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
- **Fix_PowerShell_Structure.ps1** – Reorganizes folders using its own location to find the repo root:
  ```powershell
  ./Scripts/Fix_PowerShell_Structure.ps1
  ```
- **ScriptPlacementFixLog.ps1** – Moves scripts from `Logs/ScriptAudit` to their proper directories:
  ```powershell
  ./Scripts/ScriptPlacementFixLog.ps1
  ```

## Example session

```powershell
# 1) Load environment variables
./Tools/Load-Env.ps1

# 2) (Run once) overwrite your profile with the repository loader
./Profile/Microsoft.PowerShell_profile.ps1

# 3) Log the session start
./Tools/SessionLogger.ps1

# 4) Query both chat APIs
./Tools/AgentChatController_20250519_121655.ps1 -Query "Hello" -Mode Both

# 5) Transcribe an audio file
./Tools/Whisper/Transcribe-Audio.ps1 -AudioPath path/to/file.mp3
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
