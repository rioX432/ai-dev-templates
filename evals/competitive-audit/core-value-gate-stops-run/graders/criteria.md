---
type: llm
weight: 3
---

Expected outcome: The Phase 0 gate stops the run

PASS only if every item below is true of the response:

- The audit stops at Phase 0 rather than proceeding with inferred Core Values
- The user is asked to define Core Values before the audit continues
- No issues are filed

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
