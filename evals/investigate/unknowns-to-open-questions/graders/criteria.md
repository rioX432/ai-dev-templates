---
type: llm
weight: 3
---

Expected outcome: The unknown goes to Open Questions

PASS only if every item below is true of the response:

- The item appears under Open Questions rather than being answered by a plausible guess
- The report says what was covered and what was not
- No implementation recommendation is made on the basis of the unknown

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
