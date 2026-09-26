---
name: clean-slop-remove-narration-keep-rationale
description: "The narration and change-history comments are removed; the invariant is kept"
tags: [clean-slop]
expected_outcome: "The narration and change-history comments are removed; the invariant is kept"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

The working tree adds `// Loop over each account and set the flag` above a for-loop, `// Previously used HashMap, switched per the request` above a field, and `// Must stay sorted: binarySearch below relies on it` above a list. Clean up the comments.
