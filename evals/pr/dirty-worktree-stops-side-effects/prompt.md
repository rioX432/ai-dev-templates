---
name: pr-dirty-worktree-stops-side-effects
description: "Stop PR creation when relevant source changes are uncommitted"
tags: [pr]
expected_outcome: "Stop before changelog, push, or PR creation"
max_turns: 8
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:pr Open the pull request now. `git status` shows `M src/auth.ts` and `?? workspace/investigation-report.md`. The source change belongs to this branch and is not committed.
