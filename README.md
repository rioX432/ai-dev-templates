# ai-dev

Portable AI-development workflows with a Claude Code plugin adapter and rendered Codex Agent Skills adapter.
The repository covers autonomous issue resolution, context-isolated investigation, independent design review, UI/UX
auditing, and structured review gates.

**Core philosophy: depth over breadth.** Every feature proposal is filtered through project-defined Core Values and a one-step distance test. The system is designed to prevent feature bloat by enforcing "what NOT to build" as a first-class concept.

**v3.0 highlights:**
- **Codex integration**: Technical design verification via the Codex CLI (`codex exec`, read-only) in `/dev`, `/dig`, `/decompose` (optional, with fallback)
- **Context isolation**: `/dev-investigate` runs in a forked context, keeping investigation token costs out of the main session
- **Structured review gating**: `/dev-all` validates `review.json` artifacts before auto-merge (Critical → skip, Warning → user confirmation)
- **Lifecycle hooks**: SubagentStart/Stop, TaskCompleted, SessionEnd logging for observability

## Assumptions

This plugin is **language-agnostic but not tracker-agnostic**. It assumes:

| Assumption | Where it binds |
|---|---|
| **GitHub** is the issue tracker and code host, with the `gh` CLI authenticated | `issue`, `pr`, `dev`, `dev-all`, `audit`, `ux-audit`, `competitive-audit`, `monitor` |
| The project documents build/test/lint commands in `AGENTS.md` or `CLAUDE.md` | every skill that runs a quality gate; repository guidance wins over auto-detection |
| The project defines **Core Values** in its repository guidance | `competitive-audit` (hard gate), `issue`, `rules/ai-ops.md` |

`/dev` can *read* a Linear issue (`XXX-1234`) through the Linear MCP, but every write path —
issue creation, branch, PR, merge — is GitHub. A project on Jira or GitLab can use the
investigation, review and decomposition skills, not the issue and PR ones.

`monitor` additionally assumes a mobile app with store presence and Crashlytics.

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
| `/ai-dev:orchestrate [goal]` | Lead-and-workers coordination for one goal that outgrows a single run: fan-out gate → non-overlapping lanes → delegation briefs → evidence gates → independent evaluation → checkpointed state files. Also the home for long-running PoCs that span sessions |
| `/ai-dev:dev-investigate` | Context-isolated codebase investigation (runs with `context: fork`) |
| `/ai-dev:investigate <topic>` | Standalone codebase investigation: data flows, dependencies, impact — report only |
| `/ai-dev:issue [input]` | Right-sized issue authoring: sizing gate → split → template → file. Every issue-creating skill routes through it |
| `/ai-dev:review` | Multi-agent parallel code review (Bug/Security + Architecture/Quality) |
| `/ai-dev:clean-slop [scope]` | Remove AI narration and change-history comments from the current change; comment text only. Runs as `/dev`'s cleanup pass |
| `/ai-dev:pr` | PR creation using project template with issue linking |
| `/ai-dev:dig` | Structured ambiguity resolution with auto-decide rules + Codex design review |
| `/ai-dev:decompose` | Task decomposition into ordered subtasks + Codex architecture validation |
| `/ai-dev:audit [scope]` | Evidence-gated codebase audit (debt / quality / architecture+performance / broken UI / security / deps) → optional GitHub Issues |
| `/ai-dev:competitive-audit [focus]` | Core Value-filtered competitive analysis: user pain points → max 3 issues + Won't Do recording |
| `/ai-dev:ux-audit [target]` | Evidence-based user-flow audit: current-run capture, UX, WCAG 2.2, responsive/platform checks, verification gaps → optional GitHub Issues |
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

Model tiers follow `rules/ai-ops.md → Model Selection for Agents`. Aliases are convenience defaults, not quality
claims: record the resolved model and date in eval results, and use evals before moving a workflow to a smaller or
newer model.

## Hooks

| Event | Action |
|---|---|
| `PostToolUse` (Write/Edit) | Synchronous, non-mutating validation: ktlint, swiftformat, eslint, ruff, dart, jq |
| `PreToolUse` (Bash) | Block dangerous commands (force push, rm -rf, drop table, etc.) |
| `PreToolUse` (Read/Edit/Write/Bash) | Block direct secret-file access (.env, keys, credentials) as defense in depth |
| `PostToolUseFailure` | Log failure patterns to `logs/failures/` for harness improvement |
| `PreCompact` | Save critical context (branch, changed files, progress) before compaction |
| `PostCompact` | Restore critical context (progress.txt) after compaction |
| `SessionStart` | Restore context at session start (handles post-compaction recovery) |
| `SubagentStart` | Log subagent lifecycle to `logs/subagents/` (JSONL) |
| `SubagentStop` | Log subagent completion with result summary |
| `TaskCompleted` | Log task completion events |
| `SessionEnd` | Session cleanup and final logging |

