# ai-dev

Claude Code plugin for AI-driven development workflows. Language-agnostic harness engineering — autonomous issue resolution, multi-agent code review, PR creation, tech debt scanning, and KPI monitoring.

## Install

### As Plugin (for personal use)

```bash
# Register marketplace
/plugin marketplace add rioX432/ai-dev-templates

# Install
/plugin install ai-dev@ai-dev-templates
```

### As Project Files (for team use)

```bash
# Initialize a new project with templates
/ai-dev:init-project /path/to/project

# Or sync updates to existing projects
/ai-dev:sync
```

Common skills/agents/rules are copied to `.claude/skills/`, `.claude/agents/`, `.claude/rules/` so all team members can use them without installing the plugin.

### Auto-Sync via GitHub Actions

When this repo is pushed, GitHub Actions automatically creates PRs to sync common files to configured projects. See `.github/workflows/sync-to-projects.yml`.

## Skills

| Skill | Description |
|---|---|
| `/ai-dev:dev {issue}` | E2E: investigate → dig → decompose → implement → test → review → PR |
| `/ai-dev:dev-all [issues]` | Sequential issue processing: /dev per issue → CI wait → merge → next |
| `/ai-dev:review` | Multi-agent parallel code review (Bug/Security + Architecture/Quality) |
| `/ai-dev:pr` | PR creation using project template with issue linking |
| `/ai-dev:dig` | Structured ambiguity resolution with auto-decide rules |
| `/ai-dev:decompose` | Task decomposition into ordered subtasks with dependencies |
| `/ai-dev:audit [scope]` | Codebase health audit with parallel scanners → GitHub Issues |
| `/ai-dev:tech-debt` | Technical debt scan → GitHub Issues for high-severity findings |
| `/ai-dev:monitor` | KPI monitoring: crash rates, reviews, metrics → priorities (PoC) |
| `/ai-dev:sync` | Sync common files to target projects |
| `/ai-dev:init-project {path}` | Initialize a project with templates |

## Agents

| Agent | Model | Constraints | Role |
|---|---|---|---|
| `security-reviewer` | sonnet | maxTurns: 20, read-only | OWASP vulnerability scanner |
| `test-writer` | sonnet | maxTurns: 30 | Unit test generation |

## Hooks

| Event | Action |
|---|---|
| `PostToolUse` (Write/Edit) | Auto-lint: ktlint, swiftformat, eslint, ruff, jq (language auto-detected) |
| `PreToolUse` (Bash) | Block dangerous commands (force push, rm -rf, drop table, etc.) |
| `StopFailure` | Log failure patterns to `logs/failures/` for harness improvement |
| `PostCompact` | Restore critical context (progress.txt) after compaction |

## Harness Engineering Design

This plugin follows [harness engineering](https://mitchellh.com/writing/my-ai-adoption-journey) principles:

- **Deterministic feedback loops**: Hooks provide millisecond-level lint/format feedback — not dependent on LLM judgment
- **Context efficiency**: Skills are on-demand (loaded only when invoked), sub-agents provide context firewalls
- **Failure-driven improvement**: `StopFailure` hook logs patterns → human promotes to `rules/*.md` → never happens again
- **Peelable design**: Each component is independent — remove what the model no longer needs
- **Language-agnostic**: Skills reference CLAUDE.md for project-specific commands, not hardcoded build tools

### Architecture

```
Plugin (language-agnostic)          Project (specific)
┌──────────────────────────┐    ┌──────────────────────────┐
│ skills/ — workflow        │    │ CLAUDE.md — commands,     │
│   dev, dev-all, review,  │    │   architecture, gotchas   │
│   pr, dig, decompose,    │    │                          │
│   audit, tech-debt       │    │ .claude/agents/           │
│                          │    │   kmp-reviewer.md         │
│ agents/ — shared         │    │   ui-reviewer.md          │
│   security-reviewer      │    │                          │
│   test-writer            │    │ .claude/rules/            │
│                          │    │   kmp.md, android.md      │
│ hooks/ — auto-lint,      │    │                          │
│   block-dangerous,       │    │ .claude/settings.json     │
│   log-failure            │    │                          │
│                          │    │ REVIEW.md                 │
│ rules/ — behavior,       │    └──────────────────────────┘
│   ai-ops                 │
└──────────────────────────┘
```

## Workflow: dev

```
/ai-dev:dev #42
    ├─ Phase 1: Issue Understanding (GitHub / Linear / Figma)
    ├─ Phase 2: Investigation (Explore subagent)
    ├─ Phase 3: Ambiguity Resolution (/dig)
    ├─ Phase 4: Task Decomposition (/decompose)
    ├─ ── User confirms approach ──
    ├─ Phase 5: Branch & Implement (subtask loop)
    ├─ Phase 6: Quality Gate (build/test/lint from CLAUDE.md)
    ├─ Phase 7: Review (/review — multi-agent parallel)
    ├─ ── User confirms commit ──
    └─ Phase 8: Commit & PR
```

## Workflow: dev-all

```
/ai-dev:dev-all #42 #43 #44
    ├─ Step 1: Resolve issues + dependency analysis
    ├─ Step 2: Parallel investigation (Explore agents)
    ├─ ── User confirms execution plan ──
    └─ Step 3: Sequential loop
        ├─ /dev #42 (isolated sub-agent + worktree)
        ├─ CI wait → auto-merge
        ├─ /dev #43 (fresh context, latest main)
        ├─ CI wait → auto-merge
        └─ ...
```

## Structure

```
ai-dev-templates/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── .github/
│   └── workflows/
│       └── sync-to-projects.yml
├── skills/
│   ├── dev/SKILL.md
│   ├── dev-all/SKILL.md
│   ├── review/SKILL.md
│   ├── pr/SKILL.md
│   ├── dig/SKILL.md
│   ├── decompose/SKILL.md
│   ├── audit/SKILL.md
│   ├── tech-debt/SKILL.md
│   ├── monitor/SKILL.md
│   ├── sync/
│   │   ├── SKILL.md
│   │   └── sync-config.json
│   └── init-project/
│       ├── SKILL.md
│       └── templates/
├── agents/
│   ├── security-reviewer.md
│   └── test-writer.md
├── hooks/
│   └── hooks.json
├── scripts/
│   ├── auto-lint.sh
│   ├── block-dangerous-commands.sh
│   ├── log-failure.sh
│   └── restore-context.sh
└── rules/
    ├── behavior.md
    ├── coding-conventions.md
    └── ai-ops.md
```

## License

MIT
