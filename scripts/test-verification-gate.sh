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

echo "Verification gate tests passed"
