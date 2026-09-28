#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
export PYTHONDONTWRITEBYTECODE=1
GATE="$ROOT/scripts/verification-gate.py"
RULE="$ROOT/rules/verification.md"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# The rule's profile table is the script's table, verbatim.
diff <(python3 "$GATE" table) <(sed -n '/verification-profiles:start/,/verification-profiles:end/p' "$RULE" | sed '1d;$d')
# Every signal the script knows sits in the rule's row for the same profile.
for profile in fast standard highRisk; do
  for signal in $(python3 -c "import importlib.util,sys; s=importlib.util.spec_from_file_location('g','$GATE'); g=importlib.util.module_from_spec(s); s.loader.exec_module(g); print(' '.join(g.SIGNALS['$profile']))"); do
    grep -E "^\| .*\`$signal\`.* \| \`$profile\` \|$" "$RULE" >/dev/null || { echo "signal $signal missing from $profile row" >&2; exit 1; }
  done
done

test "$(python3 "$GATE" classify docs-only)" = fast
test "$(python3 "$GATE" classify docs-only behavior-change)" = standard
test "$(python3 "$GATE" classify docs-only auth)" = highRisk
if python3 "$GATE" classify >/dev/null 2>&1; then echo "empty signals must not classify" >&2; exit 1; fi
if python3 "$GATE" classify big-diff >/dev/null 2>&1; then echo "unknown signal must not classify" >&2; exit 1; fi

HEAD=1111111111111111111111111111111111111111
check() { # name profile signals-json checks-json [done_when-json]
  jq -n --arg p "$2" --argjson s "$3" --argjson c "$4" --argjson d "${5:-[]}" --arg h "$HEAD" \
    '{profile: $p, signals: $s, head_sha: $h, done_when: $d, checks: ($c | map(. + {head_sha: (.head_sha // $h), exit_code: (.exit_code // 0), success_signal: (.success_signal // "ok")}))}' \
    >"$TMP/$1.json"
  local status=0
  python3 "$GATE" check "$TMP/$1.json" >"$TMP/$1.out" 2>"$TMP/$1.err" || status=$?
  # 1 is a policy failure; anything else is a broken record and must not satisfy an expected "fail"
  case $status in 0) echo pass ;; 1) echo fail ;; *) echo "error:$status" ;; esac
}
field() { jq -c "$2" "$TMP/$1.out"; }

FOCUSED='{"tier":"focused","command":"pnpm test -- test/auth.test.ts","source":"local"}'
MODULE='{"tier":"affected-module","command":"pnpm --filter auth test","source":"local"}'
INTEGRATION='{"tier":"integration","command":"pnpm test:contract","source":"local"}'
FULL_LOCAL='{"tier":"full","command":"pnpm test","source":"local"}'
FULL_CI='{"tier":"full","command":"ci / test","source":"ci","required":true}'
FULL_CI_OPTIONAL='{"tier":"full","command":"ci / nightly","source":"ci"}'
FULL_STALE='{"tier":"full","command":"pnpm test","source":"local","head_sha":"2222222222222222222222222222222222222222"}'
MODULE_FAILED='{"tier":"affected-module","command":"pnpm --filter auth test","source":"local","exit_code":1}'
FULL_REQUIRED='{"tier":"full","command":"pnpm test","source":"local","required_by":"repository"}'
INTEGRATION_CI='{"tier":"integration","command":"ci / contract","source":"ci","required":true}'

