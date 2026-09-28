---
name: review-profile-selection-fast
description: "A docs-and-comment change is reviewed by the coordinator alone, with zero independent agents"
tags: [review, efficiency]
expected_outcome: "fast profile; the coordinator reviews the diff itself; no Agent is launched; the report states 0 independent reviewers"
max_turns: 8
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

/ai-dev:review Base is `main` (from the open PR). There is no shell in this session, so take this as the complete
`git diff main...HEAD`; the working tree is clean and there are no untracked files.

```diff
--- a/README.md
+++ b/README.md
@@ -12,7 +12,7 @@
-Run `pnpm dev` to start the developement server.
+Run `pnpm dev` to start the development server.
--- a/src/time.ts
+++ b/src/time.ts
@@ -1,4 +1,4 @@
-// Formats milisecond durations as "Xm Ys".
+// Formats millisecond durations as "Xm Ys".
 export function formatDuration(ms: number): string {
```
