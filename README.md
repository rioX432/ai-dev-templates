# ai-dev-templates

AI-driven development templates for Claude Code projects. Copy these into your project to get a standardized setup for code review, PR creation, tech debt scanning, and automated ops.

## Contents

```
.claude/
  commands/
    review.md       # /review — multi-phase code review (Architecture → Mobile → KMP → Perf → Security)
    pr.md           # /pr — PR creation with template and issue linking
    tech-debt.md    # /tech-debt — codebase scan with auto GitHub Issue creation
  settings.json     # Permission presets for common CLI tools
.github/
  pull_request_template.md
  workflows/
    ci.yml.template             # KMP CI (Android + iOS build & test)
    ai-ops-daily.yml.template   # Daily analysis pipeline (reviews, crashes, metrics)
CLAUDE.md.template  # Base CLAUDE.md with behavior rules and AI-driven dev flow
```

## Usage

```bash
# Copy to your project
cp -r .claude/ /path/to/your-project/.claude/
cp -r .github/ /path/to/your-project/.github/
cp CLAUDE.md.template /path/to/your-project/CLAUDE.md

# Then customize:
# 1. CLAUDE.md — fill in project name, architecture, tech stack
# 2. .github/workflows/*.template — rename to .yml and configure secrets
# 3. .claude/settings.json — add project-specific allowed commands
```

See [SETUP.md](SETUP.md) for detailed instructions.

## Skills

| Skill | What it does |
|---|---|
| `/review` | Runs a multi-phase code review checklist (Compose, SwiftUI, KMP, security, perf) with Gemini cross-review |
| `/pr` | Creates a PR from current branch using the project's PR template |
| `/tech-debt` | Scans for code smells, architecture issues, perf problems, and creates GitHub Issues for high-severity findings |

## License

MIT
