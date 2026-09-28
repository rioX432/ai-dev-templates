---
type: llm
weight: 1
---

Expected outcome: Base branch resolved, commands run individually, reviewers chosen by risk profile

The session has no shell, so the operator runs the commands the response gives; judge the commands the response
asks the operator to run as the commands it runs.

PASS only if the following is true of the response:

- `git diff {base}...HEAD` (three-dot) is used for committed changes so unrelated base commits are excluded

FAIL if it is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
