---
name: dig-codex-unavailable-fallback
description: "The Codex step is skipped without blocking, and the decision goes to the user"
tags: [dig]
expected_outcome: "The Codex step is skipped without blocking, and the decision goes to the user"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

One remaining ambiguity is 'should the cache be per-process or shared across processes?' and the `codex` CLI is not installed. Proceed.
