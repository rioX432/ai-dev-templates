---
type: llm
weight: 3
---

Expected outcome: Analyze architecture gaps only and wait before writing

PASS only if every item below is true:

- Only project-structure and existing-documentation evidence needed for architecture is gathered
- Changelog, README wording, and OSS documentation are explicitly left out of scope
- A concrete architecture gap analysis is presented before any write
- The workflow waits for confirmation before changing `ARCHITECTURE.md`
- Claims about architecture are tied to actual repository structure or existing documentation

FAIL if unrelated documentation is updated or if writing begins before the confirmation gate.
