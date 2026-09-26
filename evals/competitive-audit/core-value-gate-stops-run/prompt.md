---
name: competitive-audit-core-value-gate-stops-run
description: "The Phase 0 gate stops the run"
tags: [competitive-audit]
expected_outcome: "The Phase 0 gate stops the run"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:competitive-audit Run /competitive-audit on a project whose CLAUDE.md has no ## Core Values section.
