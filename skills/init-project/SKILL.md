---
description: "Initialize a new project with AI-driven development templates. Copies CLAUDE.md, settings, PR template, CI workflows, and GitHub Actions to the target project."
user-invocable: true
argument-hint: "{project-path}"
---

Initialize a project at `$ARGUMENTS` with AI-driven development templates.

## Steps

### 1. Validate Target

- Verify `$ARGUMENTS` is a valid directory path
- Check if it's a git repository (warn if not)
- Check for existing `.claude/` directory (warn if overwriting)

### 2. Copy Core Files

Copy the following from `skills/init-project/templates/`:

| Source | Destination | Action |
|---|---|---|
| `CLAUDE.md.template` | `$ARGUMENTS/CLAUDE.md` | Copy and prompt to fill in project details |
| `settings.json.template` | `$ARGUMENTS/.claude/settings.json` | Copy as-is |
| `pull_request_template.md` | `$ARGUMENTS/.github/pull_request_template.md` | Copy as-is |

### 3. Copy Workflow Templates

Ask user which workflows to include:

| Template | Destination | Description |
|---|---|---|
| `ci.yml.template` | `$ARGUMENTS/.github/workflows/ci.yml.template` | KMP CI pipeline |
| `ai-ops-daily.yml.template` | `$ARGUMENTS/.github/workflows/ai-ops-daily.yml.template` | Daily AI analysis |
| `claude-code.yml.template` | `$ARGUMENTS/.github/workflows/claude-code.yml` | Issue → PR automation |
| `claude-review.yml.template` | `$ARGUMENTS/.github/workflows/claude-review.yml` | Automated PR review |

### 4. Copy Rules

Copy the `rules/` directory to the project:

```
$ARGUMENTS/rules/
  behavior.md
  coding-conventions.md
  ai-ops.md
```

### 5. Create Directory Structure

```bash
mkdir -p "$ARGUMENTS/docs/claude"
touch "$ARGUMENTS/docs/claude/review_points.md"
```

### 6. Post-Setup Instructions

Output a checklist for the user:

```
## Setup Complete

Files created:
- CLAUDE.md ← Fill in project name, architecture, tech stack
- .claude/settings.json ← Add project-specific commands if needed
- .github/pull_request_template.md
- .github/workflows/ ← Rename .template files to .yml when ready
- rules/ ← Customize behavior, coding conventions, and AI ops rules
- docs/claude/review_points.md ← Will grow as reviews happen

## Next Steps
1. Edit CLAUDE.md — fill in {PROJECT_NAME}, architecture, tech stack
2. Edit rules/ — customize for your project's conventions
3. Rename workflow .template files to .yml and configure secrets
4. Commit the setup: git add -A && git commit -m "Add AI-driven development templates"
```
