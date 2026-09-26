---
type: llm
weight: 2
---

The response plans lanes for a goal spanning a server endpoint, a shared KMP client, and an Android UI.

PASS only if all of the following hold:

- Exactly one party owns the API contract - either the server lane, or the lead settling it up front - and the
  client and UI lanes are named as consumers of that published version
- The consumer lanes either wait for the contract lane, or run in parallel against a contract the response has
  already fixed and written into their briefs; they are never left to guess at an unsettled contract
- Each lane owns exactly one repository (export-server / export-shared / export-app), with no file owned by two lanes, and the three repositories are treated as independent rather than as one checkout
- The fan-out stays at roughly three lanes rather than one per file

FAIL if any item is contradicted or never addressed.
