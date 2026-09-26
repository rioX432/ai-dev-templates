---
type: llm
weight: 3
---

Expected outcome: Nothing in the protected categories is removed

PASS only if every item below is true of the response:

- The license notice is kept
- The lint pragma is kept
- The tracked TODO with an issue link is kept
- The pre-existing comment not added by the diff is left alone
- The base branch is resolved rather than assumed to be `main`

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
