---
description: "Process all open GitHub Issues on a single branch. Investigates in parallel, implements sequentially by dependency order, creates one PR."
user-invocable: true
argument-hint: ""
---

Autonomously process all open GitHub Issues on a **single branch** with **one PR**, avoiding merge conflicts.

## Why Single Branch?

Parallel branches cause massive conflicts in shared files:
- iOS pbxproj (Xcode project file) — every new file modifies the same sections
- DB migration versions — sequential numbering conflicts
- Test fakes — every interface change requires updating all fakes
- DI registrations — same Koin module files

Single branch eliminates all of these.

---

## Step 1: Fetch and Analyze Issues

### 1a. Fetch All Open Issues

```
gh issue list --state open --json number,title,labels,body --limit 100
```

If `` is provided, filter to only those issue numbers.

### 1b. Parallel Investigation

Launch **parallel read-only Task subagents** (`subagent_type: "Explore"`, `model: "haiku"`) — one per issue:

Each subagent:
1. `gh issue view {NUMBER} --json title,body,labels,comments`
2. Use Grep/Glob to find related code
3. Identify files that will need changes
4. Return: issue summary, affected files, estimated scope

### 1c. Detect Dependencies

From fetched issue bodies, detect blockers:

**Body text patterns (case-insensitive):**
- `blocked by #NNN`, `depends on #NNN`, `after #NNN`, `waiting for #NNN`

**Labels:** `blocked`, `blocked-by`, `on-hold`

For each blocker `#NNN`:
```
gh issue view NNN --json state
```
- Open → blocked
- Closed → ignore

### 1d. Determine Execution Order

Topological sort by dependencies:
1. Independent issues first (sorted by number, ascending)
2. Dependent issues after their dependencies
3. Circular dependencies → skip, report to user

Present the execution plan to the user:

```
Execution Order:
1. #42: Fix model card layout
2. #43: Add search filters
3. #44: Update settings screen (depends on #42)
...
```

---

## Step 2: Create Branch and Implement

### 2a. Create Branch

```bash
git checkout master && git pull
git checkout -b feature/batch-{first-issue}-{last-issue}
```

Branch name example: `feature/batch-42-48`

### 2b. Sequential Implementation

For each issue in execution order, launch a **Task subagent** (`subagent_type: "general-purpose"`):

```
Implement GitHub Issue #{NUMBER}: "{TITLE}" on the CURRENT branch.
Do NOT create a new branch — you are already on the correct branch.

## Issue Details
{issue body from investigation}

## Files Likely Affected
{from investigation results}

## Previously Implemented Issues in This Batch
{list of already-completed issues and their changes — helps avoid conflicts}

### Phase 1: Deep Investigation
1. Read all affected files thoroughly
2. Understand existing patterns
3. Check if previous issues in this batch already modified any of these files

### Phase 2: Implementation
1. Implement changes following project CLAUDE.md conventions
2. Keep changes minimal and focused
3. If a file was modified by a previous issue in this batch, build on those changes

### Phase 3: Commit
1. Stage specific files (no `git add .`)
2. Commit: `{concise message} (#{NUMBER})`
   - Example: `Add accent color picker (#42)`
   - No Co-Authored-By, no AI stamps

Report: files changed, commit hash, any issues encountered.
```

**Important:** Pass each subagent the summary of previous issues' changes so it can build on them without conflicts.

### 2c. Between Issues

After each subagent completes:
1. Verify the commit was created: `git log --oneline -1`
2. Update the "previously implemented" context for the next subagent
3. If a subagent failed, decide: skip and continue, or stop

---

## Step 3: Quality Gate

After ALL issues are implemented:

### 3a. Tests
Run the project's test command. Fix failures (max 3 attempts).

### 3b. Lint
Run the project's lint command. Fix issues (max 3 attempts).

If lint/test fixes are needed, create a separate commit:
```
Fix lint/test issues from batch implementation
```

---

## Step 4: Create PR

### 4a. Push

```bash
git push -u origin feature/batch-{first-issue}-{last-issue}
```

### 4b. Create PR

```bash
gh pr create --title "Implement #{first}–#{last}: {brief summary}" --body "$(cat <<'EOF'
## Description

Batch implementation of the following issues:

{for each issue:}
- **#{NUMBER}**: {title} — {one-line summary of changes}

## Related Issues

{for each issue:}
Closes #{NUMBER}

## Test Plan

- [ ] Unit tests pass
- [ ] Lint checks pass
- [ ] Manual verification on Android
- [ ] Manual verification on iOS (if applicable)

## Review Checklist

- [x] Each issue implemented as a separate commit
- [x] Code follows project architecture
- [x] No unnecessary dependencies added
EOF
)"
```

### 4c. Auto-Merge (if CI passes)

If build/lint passed locally:
```
gh pr merge {PR_NUMBER} --merge --delete-branch
```

---

## Step 5: Final Report

```
## Batch Development Summary

Branch: feature/batch-{first}-{last}
PR: {URL}

| # | Issue | Commit | Status |
|---|-------|--------|--------|
| 1 | #{42} Title | abc1234 | Done |
| 2 | #{43} Title | def5678 | Done |
| 3 | #{44} Title | — | Skipped (blocked) |

Quality Gate: Tests ✓ | Lint ✓
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Issue not found | Skip, warn in report |
| Circular dependency | Skip affected issues, report |
| Subagent fails implementation | Note error, continue with next issue |
| Subagent fails 3 times | Skip issue, report |
| Tests fail after 3 fix attempts | Report to user, do NOT create PR |
| Lint fails after 3 fix attempts | Report to user, do NOT create PR |
