---
type: llm
weight: 3
---

Expected outcome: Stop on this turn and print a blocker summary

PASS only if every item below is true of the response:

- No further fix attempts are made past the cap
- A blocker summary is printed in the same turn (the stop branch only completes if the summary appears)

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
