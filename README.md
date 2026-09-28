# ai-dev

Portable AI-development workflows with a Claude Code plugin adapter and rendered Codex Agent Skills adapter.
The repository covers autonomous issue resolution, context-isolated investigation, independent design review, UI/UX
auditing, and structured review gates.

**Core philosophy: depth over breadth.** Repositories that opt into the optional [product policy](#product-policy-optional) filter every feature proposal through project-defined Core Values and a one-step distance test, enforcing "what NOT to build" as a first-class concept. The engineering capabilities work without it.

**v3.0 highlights:**
- **Codex integration**: Technical design verification via the Codex CLI (`codex exec`, read-only) in `/dev`, `/dig`, `/decompose` (optional, with fallback)
- **Context isolation**: `/dev-investigate` runs in a forked context, keeping investigation token costs out of the main session
- **Structured review gating**: `/dev-all` validates `review.json` artifacts before auto-merge (Critical → skip, Warning → user confirmation)
- **Lifecycle hooks**: SubagentStart/Stop, TaskCompleted, SessionEnd logging for observability

## Responsibility Boundary

ai-dev-templates is a library of reusable software engineering capabilities, not a scheduler. When a Control Plane
such as Buddy runs the work, responsibilities split three ways:

| Owner | Owns | Examples |
|---|---|---|
| **Control Plane (Buddy)** | WHEN / WHO / HOW MUCH / WHAT CAPABILITY | queue and admission, task graph, agent spawn and concurrency, timeout / retry / resume, worktree scheduling, model and runtime routing, token and cost budget, long-running state, cross-project orchestration, user approval |
| **ai-dev-templates** | reusable HOW | issue sizing, investigation method, implementation guidance, review criteria, PR conventions, generic coding conventions, audits, project bootstrap, verification guidance, thin standalone wrappers |
| **Repository** | WHAT IS TRUE HERE | current architecture, build / test / lint commands, project conventions, constraints and gotchas, local exceptions |

**No nested orchestration.** Work assigned by a Control Plane resolves individual capabilities from the
[Capability Manifest](#capability-manifest) and never starts `/dev`, `/dev-all`, `/orchestrate`, or `/goal` as an
inner loop. Those remain available for direct Claude Code and Codex use: `/dev-all` and `/orchestrate` are
standalone fallbacks, and their admission, WIP, ordering, retry, effort, model-selection, and `/goal` rules live in
[standalone/orchestration.md](standalone/orchestration.md), which is excluded from resolver context.

**Where a new orchestration feature goes.** If it decides when work runs, which work is admitted, who or which
model runs it, how many run at once, how long or how much it may spend, or how a run resumes, it belongs in the
Control Plane (Buddy). Only a standalone equivalent needed by direct Claude/Codex users is added here, and only in
`standalone/` or a `standalone.*` wrapper. If it describes how to do one engineering task well regardless of who
scheduled it, it belongs here as a capability. If it is a fact about one repository, it belongs in that repository.

## Assumptions

This plugin is **language-agnostic but not tracker-agnostic**. It assumes:

| Assumption | Where it binds |
|---|---|
| **GitHub** is the issue tracker and code host, with the `gh` CLI authenticated | `issue`, `pr`, `dev`, `dev-all`, `audit`, `ux-audit`, `competitive-audit`, `monitor` |
| The project documents build/test/lint commands in `AGENTS.md` or `CLAUDE.md` | every skill that runs a quality gate; repository guidance wins over auto-detection |
| The project defines **Core Values** in its repository guidance — only where the [product policy](#product-policy-optional) applies | `competitive-audit` (hard gate), `issue`, `dev-all` |

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

## Capability Manifest

`capabilities/manifest.json` publishes fine-grained capabilities so a resolver can load one unit of reusable HOW
instead of the whole plugin. `capabilities/schema.json` defines the entry shape.

| Field | Meaning |
|---|---|
| `id` | Stable dotted ID such as `coding.investigate`, `coding.review`, `github.pr`, `ux.audit` |
| `kind` | `capability` (reusable HOW), `policy` (optional rules a repository opts into), or `standalone` (never exported) |
| `scope` | The unit it operates on, what it produces, and what it deliberately excludes |
| `entrypoint`, `resources` | Repository-relative files to load; a `skill` resource is the whole skill directory |
| `authority` | Workspace access, external side effects, whether it spawns agents, whether it needs a user |
| `hosts` | `claude` / `codex` support: `native`, `rendered` (Codex skill adapter), `partial`, or `unsupported` |
| `composes` | Capabilities it may invoke; an exported entry can never compose a `standalone` one, and its `authority` must cover everything the composed entries can do |
| `contract_version`, `content_hash` | Contract major version and a SHA-256 over every resource file |

A resolver consumes one entry like this:

1. `python3 scripts/validate-capabilities.py resolve coding.review` — prints the entry, after validating the whole
   manifest and every content hash. `export` prints every exported entry; neither ever returns `standalone` entries.
2. Check `hosts` for the current runtime and `authority` against what the caller is allowed to do. Side effects
   listed there (`git.push`, `github.pr.write`, …) are approved by the caller, not by the capability.
3. Load `entrypoint`, and only the other `resources` the entrypoint links to when the workflow reaches them.
4. Pin `content_hash`; a different hash is a different contract revision even when `contract_version` is unchanged.

Standalone entries are listed so every skill, agent, and rule is classified, not so they can be loaded:
`standalone.dev` (E2E composition wrapper), `standalone.dev-investigate` (forked-context adapter),
`standalone.dev-all` and `standalone.orchestrate` (Control Plane loops), `standalone.orchestration-policy`
(standalone operating policy), and `standalone.sync` (distribution). `python3 scripts/validate-capabilities.py
context` prints the exact text a resolver loads by default; `./scripts/test-capability-manifest.sh` fails if it
contains queue, WIP, model-routing, retry, worktree, or `/goal` policy.

Policy entries (`kind: policy`, currently `policy.core-value-filter`) are exported and resolvable but carry
`policy.optional: true` and are left out of the default context. Add them with `context --policy <id>` only for a
repository that opted in.

`python3 scripts/validate-capabilities.py` exits 0 and prints `capability manifest: OK` when the manifest matches
its schema, every resource exists, every hash is current, and no standalone wrapper is exported. After editing a
skill, agent, or rule, run `python3 scripts/validate-capabilities.py update-hashes` and review the hash change with
the content change. `./scripts/test-capability-manifest.sh` covers the rejection cases.

### Capabilities and standalone wrappers

A capability does one reusable job and stops: it takes its inputs from the caller, reports a structured result,
and does not start other steps the caller did not ask for. `/dev` is a standalone composition wrapper that runs
the capabilities in a fixed order for one person and owns the confirmations between them:

| `/dev` phase | Capability it delegates to |
|---|---|
| Investigation | `coding.investigate` (through the forked `dev-investigate` adapter) |
| Ambiguity resolution | `coding.clarify` |
| Decomposition | `coding.decompose` |
| Implementation | `coding.implement` (`skills/implement-guidance`) |
| Comment cleanup | `coding.cleanup` |
| Review | `coding.review` |
| Pull request | `github.pr` |

Buddy resolves the individual capabilities it needs and composes them under its own scheduling, approvals, and
budgets. It does not invoke `/dev` as a Control Plane; the wrapper exists for backward-compatible direct use.

The manifest is a provider contract. It is unrelated to `.claude/.ai-dev-synced`, which records what a sync copied
into one target repository so pruning never touches project-owned files.

## Skills

| Skill | Description |
|---|---|
| `/ai-dev:dev {issue}` | Standalone E2E wrapper: investigate (forked) → Codex design → dig → decompose → implement → test → review → PR |
| `/ai-dev:implement-guidance [change]` | Implement one confirmed, bounded change with per-subtask Verify; no investigation, review, commit, PR, or agents |
| `/ai-dev:dev-all [issues]` | Standalone fallback: /dev per admitted issue (explicit IDs, or the `ready` label when empty) in an isolated sub-agent → evidence-based review validation → conditional merge |
| `/ai-dev:orchestrate [goal]` | Standalone fallback for lead-and-workers coordination for one goal that outgrows a single run: fan-out gate → non-overlapping lanes → delegation briefs → evidence gates → independent evaluation → checkpointed state files. Also the home for long-running PoCs that span sessions |
| `/ai-dev:dev-investigate` | Context-isolated codebase investigation (runs with `context: fork`) |
| `/ai-dev:investigate <topic>` | Standalone codebase investigation: data flows, dependencies, impact — report only |
| `/ai-dev:issue [input]` | Right-sized issue authoring: sizing gate → split → template → file. Every issue-creating skill routes through it |
| `/ai-dev:review` | Risk-profiled review: coordinator-only for fast, 0–1 independent reviewer for standard, independent reviewers for highRisk; specialists only on matching surfaces |
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

Model tiers follow `standalone/orchestration.md → Model Selection for Agents` in standalone use; a Control Plane
routes models itself. Aliases are convenience defaults, not quality
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
runner rejects an eval dir inside a loaded component directory. Coverage: 55 cases across 20 skills, including the
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

# cases whose skill edits files need the operator grant, or Edit/Write are disabled in the run
claude plugin eval . --case 'implement-guidance-*' --runs 1 --judge-model sonnet --scaffold --allow-tools Edit Write --no-publish
```

`--case` takes one glob; when it is repeated, only the last one applies. Project agents seeded under a scaffold's
`.claude/agents/` are not registered as agent types in eval runs, so a grader for one also accepts a
general-purpose agent briefed with that file.

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

## Verification Profiles

`rules/verification.md` (`coding.verify`) sizes verification to what a change can break instead of running one fixed
build + test + lint gate for everything:

| Profile | Chosen when a signal like… | Required tiers |
|---|---|---|
| `fast` | `docs-only`, `comments-only`, `test-only`, `refactor-no-behavior-change` | focused (no local full suite) |
| `standard` | `behavior-change`, `new-feature`, `crosses-module-boundary` | focused + affected-module (+ integration across modules) |
| `highRisk` | `auth`, `security`, `public-contract`, `data-migration`, `concurrency`, `build-or-ci-config` | focused + affected-module + integration + full |

The highest signal wins and diff size never lowers it. An issue's `Done when` commands always run, and repository
guidance overrides every default. `standard` may hand `integration`, and `highRisk` may hand `full`, to a required
CI check that passes on the same head commit. After a review fix, only the surface that fix touched is re-verified.

`/review` (`coding.review`) uses the same classification for reviewer count: `fast` is reviewed by the coordinator
alone (0 independent reviewers), `standard` adds at most one — the specialist whose surface the change touches,
or a general reviewer for a concrete signal — and
`highRisk` always has at least one. Security, UI, and performance specialists — including project reviewers in
`.claude/agents/` — run only when the change touches their surface. Critical/Warning verification, deduplication,
and Critical blocking are unchanged.

`scripts/verification-gate.py` checks a verification record deterministically (`classify`, `check`), and
`./scripts/test-verification-gate.sh` proves a highRisk record with only focused checks fails, a fast record running
the full suite locally fails, stale or failed evidence satisfies nothing, and the rule's table matches the script.

## Feature Bloat Prevention

AI-driven development can accelerate implementation speed, but without guardrails it leads to scope explosion. This plugin addresses this structurally:

### Product Policy (optional)

The Core Value filter, Won't Do registry, weekly review of research issues, and 2-axis feature prioritization live
in [policies/core-value-filter.md](policies/core-value-filter.md) (`policy.core-value-filter`). They decide which
features are worth building; they never gate bug or security fixes, investigation, implementation, verification, or
review. A repository without Core Values uses every engineering capability unblocked.

Which policy applies is resolved in this order, and the first match wins:

| Precedence | Source | Effect |
|---|---|---|
| 1 | Repository guidance `## Product policy` (`AGENTS.md` / `CLAUDE.md`) | `none` turns it off; `core-value-filter` turns it on; a repository path replaces it with the repository's own policy |
| 2 | Compatibility default | With no such section, the policy applies when the repository has `## Core Values` or `## Won't Do`, or a synced `.claude/rules/core-value-filter.md` |
| 3 | Provider default | Otherwise the repository is generic-only and nothing asks for Core Values |

Repository truth outranks the provider: the repository's Core Values, Won't Do entries, and any replacement policy
are the content; the provider file only supplies the procedure. `/sync` copies the policy to
`.claude/rules/core-value-filter.md` (`policy_rules` in `sync-config.json`), so a project synced before this split
keeps enforcing it without editing anything; it opts out with `## Product policy` set to `none`. A Control Plane
adds `policy.core-value-filter` to a task's context only for a repository where the policy applies.

### Core Value Filter

Each project defines **Core Values** (max 3) in its `AGENTS.md` / `CLAUDE.md`. Every feature proposal must pass the **one-step distance test**:

> "Does this DIRECTLY strengthen a Core Value, without intermediate reasoning?"

- ✅ "Translation accuracy improvement → Core Value: accurate translation" (1 step)
- ❌ "Add meeting summary → helps users → they'll use translation more" (2+ steps)

### Won't Do Registry

Features explicitly decided NOT to build are recorded under `## Won't Do` in repository guidance with reasoning. This prevents:
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
- **ai-ops rule**: Research → Issue → Implementation (no shortcut from research to code); the product policy adds a weekly review
- **dev-all**: Admits only explicit issue IDs or the ready label; auto-skips `won't`-labeled issues, and Won't Do list entries where the product policy applies

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
- **Depth over breadth**: the optional Core Value filter + Won't Do registry prevent the feature factory anti-pattern

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
    ├─ Phase 5: Branch & Implement (/implement-guidance → /clean-slop)
    ├─ Phase 6: Verification (fast / standard / highRisk profile)
    ├─ Phase 7: Review (/review → review.json artifact)
    ├─ ── User confirms commit ──
    └─ Phase 8: Commit & PR (/pr)
```

## Workflow: dev-all

```
/ai-dev:dev-all #42 #43 #44        (no arguments: open issues labeled `ready`, never all open issues)
    ├─ Step 1: Resolve admitted issues + dependency analysis
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
├── capabilities/
│   ├── manifest.json              ← fine-grained capability IDs, authority, hosts, content hashes
│   └── schema.json
├── evals/                         ← claude plugin eval suite, <skill>/<case>/
├── skills/
│   ├── dev/SKILL.md
│   ├── dev-investigate/SKILL.md  ← context: fork, thin wrapper
│   ├── implement-guidance/SKILL.md ← coding.implement: bounded implementation loop
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
│   ├── validate-capabilities.py   ← manifest schema, reference, hash, and export validation
│   ├── test-capability-manifest.sh
│   ├── verification-gate.py       ← verification profile classification + record check
│   ├── test-verification-gate.sh
│   ├── sync-config.py             ← sync schema validation + CI matrix rendering
│   ├── test-sync-config.sh
│   ├── save-context.sh
│   └── restore-context.sh
├── standalone/
│   └── orchestration.md           ← admission, WIP, retry, effort, model selection, /goal (standalone only)
├── policies/
│   └── core-value-filter.md       ← optional product policy: Core Values, Won't Do, weekly review, 2-axis
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
    ├── verification.md          ← risk-based verification profiles
    └── ai-ops.md                ← issue-driven engineering flow (no product policy required)
```

## License

MIT
