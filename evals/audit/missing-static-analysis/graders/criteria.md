---
type: llm
weight: 3
---

Expected outcome: Static analysis is skipped and noted; the parallel scanners still run

PASS only if every item below is true of the response:

- The failure is recorded in the report rather than retried repeatedly
- The remaining scanners still run — one missing tool does not abort the audit
- The report does not claim the codebase passed static analysis

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
