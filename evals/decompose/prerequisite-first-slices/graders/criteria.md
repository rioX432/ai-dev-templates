---
type: llm
weight: 3
---

Expected outcome: Behavior slices with the shared prerequisite first, tests inside each slice, each with a Verify command

PASS only if every item below is true of the response:

- The shared data model (and its mapper) is a prerequisite subtask ordered before the slices that need it
- Each remaining subtask delivers one user-visible behavior through the layers it needs, following the KMP layer order inside the subtask
- Implementation and its test are the same task; there is no separate tests-only subtask
- Cross-cutting checks (lint, format) are the last task and depend on the rest
- Every task states What, Where with a file path, How, Why, and Verify

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
