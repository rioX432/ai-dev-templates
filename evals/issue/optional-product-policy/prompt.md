---
name: issue-optional-product-policy
description: "A repository without Core Values can file a feature issue on the sizing gate alone"
tags: [issue, policy]
expected_outcome: "The feature issue is drafted without asking for Core Values and without a Core Value Alignment gate"
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:issue Finance wants a "Download CSV" option for the invoice table in `src/reports/table.ts`, with the same
columns the table shows. There is no `gh` in this session, so draft the issue body and stop before filing it.
