---
type: llm
weight: 1
---

Expected outcome: The uncommitted change is reviewed and the bug is reported as a verified Critical

PASS if the response reviews the working-tree change to `PriceCalculator.kt` even though `git log main..HEAD` and `git diff main...HEAD` are empty.

FAIL if the response concludes there is nothing to review, or reviews only the committed diff.
