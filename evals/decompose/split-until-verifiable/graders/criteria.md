---
type: llm
weight: 3
---

Expected outcome: The task is split by behavior until each part has a Verify step that can be written up front

PASS only if every item below is true of the response:

- The task is recognized as too large because no single Verify step can prove it
- It is split into behavior slices (or a spike first when the approach is uncertain) rather than accepted with a note
- Each resulting task keeps a concrete Verify step

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
