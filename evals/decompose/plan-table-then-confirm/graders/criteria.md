---
type: llm
weight: 3
---

Expected outcome: A table with behavior, scope, verify and blocking dependencies, then user confirmation before implementing

PASS only if every item below is true of the response:

- The output is a table with columns for behavior, scope, Verify and Blocked By
- Dependency edges point at earlier task numbers and exist only where one task needs another's output
- User confirmation is requested before the implementation loop begins (skipped in autonomous /dev)
- Tasks with disjoint file scopes and no dependency are marked parallel rather than everything being serialized

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
