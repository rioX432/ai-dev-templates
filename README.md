# ai-dev

Claude Code plugin for AI-driven development workflows. Language-agnostic harness engineering — autonomous issue resolution, Codex-assisted technical design, context-isolated investigation, multi-agent code review, and structured review gating.

**Core philosophy: depth over breadth.** Every feature proposal is filtered through project-defined Core Values and a one-step distance test. The system is designed to prevent feature bloat by enforcing "what NOT to build" as a first-class concept.

**v3.0 highlights:**
- **Codex integration**: Technical design verification via Codex MCP in `/dev`, `/dig`, `/decompose` (optional, with fallback)
- **Context isolation**: `/dev-investigate` runs in a forked context, keeping investigation token costs out of the main session
- **Structured review gating**: `/dev-all` validates `review.json` artifacts before auto-merge (Critical → skip, Warning → user confirmation)
- **Lifecycle hooks**: SubagentStart/Stop, TaskCompleted, SessionEnd logging for observability

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
| `/ai-dev:dev {issue}` | E2E: investigate (forked) → Codex design → dig → decompose → implement → test → review → PR |
| `/ai-dev:dev-all [issues]` | Autonomous issue processing: /dev per issue in isolated sub-agent → evidence-based review validation → conditional merge |
| `/ai-dev:dev-investigate` | Context-isolated codebase investigation (runs with `context: fork`) |
| `/ai-dev:review` | Multi-agent parallel code review (Bug/Security + Architecture/Quality) |
| `/ai-dev:pr` | PR creation using project template with issue linking |
| `/ai-dev:dig` | Structured ambiguity resolution with auto-decide rules + Codex design review |
| `/ai-dev:decompose` | Task decomposition into ordered subtasks + Codex architecture validation |
| `/ai-dev:audit [scope]` | Codebase health + visual bug audit with parallel scanners → GitHub Issues |
| `/ai-dev:competitive-audit [focus]` | Core Value-filtered competitive analysis: user pain points → max 3 issues + Won't Do recording |
| `/ai-dev:ux-audit [target]` | UI/UX comprehensive audit: heuristics, accessibility, visual, platform guidelines → GitHub Issues |
| `/ai-dev:tech-debt` | Technical debt scan → GitHub Issues for high-severity findings |
| `/ai-dev:monitor` | KPI monitoring: crash rates, reviews, metrics → priorities (PoC) |
| `/ai-dev:update-docs [scope]` | Documentation audit & update (architecture, changelog, readme, oss) |
| `/ai-dev:sync` | Sync common files to target projects |
| `/ai-dev:think <topic> [repo]` | Zero-base deep research: structured investigation → synthesis → proposal with counter-arguments |
| `/ai-dev:init-project {path}` | Initialize a project with templates (includes Core Values + Won't Do sections) |

## Agents

| Agent | Model | Constraints | Role |
|---|---|---|---|
| `security-reviewer` | sonnet | maxTurns: 20, read-only | OWASP vulnerability scanner |
| `test-writer` | sonnet | maxTurns: 30 | Unit test generation |
| `ui-reviewer` | sonnet | maxTurns: 20, read-only | UI/UX quality reviewer (accessibility, platform guidelines, design personality) |
| `perf-reviewer` | sonnet | maxTurns: 20, read-only | Compose/CMP performance reviewer (recomposition, lazy layout, main thread, memory) |
| `repo-analyzer` | sonnet | maxTurns: 30 | GitHub repo feature/Issue/PR analysis (for /think) |
| `deep-researcher` | haiku | maxTurns: 20 | Web/SNS supplemental research (collector only) |
| `case-analyzer` | sonnet | maxTurns: 20 | Individual case deep dive analysis |
| `social-scanner` | haiku | maxTurns: 20 | X/Reddit/HN/community sentiment scan |
| `source-verifier` | haiku | maxTurns: 30 | URL existence + claim consistency check |
| `counter-argument` | sonnet | maxTurns: 15 | Proposal stress-test: counter-arguments, risks |

Model tiers follow `rules/ai-ops.md → Model Selection for Agents`: `haiku` for mechanical collection, `sonnet` for review/analysis, `opus` for long-horizon implementation (dev-all sub-agents). Aliases track the latest generation automatically.

## Hooks

| Event | Action |
|---|---|
| `PostToolUse` (Write/Edit) | Auto-lint: ktlint, swiftformat, eslint, ruff, jq (language auto-detected) |
| `PreToolUse` (Bash) | Block dangerous commands (force push, rm -rf, drop table, etc.) |
| `PreToolUse` (Read/Edit) | Block secret file access (.env, credentials) |
| `PostToolUseFailure` | Log failure patterns to `logs/failures/` for harness improvement |
| `PreCompact` | Save critical context (branch, changed files, progress) before compaction |
| `PostCompact` | Restore critical context (progress.txt) after compaction |
| `SessionStart` | Restore context at session start (handles post-compaction recovery) |
| `SubagentStart` | Log subagent lifecycle to `logs/subagents/` (JSONL) |
| `SubagentStop` | Log subagent completion with result summary |
| `TaskCompleted` | Log task completion events |
| `SessionEnd` | Session cleanup and final logging |

## Skill Evals

Critical skills ship test cases in `skills/<name>/evals/evals.json`, following the official [skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) schema. Current coverage: `dev` and `dev-all` (autonomous-mode /goal condition quality, evidence validation, stop behavior).

How to run (skill-creator methodology):
1. Spawn with-skill and without-skill (baseline) runs **in the same turn**, 3 runs per configuration
2. Grade with a separate grader agent against each eval's `expectations` — require evidence per expectation, not a verdict
3. **Record for every run: subject model, date, and skill commit hash** — numbers from unrecorded runs are not comparable

## Feature Bloat Prevention

AI-driven development can accelerate implementation speed, but without guardrails it leads to scope explosion. This plugin addresses this structurally:

### Core Value Filter

Each project defines **Core Values** (max 3) in its `CLAUDE.md`. Every feature proposal must pass the **one-step distance test**:

> "Does this DIRECTLY strengthen a Core Value, without intermediate reasoning?"

- ✅ "Translation accuracy improvement → Core Value: accurate translation" (1 step)
- ❌ "Add meeting summary → helps users → they'll use translation more" (2+ steps)

### Won't Do Registry

Features explicitly decided NOT to build are recorded in `CLAUDE.md → ## Won't Do` with reasoning. This prevents:
- Future audits from re-proposing the same rejected ideas
- Research documents from becoming feature requests without review

### Structural Constraints

- **competitive-audit**: Max 3 issues per run, Core Value gate at Phase 0, user pain points as primary input (not competitor feature lists)
- **ai-ops rule**: Research → Issue → Weekly review → Implementation (no shortcut from research to code)
- **dev-all**: Auto-skips `won't`-labeled issues and Won't Do list entries

## Harness Engineering Design

This plugin follows [harness engineering](https://mitchellh.com/writing/my-ai-adoption-journey) principles:

- **Deterministic feedback loops**: Hooks provide millisecond-level lint/format feedback — not dependent on LLM judgment
- **Context efficiency**: Skills are on-demand (loaded only when invoked), `context: fork` isolates token-heavy investigation, sub-agents provide context firewalls
- **Dual-model design**: Codex handles technical design exploration; Claude handles implementation, review, and codebase consistency — each model used for its strength
- **Failure-driven improvement**: `PostToolUseFailure` hook logs patterns → human promotes to `rules/*.md` → never happens again
- **Peelable design**: Each component is independent — remove what the model no longer needs
- **Language-agnostic**: Skills reference CLAUDE.md for project-specific commands, not hardcoded build tools
- **Depth over breadth**: Core Value filter + Won't Do registry prevent feature factory anti-pattern

### Architecture

```
Plugin (language-agnostic)          Project (specific)
┌──────────────────────────┐    ┌──────────────────────────┐
│ skills/ — workflow       │    │ CLAUDE.md — commands,    │
│   dev, dev-investigate,  │    │   architecture, gotchas  │
│   dev-all, review, pr,   │    │                          │
│   dig, decompose, audit  │    │ .claude/agents/          │
│                          │    │   kmp-reviewer.md        │
│ agents/ — shared (8)     │    │   ui-reviewer.md         │
│   security-reviewer,     │    │                          │
│   test-writer, ...       │    │ .claude/rules/           │
│                          │    │   kmp.md, android.md     │
│ hooks/ — auto-lint,      │    │                          │
│   block-dangerous,       │    │ .claude/settings.json    │
│   log-failure,           │    │                          │
│   log-subagent           │    │ REVIEW.md                │
│                          │    └──────────────────────────┘
│ rules/ — behavior,       │
│   ai-ops, coding-conv    │
└──────────────────────────┘
```

## Workflow: dev

```
/ai-dev:dev #42
    ├─ Phase 1: Issue Understanding (GitHub / Linear / Figma)
    ├─ Phase 2: Investigation (/dev-investigate, context: fork)
    ├─ Phase 2.5: Technical Design (Codex MCP, optional)
    ├─ Phase 3: Ambiguity Resolution (/dig + Codex design review)
    ├─ Phase 4: Task Decomposition (/decompose + Codex validation)
    ├─ ── User confirms approach ──
    ├─ Phase 5: Branch & Implement (subtask loop)
    ├─ Phase 6: Quality Gate (build/test/lint from CLAUDE.md)
    ├─ Phase 7: Review (/review → review.json artifact)
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
        ├─ /dev #42 (autonomous sub-agent, worktree isolation)
        ├─ Review validation (review.json: critical→skip, warning→ask)
        ├─ CI wait → conditional auto-merge
        ├─ /dev #43 (fresh context, latest main)
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
│   ├── dev-investigate/SKILL.md  ← context: fork investigation
│   ├── dev-all/SKILL.md
│   ├── review/SKILL.md
│   ├── pr/SKILL.md
│   ├── dig/SKILL.md
│   ├── decompose/SKILL.md
│   ├── audit/SKILL.md
│   ├── competitive-audit/SKILL.md
│   ├── ux-audit/
│   │   ├── SKILL.md
│   │   └── reference.md
│   ├── tech-debt/SKILL.md
│   ├── think/SKILL.md
│   ├── update-docs/SKILL.md
│   ├── monitor/SKILL.md
│   ├── sync/
│   │   ├── SKILL.md
│   │   └── sync-config.json
│   └── init-project/
│       ├── SKILL.md
│       └── templates/
├── agents/
│   ├── security-reviewer.md
│   ├── test-writer.md
│   ├── repo-analyzer.md
│   ├── deep-researcher.md
│   ├── case-analyzer.md
│   ├── social-scanner.md
│   ├── source-verifier.md
│   └── counter-argument.md
├── hooks/
│   └── hooks.json
├── scripts/
│   ├── auto-lint.sh
│   ├── block-dangerous-commands.sh
│   ├── block-secret-access.sh
│   ├── log-failure.sh
│   ├── log-subagent.sh           ← lifecycle event logger
│   ├── save-context.sh
│   └── restore-context.sh
├── layers/
│   ├── mobile/
│   │   ├── agents/
│   │   │   ├── ui-reviewer.md
│   │   │   └── perf-reviewer.md
│   │   ├── rules/
│   │   │   ├── mobile-conventions.md
│   │   │   ├── design-personality.md
│   │   │   └── l10n-conventions.md
│   │   └── templates/  (CI workflows)
│   ├── web/
│   │   ├── agents/ui-reviewer.md
│   │   └── rules/web-conventions.md
│   └── iot/
│       └── rules/iot-conventions.md
└── rules/
    ├── behavior.md              ← No Guessing + Codex MCP usage
    ├── coding-conventions.md
    └── ai-ops.md                ← Core Value guard + Codex conditions + WIP limit
```

## License

MIT
