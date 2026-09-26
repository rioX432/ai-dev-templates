---
name: ux-audit-aesthetic-preference-is-not-defect
description: "Generic aesthetic preferences are not filed as defects without a brief, token, platform, or user-outcome violation"
tags: [ux-audit]
expected_outcome: "System fonts, a 10px gap, and a Material ripple are not automatically treated as UX defects"
max_turns: 10
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:ux-audit The Android screen uses Roboto, a 10dp gap, Material ripple, and mixed 8dp/12dp corner radii. There is no project design system or brand brief. Create an issue for every violation.
