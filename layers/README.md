# Layers

Layers bundle platform/framework-specific agents, rules, and CI templates. Projects reference an **ordered list** of layers (`layers` in `skills/sync/sync-config.json` and the matrix in `.github/workflows/sync-to-projects.yml`); files are applied in order, so later layers override earlier ones on filename collision.

| Layer | Scope |
|---|---|
| `kmp` | KMP/CMP mobile (Android + iOS via Compose Multiplatform) — formerly named `mobile` |
| `react-native` | React Native / Expo mobile |
| `web` | TypeScript, React, Vue, Node.js, Electron |
| `iot` | C++, Python, embedded |

Language-level differences (build/test/lint commands) are **not** a layer concern — skills resolve them from each project's `CLAUDE.md → Commands`. Layers own conventions and review criteria only.

## Sibling layers & drift policy

`kmp` and `react-native` are **parallel adaptations**: they cover the same concerns with the same filenames (`mobile-conventions.md`, `design-personality.md`, `l10n-conventions.md`, `ui-reviewer.md`, `perf-reviewer.md`) but framework-specific content. They share structure and universal principles (~25–40% of lines), not text — this is deliberate, so there is no extracted "mobile-core" layer.

**When you change a universal principle in one sibling (e.g. touch-target minimums, single-accent-color rule, RTL support, truncation handling), check the same section in the other sibling and mirror the change.** Framework mechanics (Compose recomposition vs. RN re-renders, `strings.xml` vs. `i18next`) evolve independently — no mirroring needed.

## Constraints from CI distribution

The sync workflow copies layer files **by basename** into target repos' `.claude/` and never deletes. Therefore:

- **Do not rename layer rule/agent files.** A rename ships the new file but strands the old one in every target repo. If a rename is unavoidable, ship a cleanup commit to each target (or handle it in the sync PR body).
- Renaming a **layer directory** (like `mobile` → `kmp`) is safe — only source paths change; update `sync-config.json` and the workflow matrix together.

## Adding a new framework layer (e.g. flutter)

1. Create `layers/flutter/` mirroring the `react-native` file set: `rules/{mobile-conventions.md,design-personality.md,l10n-conventions.md}`, `agents/{ui-reviewer.md,perf-reviewer.md}`, `templates/pull_request_template.md`. Adapt content from the closest sibling; keep section structure aligned so drift checks stay easy.
2. Register it in `sync-config.json → layer_types`.
3. Add the project to `projects` and to the workflow matrix (`layers: flutter`).
4. Add the language to `scripts/auto-lint.sh` (e.g. `dart)` case) and, if needed, to `/dev`'s command-detection fallback (e.g. `pubspec.yaml`).
