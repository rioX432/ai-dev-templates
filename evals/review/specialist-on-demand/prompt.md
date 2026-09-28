---
name: review-specialist-on-demand
description: "Only the specialist whose surface the change touches is launched"
tags: [review, efficiency]
expected_outcome: "ui-reviewer is launched for the UI change; perf-reviewer and security-reviewer are not"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

/ai-dev:review Base is `main`. There is no shell in this session, so take this as the complete working-tree diff
against `main`; nothing is committed yet and there are no untracked files.

```diff
--- a/src/components/SaveButton.tsx
+++ b/src/components/SaveButton.tsx
@@ -1,7 +1,7 @@
 export function SaveButton({ onSave }: { onSave: () => void }) {
   return (
-    <button className="btn" onClick={onSave}>
+    <button className="btn btn-icon" onClick={onSave} style={{ width: 20, height: 20 }}>
       <SaveIcon />
     </button>
   );
 }
```
