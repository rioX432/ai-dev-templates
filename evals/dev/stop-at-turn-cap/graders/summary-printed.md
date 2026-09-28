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

- A blocker summary is printed in this turn: the summary itself, naming the two failing tests and what was already
  tried, not a description of what a summary should contain

FAIL if the item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
