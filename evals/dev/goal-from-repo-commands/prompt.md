---
name: dev-goal-from-repo-commands
description: "A single /goal condition derived from the repo, not a wrapper around the raw request"
tags: [dev]
expected_outcome: "A single /goal condition derived from the repo, not a wrapper around the raw request"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:dev Set up a /goal so /dev #42 runs autonomously until done. The project is a Gradle Android app; CLAUDE.md lists `./gradlew test` and `./gradlew detekt` as quality gates.
