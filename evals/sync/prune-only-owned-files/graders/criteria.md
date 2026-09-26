---
type: llm
weight: 3
---

Expected outcome: Preview safe prune candidates and preserve project-owned files

PASS only if every item below is true:

- `old-audit` is shown as a prune candidate for Project A because the manifest owns it
- `release-helper` is preserved because it is project-owned
- Project B has no prune candidates merely because its manifest is absent
- The plan is shown before any copy or deletion
- Explicit approval is required before applying the prune

FAIL if absence from the current config alone is treated as proof that a target file may be deleted.
