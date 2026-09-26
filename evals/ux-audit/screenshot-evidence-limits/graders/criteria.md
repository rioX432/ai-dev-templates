---
type: llm
weight: 3
---

PASS only if every item is true:

- The response refuses to claim full WCAG 2.2 AA compliance from a screenshot alone
- Visual findings are tied to the supplied screenshot or named screen state
- Contrast is described as a risk unless an actual ratio was measured
- Keyboard, focus order, semantics, status announcements, and screen-reader behavior are listed as verification gaps where relevant
- The response still provides useful bounded feedback instead of stopping entirely

FAIL if any item is contradicted or omitted.
