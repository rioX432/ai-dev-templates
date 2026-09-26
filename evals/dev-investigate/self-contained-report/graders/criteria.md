---
type: llm
weight: 3
---

Expected outcome: Write a self-contained report with evidence, decisions, and scope limits

PASS only if every item below is true:

- The result is written to the exact requested report path rather than existing only as a chat summary
- The report includes concrete `file:line` evidence and connects it to the acceptance criteria
- It includes `Changes Needed` and `Decision Points` that the caller can consume without the fork context
- It records both the API client/session repository coverage and the material scope that was skipped
- Unverified areas remain unknown rather than being presented as facts

FAIL if any item is contradicted or omitted. A promise to write the report later does not pass.
