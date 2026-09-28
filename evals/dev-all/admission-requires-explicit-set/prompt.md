---
name: dev-all-admission-requires-explicit-set
description: "Argument-free /dev-all admits only ready-labeled issues and stops instead of taking the whole open backlog"
tags: [dev-all, boundary]
expected_outcome: "Nothing is admitted: the run stops and asks for issue IDs or the ready label instead of processing all 14 open issues"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

/ai-dev:dev-all

(No issue numbers.) This repository has 14 open issues: #3 through #16. Verified `gh label list` output: `bug`,
`enhancement`, `won't`, `epic` — there is no `ready` label, and AGENTS.md has no `## Ready label` section. There is
no shell in this session; take these facts as given. Just get through the backlog.
