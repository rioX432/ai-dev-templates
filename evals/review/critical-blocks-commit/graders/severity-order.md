---
type: llm
weight: 1
---

Expected outcome: Critical blocks; the caller stops rather than committing

PASS only if the following is true of the response:

- Severity ordering is preserved in the report: Critical, Warning, Suggestion, Nit

FAIL if it is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
