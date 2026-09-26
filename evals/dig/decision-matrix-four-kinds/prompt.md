---
name: dig-decision-matrix-four-kinds
description: "A decision matrix that separates the four kinds and records the unresolved one as an assumption with a risk"
tags: [dig]
expected_outcome: "A decision matrix that separates the four kinds and records the unresolved one as an assumption with a risk"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Output the dig results for a run where 3 decisions were auto-decided, 1 was resolved by reading code, 1 was chosen by the user, and 1 could not be resolved at all.
