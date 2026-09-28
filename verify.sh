#!/usr/bin/env bash
set -euo pipefail

EXPECTED_MODEL="${HERMES_LOCAL_MODEL:-gemma4:12b}"
EXPECTED_URL="${HERMES_LOCAL_BASE_URL:-http://127.0.0.1:11434/v1}"
EXPECTED_CONTEXT="${HERMES_CONTEXT_LENGTH:-64000}"
EXPECTED_REASONING="${HERMES_REASONING_EFFORT:-xhigh}"

fail=0

check_equal() {
  label="$1"
  actual="$2"
  expected="$3"
  if [ "$actual" = "$expected" ]; then
    printf "OK   %-18s %s\n" "$label" "$actual"
  else
    printf "FAIL %-18s expected=%s actual=%s\n" "$label" "$expected" "$actual"
    fail=1
  fi
}

echo "============================================================"
echo " HERMES AGENTIC AGENT — VERIFY"
echo "============================================================"

if ! command -v hermes >/dev/null 2>&1; then
  echo "FAIL Hermes command not found"
  exit 1
fi

if ! command -v ollama >/dev/null 2>&1; then
  echo "FAIL Ollama command not found"
  exit 1
fi

printf "INFO Hermes version: "
hermes --version 2>/dev/null || true

if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  echo "OK   Ollama server      reachable"
else
  echo "FAIL Ollama server      not reachable"
  fail=1
fi

if ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -Fxq "$EXPECTED_MODEL"; then
  echo "OK   Ollama model       $EXPECTED_MODEL installed"
else
  echo "FAIL Ollama model       $EXPECTED_MODEL missing"
  fail=1
fi

provider="$(hermes config get model.provider 2>/dev/null | tail -n 1 | tr -d '\r')"
model="$(hermes config get model.default 2>/dev/null | tail -n 1 | tr -d '\r')"
base_url="$(hermes config get model.base_url 2>/dev/null | tail -n 1 | tr -d '\r')"
api_mode="$(hermes config get model.api_mode 2>/dev/null | tail -n 1 | tr -d '\r')"
context="$(hermes config get model.context_length 2>/dev/null | tail -n 1 | tr -d '\r')"
reasoning="$(hermes config get agent.reasoning_effort 2>/dev/null | tail -n 1 | tr -d '\r')"
terminal_backend="$(hermes config get terminal.backend 2>/dev/null | tail -n 1 | tr -d '\r')"
browser_backend="$(hermes config get browser.backend 2>/dev/null | tail -n 1 | tr -d '\r')"

check_equal "provider" "$provider" "custom"
check_equal "model" "$model" "$EXPECTED_MODEL"
check_equal "base URL" "$base_url" "$EXPECTED_URL"
check_equal "API mode" "$api_mode" "chat_completions"
check_equal "context" "$context" "$EXPECTED_CONTEXT"
check_equal "reasoning" "$reasoning" "$EXPECTED_REASONING"
check_equal "terminal" "$terminal_backend" "local"
check_equal "browser" "$browser_backend" "browser-use"

echo
echo "Fallback providers:"
fallback_out="$(hermes fallback list 2>&1 || true)"
printf "%s\n" "$fallback_out"
if printf "%s" "$fallback_out" | grep -qi "No fallback providers configured"; then
  echo "OK   fallback chain     empty"
else
  echo "CHECK fallback chain manually above"
fi

echo
echo "Enabled CLI tools:"
hermes tools list --platform cli 2>/dev/null || true

echo
if [ "$fail" -eq 0 ]; then
  echo "RESULT: CORE LOCAL $0 PROFILE VERIFIED"
else
  echo "RESULT: VERIFY FOUND A CONFIGURATION PROBLEM"
  exit 1
fi
