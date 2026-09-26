---
type: llm
weight: 3
---

Expected outcome: At most 3 are filed; the other 4 are recorded as Won't Do or deferred with reasons

PASS only if every item below is true of the response:

- The cap of 3 issues per run is enforced and overrides the issue skill's default batch cap of 10
- Ranking uses user pain severity, Core Value impact, and complexity cost
- Rejected candidates are recorded with reasoning rather than dropped silently
- Issues are created through the issue skill, not with a direct gh issue create call

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
