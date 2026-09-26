---
type: llm
weight: 3
---

Expected outcome: A /goal condition derived from the resolved issue list, plus per-issue sub-agents launched without /goal in their prompts

PASS only if every item below is true of the response:

- The /goal condition enumerates the resolved issue list and requires a merged PR (verified via `gh pr view --json state` output) or a documented skip reason per issue
- The stop clause (turn cap scaled to batch size, 3 consecutive failures) is OR-joined into the condition
- The Agent() prompt for each issue contains explicit evidence requirements instead of a /goal slash command
- The condition forbids dropping issues from the list to finish early

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
