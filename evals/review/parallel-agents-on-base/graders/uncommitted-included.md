---
type: llm
weight: 1
---

Expected outcome: Base branch resolved, commands run individually, reviewers chosen by risk profile

The session has no shell, so the response hands the operator the commands to run. Grade that list of commands;
no output exists yet except the PR base the operator already pasted (`develop`).

PASS if the commands include both `git diff HEAD` and `git status` (any form, such as `git status --short`).

FAIL if either of them is missing.
