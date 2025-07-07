# AICommancenter

This repository collects various PowerShell scripts and modules. Some optional resources are hosted in separate repositories.

## Optional Grok SDK

The directory `KnowledgeBase/GrokAI/grok-sdk` previously referenced a Git submodule for the [grok](https://github.com/xai-org/grok) project. It has been removed from the repository to avoid empty directories.

If you need these files, clone the dependency manually:

```bash
git clone https://github.com/xai-org/grok.git KnowledgeBase/GrokAI/grok-sdk
```

To update the dependency later, run:

```bash
cd KnowledgeBase/GrokAI/grok-sdk
git pull
```

