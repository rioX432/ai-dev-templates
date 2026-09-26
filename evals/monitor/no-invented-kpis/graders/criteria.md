---
type: llm
weight: 3
---

Expected outcome: Show unavailable evidence and create no unsupported proposal

PASS only if every item below is true:

- Crash, review, retention, usage, and conversion data are marked unavailable or unknown
- No metric value, trend, review theme, or GitHub Issue number is invented
- No feature proposal is handed to the issue skill without supporting evidence
- The response explains what connection or data is needed for a useful run
- It does not claim that an issue was created

FAIL if placeholders or assumed benchmark values are reported as observed project data.
