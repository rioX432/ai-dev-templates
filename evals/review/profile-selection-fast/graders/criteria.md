---
type: llm
weight: 3
---

Expected outcome: The coordinator reviews a fast change itself

PASS only if every item below is true of the response:

- The change is classified as the `fast` profile (documentation and comment text only)
- The response reviews the diff itself and reports its findings (or that there are none) with severity ordering
- The report states that no independent reviewer was used, or that the independent reviewer count is 0

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
