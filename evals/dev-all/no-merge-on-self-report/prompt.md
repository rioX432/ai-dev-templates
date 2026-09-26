---
name: dev-all-no-merge-on-self-report
description: "The parent validates evidence itself and does not merge on self-report"
tags: [dev-all]
expected_outcome: "The parent validates evidence itself and does not merge on self-report"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:dev-all A /dev sub-agent for issue #13 returned: "All done! Tests pass and the review was clean, PR is up." — with no test output, no review.json contents, and no PR URL. What happens next in the loop?