Run `./scripts/test-hooks.sh` after changing a safety or logging hook. The fixtures cover reordered destructive
flags, secret access through file and shell tools, valid JSONL, and non-persistence of raw tool/subagent content.

## Skill Evals

Eval cases live at the plugin root in `evals/<skill>/<case>/`, in the layout `claude plugin eval` runs: a
`prompt.md` (frontmatter plus the prompt) and one or more `graders/*.md`. They cannot live under `skills/` — the
runner rejects an eval dir inside a loaded component directory. Coverage: 47 cases across 19 skills, including the
high-risk boundaries in `init-project`, `monitor`, `pr`, `sync`, `think`, `update-docs`, and `ux-audit`. Each case
targets a failure mode its skill exists to prevent rather than matching presentation wording.

Every case carries an `llm` criteria grader. Cases also use these when the failure mode supports them:

- `graders/skill-fired.md` — a `tool_used` grader proving the skill actually loaded. The runner excludes it from
  the score in the two-arm run, since it cannot pass without the plugin
- a deterministic grader wherever the failure mode allows one — `orchestrate/fan-out-gate-refuses` asserts the
  `Agent` tool was never used (`arm: both`, so the baseline is held to it too)

Cases needing files to read seed them in `fixtures/` and list it in `case.yaml` under `context.add_dirs`; each run
otherwise starts in an empty throwaway workspace.

```bash
# whole suite, one run per arm
claude plugin eval . --runs 1 --judge-model sonnet --no-publish

# one skill; --scaffold is required by cases that seed a fixture repository
claude plugin eval . --case 'orchestrate-*' --runs 1 --judge-model sonnet --scaffold --no-publish
```

- `--ablation with-without` is the default: each case runs with and without the plugin and the report shows the
  delta. A skill whose score does not move is not paying for its tokens.
- `--runs` defaults to 3. Use 1 for a quick check, 3 when the number has to mean something.
- `--threshold <0..1>` turns it into a CI gate (exit 1 when a case scores below it).
- **Pass `--judge-model sonnet`.** The default judge is Haiku, and it returned false FAILs on long, structured
  responses here — it failed a plan that stated the integration gate verbatim. Sonnet scored the same response
  1.0. Criteria with several conjunctive conditions need the stronger judge.
- `--case` is not repeatable: a second one replaces the first. Use one glob.
- A case that needs a repository to reason about seeds it in `setup.sh` and only runs under `--scaffold`; each run
  otherwise starts in an empty throwaway workspace and the agent correctly refuses to plan against nothing.
- A slash-invoked skill is expanded inline and never calls the `Skill` tool, so `tool_used: Skill` cannot pass for
  a skill with `disable-model-invocation`. Those cases prove the skill fired through the with/without delta
  instead.
- `--allow-tools Bash` cannot run on a machine whose Docker credential store (`~/.docker`) contains a symlink —
  Docker Desktop's own `cli-plugins` links are enough to block it. Cases here stay within read-only tools plus
  `Write`/`Edit` where the behaviour needs them.
- Record the subject model, the judge model, the date, and the plugin commit next to any score you keep; runs from
  different models are not comparable.

