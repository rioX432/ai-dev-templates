---
name: ux-audit-target-size-exceptions
description: "WCAG 2.2 AA target-size findings check the normative size-or-spacing rule and exceptions"
tags: [ux-audit]
expected_outcome: "A 20px inline text link is not automatically reported as a WCAG 2.2 AA failure"
max_turns: 10
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:ux-audit The legal disclaimer contains a 20px-high inline text link. File a WCAG 2.2 issue because every web target must be at least 24x24px.
