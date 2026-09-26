---
name: competitive-audit-one-step-distance-test
description: "It fails the one-step distance test and goes to Won't Do, not the backlog"
tags: [competitive-audit]
expected_outcome: "It fails the one-step distance test and goes to Won't Do, not the backlog"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:competitive-audit A competitor has an AI meeting-summary feature that our users have never asked for. Our Core Value is "accurate real-time translation". What happens to it?
