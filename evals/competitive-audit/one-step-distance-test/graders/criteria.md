---
type: llm
weight: 3
---

Expected outcome: It fails the one-step distance test and goes to Won't Do, not the backlog

PASS only if every item below is true of the response:

- The one-step distance test is applied and shown to fail, with the intermediate reasoning steps named
- The absence of user pain point evidence is treated as disqualifying on its own
- An entry is proposed for CLAUDE.md ## Won't Do with the reason, so future audits do not re-propose it
- No issue is filed for it

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
