---
name: sync
description: "Sync common skills, agents, hooks, and rules to target projects"
user-invocable: true
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash(cp:*)
  - Bash(mkdir:*)
  - Bash(diff:*)
  - Bash(ls:*)
  - Bash(git diff:*)
  - Bash(git status)
  - AskUserQuestion
---

# /sync — Sync to Projects

Sync common skills, agents, hooks, and rules from ai-dev-templates to target projects.

**Config:** !`cat ${CLAUDE_SKILL_DIR}/sync-config.json`

## Process

### Step 1: Read Config

Read `sync-config.json` to get:
- Target project paths
- Which skills, agents, rules, and hooks to sync

### Step 2: Diff Check

For each target project:
1. Compare each common file with the project's version
2. Show a summary of what would change:

```
## Sync Preview: {project}

| File | Status |
|------|--------|
| .claude/skills/dev/SKILL.md | Updated (3 lines changed) |
| .claude/skills/dig/SKILL.md | New file |
| .claude/agents/security-reviewer.md | No change |
| .claude/rules/behavior.md | Updated (1 line changed) |
```

### Step 3: Confirm

Ask user to confirm before copying:
- Which projects to sync
- Whether to sync all files or select specific ones

### Step 4: Copy

For each confirmed project:

```bash
# Skills
mkdir -p {project}/.claude/skills/{skill}/
cp skills/{skill}/SKILL.md {project}/.claude/skills/{skill}/SKILL.md

# Agents
mkdir -p {project}/.claude/agents/
cp agents/{agent}.md {project}/.claude/agents/{agent}.md

# Rules
mkdir -p {project}/.claude/rules/
cp rules/{rule}.md {project}/.claude/rules/{rule}.md

# Hooks (merge, don't overwrite — project may have custom hooks)
# Show diff and ask user how to merge
```

### Step 5: Report

```
## Sync Complete

| Project | Files Updated | Files Added | Skipped |
|---------|--------------|-------------|---------|
| CivitDeck | 5 | 2 | 0 |
| live-translate | 4 | 3 | 0 |

Next: review changes in each project and commit.
```

## Important Notes

- **Never overwrite project-specific files**: CLAUDE.md, settings.json, project-specific agents/rules
- **Hooks require manual merge**: Projects may have custom hooks that should not be lost
- **Supporting files**: Only SKILL.md is synced, not supporting files in skill directories
