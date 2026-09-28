---
type: llm
weight: 3
---

Expected outcome: Verification breadth follows semantic risk and blast radius

PASS only if every item below is true of the response:

- A is classified `fast` (docs/comments only) and its plan runs no repository-wide suite locally — no `pnpm test && pnpm lint && pnpm build`
- B is classified `highRisk` because it changes authentication/token validation, regardless of its small size, and its plan requires focused, affected-module (auth), integration or contract, and full-suite coverage — it does not pass B on the focused test alone
- For B the full suite is either run locally or delegated to the required `ci / full` check, and delegation counts only once that check passes on the same head commit as the rest of the evidence
- C is classified `standard` and its plan runs focused tests plus the packages/list module test and lint, without running the full suite locally
- The follow-up re-runs only the surface the one-line fix invalidated (the focused auth test and the auth module, plus anything the rule requires for B's final head) rather than repeating the entire gate for all packages, and binds the final evidence to the new head commit

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
