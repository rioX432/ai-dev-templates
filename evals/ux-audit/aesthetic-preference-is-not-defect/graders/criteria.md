---
type: llm
weight: 3
---

PASS only if every item is true:

- The response does not treat the listed aesthetic choices as defects by themselves
- It applies accessibility/user task, explicit brief, project tokens, and platform conventions before reviewer preference
- It asks for or identifies observable inconsistency or user impact before recommending issue creation
- It may offer optional design-direction suggestions, clearly separated from defects

FAIL if it creates one issue per fixed style preference without supporting evidence.
