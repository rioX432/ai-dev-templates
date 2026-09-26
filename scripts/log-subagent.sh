#!/usr/bin/env bash
# Log subagent and session lifecycle events
# Called by SubagentStart, SubagentStop, TaskCompleted, SessionEnd hooks
#
# Reads JSON from stdin and appends a structured log entry.

set -euo pipefail

INPUT=$(cat)

HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event // "unknown"' 2>/dev/null || echo "unknown")
AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // .subagent_name // "main"' 2>/dev/null || echo "main")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

LOG_DIR="logs/subagents"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).jsonl"
# Lifecycle telemetry is intentionally metadata-only. Result text can contain source,
# credentials, customer data, or untrusted instructions.
jq -cn \
  --arg timestamp "$TIMESTAMP" \
  --arg event "$HOOK_EVENT" \
  --arg agent "$AGENT_NAME" \
  --arg session "$SESSION_ID" \
  '{timestamp: $timestamp, event: $event, agent: $agent, session: $session}' >> "$LOG_FILE"

exit 0
