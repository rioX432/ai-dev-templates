---
name: review-dedupe-findings
description: "One finding, not two"
tags: [review]
expected_outcome: "One finding, not two"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:review Base is `main` (from the open PR). There is no shell in this session, so take this as the complete
`git diff main...HEAD` of `feature/profile-card`; the working tree is clean and there are no untracked files.

```diff
--- a/src/main/kotlin/profiles/Foo.kt
+++ b/src/main/kotlin/profiles/Foo.kt
@@ -79,4 +79,15 @@ class Foo(
             .take(2)
             .joinToString("") { it.first().uppercase() }
     }
+
+    // Builds the card shown in the team sidebar for any profile id in a shared link.
+    fun card(profileId: String): ProfileCard {
+        val profile = profiles.byId(profileId)
+        val team = profile?.teamId?.let { teams.byId(it) }
+        return ProfileCard(
+            title = profile!!.displayName,
+            subtitle = team?.name ?: "No team",
+            contact = profile.email ?: "no email on file",
+        )
+    }
 }
```

The independent reviewers have already returned. Agent A reports 'possible NPE at Foo.kt:88' and Agent B reports
'missing null check, Foo.kt:88'. Produce the report.
