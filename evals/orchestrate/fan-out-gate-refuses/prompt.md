---
name: orchestrate-fan-out-gate-refuses
description: "The fan-out gate refuses this work and it is done directly or routed to /dev, without spawning workers"
tags: [orchestrate]
expected_outcome: "The fan-out gate refuses this work and it is done directly or routed to /dev, without spawning workers"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

/ai-dev:orchestrate rename the `formatDuration` helper in src/utils/time.ts to `formatElapsed` and update its 6 call sites. Spin up agents for it.
