#!/usr/bin/env bash
# Block dangerous commands: prevents destructive operations
# Called as PreToolUse hook for Bash events
#
# Exit code 2 = block the tool call with a message
# The hook receives tool input as JSON on stdin.

set -euo pipefail

INPUT=$(cat)

# Extract the command from tool input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# This hook is defense in depth, not a substitute for sandboxing and least-privilege
# permissions. Prefer broad, order-independent patterns for destructive command classes;
# narrow spellings are easy to bypass with reordered or long-form flags.
BLOCKED_PATTERNS=(
  "(^|[;&|][[:space:]]*)rm[[:space:]]+(-[^[:space:]]*[rR][^[:space:]]*[fF]|-[^[:space:]]*[fF][^[:space:]]*[rR]|--recursive[[:space:]]+--force|--force[[:space:]]+--recursive)([[:space:]]|$)"
  "(^|[;&|][[:space:]]*)git[[:space:]]+push([^;&|])*([[:space:]]--force([=[:space:]]|$)|[[:space:]]--force-with-lease([=[:space:]]|$)|[[:space:]]-f([[:space:]]|$))"
  "(^|[;&|][[:space:]]*)git[[:space:]]+reset[[:space:]]+--hard([[:space:]]|$)"
  "(^|[;&|][[:space:]]*)git[[:space:]]+clean[[:space:]]+-[^[:space:]]*[fdx]"
  "(^|[;&|][[:space:]]*)git[[:space:]]+(checkout|restore)[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$)"
  "(^|[;&|][[:space:]]*)(drop[[:space:]]+(table|database)|truncate[[:space:]]+table)([[:space:]]|$)"
  ":(){ :|:& };:"
  "(^|[;&|][[:space:]]*)mkfs\."
  "(^|[;&|][[:space:]]*)dd[[:space:]].*if="
  ">[[:space:]]*/dev/(sd|disk|nvme)"
)

for PATTERN in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -iqE "$PATTERN"; then
    echo "BLOCKED: Dangerous command detected matching pattern '$PATTERN'. Command: $COMMAND"
    exit 2
  fi
done

exit 0
