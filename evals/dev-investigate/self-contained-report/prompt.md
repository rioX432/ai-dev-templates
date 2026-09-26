---
name: dev-investigate-self-contained-report
description: "Preserve forked investigation evidence in the requested report"
tags: [dev-investigate]
expected_outcome: "Write a self-contained report with evidence, decisions, and scope limits"
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Write, Skill]
---

/ai-dev:dev-investigate Investigate an authentication timeout bug for /dev. The caller supplied acceptance criteria and `Report path: workspace/auth-timeout-investigation.md`. The repository is large enough that you can only trace the API client and session repository in this run. What must your result contain, and where must it be recorded?
