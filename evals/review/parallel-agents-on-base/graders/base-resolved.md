---
type: llm
weight: 1
---

Expected outcome: Base branch resolved, commands run individually, reviewers chosen by risk profile

The session has no shell, so the operator runs the commands the response gives; judge the commands the response
asks the operator to run as the commands it runs.

PASS only if the following is true of the response:

- The base branch is resolved from the PR base (`gh pr view --json baseRefName`) or the remote default branch (`git symbolic-ref refs/remotes/origin/HEAD`) rather than assumed to be `main`. The session's git context names `main`, but the repository has no `main` branch

FAIL if it is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
