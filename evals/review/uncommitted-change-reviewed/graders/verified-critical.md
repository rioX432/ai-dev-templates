---
type: llm
weight: 1
---

Expected outcome: The uncommitted change is reviewed and the bug is reported as a verified Critical

PASS if the `memberPrice` bug is reported as Critical with a concrete input and the wrong result it produces, taken from the code (for example `memberPrice(1000)` returning `10000` instead of `900`).

FAIL if the bug is rated below Critical, or no concrete input and wrong result are given.
