#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

MODEL="${HERMES_LOCAL_MODEL:-gemma4:12b}"
BASE_URL="${HERMES_LOCAL_BASE_URL:-http://127.0.0.1:11434/v1}"
CONTEXT="${HERMES_CONTEXT_LENGTH:-64000}"
REASONING="${HERMES_REASONING_EFFORT:-xhigh}"

if ! command -v hermes >/dev/null 2>&1; then
  echo "ERROR: hermes is not installed."
  exit 1
fi

echo "============================================================"
echo " APPLYING HERMES AGENTIC $0 PROFILE"
echo "============================================================"
echo "Model:      $MODEL"
echo "Endpoint:   $BASE_URL"
echo "Context:    $CONTEXT"
echo "Reasoning:  $REASONING"
echo "Terminal:   local"
echo "Budget:     $0"
echo

# Primary inference: explicit local Ollama route.
hermes config set model.provider custom
hermes config set model.default "$MODEL"
hermes config unset model.model >/dev/null 2>&1 || true
hermes config set model.base_url "$BASE_URL"
hermes config set model.api_mode chat_completions
hermes config set model.context_length "$CONTEXT"
hermes config set model.ollama_num_ctx "$CONTEXT"
hermes config unset model.api_key >/dev/null 2>&1 || true
hermes config unset model.api_key_env >/dev/null 2>&1 || true

# Agent execution behavior.
hermes config set agent.reasoning_effort "$REASONING"
hermes config set agent.execution_guidance true
hermes config set terminal.backend local
hermes config set agent.system_prompt "$(cat "$ROOT/agentic-system-prompt.txt")"

# Keep the primary route local and prevent silent model/provider failover.
hermes config unset fallback_model >/dev/null 2>&1 || true
hermes config unset fallback_providers >/dev/null 2>&1 || true
hermes config set auth.adopt_external_logins false

# Auxiliary model jobs inherit the same local main model instead of a separately
# configured cloud model.
AUX_TASKS=(
  vision
  compression
  approval
  mcp
  title_generation
  review
  memory_query_rewrite
  tts_audio_tags
  skills_hub
  triage_specifier
  kanban_decomposer
  profile_describer
  curator
)

for task in "${AUX_TASKS[@]}"; do
  hermes config set "auxiliary.$task.provider" auto >/dev/null
  hermes config unset "auxiliary.$task.model" >/dev/null 2>&1 || true
  hermes config unset "auxiliary.$task.base_url" >/dev/null 2>&1 || true
  hermes config unset "auxiliary.$task.api_key" >/dev/null 2>&1 || true
done

# Delegated subagents inherit the parent/local route.
hermes config unset delegation.provider >/dev/null 2>&1 || true
hermes config unset delegation.model >/dev/null 2>&1 || true
hermes config unset delegation.base_url >/dev/null 2>&1 || true
hermes config unset delegation.api_key >/dev/null 2>&1 || true

# $0 browser/search routing. Browser Use is the selected browser driver; no
# paid cloud browser provider is pinned. Web search may use Hermes' keyless
# fallback when available.
hermes config set browser.backend browser-use
hermes config unset browser.cloud_provider >/dev/null 2>&1 || true
hermes config unset web.provider >/dev/null 2>&1 || true
hermes config unset web.backend >/dev/null 2>&1 || true
hermes config unset web.search_backend >/dev/null 2>&1 || true
hermes config unset web.extract_backend >/dev/null 2>&1 || true
hermes config set web.keyless_fallback true >/dev/null 2>&1 || true

# Core agentic capabilities. Unavailable tools remain runtime-gated by Hermes.
CORE_TOOLSETS=(
  terminal
  file
  code_execution
  skills
  todo
  delegation
  session_search
  memory
  clarify
  vision
  video
  browser
  web
  search
  cronjob
)

for toolset in "${CORE_TOOLSETS[@]}"; do
  hermes tools enable "$toolset" --platform cli >/dev/null 2>&1 || true
done

# Image generation was intentionally not configured in the $0 setup. Keep it
# disabled so an old paid image provider cannot be invoked accidentally.
hermes tools disable image_gen --platform cli >/dev/null 2>&1 || true

# Ensure the Browser Use harness is installed when the current Hermes build
# exposes its post-setup hook. Failure here does not disable terminal/file work.
hermes tools post-setup browser_use_cli >/dev/null 2>&1 || true

echo
echo "PROFILE APPLIED."
echo "Run ./verify.sh to inspect the effective configuration."
