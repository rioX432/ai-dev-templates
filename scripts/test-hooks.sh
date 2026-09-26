#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

assert_status() {
  local expected=$1
  local script=$2
  local payload=$3
  local actual

  set +e
  printf '%s\n' "$payload" | "$script" >/dev/null 2>&1
  actual=$?
  set -e

  if [ "$actual" -ne "$expected" ]; then
    echo "FAIL: $(basename "$script") returned $actual, expected $expected"
    exit 1
  fi
}

dangerous="$SCRIPT_DIR/block-dangerous-commands.sh"
assert_status 2 "$dangerous" '{"tool_input":{"command":"git push origin main --force"}}'
assert_status 2 "$dangerous" '{"tool_input":{"command":"rm -fr build-cache"}}'
assert_status 2 "$dangerous" '{"tool_input":{"command":"rm --recursive --force build-cache"}}'
assert_status 0 "$dangerous" '{"tool_input":{"command":"git status --short"}}'

secrets="$SCRIPT_DIR/block-secret-access.sh"
assert_status 2 "$secrets" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/.env.local"}}'
assert_status 2 "$secrets" '{"tool_name":"Bash","tool_input":{"command":"sed -n 1p .env.local"}}'
assert_status 0 "$secrets" '{"tool_name":"Read","tool_input":{"file_path":"src/main.kt"}}'

(
  cd "$TMP_DIR"
  printf '%s\n' '{"tool_name":"Bash","error":"bad \"quoted\" secret=do-not-log","tool_input":{"command":"curl -H Authorization:secret"}}' \
    | "$SCRIPT_DIR/log-failure.sh"
  jq empty logs/failures/*.jsonl
  if rg -q 'do-not-log|Authorization:secret' logs/failures; then
    echo "FAIL: failure log persisted sensitive input"
    exit 1
  fi

  printf '%s\n' '{"hook_event":"SubagentStop","agent_name":"reviewer","session_id":"abc","result":"private result"}' \
    | "$SCRIPT_DIR/log-subagent.sh"
  jq empty logs/subagents/*.jsonl
  if rg -q 'private result' logs/subagents; then
    echo "FAIL: lifecycle log persisted result content"
    exit 1
  fi
)

echo "Hook safety tests passed"
