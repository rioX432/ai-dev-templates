---
name: sync
description: "Sync common skills, agents, hooks, rules, and layer-specific files to target projects"
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
  - Bash(cat:*)
  - Bash(git diff:*)
  - Bash(git status)
  - AskUserQuestion
---

# /sync — Sync to Projects

Sync common skills, agents, hooks, rules, and **layer-specific files** from ai-dev-templates to target projects.

**Config:** !`cat ${CLAUDE_SKILL_DIR}/sync-config.json`

## Process

### Step 1: Read Config

`sync-config.json → common_skills` is the single source of truth for which skills are common —
`.github/workflows/sync-to-projects.yml` reads the same list. Removing a skill from it makes
Step 4b prune it from every target on the next sync.

Read `sync-config.json` to get:
- `projects` — object mapping project name to `{ path, layers }` (`layers` is an ordered list; later layers override earlier ones on filename collision)
- `common_skills`, `common_agents`, `common_rules`, `sync_hooks` — common files for all projects
- `layer_types` — per-layer definitions for agents, rules, skills, templates

Derive the template root:
```
TEMPLATE_ROOT=${CLAUDE_SKILL_DIR}/../..
```

So common files are at `${TEMPLATE_ROOT}/skills/`, `${TEMPLATE_ROOT}/agents/`, `${TEMPLATE_ROOT}/rules/`, `${TEMPLATE_ROOT}/hooks/`.
Layer files are at `${TEMPLATE_ROOT}/layers/{layer}/`.

### Step 2: Diff Check

For each target project, diff **both common and layer-specific files**. Process the project's `layers` list in order:

```
## Sync Preview: {project} (layers: {layers})

### Common Files
| File | Status |
|------|--------|
| .claude/skills/dev/SKILL.md | Updated (3 lines) |
| .claude/agents/security-reviewer.md | No change |
| .claude/rules/behavior.md | Updated (1 line) |

### Layer Files ({layer})
| File | Source | Status |
|------|--------|--------|
| .claude/agents/ui-reviewer.md | layers/{layer}/agents/ | New file |
| .claude/rules/mobile-conventions.md | layers/{layer}/rules/ | New file |
| .github/pull_request_template.md | layers/{layer}/templates/ | Updated |
| .github/workflows/roborazzi.yml.template | layers/{layer}/templates/ | New file |
```

#### Layer file destinations:
| Source type | Destination in target project |
|---|---|
| `layers/{layer}/agents/*.md` | `{project}/.claude/agents/` |
| `layers/{layer}/rules/*.md` | `{project}/.claude/rules/` |
| `layers/{layer}/skills/*/SKILL.md` | `{project}/.claude/skills/{skill}/` |
| `layers/{layer}/templates/pull_request_template.md` | `{project}/.github/pull_request_template.md` |
| `layers/{layer}/templates/*.yml.template` | `{project}/.github/workflows/` |

**Note:** Layer `pull_request_template.md` replaces the common one if both exist.

### Step 3: Confirm

Ask user to confirm before copying:
- Which projects to sync
- Whether to sync all files or select specific ones
- For new layer templates (CI workflows), confirm each one individually

### Step 4: Copy

For each confirmed project:

```bash
# --- Common files ---

# Skills — copy the whole directory: reference files, evals, and scripts
# are part of the skill's progressive disclosure, not optional extras
mkdir -p {project}/.claude/skills/{skill}/
cp -R skills/{skill}/. {project}/.claude/skills/{skill}/

# Agents
mkdir -p {project}/.claude/agents/
cp agents/{agent}.md {project}/.claude/agents/{agent}.md

# Rules
mkdir -p {project}/.claude/rules/
cp rules/{rule} {project}/.claude/rules/{rule}

# Hooks (merge, don't overwrite — project may have custom hooks)
# Show diff and ask user how to merge

# --- Layer-specific files (repeat for each layer in the project's `layers` list, in order) ---

LAYER={one_of_project_layers}

# Layer agents
cp ${TEMPLATE_ROOT}/layers/$LAYER/agents/{agent}.md {project}/.claude/agents/{agent}.md

# Layer rules
cp ${TEMPLATE_ROOT}/layers/$LAYER/rules/{rule} {project}/.claude/rules/{rule}

# Layer skills (if any)
# mkdir -p {project}/.claude/skills/{skill}/
# cp ${TEMPLATE_ROOT}/layers/$LAYER/skills/{skill}/SKILL.md {project}/.claude/skills/{skill}/SKILL.md

# Layer templates: PR template
mkdir -p {project}/.github/
cp ${TEMPLATE_ROOT}/layers/$LAYER/templates/pull_request_template.md {project}/.github/pull_request_template.md

# Layer templates: CI workflows (only if confirmed)
mkdir -p {project}/.github/workflows/
cp ${TEMPLATE_ROOT}/layers/$LAYER/templates/{workflow}.yml.template {project}/.github/workflows/{workflow}.yml.template
```

### Step 4b: Prune files removed upstream

Copying never removes anything, so a skill deleted from this repo would linger in the target
as a stale copy that still looks current. `{project}/.claude/.ai-dev-synced` records what
previous syncs installed, so only those are eligible for removal — files the project added
itself are never touched.

```bash
MANIFEST={project}/.claude/.ai-dev-synced
# Compare the manifest's lists against what this run just copied.
# For each entry present in the manifest but NOT copied this run:
#   skills → rm -rf {project}/.claude/skills/{name}
#   agents → rm -f  {project}/.claude/agents/{name}
#   rules  → rm -f  {project}/.claude/rules/{name}
# Then rewrite the manifest with what this run copied:
#   {"skills": [...], "agents": [...], "rules": [...]}
```

**Show every prune to the user before deleting** — a removal is not reversible from the target
side. If the manifest is missing (first sync), prune nothing and just write it.

`.github/workflows/sync-to-projects.yml` runs the identical logic, so a manual `/sync` and an
automated sync converge on the same state.

---

### Step 5: Report

```
## Sync Complete

| Project | Layer | Common Updated | Common Added | Layer Updated | Layer Added | Skipped |
|---------|-------|---------------|-------------|--------------|------------|---------|
| CivitDeck | mobile | 5 | 0 | 1 | 3 | 0 |
| vtslide | web | 4 | 1 | 0 | 1 | 0 |

Next: review changes in each project and commit.
```

## Important Notes

- **Never overwrite project-specific files**: CLAUDE.md, settings.json, project-specific agents/rules not in sync config
- **Hooks require manual merge**: Projects may have custom hooks that should not be lost
- **Supporting files**: Only SKILL.md is synced for skills, not supporting files in skill directories
- **Layer PR template replaces common**: If a layer has `pull_request_template.md`, it takes precedence over the common template
- **CI workflow templates are optional**: Always confirm with user before adding new workflow files
