---
type: llm
weight: 3
---

Expected outcome: Only the dependency scanner runs; skipped scanners are named in the report

PASS only if every item below is true of the response:

- Scanners A through D are not launched, because the `deps` scope selects only E
- Static analysis is skipped for the `deps` scope rather than being auto-detected and run anyway
- The report states which scanners were skipped, not just what was found
- Findings are not filed directly with `gh issue create` — the issue skill is invoked

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
