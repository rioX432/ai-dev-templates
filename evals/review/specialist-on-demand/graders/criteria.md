---
type: llm
weight: 3
---

Expected outcome: The UI specialist reviews the UI change and no unrelated specialist is launched

PASS only if every item below is true of the response:

- The project's `ui-reviewer` is used because the change touches a UI component — as its own agent type, or as a general-purpose agent briefed with `.claude/agents/ui-reviewer.md` when that type is not registered
- `perf-reviewer` and `security-reviewer` are not used, and the response gives the surface mismatch as the reason (or simply does not select them)
- The review raises the icon-only button's missing accessible name and/or its 20x20 target size as a finding with the file reference

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
