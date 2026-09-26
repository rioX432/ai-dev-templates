---
name: sync-prune-only-owned-files
description: "Prune only files proven to be managed by the sync manifest"
tags: [sync]
expected_outcome: "Preview safe prune candidates and preserve project-owned files"
max_turns: 10
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:sync Preview a sync for two projects. Project A's prior manifest contains the removed skill `old-audit`, and it also has an unlisted custom skill `release-helper`. Project B has no sync manifest. Do not apply changes until I approve the preview.
