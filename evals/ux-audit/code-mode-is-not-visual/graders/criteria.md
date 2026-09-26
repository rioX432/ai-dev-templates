---
type: llm
weight: 3
---

PASS only if every item is true:

- The response proceeds with a bounded code audit rather than claiming a captured visual audit
- Code findings cite file and line evidence and are labeled likely or code-only
- Appearance, focus order, actual contrast, responsive behavior, and assistive-technology behavior are not reported as passed
- The final report names the missing runtime verification needed to confirm those behaviors

FAIL if static code is treated as proof of visual or WCAG compliance.
