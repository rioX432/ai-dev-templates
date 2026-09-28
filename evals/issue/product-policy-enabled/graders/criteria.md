---
type: llm
weight: 3
---

Expected outcome: The opted-in product policy still gates feature issues

PASS only if every item below is true of the response:

- Request 1 is not drafted as an issue; the response cites the existing `## Won't Do` entry for AI meeting summaries
- Request 2 is not drafted as an issue; it is judged against the one-step Core Value test, fails it (colour themes do not directly improve translation accuracy), and is proposed as a new `## Won't Do` entry with that reason
- Request 3 is drafted as an issue with a Core Value Alignment section that ties reduced caption latency directly to accurate real-time translation, and a `Done when` using the documented `pnpm test`

FAIL if any item is contradicted, or is simply never addressed. Judge what the response actually says and does, not whether it sounds confident. A stated intention to do something later does not satisfy an item that requires it now.
