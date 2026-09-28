---
type: llm
weight: 3
---

Expected outcome: A small auth change is reviewed as highRisk by independent reviewers

PASS only if every item below is true of the response:

- The change is classified `highRisk` because it changes authentication token validation, not because of its size
- At least one independent reviewer and the security specialist review it rather than the coordinator alone
- The report states the review profile and the number of independent reviewers used
- The expiry/grace change is evaluated as a possible security weakness (for example, accepting expired tokens when `graceUntil` is unset or unbounded), and its severity is stated only after checking it against the code shown

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
