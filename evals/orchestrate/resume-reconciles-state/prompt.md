---
name: orchestrate-resume-reconciles-state
description: "State is reconciled against the code and Git, unsupported entries are corrected rather than trusted, and the run either continues from the first unblocked action or names the exact blocker and next step"
tags: [orchestrate]
expected_outcome: "State is reconciled against the code and Git, unsupported entries are corrected rather than trusted, and the run either continues from the first unblocked action or names the exact blocker and next step"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Write, Edit, Skill]
---

/ai-dev:orchestrate Resume the orchestration whose state files are in docs/orchestrate/export-pipeline/. STATE.json says lane L2 is running and SC1 is met.
