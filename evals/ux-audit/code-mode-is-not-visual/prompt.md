---
name: ux-audit-code-mode-is-not-visual
description: "When no browser or device is available, code review findings are explicitly limited and not presented as a visual audit"
tags: [ux-audit]
expected_outcome: "The skill continues in code mode and labels runtime appearance and interaction as unverified"
max_turns: 10
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:ux-audit Audit the settings screen. There is no running app, browser, emulator, screenshot, or device, but the React component source is available.
