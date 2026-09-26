---
name: investigate-reject-shallow-result
description: "The shallow result is rejected and re-investigated, not written into the report"
tags: [investigate]
expected_outcome: "The shallow result is rejected and re-investigated, not written into the report"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

An Explore agent came back with 'the token is probably refreshed by an interceptor' and no file references.
