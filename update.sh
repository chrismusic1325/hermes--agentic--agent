#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
MODEL="${HERMES_LOCAL_MODEL:-gemma4:12b}"

echo "============================================================"
echo " UPDATE HERMES AGENTIC AGENT"
echo "============================================================"

# Update this lightweight profile repo when it is a Git checkout.
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo
  echo "[1/5] Updating profile repository..."
  git -C "$ROOT" pull --ff-only || echo "Profile repo pull skipped; continuing with local copy."
else
  echo
  echo "[1/5] Profile directory is not a Git checkout; continuing."
fi

echo
echo "[2/5] Updating official Hermes Agent..."

UPDATED=0
if command -v hermes >/dev/null 2>&1; then
  if command -v python3 >/dev/null 2>&1; then
    if python3 - <<'PY'
import subprocess, sys
try:
    subprocess.run(["hermes", "update"], check=True, timeout=600)
except Exception as exc:
    print(f"Hermes update failed or timed out: {exc}")
    sys.exit(1)
PY
    then
      UPDATED=1
    fi
  elif hermes update; then
    UPDATED=1
  fi
fi

if [ "$UPDATED" -ne 1 ]; then
  echo "Using the official Hermes installer as the update/recovery path..."
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
  export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi

if ! command -v hermes >/dev/null 2>&1; then
  echo "ERROR: Hermes is unavailable after update/recovery."
  exit 1
fi

echo
echo "[3/5] Ensuring Ollama and model are current..."
if ! command -v ollama >/dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | sh
fi

if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  nohup ollama serve >"$HOME/.ollama-server.log" 2>&1 &
  for _ in {1..30}; do
    curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1 && break
    sleep 1
  done
fi

ollama pull "$MODEL"

echo
echo "[4/5] Reapplying $0 agentic profile..."
"$ROOT/apply-profile.sh"

echo
echo "[5/5] Verifying..."
"$ROOT/verify.sh"

echo
echo "UPDATE COMPLETE."
