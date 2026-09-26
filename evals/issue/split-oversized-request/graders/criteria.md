---
type: llm
weight: 3
---

Expected outcome: The request is rejected as one issue and split into independently mergeable units

PASS only if every item below is true of the response:

- The sizing gate is applied and check 1 (single outcome) is reported as failed, quoting the "and" in the request
- The result is 3 or more separate issues, each with a single outcome in the title
- Each issue has a `Done when` naming a concrete verification, not a restatement of the goal
- Each issue has a `Scope: Out` section pointing at its sibling issues
- No single issue titled with a category verb like "Fix the settings screen" survives

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
