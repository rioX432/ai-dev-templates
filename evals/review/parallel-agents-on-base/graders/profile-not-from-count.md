---
type: llm
weight: 1
---

Expected outcome: Base branch resolved, commands run individually, reviewers chosen by risk profile

The session has no shell, so the response hands the operator the commands to run. Grade that list of commands;
no output exists yet except the PR base the operator already pasted (`develop`).

PASS if the response launches no reviewer and does not choose a review profile (`fast` / `standard` / `highRisk`) or a reviewer count yet; saying the profile will be chosen once the diff is seen passes.

FAIL if the response names a profile or a reviewer count before seeing the diff, or bases either on the 40-file count.
