---
type: llm
weight: 1
---

Expected outcome: Base branch resolved, commands run individually, reviewers chosen by risk profile

The session has no shell, so the response hands the operator the commands to run. Grade that list of commands;
no output exists yet except the PR base the operator already pasted (`develop`).

PASS if the committed changes are requested with a three-dot diff, `git diff <base>...HEAD`.

FAIL if the committed diff uses two dots (`<base>..HEAD`) or a plain `git diff <base>`, or no committed diff is requested.
