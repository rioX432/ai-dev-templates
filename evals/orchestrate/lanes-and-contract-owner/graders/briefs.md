---
type: llm
weight: 2
---

PASS only if every delegation brief in the response carries all four required elements:

- An objective with what counts as done
- An output format: what to return, and where artifacts go
- Tool and source guidance: which paths and commands the lane may use
- Boundaries: what is out of scope, and what to do on a blocker instead of widening scope

and the verification command named per lane comes from that repository's own CLAUDE.md (`npm test` for export-server, `./gradlew test` for export-shared, `./gradlew testDebugUnitTest` for export-app) rather than an invented one, or from the wrong repository.

FAIL if a brief is missing one of the four, or if a verification command was made up.
