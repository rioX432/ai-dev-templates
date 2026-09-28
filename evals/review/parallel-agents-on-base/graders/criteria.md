---
type: llm
weight: 3
---

Expected outcome: Base branch resolved, commands run individually, reviewers chosen by risk profile

PASS only if every item below is true of the response:

- The base branch is resolved from the PR base or the remote default branch rather than assumed to be `main`
- `git diff {base}...HEAD` (three-dot) is used for committed changes so unrelated base commits are excluded
- Uncommitted changes are included via `git diff HEAD` and `git status`, so work not yet committed is reviewed
- Git commands are run as separate calls, not chained with `&&`
- The review profile is chosen from the change's semantic signals, not from the 40-file count, before any reviewer is launched

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
