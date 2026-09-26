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
  - Bash(python3:*)
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
| `AGENTS.md.template` | `$ARGUMENTS/AGENTS.md` | Seed canonical project guidance only when absent; otherwise show proposed additions and ask before merging |
| `CLAUDE.md.template` | `$ARGUMENTS/CLAUDE.md` | Seed the thin Claude adapter only when absent; never replace project-specific overrides |
| `REVIEW.md.template` | `$ARGUMENTS/REVIEW.md` | Copy as-is |
| `settings.json.template` | `$ARGUMENTS/.claude/settings.json` | Copy the least-privilege base, then merge only the selected type's allow-list from `settings-profiles/{type}.json` |
| `pull_request_template.md` | `$ARGUMENTS/.github/pull_request_template.md` | Copy as-is |

The settings profile is an allow-list fragment, not a complete settings file. Merge its
`permissions.allow` entries into the base without replacing `ask`, `deny`, `defaultMode`,
`disableBypassPermissionsMode`, or the top-level `attribution` object.
For `common-only`, add no profile. Do not broaden a profile to an arbitrary command wildcard; leave
commands not listed here approval-gated and tell the user how to add a project-specific command later.

### 4. Copy Layer PR Template (if applicable)

If `$PROJECT_LAYERS` is not empty, for each layer in order that has a `pull_request_template.md`:

```bash
LAYER_ROOT=${CLAUDE_SKILL_DIR}/../../layers/$LAYER
cp $LAYER_ROOT/templates/pull_request_template.md $ARGUMENTS/.github/pull_request_template.md
```

This **replaces** the common PR template copied in Step 3 (later layers override earlier ones).

### 5. Copy Common Skills

Copy every skill listed in `skills/sync/sync-config.json` under `common_skills` — the same
single source of truth as Step 6. Do not hardcode the list here; read it.

```
$ARGUMENTS/.claude/skills/{skill}/   ← Claude Code adapter
$ARGUMENTS/.agents/skills/{skill}/   ← Codex / Agent Skills adapter
```

Copy each skill **directory** (`cp -R`) to the Claude adapter, not just its `SKILL.md` — reference files
(`issue/splitting.md`) and scripts are part of the skill. Render the Codex adapter with
`${TEMPLATE_ROOT}/scripts/render-codex-skill.py`, which preserves supporting files while reducing frontmatter to
portable Agent Skills fields and adding host-capability guidance. Do not raw-copy Claude-only frontmatter into
`.agents/skills`. Root-level `evals/` are plugin-development tests and are not copied into initialized projects.

### 6. Copy Common Agents and Rules

Copy every entry listed in `skills/sync/sync-config.json` under `common_agents` and
`common_rules` — that file is the single source of truth, shared with `/sync` and with
`.github/workflows/sync-to-projects.yml`. Do not hardcode the list here; read it.

```
$ARGUMENTS/.claude/agents/   ← one file per common_agents entry, plus layer agents (step 8)
$ARGUMENTS/.claude/rules/    ← one file per common_rules entry, plus layer rules (step 8)
```

### 7. Write the Sync Manifest

Write `$ARGUMENTS/.claude/.ai-dev-synced` listing what was installed, so later syncs can tell
a template file from one the project added itself:

```json
{"skills": [...], "agents": ["security-reviewer.md", ...], "rules": ["behavior.md", ...], "adapters": ["claude", "codex"]}
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

The automated workflow derives its matrix from this config; do not edit a duplicate matrix.

### 12. Post-Setup Instructions

```
## Setup Complete

Files created:
- AGENTS.md ← Fill in project overview, values, architecture, and exact commands
- CLAUDE.md ← Thin Claude adapter importing AGENTS.md and REVIEW.md
- REVIEW.md ← Customize review criteria
- .claude/settings.json ← Least-privilege base + selected stack profile; add only required project commands
- .claude/skills/ ← Claude Code skill adapter
- .agents/skills/ ← Codex / Agent Skills adapter
- .claude/agents/ ← Shared + layer ({PROJECT_LAYERS}) agents
- .claude/rules/ ← Shared + layer ({PROJECT_LAYERS}) rules
- .github/pull_request_template.md ← {PROJECT_LAYERS} layer template
- .github/workflows/ ← Selected CI templates

## Next Steps
1. Edit AGENTS.md — fill in project details, especially Commands and their success signals
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
