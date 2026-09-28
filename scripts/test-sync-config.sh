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

# Consumption modes. sync (the default) copies provider-generic content; provider resolves it
# from the capability manifest and copies only layer content.
jq '.projects.CivitDeck.consumption = "copy-everything"' "$ROOT/skills/sync/sync-config.json" > "$TMP/bad-mode.json"
if python3 "$ROOT/scripts/sync-config.py" validate --source-root "$ROOT" --config "$TMP/bad-mode.json" >/dev/null 2>&1; then
  echo "expected an unknown consumption mode to fail" >&2
  exit 1
fi

python3 "$ROOT/scripts/sync-config.py" plan --project CivitDeck --source-root "$ROOT" > "$TMP/sync-plan.json"
test "$(jq -r .consumption "$TMP/sync-plan.json")" = sync
test "$(jq '[.copy[] | select(.owner == "provider-generic" and (.source | startswith("skills/")))] | length' "$TMP/sync-plan.json")" = \
  "$(jq '.common_skills | length' "$ROOT/skills/sync/sync-config.json")"
test "$(jq '.resolve | length' "$TMP/sync-plan.json")" = 0

jq '.projects.CivitDeck.consumption = "provider"' "$ROOT/skills/sync/sync-config.json" > "$TMP/provider.json"
python3 "$ROOT/scripts/sync-config.py" validate --source-root "$ROOT" --config "$TMP/provider.json" >/dev/null
python3 "$ROOT/scripts/sync-config.py" matrix --source-root "$ROOT" --config "$TMP/provider.json" |
  jq -e '.[] | select(.repo == "CivitDeck") | .consumption == "provider"' >/dev/null
python3 "$ROOT/scripts/sync-config.py" plan --project CivitDeck --source-root "$ROOT" --config "$TMP/provider.json" > "$TMP/provider-plan.json"
test "$(jq '[.copy[] | select(.owner != "layer")] | length' "$TMP/provider-plan.json")" = 0
test "$(jq '[.copy[] | select(.owner == "layer")] | length' "$TMP/provider-plan.json")" -gt 0
# Every exported capability is resolved by reference; standalone wrappers and opt-in policies are not.
diff <(jq -r '.resolve[]' "$TMP/provider-plan.json" | sort) \
  <(python3 "$ROOT/scripts/validate-capabilities.py" --root "$ROOT" export | jq -r '.capabilities[] | select(.kind == "capability") | .id' | sort)
jq -e '.resolve | index("coding.review") and index("coding.implement")' "$TMP/provider-plan.json" >/dev/null
if jq -e '.resolve[] | select(startswith("standalone.") or startswith("policy."))' "$TMP/provider-plan.json" >/dev/null; then
  echo "provider plan resolves a standalone wrapper or an opt-in policy" >&2
  exit 1
fi

# Applying the provider plan to an empty target leaves no provider-generic file in it.
TARGET="$TMP/target"
mkdir -p "$TARGET"
jq -r '.copy[] | "\(.source) \(.destination)"' "$TMP/provider-plan.json" | while read -r source destination; do
  mkdir -p "$(dirname "$TARGET/$destination")"
  cp -R "$ROOT/$source" "$TARGET/$destination"
done
for skill in $(jq -r '.common_skills[]' "$ROOT/skills/sync/sync-config.json"); do
  test ! -e "$TARGET/.claude/skills/$skill" || { echo "provider mode copied skills/$skill" >&2; exit 1; }
done
for rule in $(jq -r '.common_rules[], (.standalone_rules // {} | keys[]), (.policy_rules // {} | keys[])' "$ROOT/skills/sync/sync-config.json"); do
  test ! -e "$TARGET/.claude/rules/$rule" || { echo "provider mode copied rule $rule" >&2; exit 1; }
done
for agent in $(jq -r '.common_agents[]' "$ROOT/skills/sync/sync-config.json"); do
  test ! -e "$TARGET/.claude/agents/$agent.md" || { echo "provider mode copied agent $agent" >&2; exit 1; }
done

# The automated workflow honours the same boundary: every step that reads a provider-generic
# list runs only for sync consumption.
python3 - "$ROOT/.github/workflows/sync-to-projects.yml" <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
steps = re.split(r"(?m)^      - name: ", text)[1:]
generic = re.compile(r"common_skills|common_agents|common_rules|standalone_rules|policy_rules")
unguarded = [step.splitlines()[0] for step in steps if generic.search(step) and "if: matrix.consumption == 'sync'" not in step]
if unguarded:
    sys.exit(f"workflow copies provider-generic content without a sync guard: {unguarded}")
if not any(generic.search(step) for step in steps):
    sys.exit("workflow no longer reads the provider-generic lists; update this check")
PY

echo "Sync config tests passed"