# highRisk cannot pass on focused checks alone
test "$(check hr-focused highRisk '["auth"]' "[$FOCUSED]")" = fail
test "$(field hr-focused .missing)" = '["affected-module","integration","full"]'
# highRisk passes with every tier, full delegated to a required CI check on the same head
test "$(check hr-full highRisk '["auth"]' "[$FOCUSED,$MODULE,$INTEGRATION,$FULL_CI]")" = pass
test "$(field hr-full .delegated_command_count)" = 1
# an informational CI job that merge does not require satisfies nothing
test "$(check hr-optional-ci highRisk '["auth"]' "[$FOCUSED,$MODULE,$INTEGRATION,$FULL_CI_OPTIONAL]")" = fail
test "$(field hr-optional-ci .missing)" = '["full"]'
# a lower declared profile is raised to the one the signals require
test "$(check understated fast '["auth"]' "[$FOCUSED]")" = fail
test "$(field understated .profile)" = '"highRisk"'
# stale evidence from an earlier head satisfies nothing
test "$(check stale highRisk '["auth"]' "[$FOCUSED,$MODULE,$INTEGRATION,$FULL_STALE]")" = fail
test "$(field stale .missing)" = '["full"]'
# a failed check satisfies nothing
test "$(check failed standard '["behavior-change"]' "[$FOCUSED,$MODULE_FAILED]")" = fail

# fast passes on focused checks and runs one command
test "$(check fast-focused fast '["docs-only"]' "[$FOCUSED]")" = pass
test "$(field fast-focused .local_command_count)" = 1
# fast does not run an unrelated full suite locally unless something requires it
test "$(check fast-full fast '["docs-only"]' "[$FOCUSED,$FULL_LOCAL]")" = fail
test "$(check fast-full-required fast '["docs-only"]' "[$FOCUSED,$FULL_REQUIRED]")" = pass
# required_by names who required the extra run; anything else is a broken record
test "$(check fast-full-bogus fast '["docs-only"]' '[{"tier":"focused","command":"pnpm test","source":"local","required_by":"felt like it"}]')" = error:2
# CI cannot stand in for a tier the profile does not let it delegate
test "$(check fast-ci fast '["docs-only"]' '[{"tier":"focused","command":"ci / unit","source":"ci"}]')" = fail

# standard adds integration only for a module-boundary change, and may delegate it
test "$(check std standard '["behavior-change"]' "[$FOCUSED,$MODULE]")" = pass
test "$(check std-boundary standard '["crosses-module-boundary"]' "[$FOCUSED,$MODULE]")" = fail
test "$(field std-boundary .missing)" = '["integration"]'
test "$(check std-boundary-ci standard '["crosses-module-boundary"]' "[$FOCUSED,$MODULE,$INTEGRATION_CI]")" = pass

# Done when commands always run as written, even when a broader tier passed
test "$(check done-when standard '["behavior-change"]' "[$FULL_LOCAL]" '["pnpm test -- test/auth.test.ts"]')" = fail
test "$(field done-when .missing)" = '["done_when: pnpm test -- test/auth.test.ts"]'

# A reused check is evidence, not a command run again
REUSED='{"tier":"focused","command":"pnpm test -- test/auth.test.ts","source":"local","reuse":{"decision":"reused","reason":"same HEAD and surface content"}}'
test "$(check reused fast '["docs-only"]' "[$REUSED]")" = pass
test "$(field reused '[.local_command_count, .reused_command_count]')" = '[0,1]'

# Evidence reuse on a real repository: the key binds HEAD, surface content, command, config, and toolchain.
REPO="$TMP/repo"
mkdir -p "$REPO/src" "$REPO/test"
git -C "$REPO" init -q
printf 'export const a = 1;\n' >"$REPO/src/a.ts"
printf 'export const b = 1;\n' >"$REPO/src/b.ts"
printf 'test a\n' >"$REPO/test/a.test.ts"
printf '{"lockfileVersion": 9}\n' >"$REPO/pnpm-lock.yaml"
git -C "$REPO" add -A
git -C "$REPO" -c user.email=t@example.com -c user.name=t commit -qm init

key() { # name tier command surface...; config pnpm-lock.yaml, toolchain node 22
  local name=$1 tier=$2 cmd=$3; shift 3
  python3 "$GATE" key --repo "$REPO" --tier "$tier" --command "$cmd" --surface "$@" \
    --config pnpm-lock.yaml --toolchain "node v22.1.0" >"$TMP/$name.key"
}
store() { # key-name [exit_code] [source] -> evidence list with that key
  jq -n --slurpfile k "$TMP/$1.key" --argjson e "${2:-0}" --arg s "${3:-local}" \
    '[{key: $k[0], source: $s, exit_code: $e, success_signal: "1 passed"}]' >"$TMP/$1.evidence"
}
decide() { # evidence-name key-name -> decision
  python3 "$GATE" reuse "$TMP/$1.evidence" "$TMP/$2.key" >"$TMP/$2.decision"
  jq -r .decision "$TMP/$2.decision"
}
reason() { jq -r .reason "$TMP/$1.decision"; }
FOCUSED_CMD="pnpm vitest run test/a.test.ts"

