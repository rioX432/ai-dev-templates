---
type: llm
weight: 3
---

Expected outcome: Critical blocks; the caller stops rather than committing

PASS only if every item below is true of the response:

- The Critical finding is reported as blocking and no commit or PR proceeds
- Severity ordering is preserved in the report: Critical, Warning, Suggestion, Nit
- Nit findings are not escalated into blockers
- The counts are printed as text so an autonomous caller can read them from the transcript

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
