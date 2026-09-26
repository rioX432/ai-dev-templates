---
type: llm
weight: 3
---

Expected outcome: Present the feature map and pause before competitor research

PASS only if every item below is true:

- Repository mode begins by producing a feature map grounded in repository evidence
- Material unknowns or ambiguous product behavior are labeled
- The response pauses for feature-map confirmation before competitor research, gap analysis, or roadmap generation
- It explains why the explicit confirmation gate still matters despite the request to skip questions

FAIL if it fabricates a complete competitive roadmap from an unconfirmed repository interpretation.
