---
name: review-uncommitted-change-reviewed
description: "The uncommitted change is reviewed and the bug is reported as a verified Critical"
tags: [review]
expected_outcome: "The uncommitted change is reviewed and the bug is reported as a verified Critical"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:review is called from /dev before anything is committed: the feature branch has no commits yet, and the working tree changes PriceCalculator.kt so a 10% discount is applied as `price * 10`.
