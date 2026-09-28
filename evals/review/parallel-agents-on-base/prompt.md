---
name: review-parallel-agents-on-base
description: "Base branch resolved, commands run individually, reviewers chosen by risk profile"
tags: [review]
expected_outcome: "Base branch resolved, commands run individually, reviewers chosen by risk profile"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

/ai-dev:review Review this branch before I open a PR. It has 40 changed files. There is no shell in this session:
I run the commands you give me in my terminal and paste their output back, but only once, so give me every command
you need to prepare the diff in one list. Start by preparing the diff.
