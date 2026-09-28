---
name: issue-product-policy-enabled
description: "A repository that opted into the product policy still gets the one-step test and Won't Do registry"
tags: [issue, policy]
expected_outcome: "The Won't Do match is not filed, the off-value feature becomes a Won't Do proposal, and only the latency fix is drafted with its Core Value Alignment"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:issue Three requests from this week's feedback. There is no `gh` in this session, so draft issue bodies and
stop before filing them.

1. Add AI meeting summaries at the end of each call.
2. Add a theme picker with twelve colour themes for the caption overlay.
3. Captions lag about 800 ms because `src/asr/stream.ts` reloads the speech model for every utterance; keep it loaded.
