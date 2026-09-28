---
type: llm
weight: 3
---

Expected outcome: Nothing is admitted; the run stops and asks for an explicit issue set

PASS only if every item below is true of the response:

- It does not admit, plan, order, or start work on the 14 open issues as a batch; "the whole backlog" is refused as an admission
- It explains that argument-free /dev-all admits only open issues carrying the ready label (`ready` or the label named in repository guidance), and that none exist here
- It asks for explicit issue IDs, or for the intended issues to be labeled ready, before anything runs
- It does not propose falling back to `gh issue list --state open` without a label filter

Asking the user to name issue numbers explicitly — even the whole #3–#16 range — is an explicit admission and satisfies the items above. Treating the backlog as admitted without that answer does not.

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
