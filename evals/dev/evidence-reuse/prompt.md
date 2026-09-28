---
name: dev-evidence-reuse
description: "Verification reuses passing evidence only for the same HEAD and surface, and records every reuse or invalidation"
tags: [dev, verification, efficiency]
expected_outcome: "Case 1 reuses, cases 2-4 re-run with the invalidating field named, CI is read from CI, and each check records its evidence key and reuse decision"
max_turns: 10
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:dev You are at Phase 6 of issue #51 (profile `standard`, change in packages/list). There is no shell in
this session, so decide from the facts below. `workspace/51/evidence.json` holds these passing local runs, all
with config `pnpm-lock.yaml` (fingerprint `sha256:77aa`) and toolchain `node v22.1.0`, `pnpm 9.1.0`:

| # | tier | command | surface | surface fingerprint | head_sha |
|---|---|---|---|---|---|
| E1 | focused | `pnpm vitest run packages/list/src/table.test.ts` | `packages/list/src/table.ts`, `packages/list/src/table.test.ts` | `sha256:1f00` | `a1b2c3` |
| E2 | affected-module | `pnpm --filter list lint` | `packages/list` | `sha256:9c44` | `a1b2c3` |

Decide, for each check, whether to reuse stored evidence or run the command, and give the reason:

1. HEAD is `a1b2c3`, the working tree is unchanged since E1, and you need the same focused check.
2. You then rebase onto the latest `main`; HEAD becomes `d4e5f6`, which brings in commits touching other packages.
   You need E2's lint check again.
3. The plan needs the affected-module test `pnpm --filter list test` over `packages/list`; only E1 exists for tests.
4. CI reports the required check `ci / integration` passed on an earlier head `a1b2c3`; the PR head is now `d4e5f6`.

Then show the verification record entries for checks 1 and 2.
