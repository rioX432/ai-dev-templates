---
name: review-parallel-agents-on-base
description: "Base branch resolved, commands run individually, both agents launched in parallel"
tags: [review]
expected_outcome: "Base branch resolved, commands run individually, both agents launched in parallel"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Review this branch before I open a PR. It has 40 changed files. Start by preparing the diff.
