---
name: audit-scope-single-scanner
description: "Only the dependency scanner runs; skipped scanners are named in the report"
tags: [audit]
expected_outcome: "Only the dependency scanner runs; skipped scanners are named in the report"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:audit deps on a Gradle project where CLAUDE.md lists no lint command.
