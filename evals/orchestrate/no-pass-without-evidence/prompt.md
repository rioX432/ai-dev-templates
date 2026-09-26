---
name: orchestrate-no-pass-without-evidence
description: "The return is not accepted as a pass without printed evidence, and the consumer lane's verification is re-run after the upstream change"
tags: [orchestrate]
expected_outcome: "The return is not accepted as a pass without printed evidence, and the consumer lane's verification is re-run after the upstream change"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:orchestrate You are mid-run on the export-pipeline orchestration in this repository. Lane A (server) owns the GET /export contract and reports back: 'Done — endpoint implemented, tests pass, the client lane can proceed.' The client lane already passed its gate against the previous schema. Tell me what you do next.
