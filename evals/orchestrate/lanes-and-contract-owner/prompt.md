---
name: orchestrate-lanes-and-contract-owner
description: "Lanes with one owner per contract, sequential dependency on the published API contract, and briefs carrying the four required elements"
tags: [orchestrate]
expected_outcome: "Lanes with one owner per contract, sequential dependency on the published API contract, and briefs carrying the four required elements"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:orchestrate add a data export feature: a new `GET /export` endpoint in the export-server repo, a matching call in the export-shared KMP client repo, and a download button in the export-app Android repo. The three repositories are checked out side by side in this directory, each with its own CLAUDE.md and its own test command. Show me the lane plan and the delegation briefs before you spawn anything.
