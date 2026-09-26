#!/usr/bin/env bash
# Seeds a small TypeScript project whose formatDuration helper has six call sites.
set -euo pipefail

mkdir -p src/utils src/ui

cat > CLAUDE.md <<'MD'
# timekeeper

## Commands
- Tests: `pnpm test`
- Typecheck: `pnpm typecheck`

## Core Values
- Readable time formatting everywhere in the app
MD

cat > src/utils/time.ts <<'TS'
export function formatDuration(ms: number): string {
  const s = Math.round(ms / 1000);
  return `${Math.floor(s / 60)}m ${s % 60}s`;
}
TS

for f in player queue history settings toast summary; do
  cat > "src/ui/$f.ts" <<TS
import { formatDuration } from "../utils/time";

export function render${f}(ms: number): string {
  return "$f: " + formatDuration(ms);
}
TS
done

git init -q
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "initial project"
