# ai-dev

Claude Code plugin for AI-driven development workflows. Provides autonomous issue resolution, code review, PR creation, tech debt scanning, and KPI monitoring.

## Install

```bash
claude plugin install /path/to/ai-dev-templates --scope user
```

Or test locally:

```bash
claude --plugin-dir /path/to/ai-dev-templates
```

## Skills

| Skill | Description |
|---|---|
| `/ai-dev:dev {N}` | Autonomous end-to-end: investigate → plan → implement → test → review → PR |
| `/ai-dev:review` | Multi-phase code review (Architecture → Mobile → KMP → Perf → Security → Quality) with Gemini cross-review |
| `/ai-dev:pr` | PR creation using project template with issue linking |
| `/ai-dev:tech-debt` | Codebase scan for technical debt, auto-creates GitHub Issues for high-severity findings |
| `/ai-dev:monitor` | KPI monitoring: crash rates, store reviews, metrics → issue proposals |
| `/ai-dev:init-project {path}` | Initialize a project with templates (CLAUDE.md, settings, CI, workflows) |

## Agents

| Agent | Role |
|---|---|
| `security-reviewer` | OWASP MASVS vulnerability scanner |
| `test-writer` | Unit test generation for changed code |

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
    ├─ Phase 5: Self-review (checklist, security-reviewer, Gemini)
    └─ Phase 6: PR (commit, push, gh pr create, Closes #42)
```

## Structure

```
ai-dev-templates/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── dev/SKILL.md
│   ├── review/SKILL.md
│   ├── pr/SKILL.md
│   ├── tech-debt/SKILL.md
│   ├── monitor/SKILL.md
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
│   └── block-dangerous-commands.sh
└── rules/
    ├── behavior.md
    ├── coding-conventions.md
    └── ai-ops.md
```

## License

MIT
