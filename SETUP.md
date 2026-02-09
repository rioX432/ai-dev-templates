# AI Dev Templates — Setup Guide

AI-driven development templates for Claude Code projects.

## Contents

```
.claude/
  commands/
    review.md          ← /review skill (mobile code review with checklist)
    pr.md              ← /pr skill (PR creation with template)
  settings.json        ← Claude Code permission presets
.github/
  pull_request_template.md  ← PR template
  workflows/
    ai-ops-daily.yml.template  ← Daily AI analysis pipeline (GitHub Actions)
CLAUDE.md.template     ← Base CLAUDE.md for AI-driven projects
```

## Usage

### New Project Setup

```bash
# Copy templates to your project
cp -r ai-dev-templates/.claude/ your-project/.claude/
cp -r ai-dev-templates/.github/ your-project/.github/
cp ai-dev-templates/CLAUDE.md.template your-project/CLAUDE.md

# Edit CLAUDE.md — fill in project-specific sections
# Edit .github/workflows/ — uncomment and configure pipelines
```

### What Each File Does

| File | Purpose | Customize? |
|---|---|---|
| `.claude/commands/review.md` | Code review skill with mobile-specific checklist | Add project-specific checks |
| `.claude/commands/pr.md` | PR creation automation | Update title format if needed |
| `.claude/settings.json` | Auto-allow common CLI commands | Add project-specific commands |
| `.github/pull_request_template.md` | PR template | Add project-specific sections |
| `CLAUDE.md.template` | AI behavior rules + architecture guide | **Must customize per project** |
| `ai-ops-daily.yml.template` | Automated data collection + AI analysis | Configure API keys and scripts |

### Included Workflows

1. **Review** (`/review`): Multi-phase code review
   - Architecture → Mobile (Compose/SwiftUI) → KMP → Performance → Security → Quality
   - Cross-review with Gemini MCP
   - Severity-based output (Critical/Warning/Suggestion/Nit)

2. **PR** (`/pr`): Automated PR creation
   - Analyzes all commits on branch
   - Links GitHub Issues
   - Uses project PR template

3. **AI Ops** (GitHub Actions): Daily automated pipeline
   - Store review collection + sentiment analysis
   - Crashlytics analysis + auto-fix
   - Metrics collection + trend analysis
   - Feature prioritization (2-axis: user requests × metrics)

4. **Feature Prioritization**: 2-axis evaluation framework
   - Axis 1: User requests (qualitative)
   - Axis 2: Metrics (quantitative)
   - Both axes must align before implementing
