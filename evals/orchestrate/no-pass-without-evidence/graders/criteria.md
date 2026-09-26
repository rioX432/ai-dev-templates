---
type: llm
weight: 3
---

Expected outcome: The return is not accepted as a pass without printed evidence, and the consumer lane's verification is re-run after the upstream change

PASS only if every item below is true of the response:

- The return is treated as needs-evidence rather than pass, because no command output was shown
- The response asks for the command and its output (or runs the verification itself) instead of trusting the worker's verdict
- The client lane's gate is reopened / its verification re-run because the contract it consumed changed
- Feedback to the worker names what is missing and what would count as fixed, rather than repeating the same brief

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
