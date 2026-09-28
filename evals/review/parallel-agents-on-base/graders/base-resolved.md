---
type: llm
weight: 1
---

Expected outcome: Base branch resolved, commands run individually, reviewers chosen by risk profile

The session has no shell, so the response hands the operator the commands to run. Grade that list of commands;
no output exists yet except the PR base the operator already pasted (`develop`).

PASS if every `git log` / `git diff` command that takes a base uses `develop` (or `origin/develop`), the PR base the
lookup returned.

FAIL if any of them names `main` (or `origin/main`), the branch the session's git context reports; if the base is
set to `main` as a fallback; or if no `git log` / `git diff` command is given. This repository has no `main` branch.
