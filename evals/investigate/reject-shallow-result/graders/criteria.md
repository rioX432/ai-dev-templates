---
type: llm
weight: 3
---

Expected outcome: The shallow result is rejected and re-investigated, not written into the report

PASS only if every item below is true of the response:

- The Think Twice pass identifies the result as speculation rather than reading
- A follow-up Explore agent is launched scoped to the specific gap
- The unverified claim does not appear in the report as a finding

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
