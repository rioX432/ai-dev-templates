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

echo "Sync config tests passed"
