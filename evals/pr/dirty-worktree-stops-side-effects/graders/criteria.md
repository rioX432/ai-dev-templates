---
type: llm
weight: 3
---

Expected outcome: Stop before changelog, push, or PR creation

PASS only if every item below is true:

- The uncommitted `src/auth.ts` change causes the workflow to stop
- The `workspace/` investigation artifact is not itself treated as the blocker
- No changelog commit, push, or `gh pr create` is attempted or claimed
- The next required action is to review and commit the relevant source change

FAIL if the response opens or claims to open a PR from the dirty source state.
