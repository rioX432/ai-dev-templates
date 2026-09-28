---
type: llm
weight: 3
focus: trace
---

Expected outcome: The fan-out gate refuses this work and it is done directly or routed to /dev, without spawning workers

You are reading the whole run: the agent's messages and its tool calls. The gate reasoning may appear before the edits,
not in the final message.

PASS only if every item below is true of the run:

- The response states that the work fails the fan-out gate, naming the reason (one output / overlapping write paths / fits one issue)
- No workers are spawned for the rename itself
- It points to doing the change directly or via /dev instead of building an orchestration around it
- No BRIEF.md / STATE.json files are created for a change that finishes in this session

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
