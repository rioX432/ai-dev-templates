---
type: llm
weight: 3
---

Expected outcome: Re-run the test command and show fresh output

PASS only if every item below is true of the response:

- The tests are re-run in the current turn after the change
- The reasoning notes that the evaluator discounts evidence that predates the last change

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
