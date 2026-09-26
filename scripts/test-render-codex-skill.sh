#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

python3 "$ROOT/scripts/render-codex-skill.py" "$ROOT/skills/ux-audit" "$TMP/ux-audit"

test -f "$TMP/ux-audit/SKILL.md"
test -f "$TMP/ux-audit/reference.md"
test "$(grep -c '^name:' "$TMP/ux-audit/SKILL.md")" -eq 1
test "$(grep -c '^description:' "$TMP/ux-audit/SKILL.md")" -eq 1
! grep -q '^allowed-tools:' "$TMP/ux-audit/SKILL.md"
! grep -q '^user-invocable:' "$TMP/ux-audit/SKILL.md"
grep -q 'Host adaptation' "$TMP/ux-audit/SKILL.md"

echo "Codex skill rendering tests passed"
