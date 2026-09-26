---
type: llm
weight: 3
---

Expected outcome: A single /goal condition derived from the repo, not a wrapper around the raw request

PASS only if every item below is true of the response:

- The condition names `./gradlew test` (resolved from CLAUDE.md), not a guessed command like `npm test`
- The condition requires an exact evidence signal from command output (e.g. BUILD SUCCESSFUL / 0 failed) in the most recent turn
- The condition requires review.json counts printed as text with "critical": 0
- The stop clause is OR-joined into the condition ("— or stop after N turns"), not a separate sentence
- A guardrail forbids modifying test files and requires `git diff --stat` as proof

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
