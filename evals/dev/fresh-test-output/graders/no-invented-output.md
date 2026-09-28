---
type: regex
pattern: "BUILD SUCCESSFUL in \\d|\\d+ tests? completed, 0 failed|\\bPASSED\\b"
match: not_contains
weight: 1
---
