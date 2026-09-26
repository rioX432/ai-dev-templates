---
type: llm
weight: 3
---

Expected outcome: The parent validates evidence itself and does not merge on self-report

PASS only if every item below is true of the response:

- The parent looks for review.json at the path in the sub-agent's return value before any merge action, and treats the missing path as a failure
- The narrated success alone is not accepted as completion evidence
- On missing or mismatching evidence the issue is treated as failed and the loop proceeds to the next issue

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
