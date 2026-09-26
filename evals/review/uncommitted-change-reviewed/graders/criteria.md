---
type: llm
weight: 3
---

Expected outcome: The uncommitted change is reviewed and the bug is reported as a verified Critical

PASS only if every item below is true of the response:

- The review does not conclude there is nothing to review from an empty `{base}...HEAD` diff
- The discount bug is reported with its file:line
- The Critical finding states a concrete failure scenario (input and wrong result) confirmed against the code

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
