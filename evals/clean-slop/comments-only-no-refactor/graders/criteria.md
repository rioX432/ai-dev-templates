---
type: llm
weight: 3
---

Expected outcome: Only comment text changes; the rename and import removal are declined as out of scope

PASS only if every item below is true of the response:

- No identifier is renamed
- No import is removed
- The reply states that logic or import changes are outside this pass
- Changes are left uncommitted

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
