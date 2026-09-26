---
name: audit-finding-cap-and-grouping
description: "At most 11 findings reach the issue skill, grouped by root cause, and Medium/Low stay in the report"
tags: [audit]
expected_outcome: "At most 11 findings reach the issue skill, grouped by root cause, and Medium/Low stay in the report"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:audit found 3 Critical, 8 High, 22 Medium and 61 Low findings. The user picks "All Critical + High". What gets filed?
