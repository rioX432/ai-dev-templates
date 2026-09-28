---
type: llm
weight: 1
focus:
  source: file
  path: workspace/auth-timeout-investigation.md
---

Expected outcome: Write a self-contained report with evidence, decisions, and scope limits

You are reading the report file itself. The caller will see nothing else from the investigation.

PASS only if the item below is true of the report:

- Its `file:line` evidence is connected to both acceptance criteria (the single refresh after expiry, and the
  retryable timeout)

FAIL if the item is contradicted or omitted, or if the file is empty. A promise to investigate later does not pass.
