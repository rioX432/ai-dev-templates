---
type: llm
weight: 3
---

Expected outcome: The narration and change-history comments are removed; the invariant is kept

PASS only if every item below is true of the response:

- The loop narration comment is removed
- The change-history comment is removed because it states no lasting constraint
- The sorted-list invariant comment is kept unchanged
- No code, import, or declaration line differs in the resulting diff

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
