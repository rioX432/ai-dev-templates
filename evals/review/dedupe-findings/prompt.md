---
name: review-dedupe-findings
description: "One finding, not two"
tags: [review]
expected_outcome: "One finding, not two"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Agent A reports 'possible NPE at Foo.kt:88' and Agent B reports 'missing null check, Foo.kt:88'. Produce the report.
