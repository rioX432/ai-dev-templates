#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

python3 "$ROOT/scripts/sync-config.py" validate --source-root "$ROOT" --config "$ROOT/skills/sync/sync-config.json"
MATRIX=$(python3 "$ROOT/scripts/sync-config.py" matrix --source-root "$ROOT" --config "$ROOT/skills/sync/sync-config.json")
test "$(printf '%s' "$MATRIX" | jq 'length')" -eq 9
test "$(printf '%s' "$MATRIX" | jq -r '.[0].adapters')" = "claude codex"

cp "$ROOT/skills/sync/sync-config.json" "$TMP/invalid.json"
jq '.projects.CivitDeck.layers = ["missing-layer"]' "$TMP/invalid.json" > "$TMP/invalid.next"
mv "$TMP/invalid.next" "$TMP/invalid.json"
if python3 "$ROOT/scripts/sync-config.py" validate --source-root "$ROOT" --config "$TMP/invalid.json" >/dev/null 2>&1; then
  echo "expected invalid layer to fail" >&2
  exit 1
fi

jq '.default_adapters = ["codex"]' "$ROOT/skills/sync/sync-config.json" > "$TMP/no-claude.json"
if python3 "$ROOT/scripts/sync-config.py" validate --source-root "$ROOT" --config "$TMP/no-claude.json" >/dev/null 2>&1; then
  echo "expected missing Claude baseline adapter to fail" >&2
  exit 1
fi

jq '.standalone_rules["standalone-orchestration.md"] = "rules/ai-ops.md"' "$ROOT/skills/sync/sync-config.json" > "$TMP/outside.json"
if python3 "$ROOT/scripts/sync-config.py" validate --source-root "$ROOT" --config "$TMP/outside.json" >/dev/null 2>&1; then
  echo "expected a standalone rule sourced outside standalone/ to fail" >&2
  exit 1
fi

jq '.standalone_rules["ai-ops.md"] = "standalone/orchestration.md"' "$ROOT/skills/sync/sync-config.json" > "$TMP/shadow.json"
if python3 "$ROOT/scripts/sync-config.py" validate --source-root "$ROOT" --config "$TMP/shadow.json" >/dev/null 2>&1; then
  echo "expected a standalone rule shadowing a common rule to fail" >&2
  exit 1
fi

jq '.policy_rules["core-value-filter.md"] = "standalone/orchestration.md"' "$ROOT/skills/sync/sync-config.json" > "$TMP/policy-outside.json"
if python3 "$ROOT/scripts/sync-config.py" validate --source-root "$ROOT" --config "$TMP/policy-outside.json" >/dev/null 2>&1; then
  echo "expected a policy rule sourced outside policies/ to fail" >&2
  exit 1
fi

jq '.policy_rules["standalone-orchestration.md"] = "policies/core-value-filter.md"' "$ROOT/skills/sync/sync-config.json" > "$TMP/policy-shadow.json"
if python3 "$ROOT/scripts/sync-config.py" validate --source-root "$ROOT" --config "$TMP/policy-shadow.json" >/dev/null 2>&1; then
  echo "expected a policy rule shadowing a standalone rule to fail" >&2
  exit 1
fi

echo "Sync config tests passed"
