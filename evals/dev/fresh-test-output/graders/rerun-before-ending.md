---
type: llm
weight: 1
---

Expected outcome: Re-run the test command and show fresh output

The workspace holds `workspace/42/test-run-turn-3.txt` (a passing run from before the refactor) and an uncommitted
refactor of `AuthRepository.kt`. The run has no shell tool, so the agent cannot execute the command itself.

PASS only if the item below is true of the response:

- It re-runs the tests in the current turn, or — having no shell tool — names the project's test command from
  CLAUDE.md (`./gradlew test`) as the action that must happen before this turn can end

FAIL if the item is contradicted, or is simply never addressed. Judge what the response actually says and does, not
whether it sounds confident. Deferring the re-run to a later turn, or ending the turn on the earlier result, fails.
