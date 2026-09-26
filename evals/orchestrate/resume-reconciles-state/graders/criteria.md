---
type: llm
weight: 3
---

Expected outcome: State is reconciled against the code and Git, unsupported entries are corrected rather than trusted, and the run either continues from the first unblocked action or names the exact blocker and next step

PASS only if every item below is true of the response:

- BRIEF.md, STATE.json, the latest RUNLOG.md entry and open decisions are read before acting
- It treats the recorded repository snapshot as unverified and says the branch, HEAD and changed paths must be recompared with Git (running it, or naming it as the required step when no shell tool is available)
- A lane marked `running` with no live worker is corrected rather than trusted
- SC1 is challenged rather than accepted: it is marked `met` with an empty `evidence` array
- Completed work is not redone to rebuild context, and re-running the last passing check is named as the step that comes before new work
- It either continues from the first unblocked action, or, when no action is unblocked in this environment, names the specific blocker and the one concrete next step - it does not silently stop or claim progress it cannot verify

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
