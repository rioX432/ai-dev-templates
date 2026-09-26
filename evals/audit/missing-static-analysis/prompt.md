---
name: audit-missing-static-analysis
description: "Static analysis is skipped and noted; the parallel scanners still run"
tags: [audit]
expected_outcome: "Static analysis is skipped and noted; the parallel scanners still run"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:audit During /audit, detekt is not installed and `./gradlew detekt` fails with 'task not found'. Continue.
