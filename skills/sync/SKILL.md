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
  - Bash(python3:*)
  - Bash(git diff:*)
  - Bash(git status)
  - AskUserQuestion
---

# /sync — Sync to Projects

Sync common skills, agents, hooks, rules, and **layer-specific files** from ai-dev-templates to target projects.

**Config:** !`cat ${CLAUDE_SKILL_DIR}/sync-config.json`

## Process

### Step 1: Read Config

Run `python3 ${TEMPLATE_ROOT}/scripts/sync-config.py validate --source-root ${TEMPLATE_ROOT}` before producing a
preview. Stop on unknown layers, duplicate entries, or missing source files.

`sync-config.json → common_skills` is the single source of truth for which skills are common —
`.github/workflows/sync-to-projects.yml` reads the same list. Removing a skill from it makes
automated sync report it as stale; deletion remains confirmation-gated in Step 4b.

Read `sync-config.json` to get:
- `projects` — object mapping project name to `{ path, layers, adapters? }` (`layers` is ordered; later layers override earlier ones)
- `default_adapters` — host outputs to render when a project does not override them
- `common_skills`, `common_agents`, `common_rules` — common files for all projects
- `layer_types` — per-layer definitions for agents, rules, skills, templates
- `hook_policy` — `manual` means inspect and merge hooks rather than overwriting them

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
| .agents/skills/dev/SKILL.md | Updated (portable frontmatter) |
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

# Skills — copy the whole directory: references and skill-local scripts are
# part of progressive disclosure. Root-level evals/ stay in this plugin repo.
mkdir -p {project}/.claude/skills/{skill}/
cp -R skills/{skill}/. {project}/.claude/skills/{skill}/

# Codex / Agent Skills adapter — preserve supporting files but render portable
# frontmatter and host-capability guidance rather than raw-copying Claude fields.
python3 scripts/render-codex-skill.py \
  skills/{skill} {project}/.agents/skills/{skill}

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
#   skills → rm -rf {project}/.claude/skills/{name} {project}/.agents/skills/{name}
#   agents → rm -f  {project}/.claude/agents/{name}
#   rules  → rm -f  {project}/.claude/rules/{name}
# Then rewrite the manifest with what this run copied:
#   {"skills": [...], "agents": [...], "rules": [...], "adapters": ["claude", "codex"]}
```

**Show every prune to the user before deleting** — a removal is not reversible from the target
side. If the manifest is missing (first sync), prune nothing and just write it.

`.github/workflows/sync-to-projects.yml` derives its project matrix and file lists from the same config. Compare
its PR preview with this manual plan before treating the two paths as converged; hooks and newly introduced
workflow templates remain confirmation-gated rather than silently overwritten. Automated sync never prunes:
it emits a warning and retains stale ownership entries until a reviewed manual sync removes them.

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

- **Never overwrite project-specific files**: `CLAUDE.md`, `AGENTS.md`, settings.json, project-specific agents/rules not in sync config
- **Hooks require manual merge**: Projects may have custom hooks that should not be lost
- **Supporting files**: Sync the whole skill directory so referenced procedures and scripts stay with SKILL.md;
  root-level `evals/` are plugin-development tests and are not copied into target projects
- **Host adapters**: `.claude/skills` keeps Claude-specific frontmatter; `.agents/skills` is rendered through
  `scripts/render-codex-skill.py`. Hooks and Claude named-agent discovery are not claimed to work in Codex
- **Layer PR template replaces common**: If a layer has `pull_request_template.md`, it takes precedence over the common template
- **CI workflow templates are optional**: Always confirm with user before adding new workflow files
- **Automated workflow templates are seed-only**: CI adds a missing template but never overwrites an existing one;
  updates to an existing project workflow require an explicit reviewed merge
- **AGENTS.md is seed-only**: add the portable template only when the target has no `AGENTS.md`; never replace
  project guidance during sync
