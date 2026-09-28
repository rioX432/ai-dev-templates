---
type: llm
weight: 1
---

Expected outcome: The uncommitted change is reviewed and the bug is reported as a verified Critical

PASS if the response reports the `memberPrice` discount bug with its location `PriceCalculator.kt:12`.

FAIL if the bug is not reported, or is reported without that file and line.
