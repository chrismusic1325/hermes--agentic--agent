# Hermes Agentic Agent

A reproducible **$0-budget, local-first Hermes Agent** setup for general agentic work.

This repository is not a video-editor-only project. It configures the latest official Hermes Agent so it can act as a worker across local files, repositories, terminal tasks, coding, browser tasks, skills, video workflows, automation, and other supported tool-based work.

## Operating profile

- Upstream: latest official `NousResearch/hermes-agent`
- Inference: local Ollama
- Default model: `gemma4:12b`
- Base URL: `http://127.0.0.1:11434/v1`
- API mode: `chat_completions`
- Context: `64000`
- Reasoning: `xhigh`
- Terminal backend: local
- Browser driver: Browser Use when available
- Budget: **$0 maximum**
- Paid fallback providers: disabled
- Desktop and CLI: supported
- Behavior: action-first and tool-first

## $0 budget rule

The repository-level operating constraint is simple:

> Spend $0.

The agent may use local resources and genuinely free services. It must not make purchases, start paid trials, invoke metered paid services, or silently fail over to a provider that can create charges. If a step cannot be completed for $0, it should complete everything else it can and report only the blocked step.

This profile does not modify upstream Hermes safety or platform controls. It only adds the $0 budget rule and action-first working behavior.

## Install or rebuild

On macOS/Linux:

```bash
git clone https://github.com/chrismusic1325/hermes--agentic--agent.git
cd hermes--agentic--agent
chmod +x bootstrap.sh start.sh verify.sh update.sh
./bootstrap.sh
```

The bootstrap script:

1. Installs or refreshes the latest official Hermes Agent.
2. Starts Ollama locally.
3. Pulls `gemma4:12b` if necessary.
4. Configures Hermes to use the local Ollama OpenAI-compatible endpoint.
5. Sets 64K context and `xhigh` reasoning.
6. Keeps terminal execution local.
7. Clears fallback providers so Hermes cannot silently fall back to a paid model.
8. Adds the action-first worker instructions.
9. Enables core agentic toolsets for CLI/Desktop-compatible sessions.
10. Verifies the resulting setup.

## Start

Desktop:

```bash
./start.sh desktop
```

Desktop with a working folder:

```bash
./start.sh desktop "$HOME/Desktop/untitled folder"
```

CLI:

```bash
./start.sh cli
```

CLI in a project/folder:

```bash
./start.sh cli /path/to/project
```

## Update to latest official Hermes

```bash
./update.sh
```

This uses Hermes's official updater and then reapplies this repository's local $0 profile.

## Verify

```bash
./verify.sh
```

## What this repository does not touch

The scripts in this repository do not modify Creator Growth Suite, OpenClaw, Rumble Agent, your other GitHub repositories, social accounts, or unrelated local projects.
