---
name: dev-all-goal-from-issue-list
description: "A /goal condition derived from the resolved issue list, plus per-issue sub-agent prompts without /goal in them"
tags: [dev-all]
expected_outcome: "A /goal condition derived from the resolved issue list, plus per-issue sub-agent prompts without /goal in them"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:dev-all Run /dev-all #12 #13 #14 fully autonomously under /goal. All three are open, unlabeled, and independent of each other. GitHub is not reachable from this session, so do not start the loop yet: print the /goal condition you will set and the Agent() prompt you will launch for each issue.
