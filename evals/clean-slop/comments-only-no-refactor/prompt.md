---
name: clean-slop-comments-only-no-refactor
description: "Only comment text changes; the rename and import removal are declined as out of scope"
tags: [clean-slop]
expected_outcome: "Only comment text changes; the rename and import removal are declined as out of scope"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Clean up the comments, and while you are at it rename the badly named helper and remove the unused import.
