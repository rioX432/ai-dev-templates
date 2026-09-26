---
name: clean-slop-protected-comments-survive
description: "Nothing in the protected categories is removed"
tags: [clean-slop]
expected_outcome: "Nothing in the protected categories is removed"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Clean up comments on this branch. The diff also touches a file with `// Copyright 2024 Example Inc.`, `// eslint-disable-next-line no-console`, a `// TODO(#123): drop after v2 migration`, and an unchanged 3-year-old comment in the same hunk context.
