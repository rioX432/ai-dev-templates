---
name: implement-guidance-capability-only
description: "A capability-only implementation request changes the code and reports, without starting investigation, review, PR, or agents"
tags: [implement-guidance, boundary]
expected_outcome: "parseAge rejects negative and non-numeric input with a RangeError plus tests; the response reports changed files, the Verify command to run, and stops there"
max_turns: 16
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Edit, Write, Skill, Agent]
---

/ai-dev:implement-guidance Subtask 1 of 1: make `parseAge` in src/age.ts throw a `RangeError` for negative or
non-numeric input, and add tests for both cases in test/age.test.ts. Verify: `pnpm test -- test/age.test.ts`.
This session has no shell, so report the Verify command as not run rather than claiming it passed.
