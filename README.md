# ai-dev

Claude Code plugin for AI-driven development workflows. Provides autonomous issue resolution, multi-agent code review, PR creation, tech debt scanning, and KPI monitoring.

## Install

```bash
# 1. Register marketplace (once)
/plugin marketplace add rioX432/ai-dev-templates

# 2. Install to project (recorded in .claude/settings.json → Git managed)
/plugin install ai-dev --scope project
```

For development/testing:

```bash
claude --plugin-dir /path/to/ai-dev-templates
```

## Skills

| Skill | Description |
|---|---|
| `/ai-dev:dev {N}` | Autonomous end-to-end: investigate → plan → implement → test → review → PR |
| `/ai-dev:review` | Multi-agent code review (Bug/Security + Architecture/UI agents in parallel) with Gemini cross-review |
| `/ai-dev:pr` | PR creation using project template with issue linking |
| `/ai-dev:tech-debt` | Codebase scan for technical debt, auto-creates GitHub Issues for high-severity findings |
| `/ai-dev:monitor` | KPI monitoring: crash rates, store reviews, metrics → issue proposals |
| `/ai-dev:init-project {path}` | Initialize a project with templates (CLAUDE.md, REVIEW.md, settings, CI, workflows) |

## Agents

| Agent | Model | Role |
|---|---|---|
| `security-reviewer` | sonnet | OWASP MASVS vulnerability scanner |
| `test-writer` | sonnet | Unit test generation for changed code |

## Templates

| Template | Description |
|---|---|
| `CLAUDE.md` | Project configuration with `@REVIEW.md` import, commands, architecture, Think Twice checklist |
| `REVIEW.md` | Review criteria: severity definitions, platform-specific checks, false positive reduction guide |
| `settings.json` | Permissions with `*.pbxproj` deny rules, linter allow rules |

## Hooks

| Event | Action |
|---|---|
| `PostToolUse` (Write/Edit) | Auto-lint saved files (ktlint, swiftformat, eslint, ruff, etc.) |
| `PreToolUse` (Bash) | Block dangerous commands (force push to main, rm -rf /, etc.) |

## Workflow: dev

```
/ai-dev:dev 42
    ├─ Phase 1: Investigate (gh issue view, code exploration)
    ├─ Phase 2: Plan (present to user for approval)
    ├─ Phase 3: Implement (branch, code, auto-lint)
    ├─ Phase 4: Test (test-writer agent, build, run)
    ├─ Phase 5: Self-review (REVIEW.md + multi-agent review + security-reviewer)
    └─ Phase 6: PR (commit, push, gh pr create, Closes #42)
```

## Workflow: review

```
/ai-dev:review
    ├─ Step 0: Checkout & prepare (branch, commits, diff)
    ├─ Step 1: Build change context (intent, risk areas)
    ├─ Step 2: Multi-agent parallel review
    │   ├─ Agent A: Bug & Logic + Security (sonnet)
    │   └─ Agent B: Architecture & UI (sonnet)
    ├─ Step 3: Merge & deduplicate findings
    ├─ Step 4: Cross-review verification (Gemini)
    └─ Step 5: Final report with verification attribution
```

## Structure

```
ai-dev-templates/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── skills/
│   ├── dev/SKILL.md
│   ├── review/SKILL.md
│   ├── pr/SKILL.md
│   ├── tech-debt/SKILL.md
│   ├── monitor/SKILL.md
│   └── init-project/
│       ├── SKILL.md
│       └── templates/
│           ├── CLAUDE.md.template
│           ├── REVIEW.md.template
│           └── settings.json.template
├── agents/
│   ├── security-reviewer.md
│   └── test-writer.md
├── hooks/
│   └── hooks.json
├── scripts/
│   ├── auto-lint.sh
│   └── block-dangerous-commands.sh
└── rules/
    ├── behavior.md
    ├── coding-conventions.md
    └── ai-ops.md
```

## License

MIT
