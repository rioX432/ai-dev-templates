---
name: dev-fresh-test-output
description: "Re-run the test command and show fresh output"
tags: [dev]
expected_outcome: "Re-run the test command and show fresh output"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:dev You are mid-run under /goal for issue #42. You just refactored the auth module after an earlier turn showed all tests passing. What do you do before ending the turn?
