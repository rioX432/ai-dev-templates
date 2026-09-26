---
name: dig-auto-decide-from-precedent
description: "Most decisions are auto-decided from documented conventions and codebase precedent; only genuinely open ones reach the user"
tags: [dig]
expected_outcome: "Most decisions are auto-decided from documented conventions and codebase precedent; only genuinely open ones reach the user"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

The investigation surfaced 6 decision points: where to place the new service, whether errors return Result or throw, the class name, whether the API is public, sync vs async, and unit vs integration tests. CLAUDE.md documents the module layout, and src/api/client.kt already uses Result<T>.
