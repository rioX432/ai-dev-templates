---
type: llm
weight: 3
---

Expected outcome: At most 11 findings reach the issue skill, grouped by root cause, and Medium/Low stay in the report

PASS only if every item below is true of the response:

- Medium and Low findings are explicitly kept out of issue creation
- Findings sharing a root cause are grouped into one issue before handoff, not filed one per occurrence
- Each handed-over finding carries its file:line so the issue can name expected files
- The batch cap of 10 issues per run is respected or the overflow is reported rather than silently filed

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
