---
type: llm
weight: 3
---

Expected outcome: Most decisions are auto-decided from documented conventions and codebase precedent; only genuinely open ones reach the user

PASS only if every item below is true of the response:

- Placement is auto-decided from the CLAUDE.md module layout, citing the rule
- Error handling is auto-decided as Result<T> by citing the existing pattern with a file reference
- Naming and test strategy are dropped or auto-decided from conventions rather than asked
- At most 5 questions are asked in total (no more than 4 at a time), and each carries 2-4 concrete options and a recommendation
- The recommended option is the one matching existing codebase patterns

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
