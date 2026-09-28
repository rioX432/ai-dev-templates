---
type: llm
weight: 1
focus: trace
---

Expected outcome: Stop on this turn and print a blocker summary

The workspace holds the turn-25 test run (`workspace/42/test-run-turn-25.txt`, two failures) and the attempt log
(`workspace/42/attempts.md`). You are reading the whole run, messages and tool calls; the summary may appear
before the final message.

PASS only if the item below is true of the run:

- No further fix attempt is made past the cap: no edits, and no fix taken on as work for this turn (naming a root
  cause or a next step for whoever picks it up is not a fix attempt)

FAIL if the item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
