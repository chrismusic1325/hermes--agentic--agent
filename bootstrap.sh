#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
MODEL="${HERMES_LOCAL_MODEL:-gemma4:12b}"

echo "============================================================"
echo " HERMES AGENTIC AGENT — $0 LOCAL BOOTSTRAP"
echo "============================================================"
echo

# Keep a Mac awake while installing/updating and downloading the local model.
if command -v caffeinate >/dev/null 2>&1; then
  caffeinate -dimsu -w $$ >/dev/null 2>&1 &
fi

echo "[1/6] Installing/updating official Hermes Agent..."

if command -v hermes >/dev/null 2>&1; then
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY' || true
import subprocess
try:
    subprocess.run(["hermes", "update"], check=True, timeout=600)
except Exception as exc:
    print(f"Hermes updater did not finish cleanly: {exc}")
PY
  else
    hermes update || true
  fi
fi

# Official installer is also the recovery path if Hermes is absent or its
# updater failed. It tracks the current official Hermes release/main install.
if ! command -v hermes >/dev/null 2>&1; then
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
fi

if ! command -v hermes >/dev/null 2>&1; then
  export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi

if ! command -v hermes >/dev/null 2>&1; then
  echo "ERROR: Hermes is still unavailable after the official installer."
  exit 1
fi

echo
echo "[2/6] Ensuring Ollama is installed..."

if ! command -v ollama >/dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | sh
  export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo "ERROR: Ollama installation did not provide the ollama command."
  exit 1
fi

echo
echo "[3/6] Starting local Ollama server..."

if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  nohup ollama serve >"$HOME/.ollama-server.log" 2>&1 &
  READY=0
  for _ in {1..30}; do
    if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
      READY=1
      break
    fi
    sleep 1
  done
  if [ "$READY" -ne 1 ]; then
    echo "ERROR: Ollama server did not become ready."
    echo "Log: $HOME/.ollama-server.log"
    exit 1
  fi
fi

echo "Ollama server: WORKING"

echo
echo "[4/6] Ensuring local model is installed..."
if ! ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -Fxq "$MODEL"; then
  ollama pull "$MODEL"
else
  echo "$MODEL is already installed."
fi

echo
echo "[5/6] Applying local $0 agentic profile..."
"$ROOT/apply-profile.sh"

echo
echo "[6/6] Verifying..."
"$ROOT/verify.sh"

echo
echo "============================================================"
echo " READY"
echo "============================================================"
echo "Desktop: $ROOT/start.sh desktop"
echo "CLI:     $ROOT/start.sh cli"
