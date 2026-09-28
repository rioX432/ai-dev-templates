---
type: llm
weight: 3
---

Expected outcome: A generic repository is not blocked by the optional product policy

PASS only if every item below is true of the response:

- An issue body is drafted for the CSV download; the response does not stop or wait to ask the user to define Core Values first
- The draft has no Core Value Alignment requirement, or explicitly marks it as not applicable because the repository has no product policy
- The sizing gate is applied, and `Done when` names the repository's documented `pnpm test` (with its success signal) or another documented command, not an invented one
- Nothing is proposed for a `## Won't Do` list

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
