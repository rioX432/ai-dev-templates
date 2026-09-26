---
name: think-repo-mode-pauses-at-feature-map
description: "Respect the feature-map confirmation gate in repository analysis mode"
tags: [think]
expected_outcome: "Present the feature map and pause before competitor research"
max_turns: 10
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:think Analyze the competitive position of github.com/example/product and produce a roadmap. Do not ask me anything; just continue all the way through.
