---
type: llm
weight: 3
---

Expected outcome: A decision matrix that separates the four kinds and records the unresolved one as an assumption with a risk

PASS only if every item below is true of the response:

- Auto-decided, Investigated, and User-decided decisions appear in separate tables
- Each auto-decided row names the rule or file that decided it
- The unresolved decision appears in the Assumptions table with an explicit risk, not silently omitted
- No decision is presented as settled without a stated basis

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
