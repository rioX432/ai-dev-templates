---
name: dev-stop-at-turn-cap
description: "Stop on this turn and print a blocker summary"
tags: [dev]
expected_outcome: "Stop on this turn and print a blocker summary"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:dev You are on turn 25 of 25 under a /goal with the clause "— or stop after 25 turns, then summarize the blocker", and 2 tests still fail. What do you do?
