---
type: llm
weight: 3
---

Expected outcome: Evidence is reused only on an exact key match, and every decision is auditable

PASS only if every item below is true of the response:

- Check 1 reuses E1 without running the command again, because HEAD, command, surface content, config, and toolchain all match
- Check 2 runs the lint again because HEAD changed to a commit that is not the tree E2 ran on; it does not reuse E2 on the grounds that packages/list itself looked unchanged
- Check 3 runs `pnpm --filter list test`, because focused evidence over two files does not cover the wider packages/list surface or a different command
- Check 4 does not count the earlier-head CI result, and does not substitute any local evidence for CI status; it waits for or re-reads the required check on `d4e5f6`
- The record entries for checks 1 and 2 carry the evidence key fields (HEAD, command, surface or its fingerprint, config, toolchain) and a reuse decision with its reason (reused vs ran, naming the invalidating field for check 2)

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
