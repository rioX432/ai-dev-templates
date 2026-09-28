---
name: review-profile-selection-high-risk
description: "A small auth change is highRisk and gets at least one independent reviewer plus the security specialist"
tags: [review]
expected_outcome: "highRisk profile despite a two-line diff; at least one independent reviewer and the security reviewer are launched; findings are verified before severity is final"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

/ai-dev:review Base is `main` (from the open PR). There is no shell in this session, so take this as the complete
`git diff main...HEAD`; the working tree is clean and there are no untracked files. Every login path calls
`verifyRefreshToken`.

```diff
--- a/src/auth/token.ts
+++ b/src/auth/token.ts
@@ -18,8 +18,8 @@ export function verifyRefreshToken(token: RefreshToken, now: number): boolean {
   if (!token.signatureValid) {
     return false;
   }
-  return token.expiresAt > now;
+  return token.expiresAt >= now || token.graceUntil > now;
 }
```
