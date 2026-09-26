#!/usr/bin/env bash
# Log tool failure patterns for harness improvement
# Called as PostToolUseFailure hook
#
# Records a bounded, redacted failure summary to logs/failures/ for later analysis.
# Human reviews these logs and promotes patterns to rules/*.md

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
ERROR_KIND=$(echo "$INPUT" | jq -r '
  (.error.type // .error.code // .reason.type // .reason.code // "tool_failure")
  | tostring
  | if test("^[A-Za-z0-9_.-]{1,80}$") then . else "tool_failure" end
' 2>/dev/null || echo "tool_failure")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create logs directory if needed
LOG_DIR="logs/failures"
mkdir -p "$LOG_DIR"

# Never persist raw tool input: it can contain source, issue bodies, shell commands,
# credentials, or prompt-injection payloads. jq handles quoting and newlines safely.
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).jsonl"
jq -cn \
  --arg timestamp "$TIMESTAMP" \
  --arg tool "$TOOL_NAME" \
  --arg errorKind "$ERROR_KIND" \
  '{timestamp: $timestamp, tool: $tool, errorKind: $errorKind}' >> "$LOG_FILE"

exit 0
