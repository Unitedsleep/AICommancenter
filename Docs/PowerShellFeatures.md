# PowerShell Features

This document summarizes the scripts and modules that ship with **AI Command Center**. Use it as a quick reference when exploring the repository.

## Tools folder

Each item in `Tools/` is a stand-alone script for daily tasks:

- **Ask-OpenAI.ps1** – simple wrapper for sending prompts to OpenAI. Example:
  ```powershell
  . ./Tools/Ask-OpenAI.ps1
  Ask-OpenAI -Prompt "Hello"
  ```
- **AgentChatController_20250519_121655.ps1** – dual engine chat script that can query OpenAI and Grok. Load your `.env` file automatically and specify the mode:
  ```powershell
  ./Tools/AgentChatController_20250519_121655.ps1 -Query "How are you?" -Mode Both
  ```
- **Whisper/Transcribe-Audio.ps1** – uses the Whisper CLI to convert audio to text:
  ```powershell
  ./Tools/Whisper/Transcribe-Audio.ps1 -AudioPath path/to/file.mp3
  ```
- **Load-Env.ps1** – loads variables from `Config/.env` into the current session:
  ```powershell
  ./Tools/Load-Env.ps1
  ```
- **SessionLogger.ps1** – appends a timestamp and PowerShell version to `Logs/SessionLog.csv`:
  ```powershell
  ./Tools/SessionLogger.ps1
  ```
- **Start-HeadlessBrowser.ps1** – launches Chrome or Edge in headless mode. Provide `-Edge` or a custom path if needed:
  ```powershell
  ./Tools/Start-HeadlessBrowser.ps1 -Url "https://example.com" -Edge
  ```

## Scripts folder

The `Scripts/` directory holds maintenance utilities for the repository itself:

- **Fix_PowerShell_Structure.ps1** – reorganizes the folder layout. Run it from anywhere:
  ```powershell
  ./Scripts/Fix_PowerShell_Structure.ps1
  ```
- **ScriptPlacementFixLog.ps1** and timestamped variants – move misplaced scripts from `Logs/ScriptAudit` back into `Tools/` or `Scripts/`:
  ```powershell
  ./Scripts/ScriptPlacementFixLog.ps1
  ```

## Modules folder

Several PowerShell modules are included for PDF management and PowerToys configuration:

- **PSWritePDF** and **PsPdf** provide functions such as `Merge-PDF`, `Split-PDF` and `Convert-PDFToText`.
- **PDFTools** ships supporting DLLs used by the other PDF modules.
- **Microsoft.PowerToys.Configure** exposes commands for editing PowerToys settings programmatically.

These modules are imported automatically by the profile script so their functions are available in every session.

## Logging and profile redirection

`Tools/SessionLogger.ps1` creates `Logs/SessionLog.csv` with a timestamp and PowerShell version. The profile script in `Profile/` overwrites your default `$PROFILE` and loads utilities from the repository on startup. To install it, run:

```powershell
./Profile/Microsoft.PowerShell_profile.ps1
```

The installed loader ensures future PowerShell sessions always import the modules, load environment variables and call `SessionLogger.ps1` automatically.

## Quick start example

A typical workflow looks like:

```powershell
# Load environment variables
./Tools/Load-Env.ps1

# Redirect the PowerShell profile (run once)
./Profile/Microsoft.PowerShell_profile.ps1

# Start the session logger
./Tools/SessionLogger.ps1
```

From here you can query AI services or convert audio files as needed using the tools above.
