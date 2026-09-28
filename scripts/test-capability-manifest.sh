#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
VALIDATE="$ROOT/scripts/validate-capabilities.py"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

test "$(python3 "$VALIDATE")" = "capability manifest: OK"

EXPORT=$(python3 "$VALIDATE" export)
for id in standalone.dev standalone.dev-all standalone.orchestrate standalone.dev-investigate standalone.ai-ops standalone.sync; do
  if printf '%s' "$EXPORT" | jq -e --arg id "$id" '.capabilities[] | select(.id == $id)' >/dev/null; then
    echo "export leaked standalone entry $id" >&2
    exit 1
  fi
done
for skill in dev dev-all orchestrate; do
  if printf '%s' "$EXPORT" | jq -e --arg p "skills/$skill" '.capabilities[].resources[] | select(.path == $p)' >/dev/null; then
    echo "export references standalone wrapper skills/$skill" >&2
    exit 1
  fi
done
test "$(python3 "$VALIDATE" resolve coding.review | jq -r '.entrypoint')" = "skills/review/SKILL.md"
if python3 "$VALIDATE" resolve standalone.dev-all >/dev/null 2>&1; then
  echo "resolver loaded a standalone control plane" >&2
  exit 1
fi

# Buddy-facing context: everything a resolver can load must be free of standalone
# Control Plane policy. The same markers must match the standalone policy itself, so
# a passing scan cannot come from markers that match nothing.
CONTROL_PLANE_MARKERS='/goal\b|\bWIP\b|dev-all|\borchestrate\b|model selection|effort level|worktree|lowest-numbered|consecutive failures|turn cap|maxTurns|\(model:|ready label|standalone/orchestration|standalone-orchestration'
python3 "$VALIDATE" context >"$TMP/context.md"
if grep -n -i -E "$CONTROL_PLANE_MARKERS" "$TMP/context.md"; then
  echo "Buddy-facing capability context contains standalone orchestration policy" >&2
  exit 1
fi
for marker in '/goal' 'WIP limit' 'Model Selection' 'Effort Level' 'worktree' 'consecutive failures' 'turn cap' 'ready label'; do
  grep -q -F "$marker" "$ROOT/standalone/orchestration.md" || {
    echo "marker '$marker' no longer appears in the standalone policy; update the scan" >&2
    exit 1
  }
done

# Each mutation runs against a private copy so hash and coverage checks see real files.
fresh_copy() {
  rm -rf "$TMP/src"
  mkdir -p "$TMP/src"
  cp -R "$ROOT/capabilities" "$ROOT/skills" "$ROOT/agents" "$ROOT/rules" "$ROOT/standalone" "$ROOT/.claude-plugin" "$TMP/src/"
}

expect_failure() {
  local label=$1 pattern=$2
  if python3 "$VALIDATE" --root "$TMP/src" >"$TMP/out" 2>&1; then
    echo "expected failure: $label" >&2
    exit 1
  fi
  if ! grep -q -- "$pattern" "$TMP/out"; then
    echo "wrong failure for $label:" >&2
    cat "$TMP/out" >&2
    exit 1
  fi
}

mutate() {
  jq "$1" "$TMP/src/capabilities/manifest.json" >"$TMP/next.json"
  mv "$TMP/next.json" "$TMP/src/capabilities/manifest.json"
}

fresh_copy
mutate '(.capabilities[] | select(.id == "standalone.dev-all")) |= (.kind = "capability" | .id = "coding.batch" | del(.standalone) | .composes = [])'
expect_failure "exported dev-all" "standalone wrapper and cannot be exported"

fresh_copy
mutate '(.capabilities[] | select(.id == "standalone.orchestrate")) |= (.kind = "capability" | .id = "coding.orchestrate" | del(.standalone))'
expect_failure "exported orchestrate" "standalone wrapper and cannot be exported"

fresh_copy
mutate '(.capabilities[] | select(.id == "coding.review")).composes += ["standalone.dev"]'
expect_failure "capability composing a wrapper" "cannot compose standalone entry"

fresh_copy
printf '\nDrift.\n' >>"$TMP/src/skills/review/SKILL.md"
expect_failure "stale content hash" "coding.review: content_hash is stale"

fresh_copy
mutate '.capabilities += [.capabilities[0]]'
expect_failure "duplicate id" "duplicate capability id coding.investigate"

fresh_copy
mutate '(.capabilities[0]).owner = "someone"'
expect_failure "unknown field" "unknown field 'owner'"

fresh_copy
mutate '(.capabilities[0]).authority.external += ["github.deploy"]'
expect_failure "unknown authority" "is not one of"

fresh_copy
mutate '(.capabilities[0]).resources[0].path = "skills/missing"'
expect_failure "missing resource" "has no SKILL.md"

fresh_copy
mutate '(.capabilities[] | select(.id == "coding.conventions")) |= (.resources[0].path = "rules/../../outside.md" | .entrypoint = "rules/../../outside.md")'
expect_failure "path outside provider root" "resolves outside the provider root"

fresh_copy
mkdir -p "$TMP/src/skills/unclassified"
printf -- '---\nname: unclassified\ndescription: x\n---\n' >"$TMP/src/skills/unclassified/SKILL.md"
expect_failure "unclassified skill" "skills/unclassified is not classified"

fresh_copy
mutate '.provider.version = "0.0.1"'
expect_failure "provider version drift" "provider.version 0.0.1"

fresh_copy
mutate '.capabilities += [(.capabilities[] | select(.id == "coding.conventions")) | .id = "coding.dev-leak" | .resources = [{"type": "doc", "path": "skills/dev/SKILL.md"}] | .entrypoint = "skills/dev/SKILL.md"]'
expect_failure "wrapper re-exported as another resource type" "must be a 'skill' resource only under skills/"

fresh_copy
mutate '(.capabilities[] | select(.id == "audit.codebase")).authority.external = ["github.read"]'
expect_failure "composer understates composed authority" "omits \['github.issue.write'\] from composed github.issue"

# update-hashes repairs genuine drift and leaves a manifest that validates
fresh_copy
printf '\nDrift.\n' >>"$TMP/src/skills/review/SKILL.md"
python3 "$VALIDATE" --root "$TMP/src" update-hashes >/dev/null
test "$(python3 "$VALIDATE" --root "$TMP/src")" = "capability manifest: OK"
test "$(jq -r '.capabilities[] | select(.id == "coding.review") | .content_hash' "$TMP/src/capabilities/manifest.json")" != \
  "$(jq -r '.capabilities[] | select(.id == "coding.review") | .content_hash' "$ROOT/capabilities/manifest.json")"

# A CRLF checkout of the same content keeps the committed hash
fresh_copy
python3 - "$TMP/src/rules/behavior.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
path.write_bytes(path.read_bytes().replace(b"\n", b"\r\n"))
PY
test "$(python3 "$VALIDATE" --root "$TMP/src")" = "capability manifest: OK"

fresh_copy
mutate '(.capabilities[] | select(.id == "engineering.workflow")).resources += [{"type": "doc", "path": "standalone/orchestration.md"}]'
expect_failure "exported entry loading standalone policy" "is standalone policy and cannot be exported"

fresh_copy
printf '# stray\n' >"$TMP/src/standalone/unlisted.md"
expect_failure "unclassified standalone policy" "standalone/unlisted.md is not classified"

fresh_copy
mutate '(.capabilities[] | select(.id == "coding.implement")).authority.spawns_agents = true'
expect_failure "authority disagrees with allowed-tools" "coding.implement: authority.spawns_agents disagrees"

echo "Capability manifest tests passed"
