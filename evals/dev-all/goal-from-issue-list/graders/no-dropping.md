---
type: llm
weight: 1
---

Expected outcome: A /goal condition derived from the resolved issue list, plus per-issue sub-agent prompts without /goal in them

PASS only if the item below is true of the response:

- The condition forbids dropping issues from the list to finish early

FAIL if the item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
