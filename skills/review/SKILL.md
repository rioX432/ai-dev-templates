---
description: "Multi-agent code review against the base branch. Use when reviewing changes before PR creation or during fix-issue Phase 5."
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
  - "Bash(git *)"
  - "Bash(gh *)"
---

Review the current branch's changes against the base branch using parallel review agents.

## Step 0: Checkout & Prepare

1. Identify the base branch (`main` or `master`) and current branch
2. Run `git log` to get the list of commits on this branch
3. Run `git diff` against the base branch to get the full changeset
4. Read the PR description if available: `gh pr view --json body`
5. **Important**: Run each command individually — do NOT chain with `&&`

## Step 1: Build Change Context

1. From the commit messages and PR description, understand the **intent** of the change
2. List all changed files and categorize them:
   - **Core logic** (business logic, data layer)
   - **UI** (Compose, SwiftUI, layouts)
   - **Infrastructure** (build, CI, config)
   - **Tests**
3. Identify **risk areas**: files with complex changes, new integrations, security-sensitive code

## Step 2: Multi-Agent Parallel Review

Launch **two review agents in parallel** using the Agent tool (model: sonnet):

### Agent A: Bug & Logic + Security
```
Review the following changed files for bugs, logic errors, and security issues.
Read REVIEW.md at the project root for review criteria.

Focus areas:
- Null safety violations
- Structured concurrency issues
- Error handling gaps
- Security (OWASP MASVS): hardcoded secrets, input sanitization, data exposure
- API level / platform compatibility
- Data & performance: memory leaks, main thread blocking, redundant network calls

For each finding, report: [file:line] severity — description
Severity levels: Critical / Warning / Suggestion / Nit
```

### Agent B: Architecture & UI
```
Review the following changed files for architecture and UI quality.
Read REVIEW.md at the project root for review criteria.

Focus areas:
- Architecture: SRP, layer boundaries, DI patterns
- Compose: recomposition, remember/key, state management, effect handlers
- SwiftUI: @StateObject scoping, weak self, task cancellation
- KMP: expect/actual consistency, no platform imports in commonMain
- Testing: changed code has corresponding test updates

For each finding, report: [file:line] severity — description
Severity levels: Critical / Warning / Suggestion / Nit
```

## Step 3: Merge Agent Findings

1. Collect findings from both agents
2. **Deduplicate**: remove findings reported by both agents
3. Assign final severity based on REVIEW.md definitions:
   - **Critical**: crash, data loss, security vulnerability, incorrect behavior
   - **Warning**: potential bug, performance issue, architectural violation
   - **Suggestion**: improvement opportunity, non-blocking
   - **Nit**: style/preference, optional

## Step 4: Cross-Review Verification

Use Gemini MCP (`mcp__gemini-deepsearch__deep_search`) for cross-review on non-trivial changes:
- Share the merged findings and ask Gemini to verify or challenge them
- Apply consensus rules:
  - **3 reviewers agree** (Agent A + Agent B + Gemini): high confidence
  - **2 agree**: include with note
  - **1 only**: include as "unverified" unless Critical severity

## Step 5: Present Final Report

```
## Review Summary

**Branch:** {current} → {base}
**Files changed:** N
**Risk level:** Low / Medium / High
**Reviewed by:** Agent A (Bug/Security) + Agent B (Arch/UI) + Gemini

### Critical (must fix)
- [file:line] description — verified by: {agents}

### Warning (should fix)
- [file:line] description — verified by: {agents}

### Suggestion (nice to have)
- [file:line] description — verified by: {agents}

### Nit (optional)
- [file:line] description

### Cross-Review Notes
- {Gemini's additional findings or disagreements}
```
