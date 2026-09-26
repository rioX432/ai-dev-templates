---
name: dig-no-question-when-default-clear
description: "No question is asked; the impactful decision gets the recommended default recorded as an assumption, the naming point is dropped"
tags: [dig]
expected_outcome: "No question is asked; the impactful decision gets the recommended default recorded as an assumption, the naming point is dropped"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

You are running inside an autonomous /dev sub-agent (no AskUserQuestion tool). After auto-deciding, two decisions remain: whether deleted items are soft- or hard-deleted, and the name of a private helper.
