---
name: init-project
description: "Initialize a new project with AI-driven development templates and layer-specific configuration"
user-invocable: true
disable-model-invocation: true
argument-hint: "{project-path}"
allowed-tools:
  - Read
  - Write
  - Bash(mkdir:*)
  - Bash(cp:*)
  - Bash(ls:*)
  - Bash(cat:*)
  - AskUserQuestion
---

# /init-project — Project Initialization

Initialize a project at `$ARGUMENTS` with AI-driven development templates.

## Steps

### 1. Validate Target

- Verify `$ARGUMENTS` is a valid directory path
- Check if it's a git repository (warn if not)
- Check for existing `.claude/` directory (warn if overwriting)

### 2. Select Project Type

Ask the user for the project type:

→ **AskUserQuestion:** What type of project is this?
1. **kmp** — KMP/CMP, Android, iOS
2. **react-native** — React Native, Expo
3. **web** — TypeScript, React, Vue, Node.js, Electron
4. **iot** — C++, Python, embedded
5. **common-only** — no layer-specific files

Store the corresponding layer list as `$PROJECT_LAYERS` (currently one layer per type; the list form allows composing layers later — see `layers/README.md`).

### 3. Copy Core Files

Copy the following from `${CLAUDE_SKILL_DIR}/templates/`:

| Source | Destination | Action |
|---|---|---|
| `CLAUDE.md.template` | `$ARGUMENTS/CLAUDE.md` | Copy, prompt to fill in |
| `REVIEW.md.template` | `$ARGUMENTS/REVIEW.md` | Copy as-is |
| `settings.json.template` | `$ARGUMENTS/.claude/settings.json` | Copy as-is |
| `pull_request_template.md` | `$ARGUMENTS/.github/pull_request_template.md` | Copy as-is |

### 4. Copy Layer PR Template (if applicable)

If `$PROJECT_LAYERS` is not empty, for each layer in order that has a `pull_request_template.md`:

```bash
LAYER_ROOT=${CLAUDE_SKILL_DIR}/../../layers/$LAYER
cp $LAYER_ROOT/templates/pull_request_template.md $ARGUMENTS/.github/pull_request_template.md
```

This **replaces** the common PR template copied in Step 3 (later layers override earlier ones).

### 5. Copy Common Skills

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

### 6. Copy Common Agents

```
$ARGUMENTS/.claude/agents/
  security-reviewer.md
  test-writer.md
```

### 7. Copy Common Rules

```
$ARGUMENTS/.claude/rules/
  behavior.md
  ai-ops.md
```

### 8. Copy Layer-Specific Files (if $PROJECT_LAYERS is not empty)

For each `$LAYER` in `$PROJECT_LAYERS` (in order), read `layer_types.$LAYER` from `${CLAUDE_SKILL_DIR}/../sync/sync-config.json` and set `LAYER_ROOT=${CLAUDE_SKILL_DIR}/../../layers/$LAYER`.

#### Layer Agents
```bash
for agent in layer_types.$LAYER.agents:
  mkdir -p $ARGUMENTS/.claude/agents/
  cp $LAYER_ROOT/agents/$agent.md $ARGUMENTS/.claude/agents/$agent.md
```

#### Layer Rules
```bash
for rule in layer_types.$LAYER.rules:
  mkdir -p $ARGUMENTS/.claude/rules/
  cp $LAYER_ROOT/rules/$rule $ARGUMENTS/.claude/rules/$rule
```

#### Layer Skills (if any)
```bash
for skill in layer_types.$LAYER.skills:
  mkdir -p $ARGUMENTS/.claude/skills/$skill/
  cp $LAYER_ROOT/skills/$skill/SKILL.md $ARGUMENTS/.claude/skills/$skill/SKILL.md
```

### 9. Copy Workflow Templates (Optional)

Ask user which workflows to include.

**Common workflows:**

| Template | Description |
|---|---|
| `ai-ops-daily.yml.template` | Daily AI analysis |
| `claude-code.yml.template` | Issue → PR automation |
| `claude-review.yml.template` | Automated PR review |

**Layer workflows** (from `layers/$LAYER/templates/*.yml.template`, for each layer in `$PROJECT_LAYERS`):

For kmp:
| Template | Description |
|---|---|
| `ci-kmp.yml.template` | KMP CI pipeline (Android + iOS build & test) |
| `roborazzi.yml.template` | Roborazzi screenshot comparison on PRs |
| `android-emulator-test.yml.template` | Android emulator instrumented tests |
| `maestro-smoke-test.yml.template` | Maestro E2E smoke tests |

Copy selected templates to `$ARGUMENTS/.github/workflows/`.

### 10. Copy Routines Guide (Optional)

Ask user if they want to set up Claude Code Routines (cloud-based scheduled agents):

If yes:
```bash
cp ${CLAUDE_SKILL_DIR}/templates/routines.md.template $ARGUMENTS/docs/routines.md
```

### 11. Register in sync-config.json

Add the new project to `${CLAUDE_SKILL_DIR}/../sync/sync-config.json`:

```json
"projects": {
  ...
  "{project-name}": { "path": "{relative-path}", "layers": ["{LAYER}", ...] }
}
```

Also add a matching matrix entry (`repo` + space-separated `layers`) to `.github/workflows/sync-to-projects.yml` so CI distribution covers the new project.

### 12. Post-Setup Instructions

```
## Setup Complete

Files created:
- CLAUDE.md ← Fill in project name, architecture, tech stack, commands
- REVIEW.md ← Customize review criteria
- .claude/settings.json ← Add project-specific permissions
- .claude/skills/ ← Shared skills (synced from ai-dev-templates)
- .claude/agents/ ← Shared + layer ({PROJECT_LAYERS}) agents
- .claude/rules/ ← Shared + layer ({PROJECT_LAYERS}) rules
- .github/pull_request_template.md ← {PROJECT_LAYERS} layer template
- .github/workflows/ ← Selected CI templates

## Next Steps
1. Edit CLAUDE.md — fill in project details, especially Commands section
2. **Define design tokens** — choose brand font, accent color, and review design-personality.md
3. Add project-specific agents to .claude/agents/ (e.g., kmp-reviewer.md)
4. Add project-specific rules to .claude/rules/
5. Rename workflow .template files to .yml and configure secrets
6. Commit: git add -A && git commit -m "Add AI-driven development templates"

7. **Set up Routines** — configure cloud-based scheduled agents at claude.ai/code/routines (see docs/routines.md)

## Keeping Up to Date
Common + layer files are synced from ai-dev-templates.
Run /sync from ai-dev-templates to update all projects.
```
