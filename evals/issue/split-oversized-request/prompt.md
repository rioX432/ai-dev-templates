---
name: issue-split-oversized-request
description: "The request is rejected as one issue and split into independently mergeable units"
tags: [issue]
expected_outcome: "The request is rejected as one issue and split into independently mergeable units"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

File a GitHub Issue for this: "The settings screen is a mess. Fix the layout, add dark mode, and make the toggles accessible."
