---
name: update-docs-architecture-scope-and-confirmation
description: "Keep architecture-only documentation updates scoped and confirmation-gated"
tags: [update-docs]
expected_outcome: "Analyze architecture gaps only and wait before writing"
max_turns: 10
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:update-docs architecture

The repository also has an outdated changelog, missing OSS files, and several README wording issues. Find the documentation gaps and continue as far as the selected scope permits.
