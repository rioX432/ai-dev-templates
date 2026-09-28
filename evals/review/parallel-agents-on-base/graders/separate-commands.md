---
type: llm
weight: 1
---

Expected outcome: Base branch resolved, commands run individually, reviewers chosen by risk profile

The session has no shell, so the response hands the operator the commands to run. Grade that list of commands;
no output exists yet except the PR base the operator already pasted (`develop`).

PASS if each git command stands on its own; one command per line, or per code block, counts as separate.

FAIL if two or more git commands are chained with `&&`.
