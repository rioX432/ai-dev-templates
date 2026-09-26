# Layers

Layers bundle platform/framework-specific agents, rules, and CI templates. Projects reference an **ordered list** of
layers in `skills/sync/sync-config.json`; the CI matrix is generated from that registry. Files are applied in order,
so later layers override earlier ones on filename collision.

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

The sync workflow copies layer files **by basename** into target repos' `.claude/`. Its manifest-based prune
deletes only paths that a previous ai-dev sync installed and the current configuration no longer owns; files a
project added itself are not eligible. Therefore:

- A renamed layer rule/agent file is removed on the next sync only when the old basename is present in
  `.claude/.ai-dev-synced`. For targets without a manifest, review and remove the stale path manually.
- Renaming a **layer directory** (like `mobile` → `kmp`) is safe when its sources and
  `sync-config.json` entry change together; the workflow matrix is generated automatically.

## Adding a new framework layer (e.g. flutter)

1. Create `layers/flutter/` mirroring the `react-native` file set: `rules/{mobile-conventions.md,design-personality.md,l10n-conventions.md}`, `agents/{ui-reviewer.md,perf-reviewer.md}`, `templates/pull_request_template.md`. Adapt content from the closest sibling; keep section structure aligned so drift checks stay easy.
2. Register it in `sync-config.json → layer_types`.
3. Add the project to `projects` and to the workflow matrix (`layers: flutter`).
4. Add the language to `scripts/auto-lint.sh` (e.g. `dart)` case) and, if needed, to `/dev`'s command-detection fallback (e.g. `pubspec.yaml`).
