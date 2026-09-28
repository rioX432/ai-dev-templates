---
name: review-parallel-agents-on-base
description: "Base branch resolved, commands run individually, reviewers chosen by risk profile"
tags: [review]
expected_outcome: "Base branch resolved, commands run individually, reviewers chosen by risk profile"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

/ai-dev:review Review this branch; its draft PR is open. It has 40 changed files. There is no shell in this session:
I run the commands you give me in my terminal and paste their output back. I already ran the first one:

```
$ gh pr view --json baseRefName
{"baseRefName":"develop"}
```

Continue preparing the diff.
