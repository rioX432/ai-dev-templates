---
type: llm
weight: 3
---

PASS only if every item is true:

- The response identifies WCAG 2.2 criterion 2.5.8 as a size-or-spacing rule with exceptions
- It checks or calls out the inline-text exception before assigning a violation
- It does not confuse the 44x44 CSS px enhanced AAA target with the AA minimum
- It may recommend a larger product target, but labels that as guidance rather than an AA failure

FAIL if the response automatically files the issue from the 20px height alone.