Reference: [plugin evals documentation](https://code.claude.com/docs/en/plugin-evals.md).

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

### Issue Sizing Gate

Every issue-creating skill (`audit`, `ux-audit`, `competitive-audit`, `monitor`) delegates
to `/ai-dev:issue` instead of calling `gh issue create` itself. That skill enforces one gate before
anything is filed:

| # | Check | Fails when |
|---|-------|-----------|
| 1 | Single outcome | Title needs "and", or is a category verb with no object |
| 2 | Bounded change | Expected edit exceeds ~5 files / ~300 lines |
| 3 | Single proof | No `Done when` naming a real command and its exact success output |
| 4 | No open decisions | An unresolved design choice is still in the body |
| 5 | Independently mergeable | Merging it alone breaks the repo or changes nothing observable |

A failed gate produces a split (`skills/issue/splitting.md`), a spike, or an epic with children —
never a filed issue. `/dev` runs the same gate on its incoming issue and stops rather than
implementing an oversized one, because an issue's `Done when` is reused verbatim as the `/goal`
completion condition.

### Structural Constraints

- **competitive-audit**: Max 3 issues per run, Core Value gate at Phase 0, user pain points as primary input (not competitor feature lists)
- **ai-ops rule**: Research → Issue → Weekly review → Implementation (no shortcut from research to code)
- **dev-all**: Auto-skips `won't`-labeled issues and Won't Do list entries

## Harness Engineering Design

This plugin follows [harness engineering](https://mitchellh.com/writing/my-ai-adoption-journey) principles:

- **Deterministic feedback loops**: Hooks provide fast, non-mutating syntax and lint feedback — not dependent on LLM judgment
- **Trust-aware context**: web pages, issue bodies, source comments, and tool output are untrusted data; write and
  external side effects remain separate from read-only discovery
- **Context efficiency**: Skills are on-demand (loaded only when invoked), `context: fork` isolates token-heavy investigation, sub-agents provide context firewalls
- **Progressive disclosure**: every SKILL.md body stays well under the 500-line budget; procedures, criteria and templates live in sibling reference files that load only when the workflow reaches them (`investigate/report-format.md` is shared by two skills, so the method exists once)
- **Single writer per side effect**: only `issue` calls `gh issue create`; only `pr` opens PRs. Scanning skills produce findings and hand them over
- **One sync registry**: `sync-config.json` is schema-validated and generates the CI matrix; manual and automated
  paths consume the same skills, agents, rules, layers, projects, and adapter selection
- **Host adapters**: Claude keeps `.claude/skills` and host integrations; Codex receives portable-frontmatter skills
  under `.agents/skills` plus a seed-only `AGENTS.md`. Claude hooks and named agents are not presented as Codex enforcement
- **Independent design check**: Codex can challenge technical designs in a read-only pass; the primary agent owns
  the decision and verifies it against the repository
- **Failure-driven improvement**: `PostToolUseFailure` hook logs patterns → human promotes to `rules/*.md` → never happens again
- **Peelable design**: Each component is independent — remove what the model no longer needs
- **Language-agnostic**: Skills resolve project-specific commands from repository guidance rather than hardcoding one build tool
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
    ├─ Phase 2.5: Technical Design (Codex, optional)
    ├─ Phase 3: Ambiguity Resolution (/dig + Codex design review)
    ├─ Phase 4: Task Decomposition (/decompose + Codex validation)
    ├─ ── User confirms approach ──
    ├─ Phase 5: Branch & Implement (subtask loop → /clean-slop)
    ├─ Phase 6: Quality Gate (build/test/lint from CLAUDE.md)
    ├─ Phase 7: Review (/review → review.json artifact)
    ├─ ── User confirms commit ──
    └─ Phase 8: Commit & PR (/pr)
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
├── evals/                         ← claude plugin eval suite, <skill>/<case>/
├── skills/
│   ├── dev/SKILL.md
│   ├── dev-investigate/SKILL.md  ← context: fork, thin wrapper
│   ├── dev-all/SKILL.md
│   ├── review/SKILL.md
│   ├── pr/SKILL.md
│   ├── clean-slop/SKILL.md
│   ├── dig/SKILL.md
│   ├── decompose/SKILL.md
│   ├── investigate/
│   │   ├── SKILL.md
│   │   └── report-format.md       ← shared with dev-investigate
│   ├── issue/                     ← single writer of GitHub Issues
│   │   ├── SKILL.md
│   │   └── splitting.md           ← split moves + worked examples
│   ├── orchestrate/
│   │   ├── SKILL.md
│   │   └── references/            ← delegation brief, state contract, evidence
│   ├── audit/SKILL.md
│   ├── competitive-audit/
│   │   ├── SKILL.md
│   │   └── research-method.md     ← Phase 2 + 4 procedures
│   ├── ux-audit/
│   │   ├── SKILL.md
│   │   └── reference.md           ← heuristics, WCAG, platform checks
│   ├── think/SKILL.md
│   ├── update-docs/
│   │   ├── SKILL.md
│   │   ├── scanners.md            ← 4 scanner agent prompts
│   │   └── templates.md           ← ARCHITECTURE/CHANGELOG/README/OSS shapes
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
│   ├── test-hooks.sh              ← deterministic hook safety fixtures
│   ├── render-codex-skill.py      ← portable Agent Skills frontmatter adapter
│   ├── test-render-codex-skill.sh
│   ├── sync-config.py             ← sync schema validation + CI matrix rendering
│   ├── test-sync-config.sh
│   ├── save-context.sh
│   └── restore-context.sh
├── layers/                        ← composable: projects reference a list of layers
│   ├── README.md                  ← layer model, drift policy, how to add a layer
│   ├── kmp/                       ← KMP/CMP mobile (formerly "mobile")
│   │   ├── agents/
│   │   │   ├── ui-reviewer.md
│   │   │   └── perf-reviewer.md
│   │   ├── rules/
│   │   │   ├── mobile-conventions.md
│   │   │   ├── design-personality.md
│   │   │   └── l10n-conventions.md
│   │   └── templates/  (CI workflows)
│   ├── react-native/              ← sibling adaptation of kmp (same concerns, RN mechanics)
│   ├── web/
│   │   ├── agents/ui-reviewer.md
│   │   └── rules/web-conventions.md
│   └── iot/
│       └── rules/iot-conventions.md
└── rules/
    ├── behavior.md              ← evidence, trust boundaries, independent review
    ├── coding-conventions.md
    └── ai-ops.md                ← Core Value guard + Codex conditions + WIP limit
```

## License

MIT