key base focused "$FOCUSED_CMD" src/a.ts test/a.test.ts
store base
# same HEAD, same surface: the duplicate command is skipped
key same focused "$FOCUSED_CMD" src/a.ts test/a.test.ts
test "$(decide base same)" = reuse
test "$(reason same)" = "same HEAD and surface content"
# no evidence yet: run
test "$(python3 "$GATE" reuse "$TMP/missing.evidence" "$TMP/same.key" | jq -r .decision)" = run

# an uncommitted fix outside the surface leaves it reusable; the whole-repository surface is not
key full-before full "pnpm test" .
store full-before
printf 'export const b = 2;\n' >"$REPO/src/b.ts"
key outside focused "$FOCUSED_CMD" src/a.ts test/a.test.ts
test "$(decide base outside)" = reuse
key full-after full "pnpm test" .
test "$(decide full-before full-after)" = run
test "$(reason full-after)" = "evidence[0]: surface content changed"

# an edit inside the surface invalidates it
printf 'export const a = 2;\n' >"$REPO/src/a.ts"
key inside focused "$FOCUSED_CMD" src/a.ts test/a.test.ts
test "$(decide base inside)" = run
test "$(reason inside)" = "evidence[0]: surface content changed"

# committing exactly the verified tree keeps the evidence; any other new HEAD invalidates it
key verified focused "$FOCUSED_CMD" src/a.ts test/a.test.ts
store verified
git -C "$REPO" add -A
git -C "$REPO" -c user.email=t@example.com -c user.name=t commit -qm fix
key committed focused "$FOCUSED_CMD" src/a.ts test/a.test.ts
test "$(decide verified committed)" = reuse
test "$(reason committed)" = "HEAD commits the verified tree unchanged"
printf 'notes\n' >"$REPO/NOTES.md"
git -C "$REPO" add -A
git -C "$REPO" -c user.email=t@example.com -c user.name=t commit -qm notes
key next-head focused "$FOCUSED_CMD" src/a.ts test/a.test.ts
test "$(decide verified next-head)" = run
test "$(reason next-head)" = "evidence[0]: HEAD changed"

# an expanded surface does not inherit narrower evidence
key narrow affected-module "pnpm --filter app test" src/a.ts
store narrow
key wide affected-module "pnpm --filter app test" src/a.ts src/b.ts
test "$(decide narrow wide)" = run
test "$(reason wide)" = "evidence[0]: surface changed; surface content changed"

# configuration and toolchain are part of the key
printf '{"lockfileVersion": 10}\n' >"$REPO/pnpm-lock.yaml"
key new-lock affected-module "pnpm --filter app test" src/a.ts
test "$(decide narrow new-lock)" = run
test "$(reason new-lock)" = "evidence[0]: config_fingerprint changed"
git -C "$REPO" checkout -q -- pnpm-lock.yaml
python3 "$GATE" key --repo "$REPO" --tier affected-module --command "pnpm --filter app test" --surface src/a.ts \
  --config pnpm-lock.yaml --toolchain "node v24.0.0" >"$TMP/new-node.key"
test "$(decide narrow new-node)" = run
test "$(reason new-node)" = "evidence[0]: toolchain changed"

# failed runs and CI results are never reused
key again affected-module "pnpm --filter app test" src/a.ts
store narrow 1
test "$(decide narrow again)" = run
test "$(reason again)" = "evidence[0]: stored run did not pass"
store narrow 0 ci
test "$(decide narrow again)" = run
test "$(reason again)" = "evidence[0]: CI evidence is read from CI status, never reused from a local store"

echo "Verification gate tests passed"
