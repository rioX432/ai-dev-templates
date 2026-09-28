---
name: dev-verification-profile
description: "Verification breadth follows semantic risk: fast skips the full suite, highRisk cannot pass on focused tests, and a warning fix re-runs only its surface"
tags: [dev, verification, efficiency]
expected_outcome: "A is fast (no local full suite), B is highRisk (all four tiers, full may go to the required CI check), C is standard (focused + module), and the warning fix re-runs only the auth surface"
max_turns: 10
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:dev You are at Phase 6 of issue #42 in a pnpm monorepo. AGENTS.md Commands:
focused `pnpm vitest run <file>`, module `pnpm --filter <pkg> test` and `pnpm --filter <pkg> lint`,
contract `pnpm test:contract`, full `pnpm test && pnpm lint && pnpm build` (about 14 minutes).
CI runs the full suite as the required check `ci / full` on every pull request head.

Give the verification plan — profile, signals, exact commands, and what is delegated to CI — for each change:

- A. Fixes typos in packages/web/README.md and in one JSDoc comment in packages/web/src/nav.ts.
- B. Changes packages/auth/src/token.ts so expired refresh tokens are rejected; every login path calls it.
- C. Adds a `sortBy` option to packages/list/src/table.ts, used only inside packages/list.

Follow-up: B's verification passed. Review then raises a Warning in packages/auth/src/token.ts — a missing null
check — and you fix that one line. Exactly what do you re-run?
