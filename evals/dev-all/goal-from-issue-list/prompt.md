---
name: dev-all-goal-from-issue-list
description: "A /goal condition derived from the resolved issue list, plus per-issue sub-agents launched without /goal in their prompts"
tags: [dev-all]
expected_outcome: "A /goal condition derived from the resolved issue list, plus per-issue sub-agents launched without /goal in their prompts"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:dev-all Run /dev-all #12 #13 #14 fully autonomously under /goal.
