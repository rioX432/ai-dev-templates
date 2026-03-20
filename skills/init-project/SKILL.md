---
name: init-project
description: "Initialize a new project with AI-driven development templates and Plugin configuration"
user-invocable: true
disable-model-invocation: true
argument-hint: "{project-path}"
allowed-tools:
  - Read
  - Write
  - Bash(mkdir:*)
  - Bash(cp:*)
  - Bash(ls:*)
  - AskUserQuestion
---

# /init-project — Project Initialization

Initialize a project at `$ARGUMENTS` with AI-driven development templates.

## Steps

### 1. Validate Target

- Verify `$ARGUMENTS` is a valid directory path
- Check if it's a git repository (warn if not)
- Check for existing `.claude/` directory (warn if overwriting)

### 2. Copy Core Files

Copy the following from `${CLAUDE_SKILL_DIR}/templates/`:

| Source | Destination | Action |
|---|---|---|
| `CLAUDE.md.template` | `$ARGUMENTS/CLAUDE.md` | Copy, prompt to fill in |
| `REVIEW.md.template` | `$ARGUMENTS/REVIEW.md` | Copy as-is |
| `settings.json.template` | `$ARGUMENTS/.claude/settings.json` | Copy as-is |
| `pull_request_template.md` | `$ARGUMENTS/.github/pull_request_template.md` | Copy as-is |

### 3. Copy Common Skills

Copy shared skills from ai-dev-templates:

```
$ARGUMENTS/.claude/skills/
  dev/SKILL.md
  dev-all/SKILL.md
  review/SKILL.md
  pr/SKILL.md
  dig/SKILL.md
  decompose/SKILL.md
  tech-debt/SKILL.md
  audit/SKILL.md
```

### 4. Copy Common Agents

```
$ARGUMENTS/.claude/agents/
  security-reviewer.md
  test-writer.md
```

### 5. Copy Common Rules

```
$ARGUMENTS/.claude/rules/
  behavior.md
  ai-ops.md
```

### 6. Copy Workflow Templates (Optional)

Ask user which workflows to include:

| Template | Description |
|---|---|
| `ci.yml.template` | CI pipeline |
| `ai-ops-daily.yml.template` | Daily AI analysis |
| `claude-code.yml.template` | Issue → PR automation |
| `claude-review.yml.template` | Automated PR review |

### 7. Post-Setup Instructions

```
## Setup Complete

Files created:
- CLAUDE.md ← Fill in project name, architecture, tech stack, commands
- REVIEW.md ← Customize review criteria
- .claude/settings.json ← Add project-specific permissions
- .claude/skills/ ← Shared skills (synced from ai-dev-templates)
- .claude/agents/ ← Shared + add project-specific agents
- .claude/rules/ ← Shared + add project-specific rules
- .github/pull_request_template.md

## Next Steps
1. Edit CLAUDE.md — fill in project details, especially Commands section
2. Add project-specific agents to .claude/agents/ (e.g., kmp-reviewer.md)
3. Add project-specific rules to .claude/rules/ (e.g., kmp.md)
4. Rename workflow .template files to .yml and configure secrets
5. Commit: git add -A && git commit -m "Add AI-driven development templates"

## Keeping Up to Date
Common skills/agents/rules are synced from ai-dev-templates.
When ai-dev-templates is updated:
- GitHub Actions automatically creates PRs to this project
- Or run /sync manually from the ai-dev-templates directory
```
