---
type: llm
weight: 3
---

Expected outcome: No question is asked; the impactful decision gets the recommended default recorded as an assumption, the naming point is dropped

PASS only if every item below is true of the response:

- No attempt is made to ask the user
- The soft/hard delete decision is resolved with a recommended option and recorded in Assumptions with source `default` and a risk
- The private helper name is dropped or auto-decided rather than treated as a blocking decision
- The output includes Acceptance Criteria and Out of Scope sections

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
