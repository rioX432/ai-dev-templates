---
type: llm
weight: 1
---

Expected outcome: A single /goal condition derived from the repo, not a wrapper around the raw request

PASS only if the item below is true of the response:

- The stop clause is OR-joined into the condition ("— or stop after N turns"), not a separate sentence

FAIL if the item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
