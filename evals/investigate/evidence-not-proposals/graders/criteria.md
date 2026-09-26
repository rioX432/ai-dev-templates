---
type: llm
weight: 3
---

Expected outcome: A report grounded in file:line evidence, with no proposals

PASS only if every item below is true of the response:

- 2-4 investigation axes are chosen and Explore agents are launched in parallel, one per axis
- Every claim in the report carries a file:line reference
- Facts read from code are distinguished from inferences
- The report ends without proposing an implementation or filing an issue

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
