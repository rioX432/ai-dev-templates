---
name: dev-investigate-self-contained-report
description: "Preserve forked investigation evidence in the requested report"
tags: [dev-investigate]
expected_outcome: "Write a self-contained report with evidence, decisions, and scope limits"
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Write, Skill]
---

/ai-dev:dev-investigate Report path: workspace/auth-timeout-investigation.md. Issue #57 for /dev: users are logged out after the app sits idle for about 30 minutes, and requests made right after that sometimes time out. Acceptance criteria: (1) the first request after the access token expires refreshes it once and succeeds without logging the user out; (2) a request that times out surfaces a retryable error instead of logging the user out. Keywords: timeout, refresh, 401, logout, expiresAt. Affected areas: network (API client), session (session repository). The repository is large enough that this run can only trace the API client and the session repository.
