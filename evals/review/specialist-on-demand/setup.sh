#!/usr/bin/env bash
# Seeds a web project with project reviewers for UI and performance, and a UI-only change.
set -euo pipefail

mkdir -p .claude/agents src/components

cat > .claude/agents/ui-reviewer.md <<'MD'
---
name: ui-reviewer
description: "Reviews UI components, styles, and accessibility in src/components and *.css. Use when a change touches user-facing UI."
tools: Read, Grep, Glob
---

Review the changed UI for accessibility (labels, contrast, focus order, target size) and consistency with existing components.
MD

cat > .claude/agents/perf-reviewer.md <<'MD'
---
name: perf-reviewer
description: "Reviews performance of data loading, list rendering, and hot paths in src/data and src/lists. Use when a change touches those paths."
tools: Read, Grep, Glob
---

Review the changed hot paths for redundant work, unbounded lists, and blocking I/O.
MD

cat > src/components/SaveButton.tsx <<'TSX'
export function SaveButton({ onSave }: { onSave: () => void }) {
  return (
    <button className="btn" onClick={onSave}>
      <SaveIcon />
    </button>
  );
}
TSX

git init -q
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "initial project"
