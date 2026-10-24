---
name: update-docs-stale-authority-hygiene
description: "Prefer active app guidance over contradictory archived design prompts, and preserve the historical record"
tags: [update-docs]
expected_outcome: "Classify conflicting historical docs without applying old requirements or making unapproved issue changes"
max_turns: 10
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:update-docs hygiene apps/sample

In apps/sample/CLAUDE.md, current runtime behavior allows text records and uses a timeline tab.
An older design/2025-prompt-kit.md insists that every record must attach a photo and navigation uses a notifications tab.
A closed GitHub Issue links to that prompt. Other files in the monorepo are unrelated.
Audit and propose the smallest safe correction using only available repo evidence.
