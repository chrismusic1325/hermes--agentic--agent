#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
MODE="${1:-desktop}"
WORKDIR="${2:-}"
MODEL="${HERMES_LOCAL_MODEL:-gemma4:12b}"

if ! command -v hermes >/dev/null 2>&1; then
  echo "Hermes is not installed. Run:"
  echo "  $ROOT/bootstrap.sh"
  exit 1
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo "Ollama is not installed. Run:"
  echo "  $ROOT/bootstrap.sh"
  exit 1
fi

if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  nohup ollama serve >"$HOME/.ollama-server.log" 2>&1 &
  for _ in {1..30}; do
    curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1 && break
    sleep 1
  done
fi

if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  echo "ERROR: Ollama server is not reachable."
  exit 1
fi

if ! ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -Fxq "$MODEL"; then
  ollama pull "$MODEL"
fi

# Reapply the repo profile on every launch so stale Desktop/provider settings do
# not silently take over.
"$ROOT/apply-profile.sh" >/dev/null

if [ -n "$WORKDIR" ]; then
  cd "$WORKDIR"
fi

case "$MODE" in
  desktop)
    # A running Desktop process can retain an old session/model snapshot.
    # Restart only Hermes Desktop; do not touch unrelated applications.
    if [ "$(uname -s)" = "Darwin" ]; then
      pkill -f '/Hermes.app/Contents/MacOS/Hermes' >/dev/null 2>&1 || true
      sleep 1
    fi
    exec hermes desktop
    ;;
  cli)
    exec hermes
    ;;
  *)
    echo "Usage:"
    echo "  ./start.sh desktop [working-folder]"
    echo "  ./start.sh cli [working-folder]"
    exit 2
    ;;
esac
