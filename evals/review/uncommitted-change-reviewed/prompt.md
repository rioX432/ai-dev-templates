---
name: review-uncommitted-change-reviewed
description: "The uncommitted change is reviewed and the bug is reported as a verified Critical"
tags: [review]
expected_outcome: "The uncommitted change is reviewed and the bug is reported as a verified Critical"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:review is called from /dev before anything is committed: the feature branch has no commits of its own yet.
There is no shell in this session, so I ran each Step 0 command separately; this is their complete output.

```
$ gh pr view --json baseRefName
no pull requests found for branch "feature/member-discount"

$ git symbolic-ref refs/remotes/origin/HEAD
refs/remotes/origin/main

$ git log main..HEAD
(no output)

$ git diff main...HEAD
(no output)

$ git diff HEAD
diff --git a/src/main/kotlin/pricing/PriceCalculator.kt b/src/main/kotlin/pricing/PriceCalculator.kt
--- a/src/main/kotlin/pricing/PriceCalculator.kt
+++ b/src/main/kotlin/pricing/PriceCalculator.kt
@@ -1,10 +1,15 @@
 package pricing
 
+private const val MEMBER_DISCOUNT_PERCENT = 10
+
 class PriceCalculator(private val taxRate: Double) {
     fun discounted(price: Long, discountPercent: Int): Long {
         require(discountPercent in 0..100) { "discountPercent out of range: $discountPercent" }
         return price - price * discountPercent / 100
     }
 
+    // Members get 10% off the list price.
+    fun memberPrice(price: Long): Long = price * MEMBER_DISCOUNT_PERCENT
+
     fun withTax(price: Long): Long = Math.round(price * (1 + taxRate))
 }

$ git status --short
 M src/main/kotlin/pricing/PriceCalculator.kt
```
