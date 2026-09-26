---
name: ux-audit-screenshot-evidence-limits
description: "Screenshot-only evidence is reported as visual risk, not WCAG compliance or verified assistive-technology behavior"
tags: [ux-audit]
expected_outcome: "The audit ties findings to the screenshot while naming the interaction and accessibility checks that remain unverified"
max_turns: 10
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:ux-audit I only have one screenshot of the checkout form. Audit it and tell me whether it is WCAG 2.2 AA compliant.
