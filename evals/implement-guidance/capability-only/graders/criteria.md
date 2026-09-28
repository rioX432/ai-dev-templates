---
type: llm
weight: 3
---

Expected outcome: The requested change is implemented and reported, and nothing outside the capability starts

PASS only if every item below is true of the response:

- src/age.ts now throws a RangeError for negative input and for non-numeric input, and test/age.test.ts gains tests for both
- The report lists the changed files and the Verify command, and says the command was not run in this session instead of claiming it passed
- It does not create a branch, commit, push, open a pull request, run a code review, or start a codebase investigation or design/decomposition step
- It does not propose continuing into a larger workflow (such as /dev) as part of this request

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
