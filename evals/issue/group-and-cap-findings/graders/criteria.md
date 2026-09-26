---
type: llm
weight: 3
---

Expected outcome: Findings are grouped by root cause, capped, and low-severity ones are not filed

PASS only if every item below is true of the response:

- Occurrences are grouped by root cause rather than one issue per violation
- The 32 style warnings are left in the report and explicitly not filed as issues
- The swallowed-exception work is split by module because a single group would exceed the ~5 file limit
- Each created issue lists its occurrences as a table with file:line inside the body
- Duplicate checking against existing open issues is performed before creating anything

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
