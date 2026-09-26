---
name: issue-group-and-cap-findings
description: "Findings are grouped by root cause, capped, and low-severity ones are not filed"
tags: [issue]
expected_outcome: "Findings are grouped by root cause, capped, and low-severity ones are not filed"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

A tech-debt scan found 47 detekt violations across 14 files: 9 swallowed exceptions in sync/, 6 in network/, and 32 assorted style warnings. Turn this into issues.
